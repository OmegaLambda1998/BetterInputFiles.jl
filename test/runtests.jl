using OLUtils
using Test

@testset verbose = true "OLUtils.jl" begin

    @testset "Global setup" begin
        # Test defaults
        correct_default_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => @__DIR__,
                "logging" => false,
                "log_file" => nothing,
                "base_path" => joinpath(@__DIR__, ""),
                "output_path" => joinpath(@__DIR__, "Output") 
            )
        )
        default_toml = Dict{Any, Any}("global" => Dict{Any, Any}("toml_path" => @__DIR__, "logging" => false))
        setup_global!(default_toml, false)
        @test default_toml == correct_default_toml
        # Test that output path was created
        @test ispath(default_toml["global"]["output_path"])
        # Cleanup output path created by test
        rm(default_toml["global"]["output_path"], recursive=true, force=true)
        @test !ispath(default_toml["global"]["output_path"])

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
        logging_toml = Dict{Any, Any}("global" => Dict{Any, Any}("toml_path" => @__DIR__, "log_file" => "test_log.log"))
        setup_global!(logging_toml, false)
        @test logging_toml == correct_logging_toml
        # Test that output path was created
        @test ispath(logging_toml["global"]["output_path"])
        # Test that log file was created
        @test ispath(logging_toml["global"]["log_file"])
        # Cleanup output path created by test
        rm(logging_toml["global"]["output_path"], recursive=true, force=true)
        @test !ispath(logging_toml["global"]["output_path"])

        # Test custom paths 
        correct_paths_toml = Dict{Any, Any}(
            "global" => Dict{Any, Any}(
                "toml_path" => @__DIR__,
                "logging" => false,
                "log_file" => nothing,
                "base_path" => joinpath(@__DIR__, ""),
                "output_path" => joinpath(@__DIR__, "Output"),
                "input_path" => joinpath(@__DIR__, "Input"),
                "data_path" => joinpath(@__DIR__, "Input", "Data"),
            )
        )

        paths = Dict("input_path" => ("base_path", "Input"), "data_path" => ("input_path", "Data"))

        paths_toml = Dict{Any, Any}("global" => Dict{Any, Any}("toml_path" => @__DIR__, "logging" => false))
        setup_global!(paths_toml, false, paths)
        @test paths_toml == correct_paths_toml
        # Test that output path was created
        @test ispath(paths_toml["global"]["output_path"])
        # Cleanup output path created by test
        rm(paths_toml["global"]["output_path"], recursive=true, force=true)
        @test !ispath(paths_toml["global"]["output_path"])
        # Cleanup input path created by test
        rm(paths_toml["global"]["input_path"], recursive=true, force=true)
        @test !ispath(paths_toml["global"]["input_path"])



    end
end
