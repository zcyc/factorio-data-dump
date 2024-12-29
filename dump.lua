-- 模块模拟系统
local function create_mock_module()
    return setmetatable({}, {
        __index = function(t, k)
            t[k] = create_mock_module()
            return t[k]
        end
    })
end

-- 重写 require 函数
local original_require = require
_G.require = function(module_name)
    local success, result = pcall(original_require, module_name)
    if not success then
        print("Mocking module: " .. module_name)
        local mock = create_mock_module()
        package.loaded[module_name] = mock
        return mock
    end
    return result
end

-- 基本单位常量
local units = {
    "kg", "meter", "second", "joule", "tons", "grams", "milligrams",
    "kilometers", "miles", "hours", "minutes", "kilo", "mega", "giga"
}

-- 初始化基本单位
for _, unit in ipairs(units) do
    _G[unit] = 1
end

-- 派生单位
_G.watt = _G.joule / _G.second
_G.newton = _G.kg * _G.meter / (_G.second * _G.second)
_G.hp = 745.7 * _G.watt
_G.pounds = 0.45359237 * _G.kg
_G.ounces = _G.pounds / 16

-- 辅助函数
_G.volume_multiplier = function(value) return value or 1 end

-- JSON序列化函数
local function to_json(o)
    if type(o) == "number" then
        return tostring(o)
    elseif type(o) == "string" then
        return string.format("%q", o)
    elseif type(o) == "boolean" then
        return tostring(o)
    elseif type(o) == "table" then
        if next(o) == nil then return "{}" end

        local is_array = true
        local n = 0
        for k, _ in pairs(o) do
            n = n + 1
            if type(k) ~= "number" or k ~= n then
                is_array = false
                break
            end
        end

        local parts = {}
        if is_array then
            parts[1] = "["
            for i, v in ipairs(o) do
                if i > 1 then parts[#parts + 1] = "," end
                parts[#parts + 1] = to_json(v)
            end
            parts[#parts + 1] = "]"
        else
            parts[1] = "{"
            local first = true
            for k, v in pairs(o) do
                if not first then parts[#parts + 1] = "," end
                first = false
                parts[#parts + 1] = string.format("%q", tostring(k))
                parts[#parts + 1] = ":"
                parts[#parts + 1] = to_json(v)
            end
            parts[#parts + 1] = "}"
        end
        return table.concat(parts)
    else
        return "null"
    end
end

-- Factorio data 对象
local data = {
    raw = {},
    extend = function(self, entries)
        for _, entry in ipairs(entries) do
            if not self.raw[entry.type] then
                self.raw[entry.type] = {}
            end
            self.raw[entry.type][entry.name] = entry
        end
    end
}

-- Factorio util 对象
local util = {
    technology_icon_constant_damage = function(path) return {{icon = path}} end,
    technology_icon_constant_speed = function(path) return {{icon = path}} end,
    technology_icon_constant_equipment = function(path) return {{icon = path}} end,
    technology_icon_constant_capacity = function(path) return {{icon = path}} end,
    technology_icon_constant_followers = function(path) return {{icon = path}} end,
    technology_icon_constant_movement_speed = function(path) return {{icon = path}} end,
    technology_icon_constant_braking_force = function(path) return {{icon = path}} end,
    technology_icon_constant_stack_size = function(path) return {{icon = path}} end,
    technology_icon_constant_productivity = function(path) return {{icon = path}} end,
    technology_icon_constant_range = function(path) return {{icon = path}} end
}

-- 设置全局对象
_G.data = data
_G.util = util

-- 加载并保存数据
local function save_to_json(filename)
    local OUTPUT_DIR = "output"
    os.execute("mkdir -p " .. OUTPUT_DIR)

    dofile("base/prototypes/" .. filename .. ".lua")

    local full_path = OUTPUT_DIR .. "/" .. filename .. ".json"
    local file = io.open(full_path, "w")
    if file then
        file:write(to_json(data.raw))
        file:close()
        print("Data has been saved to " .. full_path)
    else
        print("Error: Could not open file for writing: " .. full_path)
    end
end

-- 执行导出
save_to_json("recipe")
