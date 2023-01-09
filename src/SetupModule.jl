module SetupModule

# External Packages
using TOML
using DataStructures
using LoggingExtras

# Internal Packages

# Exports
export setup_global!

"""
    default_paths::OrderedDict{String, Tuple{String, String}}

The default paths which will be expanded into absolute paths and used throughout the project.

```
default_paths::OrderedDict{String, Tuple{String, String}} = OrderedDict{String, Tuple{String, String}}(
    # Name => relative, default
    "base_path" => ("toml_path", ""),
    "output_path" => ("base_path", "Output")
)
```

This dictionary maps `("path_name" => ("relative_name", "default_path"))`, where `"path_name"` is a human readable name for the path, `"relative_name"` is the name of the path which `"path_name"` is relative to, and `"default_path"` is the default value for the path (either absolute or relative). If `"path_name"` already exists inside `toml["global"]`, then that path will be used either as is (if an absolute path) or relative to `"relative_name"`, otherwise the `"default_path"` will be used

"""
const default_paths::OrderedDict{String, Tuple{String, String}} = OrderedDict{String, Tuple{String, String}}(
    # Name => relative, default
    "base_path" => ("toml_path", ""),
    "output_path" => ("base_path", "Output")
)


"""
    setup_paths!(toml::Dict, paths::OrderedDict{String, Tuple{String, String}}; mkdirs::Bool=true)

Helper function which sets up paths, expanding relative paths and ensuring all interim directories exist

# Arguments
- `toml::Dict`: The toml file we are modifying. This assumes that the toml already has a `"global"` key with value `Dict{Any, Any}("toml_path"=>"/path/to/input"), where `"toml_path"` is the path to the `.toml` file
- `paths::OrderedDict{String, Tuple{String, String}}`: Paths to expand. `paths` will be merged with the following `default_paths`, with `paths` taking preference. See [`default_paths`](@ref) for a the syntax of `paths`
- `mkdirs::Bool`: Whether to actually make the directories or not, useful when simply wanting to populate `toml` without changing anything on the disk

See also [`setup_global!`](@ref)
"""
function setup_paths!(toml::Dict, paths::OrderedDict{String, Tuple{String, String}}; mkdirs::Bool=true)
    config = get(toml, "global", Dict())
    for (path_name, (relative_name, default)) in paths
        # Get which `path_name` to set this path relative to
        # Requires that `relative_name` already exists in `config`
        if !(relative_name in keys(config))
            throw(ErrorException("Relative path $relative_name for path $path_name doesn't exist. Make sure you have defined your paths in the correct order!"))
        end
        relative = config[relative_name] 
        path = get(config, path_name, default)
        # If `path` is absolute, ignore `relative`, otherwise make `path` relative to `relative`
        if !isabspath(path)
            path = joinpath(relative, path)
        end
        path = abspath(path)
        if mkdirs
            if !isdir(path)
                mkpath(path)
            end
        end
        config[path_name] = path
    end
    toml["global"] = config
end


"""
    setup_logging!(toml::Dict, output_path::String="output_path"; log::Bool=true)

Helper function which sets up log level, log files, etc...
Assumes that [`setup_paths!`](@ref) has already been run on `toml`

# Arguments
- `toml::Dict`: The toml file we are modifying. This assumes that the toml already has a `"global"` key with value `Dict{Any, Any}("toml_path"=>"/path/to/input"), where `"toml_path"` is the path to the `.toml` file
- `output_path::String`: The `"path_name"` of the output directory where log files should be written. See [`default_paths`](@ref) for more details
- `do_log::Bool`: Whether to actually log anything, useful when simply wanting to populate `toml` without changing anything on the disk

See also [`setup_global!`](@ref)
"""
function setup_logging!(toml::Dict, output_path::String="output_path"; do_log::Bool=true)
    config = get(toml, "global", Dict())
    if !(output_path in keys(config))
        throw(ErrorException("Output path $output_path not defined"))
    end
    output = config[output_path]
    logging = do_log && get(config, "logging", true)
    config["logging"] = logging
    # Setup logfile
    log_file = get(config, "log_file", "log.txt")
    log_file = abspath(joinpath(output, log_file))
    config["log_file"] = log_file
    toml["global"] = config
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
    function fmt(io, args)
        if args.level == Logging.Error
            color = :red
            bold = true
        elseif args.level == Logging.Warn
            color = :yellow
            bold = true
        elseif args.level == Logging.Info
            color = :cyan
            bold = false
        else
            color = :white
            bold = false
        end
        printstyled(io, args._module, " | ", "[", args.level, "] ", args.message, "\n"; color = color, bold = bold)
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
    setup_global!(toml::Dict, toml_path::AbstractString, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path"; test::Bool=false)

Setup the `"global"` information of toml, including paths and logging.

# Arguments
- `toml::Dict`: The toml file loaded into a `Dict`
- `toml_path::AbstractString`: The path to the input `.toml` file (from which `toml` is loaded)
- `verbose::Bool`: Whether or not to display `@debug` calls
- `paths::OrderedDict{String, Tuple{String, String}}`: Paths to expand. `paths` will be merged with the following `default_paths`, with `paths` taking preference. See [`default_paths`](@ref) for a the syntax of `paths`
- `output_path::String`: The `"path_name"` of the directory where logging should output
- `test::Bool`: Whether this run is a test or not. This will decide whether to actually create directories, or log anything

See also [`setup_paths!`](@ref), and [`setup_logging!`](@ref)

# Example
```jldoctest
toml = Dict()
toml_path = "/path/to/input/file.toml"
setup_global!(toml, toml_path, false; test=true)
println(toml)

# output

Dict{Any, Any}("global" => Dict{Any, Any}("toml_path" => "/path/to/input", "logging" => false, "base_path" => "/path/to/input/", "log_file" => "/path/to/input/Output/log.txt", "output_path" => "/path/to/input/Output"))
```
"""
function setup_global!(toml::Dict, toml_path::AbstractString, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path"; test::Bool=false)
    if !("global" in keys(toml))
        toml["global"] = Dict()
    end
    toml["global"]["toml_path"] = dirname(abspath(toml_path))
    # Merge `paths` with `default_paths`, giving preference to `paths`
    input_paths = merge(default_paths, paths)
    # If it is a test, you should not mkdirs
    setup_paths!(toml, input_paths; mkdirs=!test)
    # If it is a test, you should not log
    setup_logging!(toml, log_path; do_log=!test)
    config = toml["global"]
    if config["logging"]
        setup_logger(config["log_file"], verbose)
    end
    return toml
end

end
