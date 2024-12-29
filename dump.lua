-- 在文件开头添加模块模拟系统
local function create_mock_module()
    return setmetatable({}, {
        __index = function(t, k)
            t[k] = create_mock_module()
            return t[k]
        end
    })
end

-- 创建一个模拟 require 函数
local original_require = require
_G.require = function(module_name)
    local success, result = pcall(original_require, module_name)
    if not success then
        -- 如果模块不存在，返回一个模拟模块
        print("Mocking module: " .. module_name)
        local mock = create_mock_module()
        package.loaded[module_name] = mock
        return mock
    end
    return result
end

-- 预定义一些特定的模块内容
local sounds = {
    machine_open = {},
    machine_close = {},
    item_drop = {},
    item_pickup = {}
}

package.loaded["prototypes.entity.sounds"] = sounds

local item_sounds = {
    default = { volume = 0.5 },
    metal = { volume = 0.5 },
    wooden = { volume = 0.5 }
}

package.loaded["__base__.prototypes.item_sounds"] = item_sounds

local item_tints = {
    default_material_tint = {r = 0.5, g = 0.5, b = 0.5, a = 1.0},
    default_ammo_tint = {r = 1.0, g = 1.0, b = 0.0, a = 1.0},
    default_capsule_tint = {r = 0.0, g = 1.0, b = 0.0, a = 1.0}
}

package.loaded["__base__.prototypes.item-tints"] = item_tints

-- 添加 Factorio 单位常量
_G.kg = 1
_G.meter = 1
_G.second = 1
_G.joule = 1
_G.watt = joule / second
_G.newton = kg * meter / (second * second)
_G.hp = 745.7 * watt
_G.tons = 1000 * kg
_G.kilometers = 1000 * meter
_G.miles = 1609.344 * meter
_G.hours = 3600 * second
_G.minutes = 60 * second
_G.kilo = 1000
_G.mega = kilo * kilo
_G.giga = kilo * mega
_G.grams = kg / 1000  -- 添加克
_G.milligrams = grams / 1000  -- 添加毫克
_G.pounds = 0.45359237 * kg  -- 添加磅
_G.ounces = pounds / 16  -- 添加盎司

-- 添加 volume_multiplier 函数
_G.volume_multiplier = function(value)
    -- 这个函数在 Factorio 中用于调整音量
    -- 通常返回一个介于 0 和 1 之间的值
    return value or 1
end

-- 在文件开头添加输出目录配置
local OUTPUT_DIR = "output"

-- 确保输出目录存在
local function ensure_dir(path)
    local success, err = os.execute("mkdir -p " .. path)
    if not success then
        print("Warning: Could not create directory " .. path .. ": " .. (err or "unknown error"))
    end
end

-- 序列化为JSON的函数
local function to_json(o)
    if type(o) == "number" then
        return tostring(o)
    elseif type(o) == "string" then
        return string.format("%q", o)
    elseif type(o) == "boolean" then
        return tostring(o)
    elseif type(o) == "table" then
        if next(o) == nil then
            return "{}"
        end

        -- 检查是否为数组
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
            -- 处理数组
            table.insert(parts, "[")
            for i, v in ipairs(o) do
                if i > 1 then table.insert(parts, ",") end
                table.insert(parts, to_json(v))
            end
            table.insert(parts, "]")
        else
            -- 处理对象
            table.insert(parts, "{")
            local first = true
            for k, v in pairs(o) do
                if not first then table.insert(parts, ",") end
                first = false
                table.insert(parts, string.format("%q", tostring(k)))
                table.insert(parts, ":")
                table.insert(parts, to_json(v))
            end
            table.insert(parts, "}")
        end
        return table.concat(parts)
    else
        return "null"
    end
end

-- 模拟 Factorio data 对象
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

-- 模拟 util 对象
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

-- 加载原始数据文件
_G.data = data
_G.util = util
dofile("base/prototypes/technology.lua")

-- 将数据保存到文件
local function save_to_json(data, filename)
    ensure_dir(OUTPUT_DIR)
    local full_path = OUTPUT_DIR .. "/" .. filename
    local file = io.open(full_path, "w")
    if file then
        local json_str = to_json(data.raw)
        file:write(json_str)
        file:close()
        print("Data has been saved to " .. full_path)
    else
        print("Error: Could not open file for writing: " .. full_path)
    end
end

-- 保存数据
save_to_json(data, "technology.json")
