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
export save_input
export postprocess_input
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
        @error "BetterInputFiles doesn't know how to load an input with extension .$ext, options include $exts"
        throw(e)
    end
end

"""
    fix_dict_type(input::Dict)

Ensure dictionary is of type Dict{String, Any}

# Arguments
- `input::Dict`: Input to fix
"""
function fix_dict_type(input::Dict)
    rtn = Dict{String, Any}()
    for (key, value) in input
        if typeof(value) <: Dict
            rtn[key] = fix_dict_type(value)
        elseif typeof(value) <: AbstractString
            rtn[key] = escape_string(value)
        else
            rtn[key] = value
        end
    end
    return rtn
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
    return fix_dict_type(load_inputfile(input_path, ext))
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
    return fix_dict_type(load_inputfile(input_path, input_ext))
end


"""
    load_input(input_path::AbstractString, ext::TOMLExt)

Read .toml file in to Dict

# Arguments
- `input_path::AbstractString`: Input path to load
- `ext::TOMLExt`: Extension specifier
"""
function load_inputfile(input_path::AbstractString, ext::TOMLExt)
    return fix_dict_type(TOML.parsefile(abspath(input_path)))
end

"""
    load_input(input_path::AbstractString, ext::JSONExt)

Read .json file in to Dict

# Arguments
- `input_path::AbstractString`: Input path to load
- `ext::JSONExt`: Extension specifier
"""
function load_inputfile(input_path::AbstractString, ext::JSONExt)
    return fix_dict_type(JSON.parsefile(abspath(input_path)))
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
        return fix_dict_type(YAML.load_file(abspath(input_path)))
    # YAML currently has a bug where empty YAML files (or those with only comments) crash
    catch AssertionError
        return Dict{String, Any}()
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
    return fix_dict_type(TOML.parse(raw_input))
end

"""
    load_input(raw_input::String, ext::JSONExt)

Read .json file in to Dict

# Arguments
- `raw_input::String`: Raw input to load
- `ext::JSONExt`: Extension specifier
"""
function load_input(raw_input::String, ext::JSONExt)
    return fix_dict_type(JSON.parse(raw_input))
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
        return fix_dict_type(YAML.load(raw_input))
    # YAML currently has a bug where empty YAML files (or those with only comments) crash
    catch AssertionError
        return Dict{String, Any}()
    end
end

"""
    save_input(input::Dict, log_path::String, input_path::AbstractString, ext::InputExt)

Save `input` to the same directory that logging is being saved.

# Arguments
- `input::Dict`: Input to save
- `log_path::String`: Directory to save input to
- `input_path::AbstractString`: Original path of input
- `ext::InputExt`: Extension specifier
"""
function save_input(input::Dict{String, Any}, log_path::String, input_path::AbstractString, ext::InputExt)
    config = input["GLOBAL"]
    output_path = get(config, uppercase(log_path), nothing)
    if isnothing(output_path)
        throw(ErrorException("Unknown output path: $log_path"))
    end
    name = splitdir(input_path)[end]
    output_file = joinpath(output_path, name)
    save_input(input, output_file, ext)
end

"""
    save_input(input::Dict, output_file::AbstractString, ext::TOMLExt)

Save `input` to `output_file`, as a `.toml` file

# Arguments
- `input::Dict`: Input to save
- `output_file::AbstractString`: Path to save
- `ext::TOMLExt`: Extension specifier
"""
function save_input(input::Dict{String, Any}, output_file::AbstractString, ext::TOMLExt)
    open(output_file, "w") do io
        TOML.print(io, input)
    end
end

"""
    save_input(input::Dict, output_file::AbstractString, ext::JSONExt)

Save `input` to `output_file`, as a `.json` file

# Arguments
- `input::Dict`: Input to save
- `output_file::AbstractString`: Path to save
- `ext::JSONExt`: Extension specifier
"""
function save_input(input::Dict{String, Any}, output_file::AbstractString, ext::JSONExt)
    open(output_file, "w") do io
        JSON.print(io, input, 4)
    end
end

