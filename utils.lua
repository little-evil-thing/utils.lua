local function strColorize(str, mark)
    if type(str) ~= "string" then return error("argument must be a string", 4) end
    local colors = {["&"]={bla=30, red=31, gre=32, yel=33, blu=34, mag=35, cya=36, whi=37, Bla=90, Red=91, Gre=92, Yel=93, Blu=94, Mag=95, Cya=96, Whi=97, res=0}, ["&&"]={bla=40, red=41, gre=42, yel=43, blu=44, mag=45, cya=46, whi=47, Bla=100, Red=101, Gre=102, Yel=103, Blu=104, Mag=105, Cya=106, Whi=107}}
    local markdown = {["_"] = 4, ["/"] = 3, ["%*"] = 1, ["`"] = 9, ["~"] = 5, ['|'] = 8 }

    local code = "\x1b[%dm"
    local last

    for char in string.gmatch(str, "&&?%a%a%a") do
        local color, length = string.gsub(char, "&", "")
        if colors[length == 1 and "&" or "&&"][color] then
            local num = colors[length == 1 and "&" or "&&"][color]
            str = string.gsub(str, char, string.format(code, num), 1)
            last = color
        end
    end
    if mark == true then 
        for key, c in pairs(markdown) do
        local state = 0
        local _, len = string.gsub(str, key, "")
        if len%2 == 1 then
            len = len - 1
        end
        for i=0, len do
            str = string.gsub(str, key, state == 0 and string.format(code, c) or string.format(code, c+20), 1)
            state = state == 0 and 1 or 0
        end
        end
    end

    if last == "res" then return str 
    else return str .. string.format(code, 0) end
end
local function strDecolorize(str)
    if type(str) ~= "string" then return error("argument must be a string", 4) end
    str =  str:gsub("%[.-m", "")
    return str
