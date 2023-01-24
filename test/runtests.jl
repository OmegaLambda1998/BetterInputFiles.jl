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

    @testset "Setup" begin
        include("test_setup.jl")
    end

    @testset "Macros" begin
        include("test_macros.jl")
    end
    
end
