module IOModule

# External Packages
using Dates
using InteractiveUtils
using TOML
using JSON
using YAML

# Internal Packages

# Exports
export load_input
export load_inputfile
export load_raw_inputfile
export preprocess_input 
export get_InputExt
export InputExt

"""
    InputExt

Abstract type for input extensions. Extended by [`TOMLExt`](@ref), [`JSONExt`](@ref), and [`YAMLExt`](@ref). Extend to add functionality for other input types. Names are assumed to be of the form EXTENSIONExt for .extension, i.e the extension in uppercase followed by Ext.
"""
abstract type InputExt end

"""
    TOMLExt <: InputExt

[`InputExt`](@ref) subtype for .toml files.
"""
struct TOMLExt <: InputExt end

"""
    JSONExt <: InputExt

[`InputExt`](@ref) subtype for .json files.
"""
struct JSONExt <: InputExt end

"""
    YAMLExt <: InputExt

[`InputExt`] for .yaml files.
"""
struct YAMLExt <: InputExt end

"""
    get_ext(ext::InputExt)

Convert from the [`InputExt`](@ref) type to the '.extension' file extension.

# Arguments
- `ext::InputExt`: The InputExt subtype to convert into a file extension
"""
function get_ext(ext::InputExt)
    s = string(ext)
    s = split(s, ".")[end] # Remove module tree
    s = replace(s, "Ext()" => "")
    return lowercase(s)
end

"""
    input_exts::Vector{InputExt}

Convenience list of all [`InputExt`](@ref) subtypes defined.
"""
const input_exts::Vector{InputExt} = [ext() for ext in subtypes(InputExt)]

"""
    exts::Vector{String}

Convencience list of all '.extension' file extensions for each defined subtype of [`InputExt`](@ref).
"""
const exts::Vector{String} = get_ext.(input_exts)

"""
    get_InputExt(ext::String)

Converts from '.extension' to [`InputExt`](@ref) subtype.

# Arguments
- `ext::String`: '.extension' to convert to InputExt subtype
"""
function get_InputExt(ext::String)
    # Remove leading '.'
    if ext[1] == "."
        etx = ext[2:end]
    end
    sym = "$(uppercase(ext))Ext"
    try
        type = getfield(IOModule, Symbol(sym))
    catch e
        @error "InputFiles doesn't know how to load an input with extension .$ext, options include $exts"
        throw(e)
    end
end

"""
    load_raw_inputfile(input_path::AbstractString)

Loads in the raw text in `input_path`

# Arguments
- `input_path::AbstractString`: Input path to load
"""
function load_raw_inputfile(input_path::AbstractString)
    raw = open(input_path, "r") do io
        raw = read(io, String)
    end
    return raw
end

"""
    load_input(input_path::AbstractString)

Automatically detect extension and attempt to load input into a dictionary

# Arguments
- `input_path::AbstractString`: Input path to load
"""
function load_inputfile(input_path::AbstractString)
    ext = splitext(input_path)[end][2:end] 
    input_ext = get_InputExt(ext)()
    return load_inputfile(input_path, ext)
end

"""
    load_input(input_path::AbstractString, ext::String)

Convert ext to InputExt, then attempt to load input into a dictionary

# Arguments
- `input_path::AbstractString`: Input path to load
- `ext::String`: Extension string
"""
function load_inputfile(input_path::AbstractString, ext::String)
    input_ext = get_InputExt(ext)()
    return load_inputfile(input_path, input_ext)
end


"""
    load_input(input_path::AbstractString, ext::TOMLExt)

Read .toml file in to Dict

# Arguments
- `input_path::AbstractString`: Input path to load
- `ext::TOMLExt`: Extension specifier
"""
function load_inputfile(input_path::AbstractString, ext::TOMLExt)
    return TOML.parsefile(abspath(input_path))
end

"""
    load_input(input_path::AbstractString, ext::JSONExt)

Read .json file in to Dict

# Arguments
- `input_path::AbstractString`: Input path to load
- `ext::JSONExt`: Extension specifier
"""
function load_inputfile(input_path::AbstractString, ext::JSONExt)
    return JSON.parsefile(abspath(input_path))
end

"""
    load_input(input_path::AbstractString, ext::YAMLExt)

Read .yaml file in to Dict

# Arguments
- `input_path::AbstractString`: Input path to load
- `ext::YAMLExt`: Extension specifier
"""
function load_inputfile(input_path::AbstractString, ext::YAMLExt)
    try
        return YAML.load_file(abspath(input_path))
    # YAML currently has a bug where empty YAML files (or those with only comments) crash
    catch AssertionError
        return Dict()
    end
end

"""
    load_input(raw_input::String, ext::TOMLExt)

Read raw .toml file in to Dict

# Arguments
- `raw_input::AbstractString`: Raw input to load
- `ext::TOMLExt`: Extension specifier
"""
function load_input(raw_input::String, ext::TOMLExt)
    return TOML.parse(raw_input)
end

"""
    load_input(raw_input::String, ext::JSONExt)

Read .json file in to Dict

# Arguments
- `raw_input::String`: Raw input to load
- `ext::JSONExt`: Extension specifier
"""
function load_input(raw_input::String, ext::JSONExt)
    return JSON.parse(raw_input)
end

"""
    load_input(raw_input::String, ext::YAMLExt)

Read .yaml file in to Dict

# Arguments
- `raw_input::String`: Raw input to load
- `ext::YAMLExt`: Extension specifier
"""
function load_input(raw_input::String, ext::YAMLExt)
    try
        return YAML.load(raw_input)
    # YAML currently has a bug where empty YAML files (or those with only comments) crash
    catch AssertionError
        return Dict()
    end
end

