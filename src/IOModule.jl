module IOModule

# External Packages
using Dates
using InteractiveUtils

# Internal Packages

# Exports
export load_raw_input
export preprocess_input 

abstract type InputExt end

struct TOMLExt <: InputExt end
struct TMLExt <: InputExt end

struct JSONExt <: InputExt end
struct JSNExt <: InputExt end

struct YAMLExt <: InputExt end
struct YMLExt <: InputExt end

function get_ext(ext::InputExt)
    s = string(ext)
    s = split(s, ".")[end]
    s = replace(s, "Ext()" => "")
    return lowercase(s)
end

const input_exts::Vector{InputExt} = [ext() for ext in subtypes(InputExt)]
const exts::Vector{String} = get_ext.(input_exts)

function get_InputExt(ext::String)
    # Convert to InputExt
    sym = "$(uppercase(ext))Ext"
    try
        type = getfield(IOModule, Symbol(sym))
    catch e
        @error "InputFiles doesn't know how to load an input with extension .$ext, options include $exts"
        throw(e)
    end
end

function load_raw_input(input_path::AbstractString)
    raw = open(input_path, "r") do io
        raw = read(io, String)
    end
    return raw
end

function preprocess_input(input_path::AbstractString)
    # Get extension without leading dot
    ext = splitext(input_path)[end][2:end] 
    input_ext = get_InputExt(ext)()
    return preprocess_input(input_path, input_ext)
end

function preprocess_input(input_path::AbstractString, ext::String)
    input_ext = get_InputExt(ext)()
    return preprocess_input(input_path, input_ext)
end

function preprocess_input(input_path::AbstractString, ext::InputExt)
    raw = load_raw_input(input_path)
    raw = add_metadata(raw, ext, input_path)
    #process_includes!(raw, ext) 
    #process_env_vars!(raw, ext)
    #process_default!(raw, ext)
    #process_interpolation!(raw, ext)
    #update_case!(raw, ext)
end

function add_metadata(raw::String, ext::InputExt, input_path::AbstractString)
    return add_metadata(raw, "#", input_path)
end

function add_metadata(raw::String, comment::String, input_path::AbstractString)
    date = today()
    date_str = "$comment Created on $date\n"
    file_str = "$comment Original file: $input_path\n\n"
    return date_str * file_str * raw
end

function add_metadata(raw::String, ext::JSONExt, input_path::AbstractString)
    date = today()
    raw = "\"JSON\": " * raw * "\n}"
    metadata = "{\n\"METADATA\": {\n    \"Date\": \"$date\",\n    \"Original\": \"$input_path\"\n},\n"
    return metadata * raw
end

function add_metadata(raw::String, ext::JSNExt, input_path::AbstractString)
    return add_metadata(raw, JSONExt(), input_path)
end

end

