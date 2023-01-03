using OLUtils
using Test
using DataStructures

@testset verbose = true "OLUtils.jl" begin

    clean = (length(ARGS) > 0) && (ARGS[1] in ["-c", "--clean"])
    toml_path = joinpath(@__DIR__, "dummy.toml")
    @testset "Global setup" begin
        # Test defaults
        correct_default_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => @__DIR__,
                "logging" => false,
                "log_file" => joinpath(@__DIR__, "Output", "log.txt"),
                "base_path" => joinpath(@__DIR__, ""),
                "output_path" => joinpath(@__DIR__, "Output") 
            )
        )
        default_toml = Dict{Any, Any}("global" => Dict{Any, Any}("logging" => false))
        setup_global!(default_toml, toml_path, false)
        @test default_toml == correct_default_toml
        # Test that output path was created
        @test ispath(default_toml["global"]["output_path"])
        if clean
            # Cleanup output path created by test
            rm(default_toml["global"]["output_path"], recursive=true, force=true)
        end

        # Test logging gets created
        correct_logging_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => @__DIR__,
                "logging" => true,
                "log_file" => joinpath(@__DIR__, "Output", "test_log.log"),
                "base_path" => joinpath(@__DIR__, ""),
                "output_path" => joinpath(@__DIR__, "Output") 
            )
        )
        logging_toml = Dict{Any, Any}("global" => Dict{Any, Any}("log_file" => "test_log.log"))
        setup_global!(logging_toml, toml_path, false)
        @test logging_toml == correct_logging_toml
        # Test that output path was created
        @test ispath(logging_toml["global"]["output_path"])
        # Test that log file was created
        @test ispath(logging_toml["global"]["log_file"])
        if clean
            # Cleanup output path created by test
            rm(logging_toml["global"]["output_path"], recursive=true, force=true)
        end

        # Test custom paths 
        correct_paths_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => @__DIR__,
                "logging" => false,
                "log_file" => joinpath(@__DIR__, "Output", "log.txt"),
                "base_path" => joinpath(@__DIR__, ""),
                "output_path" => joinpath(@__DIR__, "Output"),
                "input_path" => joinpath(@__DIR__, "Input"),
                "data_path" => joinpath(@__DIR__, "Input", "Data"),
            )
        )

        paths = OrderedDict("input_path" => ("base_path", "Input"), "data_path" => ("input_path", "Data"))

        paths_toml = Dict{Any, Any}("global" => Dict{Any, Any}("logging" => false))
        setup_global!(paths_toml, toml_path, false, paths)
        @test paths_toml == correct_paths_toml
        # Test that output path was created
        @test ispath(paths_toml["global"]["output_path"])
        if clean
            # Cleanup output path created by test
            rm(paths_toml["global"]["output_path"], recursive=true, force=true)
            @test !ispath(paths_toml["global"]["output_path"])
            # Cleanup input path created by test
            rm(paths_toml["global"]["input_path"], recursive=true, force=true)
            @test !ispath(paths_toml["global"]["input_path"])
        end
    end

end
