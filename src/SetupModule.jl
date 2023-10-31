module SetupModule

# External Packages
using OrderedCollections
using LoggingExtras

# Internal Packages
using ..IOModule

# Exports
export setup_global!

"""
    default_paths::OrderedDict{String, Tuple{String, String}}

The default paths which will be expanded into absolute paths and used throughout the project.

```
default_paths::OrderedDict{String, Tuple{String, String}} = OrderedDict{String, Tuple{String, String}}(
    # Name => relative, default
    "BASE_PATH" => ("INPUT_PATH", ""),
    "OUTPUT_PATH" => ("BASE_PATH", "Output")
)
```

This dictionary maps `("path_name" => ("relative_name", "default_path"))`, where `"path_name"` is a human readable name for the path, `"relative_name"` is the name of the path which `"path_name"` is relative to, and `"default_path"` is the default value for the path (either absolute or relative). If `"path_name"` already exists inside `input["GLOBAL"]`, then that path will be used either as is (if an absolute path) or relative to `"relative_name"`, otherwise the `"default_path"` will be used

"""
const default_paths = OrderedDict{String,Tuple{String,String}}(
    # Name => relative, default
    "BASE_PATH" => ("INPUT_PATH", ""),
    "OUTPUT_PATH" => ("BASE_PATH", "Output")
)


"""
    setup_paths!(input::Dict, paths::OrderedDict{String, Tuple{String, String}})

Helper function which sets up paths, expanding relative paths and ensuring all interim directories exist

# Arguments
- `input::Dict`: The input file we are modifying. This assumes that the input already has a `"GLOBAL"` key with value `Dict{String, Any}("INPUT_PATH"=>"/path/to/input"), where `"INPUT_PATH"` is the path to the `input` file
- `paths::OrderedDict{String, Tuple{String, String}}`: Paths to expand. `paths` will be merged with the following `default_paths`, with `paths` taking preference. See [`default_paths`](@ref) for a the syntax of `paths`

See also [`setup_global!`](@ref)
"""
function setup_paths!(input::Dict, paths::OrderedDict{String,Tuple{String,String}})
    config = input["GLOBAL"]
    for (path_name, (relative_name, default)) in paths
        # Get which `path_name` to set this path relative to
        # Requires that `relative_name` already exists in `config`
        if !(uppercase(relative_name) in keys(config))
            if !(lowercase(relative_name) in keys(config))
                throw(ErrorException("Relative path $relative_name for path $path_name doesn't exist. Make sure you have defined your paths in the correct order!"))
            else
                config[uppercase(relative_name)] = config[relative_name]
                delete!(config, relative_name)
            end
        end
        relative = config[uppercase(relative_name)]
        if !(uppercase(path_name) in keys(config))
            if !(lowercase(path_name) in keys(config))
                config[uppercase(path_name)] = default
            else
                config[uppercase(path_name)] = config[lowercase(path_name)]
                delete!(config, lowercase(path_name))
            end
        end
        path = config[uppercase(path_name)]
        # If `path` is absolute, ignore `relative`, otherwise make `path` relative to `relative`
        if !isabspath(path)
            path = joinpath(relative, path)
        end
        path = abspath(path)
        if !isdir(path)
            mkpath(path)
        end
        config[uppercase(path_name)] = escape_string(path)
    end
    input["GLOBAL"] = config
end


"""
    setup_logging!(input::Dict, output_path::String="OUTPUT_PATH"; log::Bool=true)

Helper function which sets up log level, log files, etc...
Assumes that [`setup_paths!`](@ref) has already been run on `input`

# Arguments
- `input::Dict`: The input file we are modifying. This assumes that the input already has a `"GLOBAL"` key with value `Dict{String, Any}("INPUT_PATH"=>"/path/to/input"), where `"INPUT_PATH"` is the path to the input file
- `output_path::String`: The `"path_name"` of the output directory where log files should be written. See [`default_paths`](@ref) for more details

See also [`setup_global!`](@ref)
"""
function setup_logging!(input::Dict, output_path::String="OUTPUT_PATH")
    config = input["GLOBAL"]
    if !(uppercase(output_path) in keys(config))
        throw(ErrorException("Output path $output_path not defined"))
    end
    output = config[uppercase(output_path)]
    logging = get(config, "LOGGING", true)
    config["LOGGING"] = logging
    # Setup logfile
    log_file = get(config, "LOG_FILE", "log.txt")
    log_file = abspath(joinpath(output, log_file))
    config["LOG_FILE"] = log_file
    input["GLOBAL"] = config
end

"""
    setup_logger(log_file::AbstractString, verbose::Bool)

Helper function which sets up Logger formating and log level

# Arguments
- `log_file::AbstractString`: Path to log file
- `verbose::Bool`: Whether or not to display `@debug` calls

See also [`setup_logging!`](@ref) and [`setup_global!`](@ref)
"""
function setup_logger(log_file::AbstractString, verbose::Bool)
    # Set log level
    if verbose
        level = Logging.Debug
    else
        level = Logging.Info
    end
    # Define logging format
    function fmt(io::IOContext, args::NamedTuple)
        if (args.level == Logging.Error)::Bool
            color = :red
            bold = true
        elseif (args.level == Logging.Warn)::Bool
            color = :yellow
            bold = true
        elseif (args.level == Logging.Info)::Bool
            color = :cyan
            bold = false
        else
            color = :white
            bold = false
        end
        printstyled(io, args._module, " | ", "[", args.level, "] ", args.message, "\n"; color=color, bold=bold)
    end
    # Log to both `log_file` and `stdout`
    logger = TeeLogger(
        MinLevelLogger(FormatLogger(fmt, open(log_file, "w")), level),
        MinLevelLogger(FormatLogger(fmt, stdout), level)
    )
    # Set global logger
    global_logger(logger)
    @info "Logging to $log_file"
end

"""
    setup_global!(input::Dict, input_path::AbstractString, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="OUTPUT_PATH"; test::Bool=false)

Setup the `"GLOBAL"` information of input, including paths and logging.

# Arguments
- `input::Dict`: The input file loaded into a `Dict`
- `input_path::AbstractString`: The path to the input `.input` file (from which `input` is loaded)
- `verbose::Bool`: Whether or not to display `@debug` calls
- `paths::OrderedDict{String, Tuple{String, String}}`: Paths to expand. `paths` will be merged with the following `default_paths`, with `paths` taking preference. See [`default_paths`](@ref) for the syntax of `paths`
- `log_path::String`: The `"path_name"` of the directory where logging should output
- `test::Bool`: Whether this run is a test or not. This will decide whether to actually create directories, or log anything

See also [`setup_paths!`](@ref), and [`setup_logging!`](@ref)
"""
function setup_global!(input::Dict, input_path::AbstractString, verbose::Bool, paths::OrderedDict{String,Tuple{String,String}}=OrderedDict{String,Tuple{String,String}}(), log_path::String="OUTPUT_PATH")
    if !("GLOBAL" in keys(input))
        if !("global" in keys(input))
            input["GLOBAL"] = Dict()
        else
            input["GLOBAL"] = input["global"]
            delete!(input, "global")
        end
    end
    input["GLOBAL"]["INPUT_PATH"] = escape_string(dirname(abspath(input_path)))
    # Merge `paths` with `default_paths`, giving preference to `paths`
    input_paths = merge(default_paths, paths)
    setup_paths!(input, input_paths)
    setup_logging!(input, log_path)
    config = input["GLOBAL"]
    if config["LOGGING"]
        setup_logger(config["LOG_FILE"], verbose)
    end
    return input
end

end