"""
    preprocess_input(input_path::AbstractString)

Automatically detect extension type of `input_path`, then preprocess the input.

# Arguments
- `input_path::AbstractString`: Input file to preprocess

Will error if the extension of `input_path` is not part of [`exts`](@ref). If you wish to manually specify the extension, use `[preprocess_input(::AbstractString, ::String)]`(@ref). After the extension is found, will run [`preprocess_input(::AbstractString, ::String)]`(@ref) 
"""
function preprocess_input(input_path::AbstractString)
    # Get extension without leading dot
    ext = splitext(input_path)[end][2:end] 
    input_ext = get_InputExt(ext)()
    return preprocess_input(input_path, input_ext)
end

"""
    preprocess_input(input_path::AbstractString, ext::String)

Specify the extension type of `input_path` manually, then preprocess the ipnut.

# Arguments
- `input_path::AbstractString`: Input file to preprocess
- `ext::String`: Manually selected extension. Must be part of [`exts`](@ref)

If the extension of `input_path` is not defined by `InputFiles`, but acts like a defined extension, you can specify which extension to use via this function, which will then run [`preprocess_input(::AbstractString, ::String)`](@ref)
"""
function preprocess_input(input_path::AbstractString, ext::String)
    input_ext = get_InputExt(ext)()
    return preprocess_input(input_path, input_ext)
end

"""
    preprocess_input(input_path::AbstractString, ext::InputExt)

Preprocess the input path before running setup.

# Arguments
- `input_path::AbstractString`: Input file to preprocess
- `ext::InputExt`: Extension type of input file

Preprocessing includes adding metadata comments at the top-level, including other files, inserting environmental variables, propegating default values, interpolating values, and ensuring all variables are upper-case.
"""
function preprocess_input(input_path::AbstractString, ext::InputExt)
    raw = load_raw_inputfile(input_path)
    raw = add_metadata(raw, ext, input_path)
    raw = process_includes(raw, input_path) 
    raw = process_env_vars(raw)
    #process_default!(raw, ext)
    #process_interpolation!(raw, ext)
    #update_case!(raw, ext)
    return raw, ext
end

"""
    add_metadata(raw::String, ext::TOMLExt, input_path::AbstractString)

Add metadata comment to top-level of .toml file

# Arguments
- `raw::String`: Raw text of input file
- `ext::TOMLExt`: Extension of input file
- `input_path::AbstractString`: Path to input file

Runs [`add_metadata(::String, ::String, ::AbstractString)`](@ref)
"""
function add_metadata(raw::String, ext::TOMLExt, input_path::AbstractString)
    return add_metadata(raw, "#", input_path)
end

"""
    add_metadata(raw::String, ext::YAMLExt, input_path::AbstractString)

Add metadata comment to top-level of .yaml file

# Arguments
- `raw::String`: Raw text of input file
- `ext::YAMLExt`: Extension of input file
- `input_path::AbstractString`: Path to input file

Runs [`add_metadata(::String, ::String, ::AbstractString)`](@ref)
"""
function add_metadata(raw::String, ext::YAMLExt, input_path::AbstractString)
    return add_metadata(raw, "#", input_path)
end

"""
    add_metadata(raw::String, ext::JSONExt, input_path::AbstractString)

Add metadata comment to top-level of .json file

# Arguments
- `raw::String`: Raw text of input file
- `ext::JSONExt`: Extension of input file
- `input_path::AbstractString`: Path to input file

Adds new "METADATA" key, and places the original json file into a "JSON" key.
Adds the date of creation and `input_path`
"""
function add_metadata(raw::String, ext::JSONExt, input_path::AbstractString)
    date = today()
    raw = "\"JSON\": " * raw * "\n}"
    metadata = "{\n\"METADATA\": {\n    \"Date\": \"$date\",\n    \"Original\": \"$input_path\"\n},\n"
    return metadata * raw
end

"""
    add_metadata(raw::String, comment::String, input_path::AbstractString)

Add comment string to input file

# Arguments
- `raw::String`: Raw text of input file
- `comment::String`: Comment character
- `input_path::AbstractString`: Path to input file

Adds the date of creation and `input_path` comment
"""
function add_metadata(raw::String, comment::String, input_path::AbstractString)
    date = today()
    date_str = "$comment Created on $date\n"
    file_str = "$comment Original file: $input_path\n\n"
    return date_str * file_str * raw
end

"""
    process_includes(raw::String, input_path::AbstractString)

Copy `include` files specified via `<include path/to/include.file>` into `raw`

# Arguments
- `raw::String`: Raw file to provess
- `input_path::AbstractString`: Path to input file
"""
function process_includes(raw::String, input_path::AbstractString)
    base_dir = dirname(abspath(input_path))
    reg = r"<include (.*)>"
    ms = eachmatch(reg, raw)
    for m in ms
        for file in m.captures
            include_file = joinpath(base_dir, file)
            if isfile(include_file)
                open(include_file, "r") do io
                    replace_include = read(io, String)
                    raw = replace(raw, "<include $file>" => read(io, String))
                end
            else
                @error "Can't find include file: $include_file"
            end
        end
    end
    return raw
end

"""
    process_env_vars(raw::String)

Interpolate environmental variables into `raw`, specified via `<\$ENV>`

# Arguments
- `raw::String`: Raw file to process
"""
function process_env_vars(raw)
    reg = r"<\$(.*)>"
    ms = eachmatch(reg, raw)
    for m in ms
        for key in m.captures
            value = get(ENV, key, "nothing")
            if isnothing(value)
                @error "Unknown environmental variable \$$key, replacing with `$(nothing)`"
            end
            raw = replace(raw, "<\$$key>" => value)
        end
    end
    return raw
end

end
