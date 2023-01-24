# Advanced Usage

## Contents
```@contents
Pages = ["advanced.md"]
```

Most of my packages use the same boilerplate to setup everything in a way that allows easy access propogation of user provided parameters:

```julia
using InputFiles
using ArgParse

function get_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--verbose", "-v"
            help = "Increase level of logging verbosity"
            action = :store_true
        "input"
            help = "Path to input file"
            required = true
    end
    return parse_args(s)
end

function main()
    args = get_args()
    verbose = args["verbose"]
    input_path = args["input"]
    input = setup_input(toml, verbose)
    @debug "Read in $input_path"
    run_MyPackage(input) # Actually run everything with the prepared `input`
end
```

Given an input file, this will produce a dictionary with a `global` key containing a dictionary with
- `input_path`: The directory the input file is stored in
- `base_path`: A base path defined relative to `input_path` from which any relative paths used by the package will be relative to
- `output_path`: The output directory where all output, including logging, will be put
- `logging`: Whether logging was set up. This allows you to use my InputFiles logging function or your own
- `log_file`: If using my logging function, then in addition to `stdout`, logs will be saved to `log_file`

## Input file options
Much of the behaviour can be controlled from the input file itself, without needed to change any code. Note that all of these examples are written in TOML, but will work for YAML, and JSON files as well.

### Change default paths
By default, InputFiles sets `base_path` equal to `input_path`, and `output_path` equal to `base_path/Output`. By defining your own (absolute or relative) `base_path`, and `output_path`, you can change these defaults. Note that `base_path` is defined relative to `input_path`, and `output_path` is defined relative to `base_path`, but absolute paths are respected.

```toml
[ global ]
    base_path = "../Examples"
    # base_path = input_path/../Examples
    output_path = "/tmp/test"
    # output_path = "/tmp/test"
```

### Change logging behaviour
You can define in the input file, whether you want to use InputFiles logging or not. Additionally you can specify a new location for the log file (defaults to `output_path/log.txt`). This can be either absolute, or relative to `output_path`.

```toml
[ global ]
    logging = false
    log_file = logs/out.txt
    # log_file = output_path/logs/out.txt
```

### Include another input file
It is sometimes helpful to seperate your input into a number of different files, or to use the same input options in a number of different files.

```toml
# file_1.toml
[ key1 ]
    a = 1
    b = 2

# file_2.toml
<include file_1.toml>

[ key2 ]
    c = 3
    d = 4
```

```julia
input = setup_input("file_2.toml", verbose)
```

Will produce:

```toml
[ key1 ]
    a = 1
    b = 2

[ key2 ]
    c = 3
    d = 4
```

### Interpolate Environmental Variables
You can easily interpolate environmental variables via:

```toml
[ key1 ]
    a = <$A>
    b = <$B>
```

### Generic Interpolation
You can also interpolate other keys, as long as they belong to the same subtree, allowing for easy duplication.

```toml
[ key1 ]
    a = 1
    b = <%a>
```

### Propogate defaults
You can specify default values which will be available under every key. These are also quite useful when combined with interpolation, as this default value will be part of every base key. If a default key is specified already, then the default will be ignored

```toml
[ DEFAULT ]
    a = 1
    b = 2

[ key1 ]
    c = <%a>
    d = <%b>
```

### Automatic upper-case
Finally, InputFiles will automatically make every key upper-case, so your user's can ignore case when specifying keys. Values are still case-specific.

## Script options
In addition to changing behaviour from the input file, there's also a lot of functionality InputFiles provides when writing scripts 

### Add new global paths
By defining an `OrderedDict{String, Tuple{String, String}}` of paths, you can add new global paths, which can be accessed throughout the package. The following creates `data_path` relative to `base_path`, and `filter_path` relative to `data_path`. You must provide defaults for these paths but the user can overwrite then in the `.toml` (see [Change default paths](@ref)).

```julia
paths = Dict(
    # Name of path => (relative parent, default)
    "data_path" => ("base_path", "Data")
    "filter_path" => ("data_path", "Filters")

input = setup_input(input_path, verbose; paths=paths) 
```

### Custom Metadata
By providing InputFiles with a `Vector{Tuple{String, String}}`, you can add additional metadata to the input file, in addition to the date of creation and original input file.

```julia
custom_metadata = [("Custom", "Metadata")]

input = setup_input(input_path, verbose; custom_metadata=custom_metadata)
```

This will create a new `key="Custom"` and `value="Metadata"` in the `Metadata` dictionary.

### Manually set extension 
Sometimes you will have an input file which acts like a TOML, YAML, or JSON file, but has a different extension. If this is the case, you can let InputFiles know which extension to assume.

```julia
input = setup_input("/path/to/input.example", verbose, "toml")
```

## Macros

`InputFiles` also provides a number of macros, mostly focused at making reading from and writing to the input file easier.

### `@get`

The most basic macro is [`@get`](@ref). This macro will take any expression matching `dictionary[key]`, `getindex(dictionary, key)`, or `get(dictionary, key, default)`, and case-insensitively get the value of `key` in `dictionary`. This assumes that every key in `dictionary` is capitalised, but that is guaranteed by `InputFiles` on setup, and you can make use of [`@set!`](@ref) to ensure that stays true throughout.

```julia
d = Dict("A" => 1, "B" => 2)
d["A"] == @get d["a"]
d["A"] == @get getindex(d, "a")
```

### `@set!`

[`@set!`](@ref) matches `dictionary[key] = value`, or `setindex!(dictionary, value, key)` and will case-insensitively set `value` to `key` in `dictionary`, ensuring `key` ends up capitalised.

```julia
d = Dict{String, Int64}()
@set! d["a"] = 1
@set! d["B"] = 2
@set! setindex!(d, 3, "c")
@set! setindex!(d, 4, "D")

d = Dict{String, Int64} with 4 entries:
  "A" => 1
  "B" => 2
  "C" => 3
  "D" => 4
```

```
