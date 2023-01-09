@testset "IO" begin

    input_file_dir = joinpath(@__DIR__, "test_files", "input_files")

    @testset "InputExt" begin
        # Test that the correct InputExt is found
        for (ext, input_ext) in zip(InputFiles.IOModule.exts, InputFiles.IOModule.input_exts)
            @test InputFiles.IOModule.get_InputExt(ext)() == input_ext
        end

        # Test that an unknown InputExt fails
        @test_throws UndefVarError InputFiles.IOModule.get_InputExt("DoesNotExist")()
    end

    @testset "Load Raw" begin
        # Test blank inputs
        blank_inputs = readdir(joinpath(input_file_dir, "blank"), join=true)
        for input in blank_inputs
            if any(ext -> occursin(ext, input), ["json", "jsn"])
                # Deal with windows carriage returns
                @test replace(load_raw_input(input), "\r\n" => "\n") == "{\n}\n"
            else
                @test load_raw_input(input) == ""
            end
        end
    end

    @testset "Preprocess" begin
        # Test blank inputs
        blank_inputs = readdir(joinpath(input_file_dir, "blank"), join=true)
        for input in blank_inputs
            if any(ext -> occursin(ext, input), ["json", "jsn"])
                correct_raw = "{\n\"METADATA\": {\n    \"Date\": \"$(today())\",\n    \"Original\": \"$(input)\"\n},\n\"JSON\": {\n}\n\n}"
            else
                correct_raw = "# Created on $(today())\n# Original file: $input\n\n"
            end
            @test replace(preprocess_input(input), "\r\n" => "\n") == correct_raw
        end
    end

end
