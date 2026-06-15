-- ╔══════════════════════════════════════════════════════════╗
-- ║                     SaveManager v2                      ║
-- ║         Config save/load system for Fluent UI           ║
-- ╚══════════════════════════════════════════════════════════╝

local HttpService = game:GetService("HttpService")

-- ─────────────────────────────────────────────
--  Core module
-- ─────────────────────────────────────────────

local SaveManager = {}
SaveManager.Folder  = "FluentSettings"
SaveManager.Ignore  = {}
SaveManager.Options = {}
SaveManager.Library = nil

-- ─────────────────────────────────────────────
--  Type parsers  (Save → serialise, Load → apply)
-- ─────────────────────────────────────────────

SaveManager.Parser = {

    Toggle = {
        Save = function(idx, object)
            return { type = "Toggle", idx = idx, value = object.Value }
        end,
        Load = function(idx, data)
            if SaveManager.Options[idx] then
                SaveManager.Options[idx]:SetValue(data.value)
            end
        end,
    },

    Slider = {
        Save = function(idx, object)
            return { type = "Slider", idx = idx, value = tostring(object.Value) }
        end,
        Load = function(idx, data)
            if SaveManager.Options[idx] then
                SaveManager.Options[idx]:SetValue(data.value)
            end
        end,
    },

    Dropdown = {
        Save = function(idx, object)
            return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi }
        end,
        Load = function(idx, data)
            if SaveManager.Options[idx] then
                SaveManager.Options[idx]:SetValue(data.value)
            end
        end,
    },

    Colorpicker = {
        Save = function(idx, object)
            return {
                type         = "Colorpicker",
                idx          = idx,
                value        = object.Value:ToHex(),
                transparency = object.Transparency,
            }
        end,
        Load = function(idx, data)
            if SaveManager.Options[idx] then
                SaveManager.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
            end
        end,
    },

    Keybind = {
        Save = function(idx, object)
            return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
        end,
        Load = function(idx, data)
            if SaveManager.Options[idx] then
                SaveManager.Options[idx]:SetValue(data.key, data.mode)
            end
        end,
    },

    Input = {
        Save = function(idx, object)
            return { type = "Input", idx = idx, text = object.Value }
        end,
        Load = function(idx, data)
            if SaveManager.Options[idx] and type(data.text) == "string" then
                SaveManager.Options[idx]:SetValue(data.text)
            end
        end,
    },
}

-- ─────────────────────────────────────────────
--  Internal helpers
-- ─────────────────────────────────────────────

--- Sends a notification through the linked library (safe-call).
local function notify(title, content, sub, duration)
    if SaveManager.Library then
        SaveManager.Library:Notify({
            Title      = title,
            Content    = content,
            SubContent = sub,
            Duration   = duration or 7,
        })
    end
end

--- Returns the full path to a settings file.
local function configPath(name)
    return SaveManager.Folder .. "/settings/" .. name .. ".json"
end

-- ─────────────────────────────────────────────
--  Public API
-- ─────────────────────────────────────────────

--- Marks option indexes that should never be written to a config file.
function SaveManager:SetIgnoreIndexes(list)
    for _, key in next, list do
        self.Ignore[key] = true
    end
end

--- Changes the root folder and rebuilds the directory tree.
function SaveManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

--- Attaches a Fluent library instance (required before most operations).
function SaveManager:SetLibrary(library)
    self.Library = library
    self.Options = library.Options
end

--- Creates the necessary folders if they don't already exist.
function SaveManager:BuildFolderTree()
    local paths = {
        self.Folder,
        self.Folder .. "/settings",
    }

    for _, path in ipairs(paths) do
        if not isfolder(path) then
            makefolder(path)
        end
    end
end

--- Serialises all tracked options into a JSON config file.
function SaveManager:Save(name)
    if not name then
        return false, "no config file is selected"
    end

    local data = { objects = {} }

    for idx, option in next, self.Options do
        if self.Parser[option.Type] and not self.Ignore[idx] then
            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end
    end

    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then
        return false, "failed to encode data"
    end

    writefile(configPath(name), encoded)
    return true
end

--- Deserialises a JSON config file and applies each option's value.
function SaveManager:Load(name)
    if not name then
        return false, "no config file is selected"
    end

    local path = configPath(name)
    if not isfile(path) then
        return false, "invalid file"
    end

    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if not ok then
        return false, "decode error"
    end

    for _, option in next, decoded.objects do
        if self.Parser[option.type] then
            -- task.spawn prevents a bad option from blocking the rest of the load.
            task.spawn(function()
                self.Parser[option.type].Load(option.idx, option)
            end)
        end
    end

    return true
