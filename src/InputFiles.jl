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

function setup_input(input_path::AbstractString, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path")
    ext = splitext(input_path)[end][2:end] 
    return setup_input(input_path, ext, verbose, paths, log_path)
end


function setup_input(input_path::AbstractString, ext::String, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path")
    ext = get_InputExt(ext)()
    return setup_input(input_path, ext, verbose, paths, log_path)
end

function setup_input(input_path::AbstractString, ext::InputExt, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path")
    input::Dict{String, Any}, ext = preprocess_input(input_path, ext)
    setup_global!(input, input_path, verbose, paths, log_path)
    input = postprocess_input(input)
    save_input(input, log_path, input_path, ext)
    return input
end

end # module
