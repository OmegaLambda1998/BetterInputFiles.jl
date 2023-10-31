using BetterInputFiles
using Test
using OrderedCollections 
using Dates


const ext_dict = Dict(
    "yml" => "yaml",
    "tml" => "toml",
    "jsn" => "json"
)


@testset verbose = true "BetterInputFiles.jl" begin
    test_files = joinpath(@__DIR__, "test_files")
    input_files = joinpath(test_files, "input_files")
    expected_outputs = joinpath(test_files, "expected_outputs")

    @testset "InputExt" begin
        @test BetterInputFiles.get_InputExt(".yaml") == BetterInputFiles.get_InputExt("yaml")
    end

    @testset "expected errors" begin
        test_file = joinpath(test_files, "broken.ext")
        @test_throws UndefVarError setup_input(test_file, false)
        test_file = joinpath(input_files, "blank", "blank.toml")
        broken_paths = OrderedDict(
            "a_path" => ("b_path", "A"),
            "b_path" => ("base_path", "B")
        )
        @test_throws ErrorException setup_input(test_file, false; paths=broken_paths)
    end

    @testset "expected outputs" begin
        ENV["A"] = 1
        ENV["B"] = 2

        custom_metadata = [("A", "B")]
        

        for dir in readdir(input_files)
            input_dir = joinpath(input_files, dir)
            expected_dir = joinpath(expected_outputs, dir)
            @testset "$dir" begin
                for file in readdir(input_dir)
                    if isfile(joinpath(input_dir, file))
                        test_file = joinpath(input_dir, file)
                        ext = splitext(file)[end][2:end] 
                        if ext in keys(ext_dict)
                            ext = ext_dict[ext]
                        end
                        input_1 = setup_input(test_file, false; custom_metadata=custom_metadata)
                        input_2 = setup_input(test_file, false, ext; custom_metadata=custom_metadata)
                        expected_output_1 = BetterInputFiles.load_inputfile(joinpath(expected_dir, file))
                        expected_output_2 = BetterInputFiles.load_inputfile(joinpath(expected_dir, file), ext)
                        # Deal with github's paths
                        input_1["METADATA"] = expected_output_1["METADATA"]
                        input_2["METADATA"] = expected_output_2["METADATA"]
                        input_1["GLOBAL"] = expected_output_1["GLOBAL"]
                        input_2["GLOBAL"] = expected_output_2["GLOBAL"]
                        @test input_1 == expected_output_1
                        @test input_2 == expected_output_2
                    end
                end
            end
        end
    end
end
