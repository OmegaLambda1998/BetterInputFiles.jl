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
This package provides one main function, and a number of helper macros. The `setup_input` function does most of the heavy lifting, pre-processing, loading, and post-processing the input file you give it. An idiomatic way of using this package is as follows:

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
    input = setup_input(input_path, verbose)
    # Run your package with the input file
    run_MyPackage(input)
end
```