"""
    save_input(input::Dict, output_file::AbstractString, ext::YAMLExt)

Save `input` to `output_file`, as a `.yaml` file

# Arguments
- `input::Dict`: Input to save
- `output_file::AbstractString`: Path to save
- `ext::YAMLExt`: Extension specifier
"""
function save_input(input::Dict{String, Any}, output_file::AbstractString, ext::YAMLExt)
    YAML.write_file(output_file, input)
end

"""
    postprocess_input(input::Dict)

Run postprocessing on input

# Arguments
- `input::Dict`: Input to postprocess
"""
function postprocess_input(input::Dict)
    input = update_case(input)
    return input
end

"""
    update_case(input::Dict)

Recursively ensure every key in `input` is uppercase

# Arguments
- `input::Dict`: The input to update
"""
function update_case(input::Dict)
    rtn = Dict{String, Any}()
    for (key, value) in input
        rtn[uppercase(key)] = update_case(value)
    end
    return rtn
end

"""
    update_case(input::AbstractArray)

Updated the case of every element in `input`.

# Arguments
- `input::AbstractArray`: Input to process 
"""
function update_case(input::AbstractArray)
    return update_case.(input) 
end

"""
    update_case(input::Any)

Stopping condition of [`postprocess_input(::Dict)`](@ref), when a value is reached

# Arguments
- `input::Any`: Return input
"""
function update_case(input::Any)
    return input
end

"""
    preprocess_input(input_path::AbstractString)

Automatically detect extension type of `input_path`, then preprocess the input.

# Arguments
- `input_path::AbstractString`: Input file to preprocess

Will error if the extension of `input_path` is not part of [`exts`](@ref). If you wish to manually specify the extension, use `[preprocess_input(::AbstractString, ::String)]`(@ref). After the extension is found, will run [`preprocess_input(::AbstractString, ::String)]`(@ref) 
"""
function preprocess_input(input_path::AbstractString, custom_metadata::Vector{Tuple{String, String}} = Vector{Tuple{String, String}}())

    # Get extension without leading dot
    ext = splitext(input_path)[end][2:end] 
    input_ext = get_InputExt(ext)()
    return preprocess_input(input_path, input_ext, custom_metadata)
end

"""
    preprocess_input(input_path::AbstractString, ext::String)

Specify the extension type of `input_path` manually, then preprocess the ipnut.

# Arguments
- `input_path::AbstractString`: Input file to preprocess
- `ext::String`: Manually selected extension. Must be part of [`exts`](@ref)

If the extension of `input_path` is not defined by `BetterInputFiles`, but acts like a defined extension, you can specify which extension to use via this function, which will then run [`preprocess_input(::AbstractString, ::String)`](@ref)
"""
function preprocess_input(input_path::AbstractString, ext::String, custom_metadata::Vector{Tuple{String, String}} = Vector{Tuple{String, String}}())

    input_ext = get_InputExt(ext)()
    return preprocess_input(input_path, input_ext, custom_metadata)
end

"""
    preprocess_input(input_path::AbstractString, ext::InputExt)

Preprocess the input path before running setup.

# Arguments
- `input_path::AbstractString`: Input file to preprocess
- `ext::InputExt`: Extension type of input file

Preprocessing includes adding metadata comments at the top-level, including other files, inserting environmental variables, propegating default values, interpolating values, and ensuring all variables are upper-case.
"""
function preprocess_input(input_path::AbstractString, ext::InputExt, custom_metadata::Vector{Tuple{String, String}} = Vector{Tuple{String, String}}())

    raw = load_raw_inputfile(input_path)
    raw = add_metadata(raw, ext, input_path, custom_metadata)
    raw = process_includes(raw, input_path) 
    raw = process_env_vars(raw)
    input = process_interpolation(raw, ext)
    return input, ext
end

"""
    add_metadata(raw::String, ext::TOMLExt, input_path::AbstractString)

Add metadata comment to top-level of .toml file

# Arguments
- `raw::String`: Raw text of input file
- `ext::TOMLExt`: Extension of input file
- `input_path::AbstractString`: Path to input file

Adds a new "METADATA" key, containing the date of creation and `input_path` 
"""
function add_metadata(raw::String, ext::TOMLExt, input_path::AbstractString, custom_metadata::Vector{Tuple{String, String}} = Vector{Tuple{String, String}}())
    date = today()
    metadata = "[ METADATA ]\n    DATE = \"$date\"\n    ORIGINAL = \"$input_path\"\n"
    for (key, value) in custom_metadata
        metadata *= "    $(uppercase(key)) = \"$value\""
    end
    return metadata * "\n" * raw
