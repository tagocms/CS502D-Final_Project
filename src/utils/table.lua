function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function ipairs_reverse(t)
    local function iter(t, i)
        i = i - 1
        if i > 0 then
            return i, t[i]
        end
    end
    return iter, t, #t + 1
end