end
local function inspect(item, options)
    local typeof = type(item)
    local str = ""
    options = options or {}
    if type(options) ~= "table" then error("second argument (options) must be a table", 4) end

    options.__inherit  = options.__inherit or {depth = -1, recursive=-1}
    local luahl = {
        ["nil"] = "&Blu",
        string = "&gre",
        number = "&cya",
        boolean = "&Red",
        syntax = "&res",
        builtin = "&red",
        keyword = "&mag",
        class = "&Gre",
        metatable = "&red",
        ["function"] = "&Blu",
    }
    local builtinkeyword = {
        "and","break","do", "else", "elseif", "end", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "until", "while"
    }

    local function convert(str, types, base)
        local bool= false
        for _, ntype in ipairs(types) do
            if bool == true then break end
            bool = type(str) == ntype
        end
        if bool == false then
            return base
        end
        return str
    end

    local parameters = {
        depth = convert(options.depth, {"boolean", "number"}, false),
        maxTableLen = convert(options.maxTableLen, {"boolean", "number"}, 20),
        maxStringLen = convert(options.maxStringLen, {"boolean", "number"}, 160),
        compact = convert(options.compact, {"boolean"}, true),
        maxLen = convert(options.maxLen, {"boolean", "number"}, false),
        colors = convert(options.colors, {"boolean"}, false),
        customColors = convert(options.customColors, {"table"}, luahl)
    }
    for k, v in pairs(parameters.customColors) do
            parameters.customColors[k] = v:gmatch("&%a%a%a")() or ""
    end
    for k, v in pairs(luahl) do
        if not parameters.customColors[k] then
            parameters.customColors[k] = k=="syntax" and v or ""
        end
    end

    local inherit = {depth=options.__inherit.depth, recursive=options.__inherit.recursive}
    if inherit then
        if typeof == "table" then inherit.depth = inherit.depth + 1 elseif inherit.depth == -1 then inherit.depth = 0 end
        inherit.recursive = inherit.recursive + 1
        parameters.__inherit = inherit
    end
    if typeof == "string" then
        local trunced=false
        local len = #item
        if type(parameters.maxStringLen) == "number" then
            if len > parameters.maxStringLen then
                item = item:sub(1, math.abs(parameters.maxStringLen))
                trunced = true
            end
        end
        if parameters.colors then
            item =  parameters.customColors.string .. item ..  parameters.customColors.syntax
        end
        if trunced then
            item = item .. " ... "..len-math.abs(parameters.maxStringLen).." more"
        end
        if inherit.recursive > 0 then item = "'"..item.."'" end
        str=str..item
    elseif typeof == "number" then
        if parameters.colors then
            item =  parameters.customColors.number .. tostring(item) ..  parameters.customColors.syntax
        end
        str = str..item
    elseif typeof == "table" then
        local len=0
        for _ in pairs(item) do
            len=len+1
        end
        if type(parameters.depth) == "number" then
            if parameters.depth <= inherit.depth then
            if parameters.colors then
                local syntax = parameters.customColors.syntax
                local builtin = parameters.customColors.builtin
                    str =  builtin .. "[table:"..parameters.customColors.number..len..builtin.."]" ..  syntax
                    str = strColorize(str)
            else
                    str = "[table:"..len.."]"
            end
                return str
            end
        end
            local actuallen = 0
            local maxed = false
            local substr = parameters.customColors.syntax.."{%s"
            local start = true
            for k, v in ipairs(item) do
                if type(parameters.maxTableLen) == "number" then
                    if actuallen >= math.abs(parameters.maxTableLen) then
                        substr = substr:format(" ... " .. len - actuallen .. " more%s")
                        maxed = true
                        break
                    end
                end
                local tab = ""
                if not parameters.compact then
                    if k==1 and type(v) ~= "table" then
                        tab = "\n"
                        for i=0, inherit.depth do
                            tab = tab.."\t"
                        end
                    end
                    if type(v) == "table" then
                        tab = "\n"
                        for i=0, inherit.depth do
                            tab = tab.."\t"
                        end
                    end
                end
                substr = substr:format((start and "" or ", ")..tab..inspect(v, parameters).."%s")
                start = false
                actuallen = actuallen + 1
            end

            for k, v in pairs(item) do
                if maxed == true then break end
                    if type(parameters.maxTableLen) == "number" then
                    if actuallen >= math.abs(parameters.maxTableLen) then
                        substr = substr:format(" ... " .. len - actuallen .. " more%s")
                        maxed = true
                        break
                    end
                end
                if type(k) ~= "number" then
                    local key
                    if parameters.colors then
                        key = type(k) == "string" and parameters.customColors.keyword.. k .. parameters.customColors.syntax or parameters.customColors.keyword .."["..type(k).."]"..parameters.customColors.syntax
                    else
                        key = type(k) == "string" and k or "["..type(k).."]"
                    end
                    local tab = ""
                    if not parameters.compact then
                        tab = "\n"
                        for i=0, inherit.depth do
                            tab = tab.."\t"
                        end
                    end
                    substr = substr:format((start and "" or ", ").. tab ..key ..":"..inspect(v, parameters).."%s")
                    start=false
                    actuallen = actuallen + 1
                end
            end
            if not parameters.colors then
                substr = substr:sub("5")
            end
            local tab = ""
            if not parameters.compact then
                for i=1, inherit.depth do
                    tab = tab.."\t"
                end
                substr = substr:format("\n"..tab.."%s")
            end
            str = substr:format("}")
    elseif typeof == "function" then
        local infos = debug.getinfo(item)
        local func = item
        if type(parameters.depth) == "number" then
            if parameters.depth <= inherit.depth then
                if parameters.colors then
                    local syntax = parameters.customColors.syntax
                    local builtin = parameters.customColors.builtin
                    str =  builtin .. "[function:"..parameters.customColors.number..infos.nparams..builtin.."]" ..  syntax
                else
                    str = "[function:"..infos.nparams.."]"
                end
                return str
            end
        end
        
        if parameters.colors then
            local syntax = parameters.customColors.syntax
            local builtin = parameters.customColors.builtin
            item =  builtin .. "[function:"..parameters.customColors.number..infos.nparams..builtin.."]" ..  syntax
        else item = "[function:"..infos.nparams.."]" end
        if inherit.recursive <= 0 then
            local tmpdepth = parameters.depth
            parameters.depth=false

            local names = {}
            for i=1, tonumber(infos.nparams) do
                local arg = debug.getlocal(func, i)
                if arg then
                    table.insert(names, arg)
                end
            end

            local data = {
                name = infos.name or "",
                source = infos.short_src,
                args = infos.nparams,
                argsnames = names,
                type = infos.what
            }
            item = item..inspect(data, parameters)
            parameters.depth = tmpdepth
        end
        str = str..item
    elseif typeof == "userdata" then
        if parameters.colors then
            local syntax = parameters.customColors.syntax
            local builtin = parameters.customColors.builtin
            item =  builtin .. "[userdata]" ..  syntax
        else item = "[userdata]" end
        str = str..item
    elseif typeof == "thread" then
        if parameters.colors then
            local syntax = parameters.customColors.syntax
            local builtin = parameters.customColors.builtin
            item =  builtin .. "[thread]" ..  syntax
        else item = "[thread]" end
        str = str..item
    elseif typeof == "boolean" then
        if parameters.colors then
            item =  parameters.customColors.boolean .. tostring(item) .. parameters.customColors.syntax
        end
        str=str..tostring(item)
    elseif typeof == "nil" then
        if parameters.colors then
            item = parameters.customColors["nil"] .. "nil" .. parameters.customColors.syntax
        else item = "nil" end
        str=str..item
    end

    if parameters.colors and inherit.recursive == 0 then
        str = strColorize(str)
    end
    return str
