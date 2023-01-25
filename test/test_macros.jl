@testset "@get" begin

    d = Dict("A" => 1, "B" => 2)
    k = "a"
    default = 3

    @test @get d["a"] == d["A"]
    @test @get d["A"] == d["A"]
    @test @get d[k] == d["A"]

    @test @get getindex(d, "a") == getindex(d, "A")
    @test @get getindex(d, "A") == getindex(d, "A")
    @test @get getindex(d, k) == getindex(d, "A")

    @test @get get(d, "a", 3) == get(d, "A", 3)
    @test @get get(d, "A", 3) == get(d, "A", 3)
    @test @get get(d, k, 3) == get(d, "A", 3)
    @test @get get(d, k, default) == get(d, "A", 3)
    @test @get get(d, "c", default) == get(d, "c", default)

end

@testset "@set" begin
    d = Dict("A" => 1, "B" => 2)
    @set! d["c"] = 3
    @test d["C"] == 3

    d = Dict("A" => 1, "B" => 2)
    k = "c"
    value = 3
    @set! d[k] = value
    @test d["C"] == 3
    
    d = Dict("A" => 1, "B" => 2)
    @set! setindex!(d, 3, "c") 
    @test d["C"] == 3

    d = Dict("A" => 1, "B" => 2)
    k = "c"
    value = 3
    @set! setindex!(d, value, k) 
    @test d["C"] == 3
end

@testset "@required" begin
    d = Dict("A" => 1, "B" => 2)
    k = "a"
    default = 3

    @test @required d[k] == d["A"]
    @test @required getindex(d, k) == getindex(d, "A")
    @test @required get(d, k, default) == get(d, "A", 3)
    @test @required get(d, "c", default) == get(d, "c", default)
end

@testset "@restricted" begin
    d = Dict("A" => 1, "B" => 2)
    k = "a"
    default = 3

    function f1(x)
        return x < 5
    end

    f2(x) = x < 5

    @test (@restricted d[k] f1) == d["A"]
    @test (@restricted d[k] f2) == d["A"]
    @test (@restricted d[k] (x -> x < 5)) == d["A"]
    @test (@restricted getindex(d, k) f1) == getindex(d, "A")
    @test (@restricted getindex(d, k) f2) == getindex(d, "A")
    @test (@restricted getindex(d, k) (x -> x < 5)) == getindex(d, "A")
    @test (@restricted get(d, k, default) f1) == get(d, "A", 3)
    @test (@restricted get(d, k, default) f2) == get(d, "A", 3)
    @test (@restricted get(d, k, default) (x -> x < 5)) == get(d, "A", 3)
    @test (@restricted get(d, "c", default) f1) == get(d, "c", default)
    @test (@restricted get(d, "c", default) f2) == get(d, "c", default)
    @test (@restricted get(d, "c", default) (x -> x < 5)) == get(d, "c", default)
end
