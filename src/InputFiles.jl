module InputFiles 

# External Packages
using DataStructures

# Internal Packages
include("IOModule.jl")
using .IOModule

include("SetupModule.jl")
using .SetupModule

# Exports
export setup_input

"""
    setup_input(input_path::AbstractString, verbose::Bool; paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path", custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}())

Automatically choose input file extension, then run [`setup_input(::AbstractString, ::Bool, ::InputExt, ::OrderedDict{String, Tuple{String, String}}, ::String, ::Vector{Tuple{String, String}})`](@ref)

# Arguments
- `input_path::AbstractString`: Path to input file
- `verbose::Bool`: Whether to log `@debug` messages
- `paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}`: Paths to expand. `paths` will be merged with [`SetupModule.default_paths`](@ref), with `paths` taking preference. See [`SetupModule.default_paths`](@ref) for the syntax of `paths`
- `log_path::String="output_path"`: The `"path_name"` of the directory where logging should output. `log_path` must exist in `paths` or, be defined by [`SetupModule.default_paths`](@ref)
- `custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}()`: Additonal metadata to include in the input file, in addition to creation date and `input_path`
"""
function setup_input(input_path::AbstractString, verbose::Bool; paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path", custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}())
    ext = splitext(input_path)[end][2:end] 
    return setup_input(input_path, verbose, ext; paths=paths, log_path=log_path, custom_metadata=custom_metadata)
end

"""
    setup_input(input_path::AbstractString, verbose::Bool, ext::String; paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path", custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}())

Manually specify input file extension, then run [`setup_input(::AbstractString, ::Bool, ::InputExt, ::OrderedDict{String, Tuple{String, String}}, ::String, ::Vector{Tuple{String, String}})`](@ref)

# Arguments
- `input_path::AbstractString`: Path to input file
- `verbose::Bool`: Whether to log `@debug` messages
- `ext::String`: Manual extension specifier
- `paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}`: Paths to expand. `paths` will be merged with [`SetupModule.default_paths`](@ref), with `paths` taking preference. See [`SetupModule.default_paths`](@ref) for the syntax of `paths`
- `log_path::String="output_path"`: The `"path_name"` of the directory where logging should output. `log_path` must exist in `paths` or, be defined by [`SetupModule.default_paths`](@ref)
- `custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}()`: Additonal metadata to include in the input file, in addition to creation date and `input_path`
"""
function setup_input(input_path::AbstractString, verbose::Bool, ext::String; paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path", custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}())

    ext = get_InputExt(ext)()
    return setup_input(input_path, verbose, ext; paths=paths, log_path=log_path, custom_metadata=custom_metadata)
end

"""
    setup_input(input_path::AbstractString, verbose::Bool, ext::InputExt; paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path", custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}())

Main `InputFiles` function, given a path to an input file, this will preprocess, load, and postprocess the input file, including setting up paths and logging.

# Arguments
- `input_path::AbstractString`: Path to input file
- `verbose::Bool`: Whether to log `@debug` messages
- `ext::InputExt`: Extension specifier
- `paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}`: Paths to expand. `paths` will be merged with [`SetupModule.default_paths`](@ref), with `paths` taking preference. See [`SetupModule.default_paths`](@ref) for the syntax of `paths`
- `log_path::String="output_path"`: The `"path_name"` of the directory where logging should output. `log_path` must exist in `paths` or, be defined by [`SetupModule.default_paths`](@ref)
- `custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}()`: Additonal metadata to include in the input file, in addition to creation date and `input_path`
"""
function setup_input(input_path::AbstractString, verbose::Bool, ext::InputExt; paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path", custom_metadata::Vector{Tuple{String, String}}=Vector{Tuple{String, String}}())

    input::Dict{String, Any}, ext = preprocess_input(input_path, ext, custom_metadata)
    setup_global!(input, input_path, verbose, paths, log_path)
    input = postprocess_input(input)
    save_input(input, log_path, input_path, ext)
    return input
end

end # module