end

"""
    add_metadata(raw::String, ext::YAMLExt, input_path::AbstractString)

Add metadata comment to top-level of .yaml file

# Arguments
- `raw::String`: Raw text of input file
- `ext::YAMLExt`: Extension of input file
- `input_path::AbstractString`: Path to input file

Adds a new "METADATA" key, containing the date of creation and `input_path` 
"""
function add_metadata(raw::String, ext::YAMLExt, input_path::AbstractString, custom_metadata::Vector{Tuple{String, String}} = Vector{Tuple{String, String}}())
    date = today()
    metadata = "METADATA:\n    DATE: \"$date\"\n    ORIGINAL: \"$input_path\"\n"
    for (key, value) in custom_metadata
        metadata *= "    $(uppercase(key)): \"$value\""
    end
    return metadata * "\n" * raw
end

"""
    add_metadata(raw::String, ext::JSONExt, input_path::AbstractString)

Add metadata comment to top-level of .json file

# Arguments
- `raw::String`: Raw text of input file
- `ext::JSONExt`: Extension of input file
- `input_path::AbstractString`: Path to input file

Adds a new "METADATA" key, containing the date of creation and `input_path` 
"""
function add_metadata(raw::String, ext::JSONExt, input_path::AbstractString, custom_metadata::Vector{Tuple{String, String}} = Vector{Tuple{String, String}}())

    date = today()
    m_str = "\n        \"DATE\": \"$date\",\n        \"ORIGINAL\": \"$input_path\"\n"
    for (key, value) in custom_metadata
        m_str *= ",\n        \"$(uppercase(key))\": \"$value\""
    end
    metadata = "    \"METADATA\": {$m_str    }"
    # Be careful of blank json files
    if strip(raw[2:end]) == "}"
        return "{\n" * metadata * "\n}"
    end
    return "{\n" * metadata * ",\n" * raw[2:end]
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
                    raw = replace(raw, "<include $file>" => replace_include)
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
function process_env_vars(raw::String)
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

"""
    process_interpolation(raw::String, ext::InputExt)

Given the raw string for an input, load the input ([`load_input`](@ref)), and process all interpolations ([`process_interpolation(::Dict)`](@ref)), respecting defaults

# Arguments
- `raw::String`: The raw input file to process
- `ext::InputExt`: Extension specifier
"""
function process_interpolation(raw::String, ext::InputExt)
    reg = r"<%(.*)>"
    ms = eachmatch(reg, raw)
    for m in ms
        for key in m.captures
            raw = replace(raw, "<%$key>" => "\"<%$key>\"")
        end
    end
    input::Dict{String, Any} = load_input(raw, ext)
    # Get default values, checking both `default` and `DEFAULT`
    default = Dict()
    if "default" in keys(input)
        default = input["default"]
    end
    default = get(input, "DEFAULT", default)
    input = process_interpolation(input, default)
    return input
end

"""
    process_interpolation(input::Dict)

Process interpolations for `input`

# Arguments
- `input::Dict` The input to process
"""
function process_interpolation(input::Dict, default::Dict)
    reg = r"<%(.*)>"
    for (key, value) in input
        if typeof(value) <: Dict
            input[key] = process_interpolation(value, default)
        elseif typeof(value) <: AbstractArray
            # Get the set of all types contained in value
            value_types = collect(Set(typeof.(value)))
            # If value is a list of key => value pairs, recurse interpolation
            if (length(value_types) == 1) && (value_types[1] == Dict{String, Any})
                input[key] = [process_interpolation(v, default) for v in value]
            end
        elseif typeof(value) <: AbstractString
            m = match(reg, value)
            if !isnothing(m)
                for k in m.captures
                    if k in keys(input)
                        input[key] = input[k]
                    elseif k in keys(default) 
                        input[key] = default[k]
                    else
                        throw(ErrorException("Can not interpolate $k, not found in $(keys(input)), nor in $(keys(default))"))
                    end
                end
            end
        end
    end
    return input
end

end
