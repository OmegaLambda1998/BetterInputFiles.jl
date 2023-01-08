```@meta
CurrentModule = InputFiles.SetupModule
```
# Setup Functions
The main functionality provided by `InputFiles` is the ability to consistently setup packages from a `.toml` file.

```@contents
Pages = ["setup.md"]
Depth = 5
```

## Usage
Most of my packages use the same boilerplate to setup everything in a way that allows easy access propogation of user provided parameters:

```julia
using TOML
using InputFiles
using ArgParse

function get_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--verbose", "-v"
            help = "Increase level of logging verbosity"
            action = :store_true
        "input"
            help = "Path to .toml file"
            required = true
    end
    return parse_args(s)
end

function main()
    args = get_args()
    verbose = args["verbose"]
    toml_path = args["input"]
    toml = TOML.parsefile(abspath(toml_path))
    setup_global!(toml, verbose, toml_path)
    @debug "Read in $toml_path"
    run_MyPackage(toml) # Actually run everything with the prepared `toml`
end
```

Given a `.toml` file, this will produce a dictionary with a `global` key containing a dictionary with
- `toml_path`: The path to the `.toml` input file
- `base_path`: A base path defined relative to `toml_path` from which any relative paths used by the package will be relative to
- `output_path`: The output directory where all output, including logging, will be put
- `logging`: Whether logging was set up. This allows you to use my InputFiles logging function or your own
- `log_file`: If using my logging function, then in addition to `stdout`, logs will be saved to `log_file`

### Global Options
You can change much of the behaviour of InputFiles setup logic both in how you call it, and in `global` options in the input `.toml` file.

#### Toml Options
Much of the behaviour can be controlled from the `.toml` file itself, without needed to change any code.

##### Change default paths
By default, InputFiles sets `base_path` equal to `toml_path`, and `output_path` equal to `base_path/Output`. By defining your own (absolute or relative) `base_path`, and `output_path`, you can change these defaults. Note that `base_path` is defined relative to `toml_path`, and `output_path` is defined relative to `base_path`, but absolute paths are respected.

```toml
[ global ]
    base_path = "../Examples"
    # base_path = toml_path/../Examples
    output_path = "/tmp/test"
    # output_path = "/tmp/test"
```

##### Change logging behaviour
You can define in the `.toml` file, whether you want to use InputFiles logging or not. Additionally you can specify a new location for the log file (defaults to `output_path/log.txt`). This can be either absolute, or relative to `output_path`
```toml
[ global ]
    logging = false
    log_file = logs/out.txt
    # log_file = output_path/logs/out.txt
```

#### InputFiles Options

##### Add new global paths
By defining a `Dict` of paths, you can add new global paths, which can be accessed throughout the package. The following creates `data_path` relative to `base_path`, and `filter_path` relative to `data_path`. You must provide defaults for these paths but the user can overwrite then in the `.toml` (see [Change default paths](@ref)).

```julia
paths = Dict(
    "data_path" => ("base_path", "Data")
    "filter_path" => ("data_path", "Filters")

setup_global!(toml, toml_path, paths)
```
See [`default_paths`](@ref) for more details.


## API
### Public objects 
These are the functions, types, and other objects you have access to with a simple `using InputFiles`

```@autodocs
Modules = [SetupModule]
Private = false
```

### Private objects
These are the functions, types, and other objects which you don't have access to by default. They are included here for verbosity and developer assistance.

```@autodocs
Modules = [SetupModule]
Public = false
```