end
local function tblClone(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[tblClone(orig_key)] = tblClone(orig_value)
        end
        setmetatable(copy, tblClone(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Class
-- todo : add externals and internals prototypes
local class_mt = {}
function class_mt:__index(key)
    if key == "instance" then return nil end
    if key == "getPrototype" then return function() local e = {}; for k in pairs(self.prototype) do table.insert(e, k) end return e end end
    if key == "initthisclass" then self.prototype.new =nil; self.prototype.extend = nil end
    if self.prototype[key] then
        return self.prototype[key]
    end
    if self.instance == nil then return nil end
    return self.instance[key]
end
function class_mt:__tostring()
    return inspect(self, {colors=true, depth = 1})
end
function class_mt:__newindex(key, value)
    if self.prototype[key] then return false end
    if key == "prototype" or key == "instance" then return false end
    if type(value) == "function" then
        self.prototype[key] =function(...) return value(...) end
    else
        rawset(self, key, value)
    end
end
local Class = {}
Class.prototype = {}
function Class.constructor(class, base) if type(base) == "table" then for k, v in pairs(base) do class[k] = v end; end; return class end
setmetatable(Class, class_mt)
function Class:extend(new, base)
    local class, class_prototype, constructor = nil, {}, function(e, f) end
    if type(new) == "function" then
        constructor = new 
        if type(base) ~= "table" and type(base) ~= "nil" then return error("the base of the class must be a table or nil", 4) end
        class = base or {}
    else
        if type (new) ~= "table" and type(base) ~= "nil" then return error("the base of the class must be a table or nil", 4) end
        class = new or {}
    end
    local mt = getmetatable(self)
    
    for k, v in pairs(self.prototype) do
        class_prototype[k] = v
    end
    for k, v in pairs(class) do
        if type(v) == "function" then
            class_prototype[k] = v
            class[k]=nil
        end
    end

    class.instance = self
    function class:constructor(...) constructor(self, ...) end
    class.prototype = class_prototype
    setmetatable(class, mt)
    return class
end
function Class:new(...)
    local class = tblClone(self)
    local e = class.initthisclass
    if type(class.constructor) == "function" then
        class:constructor(...)
    end
    return class
end

-- Array
local function arrconstruct(self, itterable, fill)
    if type(itterable) ~= "table" and type(itterable) ~= "string" and  type(itterable) ~= "nil" and type(itterable) ~= "number" then return error("itterable must be a table, number, string or nil", 2) end
    if type(fill) ~= "function" and type(fill) ~= "nil" then return error("fill must be a function or nil", 2) end

    local arr = self
    if type(itterable) == "string" then
        for char in itterable:gmatch(".") do
            table.insert(arr, char)
        end
    elseif type(itterable) == "table" then
        for k, v in pairs(itterable) do
            table.insert(arr, v)
        end
    elseif type(itterable) == "number" then
        if type(fill) == "function" then
            for i=1, itterable do
                table.insert(arr, fill(i, arr))
            end
        end
    end
    return arr
end

local arrproto = {
    push=function(self, item)
        table.insert(self, item)
        return #self
    end,
    pop=function(self)
        local tmp = self[#self]
        self[#self] = nil
        return tmp
    end,
    shift=function(self)
        local tmp = self[1]
        self[1] = false
        for i, v in ipairs(self) do
            self[i-1] = v
        end
        self[#self] = nil
        return tmp
    end,
    unshift=function(self, item)
        local tmp
        for i, v in ipairs(self) do
            if i == 1 then
                self[i] = item
                tmp=v
            else
                self[i] = tmp
                tmp=v
            end
        end
        self[#self+1] = tmp
        return #self
    end,
    remove=function(self, index)
        if type(index) ~= "number" then return error("index must be a number", 2) end
        local tmp = self[index]
        if tmp == nil then return nil end
        for i, v in ipairs(self) do
            if i == index then
                self[i] = false
            elseif i > index then
                self[i-1] = v
            end
        end
        self[#self] = nil
        return tmp
    end,
    indexOf=function(self, item, all)
        if item == nil then return -1 end
        local match = {}
        for i, v in ipairs(self) do
            if v == item then
                table.insert(match, i)
                if all ~= true then break end
            end
        end
        return (#match == 1 and match[1] or match)
    end,
    splice=function(self, start, end_)
        if type(start) ~= "number" then return error("start must be a number", 2) end
        if type(end_) ~= "number" and type(end_) ~= "nil" then return error("end must be a positive number or nil", 2) end
        end_ = end_ or #self
        if end_ < 1 then end_ = 1 end
        if start < 1 then start = 1 end
        if start > #self then start = #self end
        local removed = {}
        for i=1, end_ do
            table.insert(removed, self:remove(start))
        end
        return removed
    end,
    reverse=function(self)
        local tmp ={}
        for i=#self, 1, -1 do
            table.insert(tmp, self[i])
        end
        for i, v in ipairs(self) do
            self[i] = tmp[i]
        end
        return self
    end,
    shuffle=function (self)
        local tmp = {}
        for i=0, #self do
            local rnd = ""..math.random(#self)
            if tmp[rnd] then 
                while tmp[rnd] do
                    rnd = ""..math.random(#self)
                end
            end
            tmp[rnd]=self[i]
        end
        local index = 1
        for i, v in pairs(tmp) do
            self[tonumber(i)] = tmp[i]
            index = index + 1
        end
        return self
    end,
    sort=function (self, callback)
        if type(callback) ~= "function" and type(callback) ~= "nil" then return error("callback must be a function or nil", 2) end
        local tmp = {}
        for i, v in ipairs(self) do
            table.insert(tmp, v)
        end
        table.sort(tmp, callback)
        for i, v in ipairs(self) do
            self[i] = tmp[i]
        end
        return self
    end,
    join=function(self, sep)
        local str = ""
        for i, v in ipairs(self) do
            if i == 1 then
                str = inspect(v, {depth=0})
            else
                str = str..sep..inspect(v, {depth=0})
            end
        end
        return str
    end,
    split=function(self, index)
        if type(index) ~= "number" then return error("index must be a number", 2) end
        if index < 1 or index > #self then return self end
        local tmp1 = {}
        local tmp2 = {}

        for i, v in ipairs(self) do
            if i <= index then
                table.insert(tmp1, v)
            else
                table.insert(tmp2, v)
            end
        end
        return tmp1, tmp2
    end, 
    forEach=function(self, callback)
        if type(callback) ~= "function" then return error("callback must be a function", 2) end
        for i, v in ipairs(self) do
            callback(v, i, self)
        end
    end,
    map=function(self, callback)
        if type(callback) ~= "function" then return error("callback must be a function", 2) end
        local tmp = {}
        for i, v in ipairs(self) do
            table.insert(tmp, callback(v, i, self))
        end
        return tmp
    end,
    includes=function(self, item)
        for i, v in ipairs(self) do
            if v == item then return true end
        end
        return false
    end,
    random=function(self, n)
        if type(n) ~= "number" then
            n = 1
        end
        if n < 1 then n=1 end
        local tmp = {}
        for i=1, n do
            table.insert(tmp, self[math.random(#self)])
        end
        return #tmp == 1 and tmp[1] or tmp
    end, 
    values=function(self)
        local tmp = {}
        for i, v in ipairs(self) do
            table.insert(tmp, v)
        end
        return tmp
    end,
    find=function(self, callback)
        if type(callback) ~= "function" then return error("callback must be a function", 2) end
        for i, v in ipairs(self) do
            if callback(v, i, self) == true then return v end
        end
    end,
    clone=function(self)
        return tblClone(self)
    end,
    filter=function(self, callback)
        if type(callback) ~= "function" then return error("callback must be a function", 2) end
        local tmp = {}
        for i, v in ipairs(self) do
            if callback(v, i, self) == true then table.insert(tmp, v) end
        end
        for i, v in ipairs(tmp) do
            self:remove(self:indexOf(v))
        end
        return self
    end,
    every=function(self, callback)
        if type(callback) ~= "function" then return error("callback must be a function", 2) end
        local state = true
        for i, v in ipairs(self) do
            if callback(v, i, self) ~= true then state = false break end
        end
        return state
    end,
    reduce=function(self, callback, initialValue)
        if type(callback) ~= "function" then return error("callback must be a function", 2) end
        local state = initialValue

        for i, v in ipairs(self) do
            state = callback(state, v, i, self)
        end
        return state
    end,
    some=function(self, callback, enumerate)
        if type(callback) ~= "function" then return error("callback must be a function", 2) end
        if type(enumerate) ~= "boolean" then enumerate = false end
        local state = false
        local n = 0
        for i, v in ipairs(self) do
            if callback(v, i, self) == true then
                state = true
                if enumerate ~= true then
                    n = 1
                    break
                else
                    n = n + 1
                end
            end
        end
        return state, n
    end,
    slice=function(self, start, end_)
        if type(start) ~= "number" then return error("start must be a number", 2) end
        if type(end_) ~= "number" and type(end_) ~= "nil" then return error("end must be a positive number or nil", 2) end
        end_ = end_ or #self
        if end_ < 1 then end_ = 1 end
        if start < 1 then start = 1 end
        if start > #self then start = #self end
        local tmp = {}
        for i=1, end_ do
            table.insert(tmp, self[start + i - 1])
        end
        return tmp
    end,
    merge=function(self, other, shallow)
        if type(other) ~= "table" then return error("you can only mergewith a table or other array", 2) end
        if shallow == true then other = tblClone(other) end
        for i, v in ipairs(other) do
            table.insert(self, v)
        end
    end
}
local Array = Class:extend(arrconstruct, arrproto)


--export
-- todo : autodetect love2d
local utilstbl = { Class = Class,  inspect = inspect, strColorize = strColorize, strDecolorize = strDecolorize, tblClone = tblClone, Array = Array }
local utilstblmt = {}
function utilstblmt:__tostring()
    return inspect(self, {colors=true, depth=1})
end
setmetatable(utilstbl, utilstblmt)

return utilstbl