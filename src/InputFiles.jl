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

function setup_input(input_path::AbstractString, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path"; test::Bool=false)
    ext = splitext(input_path)[end][2:end] 
    return setup_input(input_path, ext, verbose, paths, log_path; test=test)
end


function setup_input(input_path::AbstractString, ext::String, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path"; test::Bool=false)
    ext = get_InputExt(ext)()
    return setup_input(input_path, ext, verbose, paths, log_path; test=test)
end

function setup_input(input_path::AbstractString, ext::InputExt, verbose::Bool, paths::OrderedDict{String, Tuple{String, String}}=OrderedDict{String, Tuple{String, String}}(), log_path::String="output_path"; test::Bool=false)
    raw, ext = preprocess_input(input_path, ext)
    input = load_input(raw, ext)
    setup_global!(input, input_path, verbose, paths, log_path; test=test)
    return input
end

end # module