end

--- Convenience: ignores the standard theme-related keys.
function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({
        "InterfaceTheme",
        "AcrylicToggle",
        "TransparentToggle",
        "MenuKeybind",
    })
end

--- Returns a list of config names found in the settings folder.
function SaveManager:RefreshConfigList()
    local files = listfiles(self.Folder .. "/settings")
    local out   = {}

    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            -- Walk backwards to find the last path separator.
            local dotPos  = file:find(".json", 1, true)
            local pos     = dotPos - 1
            local char    = file:sub(pos, pos)

            while char ~= "/" and char ~= "\\" and char ~= "" do
                pos  = pos - 1
                char = file:sub(pos, pos)
            end

            if char == "/" or char == "\\" then
                local name = file:sub(pos + 1, dotPos - 1)
                if name ~= "options" then
                    table.insert(out, name)
                end
            end
        end
    end

    return out
end

--- If an autoload file exists, loads the named config automatically.
function SaveManager:LoadAutoloadConfig()
    local autoloadPath = self.Folder .. "/settings/autoload.txt"

    if not isfile(autoloadPath) then return end

    local name             = readfile(autoloadPath)
    local success, err     = self:Load(name)

    if not success then
        return notify("Interface", "Config loader", "Failed to load autoload config: " .. err)
    end

    notify("Interface", "Config loader", string.format("Auto loaded config %q", name))
end

--- Builds a full Configuration section inside the given tab.
function SaveManager:BuildConfigSection(tab)
    assert(self.Library, "Must set SaveManager.Library before calling BuildConfigSection")

    local section = tab:AddSection("Configuration")

    -- ── Input fields ──────────────────────────────────────────────
    section:AddInput("SaveManager_ConfigName", { Title = "Config name" })
    section:AddDropdown("SaveManager_ConfigList", {
        Title     = "Config list",
        Values    = self:RefreshConfigList(),
        AllowNull = true,
    })

    -- ── Create ────────────────────────────────────────────────────
    section:AddButton({
        Title    = "Create config",
        Callback = function()
            local name = SaveManager.Options.SaveManager_ConfigName.Value

            if name:gsub(" ", "") == "" then
                return notify("Interface", "Config loader", "Invalid config name (empty)")
            end

            local success, err = self:Save(name)
            if not success then
                return notify("Interface", "Config loader", "Failed to save config: " .. err)
            end

            notify("Interface", "Config loader", string.format("Created config %q", name))
            SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
        end,
    })

    -- ── Load ──────────────────────────────────────────────────────
    section:AddButton({
        Title    = "Load config",
        Callback = function()
            local name         = SaveManager.Options.SaveManager_ConfigList.Value
            local success, err = self:Load(name)

            if not success then
                return notify("Interface", "Config loader", "Failed to load config: " .. err)
            end

            notify("Interface", "Config loader", string.format("Loaded config %q", name))
        end,
    })

    -- ── Overwrite ─────────────────────────────────────────────────
    section:AddButton({
        Title    = "Overwrite config",
        Callback = function()
            local name         = SaveManager.Options.SaveManager_ConfigList.Value
            local success, err = self:Save(name)

            if not success then
                return notify("Interface", "Config loader", "Failed to overwrite config: " .. err)
            end

            notify("Interface", "Config loader", string.format("Overwrote config %q", name))
        end,
    })

    -- ── Refresh ───────────────────────────────────────────────────
    section:AddButton({
        Title    = "Refresh list",
        Callback = function()
            SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
        end,
    })

    -- ── Autoload ──────────────────────────────────────────────────
    local autoloadPath = self.Folder .. "/settings/autoload.txt"
    local initialDesc  = isfile(autoloadPath)
        and ("Current autoload config: " .. readfile(autoloadPath))
        or  "Current autoload config: none"

    local AutoloadButton
    AutoloadButton = section:AddButton({
        Title       = "Set as autoload",
        Description = initialDesc,
        Callback    = function()
            local name = SaveManager.Options.SaveManager_ConfigList.Value
            writefile(autoloadPath, name)
            AutoloadButton:SetDesc("Current autoload config: " .. name)
            notify("Interface", "Config loader", string.format("Set %q to auto load", name))
        end,
    })

    -- Exclude UI-only options from being saved.
    self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
end

-- ─────────────────────────────────────────────
--  Initialise
-- ─────────────────────────────────────────────

SaveManager:BuildFolderTree()

return SaveManager
