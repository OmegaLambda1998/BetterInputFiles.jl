module OLUtils

# External Packages
using TOML
using DataStructures
using LoggingExtras

# Internal Packages

# Exports
export setup_global!

default_paths = OrderedDict(
    # Name => relative, default
    "base_path" => ("toml_path", ""),
    "output_path" => ("base_path", "Output")
)

function setup_paths!(toml::Dict, paths::OrderedDict)
    config = get(toml, "global", Dict())
    for (path_name, (relative_name, default)) in paths
        relative = config[relative_name]
        path = get(config, path_name, nothing)
        if isnothing(path)
            path = joinpath(relative, default)
        elseif !isabspath(path)
            path = joinpath(relative, path)
        end
        path = abspath(path)
        if !isdir(path)
            mkpath(path)
        end
        config[path_name] = path
    end
    toml["global"] = config
end

function setup_logging!(toml::Dict, output_path)
    config = get(toml, "global", Dict())
    output = config[output_path]
    logging = get(config, "logging", true)
    config["logging"] = logging
    log_file = get(config, "log_file", nothing)
    if logging
        if isnothing(log_file)
            log_file = "log.txt"
        end
        log_file = abspath(joinpath(config[output_path], log_file))
    elseif !isnothing(log_file)
        @warn "Logging set to false, so log file $log_file will not be written. Please add `logging=true` to your [ global ] config"
    end
    config["log_file"] = log_file
    toml["global"] = config
end

function setup_logger(log_file::AbstractString, verbose::Bool)
    if verbose
        level = Logging.Debug
    else
        level = Logging.Info
    end
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
    logger = TeeLogger(
        MinLevelLogger(FormatLogger(fmt, open(log_file, "w")), level),
        MinLevelLogger(FormatLogger(fmt, stdout), level)
    )
    global_logger(logger)
    @info "Logging to $log_file"
end

function setup_global!(toml::Dict, verbose::Bool, paths=nothing, output_path="output_path")
    if !isnothing(paths)
        merge!(default_paths, paths)
    end
    setup_paths!(toml, default_paths)
    setup_logging!(toml, output_path)
    config = toml["global"]
    if config["logging"]
        setup_logger(config["log_file"], verbose)
    end
    return toml
end

end # module
