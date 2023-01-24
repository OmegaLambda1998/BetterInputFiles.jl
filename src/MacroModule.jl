module MacroModule

# External Packages
import MLStyle: @match
import MacroTools: postwalk, prewalk

# Internal Packages

# Exports
export @get
export @set!

"""
Taken from https://thautwarm.github.io/MLStyle.jl/stable/tutorials/capture/ on 24/01/2023
"""
function capture(template, ex, action)
    let template = Expr(:quote, template)
        quote
            @match $ex begin 
                $template => $action
                _         => nothing
            end
        end 
    end
end

"""
Taken from https://thautwarm.github.io/MLStyle.jl/stable/tutorials/capture/ on 24/01/2023
"""
macro capture(template, ex, action)
    capture(template, ex, action) |> esc
end

"""
    getter(expr::Expr)

Recursively parse `expr` for dictionary[key], getindex(dictionary, key), or get(dictionary, key, default) expressions. Then case-insensitive get `key` from `dictionary`

# Arguments
- `expr::Expr`: Expression to parse
"""
function getter(expr::Expr)
    postwalk(expr) do ex
        # Matches dictionary[key]
        @capture $(dictionary)[$(key)] ex begin
            return quote
                local dictionary_type = typeof($(esc(dictionary)))
                local expected_key_type = dictionary_type.parameters[1]
                if !(dictionary_type <: Dict{S, V} where {S <: AbstractString, V})
                    error("`@get dictionary[key]` requires dictionary<:Dict{S, V} where {S <: AbstractString, V}, not $dictionary_type")
                end
                local key_type = typeof($(esc(key)))
                if !(key_type <: expected_key_type)
                    error("`@get dictionary[key]` key has type $key_type, but requires type <:$expected_key_type")
                end
                local upper_key = uppercase("$($(esc(key)))")
                getter($(esc(dictionary)), $(esc(key)))
            end
        end

        # Matches getindex(dictionary, key)
        @capture getindex($(dictionary), $(key)) ex begin
            return quote
                local dictionary_type = typeof($(esc(dictionary)))
                local expected_key_type = dictionary_type.parameters[1]
                if !(dictionary_type <: Dict{S, V} where {S <: AbstractString, V})
                    error("`@get getindex(dictionary, key)` requires dictionary<:Dict{S, V} where {S <: AbstractString, V}, not $dictionary_type")
                end
                local key_type = typeof($(esc(key)))
                if !(key_type <: expected_key_type)
                    error("`@get getindex(dictionary, key)` key has type $key_type, but requires type <:$expected_key_type")
                end
                local upper_key = uppercase("$($(esc(key)))")
                getter($(esc(dictionary)), $(esc(key)))
            end
        end

        # Matches get(dictionary, key, default)
        @capture get($(dictionary), $(key), $(default)) ex begin
            return quote
                local dictionary_type = typeof($(esc(dictionary)))
                local expected_key_type = dictionary_type.parameters[1]
                local expected_default_type = dictionary_type.parameters[2]
                if !(dictionary_type <: Dict{S, V} where {S <: AbstractString, V})
                    error("`@get get(dictionary, key, default)` requires dictionary<:Dict{S, V} where {S <: AbstractString, V}, not $dictionary_type")
                end
                local key_type = typeof($(esc(key)))
                if !(key_type <: expected_key_type)
                    error("`@get get(dictionary, key, default)` key has type $key_type, but requires type <:$expected_key_type")
                end
                local default_type = typeof($(esc(default)))
                if !(default_type <: expected_default_type)
                    error("`@get get(dictionary, key, default)` default has type $default_type, but requires type <:$expected_default_type")
                end
                local upper_key = uppercase("$($(esc(key)))")
                getter($(esc(dictionary)), $(esc(key)), $(esc(default)))
            end
        end

        # No matches
        return ex
    end
end

