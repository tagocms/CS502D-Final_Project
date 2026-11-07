function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function deepcopy(table)
    local copy = {}
    for k, value in pairs(table) do
        if type(value) == "table" then
            copy[k] = deepcopy(value)
        else
            copy[k] = value
        end
    end

    return copy
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

function push(T, other)
    for i, item in ipairs(other) do
        table.insert(T, item)
    end
    
    return T
end

function push_with_keyvalue(T, other)
    for key, value in pairs(other) do
        T[key] = value
    end

    return T
end

function table.deepEquals(a, b, seen)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end

    seen = seen or {}
    if seen[a] == b then return true end
    seen[a] = b

    for key, value in pairs(a) do
        if not table.deepEquals(value, b[key], seen) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end

    return true
end

function table.contains(T, item, deep)
    for i, value in ipairs(T) do
        if value == item or (deep and table.deepEquals(value, item)) then
            return true
        end
    end

    return false
end
