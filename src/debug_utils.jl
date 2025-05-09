const DEBUG_MODE = Ref{Bool}(false)

function enable_debug_messages()
    return DEBUG_MODE[] = true
end

function disable_debug_messages()
    return DEBUG_MODE[] = false
end

function _is_debug_enabled()
    return DEBUG_MODE[]
end

function _debug_message(message)
    r = my_rank()
    open("debug_rank_$(r).log", "a") do io
        return println(io, "DEBUG (rank $r): ", message)
    end
end