"""
    getter(dictionary::Dict{S, V}, key::S) where {S <: AbstractString, V}

Case-insensitive get `key` from `dictionary`

# Arguments
- `dictionary::Dict{S, V}`: Dictionary to get `key` from
- `key::S`: `key` to get from `dictionary`
"""

function getter(dictionary::Dict{S, V}, key::S) where {S <: AbstractString, V}
    upper_key = uppercase("$(key)")
    return getindex(dictionary, upper_key)
end

"""
    getter(dictionary::Dict{S, V}, key::S, default::V) where {S <: AbstractString, V}

Case-insensitive get `key` from `dictionary`, returning `default` if `key` not found

# Arguments
- `dictionary::Dict{S, V}`: Dictionary to get `key` from
- `key::S`: `key` to get from `dictionary`
- `default::V`: Default value if `key` not found
"""
function getter(dictionary::Dict{S, V}, key::S, default::V) where {S <: AbstractString, V}
    upper_key = uppercase("$(key)")
    return get(dictionary, upper_key, default)
end

"""
    @get(ex::Expr)

Case-insensitive get value from input file. Matches dictionary[key], getindex(dictionary, key), and get(dictionary, key, default)

# Arguments
- `ex::Expr`: Expression to parse
"""
macro get(ex::Expr)
    try
        return getter(ex)
    catch e
        error("`$(ex)` does not match dictionary[key], getindex(dictionary, key), or get(dictionary, key, default)")
    end
end

function setter!(expr::Expr)
    postwalk(expr) do ex
        # Matches dictionary[key] = value
        @capture $(dictionary)[$(key)] = $(value) ex begin
            return quote
                local dictionary_type = typeof($(esc(dictionary)))
                local expected_key_type = dictionary_type.parameters[1]
                local expected_value_type = dictionary_type.parameters[2]
                if !(dictionary_type <: Dict{S, V} where {S <: AbstractString, V})
                    error("`@set! dictionary[key] = value` requires dictionary<:Dict{S, V} where {S <: AbstractString, V}, not $dictionary_type")
                end
                local key_type = typeof($(esc(key)))
                if !(key_type <: expected_key_type)
                    error("`@set! dictionary[key] = value` key has type $key_type, but requires type <:$expected_key_type")
                end
                local value_type = typeof($(esc(value)))
                if !(value_type <: expected_value_type)
                    error("`@set! dictionary[key] = value` value has type $value_type, but requires type <:$expected_value_type")
                end
                setter!($(esc(dictionary)), $(esc(value)), $(esc(key)))
            end
        end

        @capture setindex!($(dictionary), $(value), $(key)) ex begin
            return quote
                local dictionary_type = typeof($(esc(dictionary)))
                local expected_key_type = dictionary_type.parameters[1]
                local expected_value_type = dictionary_type.parameters[2]
                if !(dictionary_type <: Dict{S, V} where {S <: AbstractString, V})
                    error("`@set! setindex!(dictionary, value, key)` requires dictionary<:Dict{S, V} where {S <: AbstractString, V}, not $dictionary_type")
                end
                local key_type = typeof($(esc(key)))
                if !(key_type <: expected_key_type)
                    error("`@set! setindex!(dictionary, value, key)` key has type $key_type, but requires type <:$expected_key_type")
                end
                local value_type = typeof($(esc(value)))
                if !(value_type <: expected_value_type)
                    error("`@set! setindex!(dictionary, value, key)` value has type $value_type, but requires type <:$expected_value_type")
                end
                setter!($(esc(dictionary)), $(esc(value)), $(esc(key)))
            end
        end

        # No matches
        return ex
    end
end

function setter!(dictionary::Dict{S, V}, value::V, key::S) where {S <: AbstractString, V}
    upper_key = uppercase("$(key)")
    setindex!(dictionary, value, upper_key)
end

macro set!(ex::Expr)
    try
        setter!(ex)
    catch e
        error("`$(ex)` does not match dictionary[key] = value, or setindex!(dictionary, value, key)")
    end
end

end
