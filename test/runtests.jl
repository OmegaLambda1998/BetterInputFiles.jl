using InputFiles 
using Test
using DataStructures
using Dates


const ext_dict::Dict{String, String} = Dict(
    "yml" => "yaml",
    "tml" => "toml",
    "jsn" => "json"
)


@testset verbose = true "InputFiles.jl" begin

    ENV["A"] = 1
    ENV["B"] = 2
    
    test_files = joinpath(@__DIR__, "test_files")
    input_files = joinpath(test_files, "input_files")
    expected_outputs = joinpath(test_files, "expected_outputs")

    for dir in readdir(input_files)
        input_dir = joinpath(input_files, dir)
        expected_dir = joinpath(expected_outputs, dir)
        @testset "$dir" begin
            for file in readdir(input_dir)
                if isfile(joinpath(input_dir, file))
                    ext = splitext(file)[end][2:end] 
                    if ext in keys(ext_dict)
                        ext = ext_dict[ext]
                    end
                    input = setup_input(joinpath(input_dir, file), ext, false)
                    expected_output = InputFiles.load_inputfile(joinpath(expected_dir, file), ext)
                    # Deal with github's paths
                    expected_output["METADATA"] = input["METADATA"]
                    expected_output["GLOBAL"] = input["GLOBAL"]
                    @test input == expected_output
                end
            end
        end
    end

end
