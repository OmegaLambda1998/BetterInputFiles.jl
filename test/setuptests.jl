@testset "Setup" begin
    toml_path = joinpath(@__DIR__, "test_files", "dummy.toml")

    @testset "Global" begin
        # Test defaults
        correct_default_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => joinpath(@__DIR__, "test_files"),
                "logging" => false,
                "log_file" => joinpath(@__DIR__, "test_files", "Output", "log.txt"),
                "base_path" => joinpath(@__DIR__, "test_files", ""),
                "output_path" => joinpath(@__DIR__, "test_files", "Output") 
            )
        )
        default_toml = Dict{Any, Any}("global" => Dict{Any, Any}("logging" => false))
        setup_global!(default_toml, toml_path, false)
        @test default_toml == correct_default_toml
        # Test that output path was created
        @test ispath(default_toml["global"]["output_path"])

        # Test logging gets created
        correct_logging_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => joinpath(@__DIR__, "test_files"),
                "logging" => true,
                "log_file" => joinpath(@__DIR__, "test_files", "Output", "test_log.log"),
                "base_path" => joinpath(@__DIR__, "test_files", ""),
                "output_path" => joinpath(@__DIR__, "test_files", "Output") 
            )
        )
        logging_toml = Dict{Any, Any}("global" => Dict{Any, Any}("log_file" => "test_log.log"))
        setup_global!(logging_toml, toml_path, false)
        @test logging_toml == correct_logging_toml
        # Test that output path was created
        @test ispath(logging_toml["global"]["output_path"])
        # Test that log file was created
        @test ispath(logging_toml["global"]["log_file"])

        # Test custom paths 
        correct_paths_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => joinpath(@__DIR__, "test_files"),
                "logging" => false,
                "log_file" => joinpath(@__DIR__, "test_files", "Output", "log.txt"),
                "base_path" => joinpath(@__DIR__, "test_files", ""),
                "output_path" => joinpath(@__DIR__, "test_files", "Output"),
                "input_path" => joinpath(@__DIR__, "test_files", "Input"),
                "data_path" => joinpath(@__DIR__, "test_files", "Input", "Data"),
            )
        )

        paths = OrderedDict("input_path" => ("base_path", "Input"), "data_path" => ("input_path", "Data"))

        paths_toml = Dict{Any, Any}("global" => Dict{Any, Any}("logging" => false))
        setup_global!(paths_toml, toml_path, false, paths)
        @test paths_toml == correct_paths_toml
        # Test that output path was created
        @test ispath(paths_toml["global"]["output_path"])
    end
end
