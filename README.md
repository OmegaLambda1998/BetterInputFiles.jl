[![Tests](https://github.com/OmegaLambda1998/InputFiles.jl/actions/workflows/test.yml/badge.svg)](https://github.com/OmegaLambda1998/InputFiles.jl/actions/workflows/test.yml)
[![Documentation](https://github.com/OmegaLambda1998/InputFiles.jl/actions/workflows/documentation.yml/badge.svg)](https://omegalambda.com.au/InputFiles.jl/)

Provides consistent methods to load in input files, such as `.toml`, `.yaml`, and `.json` files. Also extends the functionality of these files, via pre-processing, and post-processing.

Functionality provided includes:
- Automatically add Metadata to your input
- Automatically include other input files in your input
- Interpolate environmental variables into your input
- Propegate default values throughout your input
- Generically interpolate key's throughout your input

I already use this in many of my projects, including [IABCosmo.jl](https://github.com/OmegaLambda1998/IABCosmo.jl), [SALTJacobian.jl](https://github.com/OmegaLambda1998/SALTJacobian.jl), [Supernovae.jl](https://github.com/OmegaLambda1998/Supernovae.jl), [ShockCooling.jl](https://github.com/OmegaLambda1998/ShockCooling.jl), and [Greed.jl](https://github.com/OmegaLambda1998/Greed.jl) (amongst others).

## Install

```
using Pkg
Pkg.add("InputFiles")
```

## Usage
This package provides one main function - `setup_input`. This function does most of the heavy lifting, pre-processing, loading, and post-processing the input file you give it. An idiomatic way of using this package is as follows:

```julia
using InputFiles
using DataStructures
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
    input = setup_input(input_path, verbose) # <- Have InputFiles prepare your input
    # Run your package with the input file
    run_MyPackage(input)
end
```

## Example
Given the following input file:

```
[ default ]
example = "Example"

[ key1 ]
a = 1
b = 2
    [ key1.subdict ]
    x = 3
    y = 4
    [[ key1.subdict.subsubdict ]]
        z = 5
    [[ key1.subdict.subsubdict ]]
        z = 6

<include some/other/input.toml>

[ env_var ]
a = <$A>
b = <$B>

[ interpolation ]
a = 1
b = <%a>
c = <%example>

```

Given the environmental variables `A = 1`, and `B = 1`, and `some/other/input.toml`:

```
[ key2 ]
a = 1
b = 2
```

`setup_input` will:
1. Load in the initial input file
2. Transform it into input below
3. Ensure all relative paths are expanded to absolute paths, and ensure they exist
5. Setup logging
6. Save the transformed input file to an output directory

Transformed input:
```
[METADATA]
ORIGINAL = "/path/to/original/input.toml"
DATE = "2023-01-23"

[GLOBAL]
BASE_PATH = "/path/to/original"
INPUT_PATH = "/path/to/original"
OUTPUT_PATH = "/path/to/original/Output"
LOG_FILE = "/path/to/original/Output/log.txt"
LOGGING = true

[DEFAULT]
EXAMPLE = "Example"

[KEY1]
B = 2
A = 1

    [KEY1.SUBDICT]
    Y = 4
    X = 3

        [[KEY1.SUBDICT.SUBSUBDICT]]
        Z = 5
        [[KEY1.SUBDICT.SUBSUBDICT]]
        Z = 6

[ENV_VAR]
B = 2
A = 1

[INTERPOLATION]
B = 1
A = 1
C = "Example"
```

As you can see, all key's have been capitalised so users don't need to worry about capitalisation when writing their inputs. Environmental variables have been interpolated, as have local keys and any key in `[ DEFAULT ]`. Finally, a `[ METADATA ]` key has been added containing the path to the original file, and the date the script was run, and a `[ GLOBAL ]` key was added containing information about paths and logging which can be used throughout your script. This functionality will work for both `.yaml` and `.json` files as well, and can be extended to other input types.
