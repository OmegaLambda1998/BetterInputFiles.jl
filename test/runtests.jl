using InputFiles 
using Test
using DataStructures
using Dates

@testset verbose = true "InputFiles.jl" begin

    include("iotests.jl")

    include("setuptests.jl")

end
