local SpoonInstall = hs.loadSpoon("SpoonInstall")

-- local spaces = require("hs.spaces")
local logger = require("hs.logger")

-- TODO: maybe alternative to the Lunette spoon: https://github.com/peterklijn/hammerspoon-shiftit
-- spoon.SpoonInstall.repos.lunette = {url = 'https://github.com/f0rki/Lunette', branch = 'newresize'}
-- window management
-- SpoonInstall:andUse("Lunette", {repo="lunette"})
hs.loadSpoon("Lunette")
window_modkey = { "ctrl", "cmd" }
window_modmodkey = { "ctrl", "cmd", "shift" }
customBindings = {
    center = false,
    leftHalf = {
        { window_modkey, "h" },
    },
    rightHalf = {
        { window_modkey, "l" },
    },
    topHalf = {
        { window_modkey, "j" },
    },
    bottomHalf = {
        { window_modkey, "k" },
    },
    fullScreen = {
        { window_modkey, "m" },
    },
    enlarge = false,
    shrink = false,
    undo = false,
    redo = false,
    resizeLeft = {
        { { "cmd", "alt" }, "h" },
    },
    resizeRight = {
        { { "cmd", "alt" }, "l" },
    },
    resizeUp = {
        { { "cmd", "alt" }, "k" },
    },
    resizeDown = {
        { { "cmd", "alt" }, "j" },
    },
}
spoon.Lunette:bindHotkeys(customBindings)

-- set up your windowfilter
-- switcher = hs.window.switcher.new() -- default windowfilter: only visible windows, all Spaces
switcher = hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter({}))
hs.hotkey.bind("alt", "tab", function()
    switcher:next()
end)
hs.hotkey.bind("alt-shift", "tab", function()
    switcher:previous()
end)

-- move/resize windows by just clicking them with a modifier
local SkyRocket = hs.loadSpoon("SkyRocket")
-- spoon.SpoonInstall.repos.skyrocket = {url = 'https://github.com/dbalatero/SkyRocket.spoon', branch = 'master'}
-- SpoonInstall:andUse("SkyRocket", {repo="skyrocket"})
sky = spoon.SkyRocket:new({
    opacity = 0.3,
    moveModifiers = { "alt" },
    moveMouseButton = "left",
    resizeModifiers = { "alt" },
    resizeMouseButton = "right",
})

-- TODO: check out https://github.com/mogenson/PaperWM.spoon?tab=readme-ov-file#install-with-spooninstall
--
-- doesn't work too well for me...
--
--[[
spoon.SpoonInstall.repos.PaperWM = {
    url = "https://github.com/mogenson/PaperWM.spoon",
    desc = "PaperWM.spoon repository",
    branch = "release",
}
spoon.SpoonInstall:andUse("PaperWM", {
    repo = "PaperWM",
    config = {
        screen_margin = 3,
        window_gap = {
            top = 0,
            bottom = 0,
            left = 1,
            right = 1,
        },
        -- number of fingers to detect a horizontal swipe, set to 0 to disable (the default)
        swipe_fingers = 0,
        swipe_gain = 2.0, -- swipe speed

        rejectApp = { "IINA" },
    },
    start = true,
    hotkeys = {
        focus_left = { { "alt" }, "h" },
        focus_up = { { "alt" }, "j" },
        focus_down = { { "alt" }, "k" },
        focus_right = { { "alt" }, "l" },

        swap_column_left = { { "alt", "shift" }, "h" },
        -- swap_left = { { "alt", "shift" }, "h" },
        swap_up = { { "alt", "shift" }, "k" },
        swap_down = { { "alt", "shift" }, "j" },
        -- swap_right = { { "alt", "shift" }, "l" },
        swap_column_right = { { "alt", "shift" }, "l" },

        -- focus_next = { { "alt" }, "tab" },
        -- focus_prev = { { "alt", "shift" }, "tab" },

        increase_width = { { "ctrl", "cmd" }, "l" },
        decrease_width = { { "ctrl", "cmd" }, "h" },

        slurp_in = { { "alt", "cmd" }, "i" },
        barf_out = { { "alt", "cmd" }, "o" },

        center_window = { { "alt", "cmd" }, "c" },
        full_width = { { "alt", "cmd" }, "m" },
        cycle_width = { { "alt", "cmd" }, "r" },
        toggle_floating = { { "alt" }, "f" },

        switch_space_l = { { "cmd" }, "," },
        switch_space_r = { { "cmd" }, "." },
        switch_space_1 = { { "cmd" }, "1" },
        switch_space_2 = { { "cmd" }, "2" },
        switch_space_3 = { { "cmd" }, "3" },
        switch_space_4 = { { "cmd" }, "4" },
        switch_space_5 = { { "cmd" }, "5" },
        switch_space_6 = { { "cmd" }, "6" },
        switch_space_7 = { { "cmd" }, "7" },
        switch_space_8 = { { "cmd" }, "8" },
        switch_space_9 = { { "cmd" }, "9" },

        -- move focused window to a new space and tile
        move_window_1 = { { "cmd", "shift" }, "1" },
        move_window_2 = { { "cmd", "shift" }, "2" },
        move_window_3 = { { "cmd", "shift" }, "3" },
        move_window_4 = { { "cmd", "shift" }, "4" },
        move_window_5 = { { "cmd", "shift" }, "5" },
        move_window_6 = { { "cmd", "shift" }, "6" },
        move_window_7 = { { "cmd", "shift" }, "7" },
        move_window_8 = { { "cmd", "shift" }, "8" },
        move_window_9 = { { "cmd", "shift" }, "9" },
    },
})

-- PaperWM extras
WarpMouse = hs.loadSpoon("WarpMouse")
WarpMouse:start()
ActiveSpace = hs.loadSpoon("ActiveSpace")
ActiveSpace:start()
]]

-- this is also set by lunette afaik
hs.window.animationDuration = 0


-- hotkeys

hs.hotkey.bind("alt", "q", function()
    local focused = hs.window.frontmostWindow()
    local focused_screen = focused:screen()
    focused:close()
    local newly_focused = hs.window.frontmostWindow()
    if newly_focused:screen() == focused_screen then
        newly_focused:focus()
    end
end)

function busyloop(count)
    local i = 0
    for j = 0, count do
        i = i + j
    end
    return i
end

-- app launching
-- alacritty = "/opt/homebrew/alacritty"
hs.hotkey.bind("alt", "F1", function()
    -- check if alacritty is running
    if hs.application.get("alacritty") == nil then
        hs.application.launchOrFocus("alacritty")
    else
        -- if alacritty is running use the internal mechanism to create a new window
        hs.execute("/opt/homebrew/bin/alacritty msg create-window")
        busyloop(1000)
        hs.application.launchOrFocus("alacritty")
    end
end)
hs.hotkey.bind("alt", "F2", function()
    if hs.application.get("Firefox") == nil then
        hs.application.launchOrFocus("Firefox")
    else
        hs.execute("/Applications/Firefox.app/Contents/MacOS/firefox --new-window")
        hs.application.launchOrFocus("Firefox")
    end
end)

hs.hotkey.bind("alt", "w", hs.spaces.toggleMissionControl)

-- TODO: modal hotkeys? https://www.hammerspoon.org/docs/hs.hotkey.modal.html

function caffeinate_if_docked_at_home()
    local am_i_docked = false -- find out if docked at home office
    if hs.battery.powerSource() == "AC Power" then
        local external_screen = "C34H89x"
        for i, screen in ipairs(hs.screen.allScreens()) do
            if screen:name() == external_screen then
                am_i_docked = true
                hs.logger.i("detected docked")
            end
        end
    end

    if am_i_docked then
        -- prevent sleep on systemIdle if docked at home office
        hs.caffeinate.set("systemIdle", true, false)

        -- disconnect from wifi if we are docked and have ethernet available
        if hs.wifi.currentNetwork() == "Kaspresknoedl-5" or hs.wifi.currentNetwork() == "Kaspresknoedl-5" then
            hs.logger.i("disassociated from network", hs.wifi.currentNetwork())
            hs.wifi.disassociate()
        end
    else
        -- else allow it
        hs.caffeinate.set("systemIdle", false, false)

        -- https://github.com/Hammerspoon/hammerspoon/issues/1214
        -- bit of a hack with applescript...
        hs.osascript.applescript([[
tell application "System Events"
    tell process "SystemUIServer"
        click (menu bar item 1 of menu bar 1 whose description contains "Wi-Fi")
        click menu item "Kaspresknoedl-5" of menu 1 of result
    end tell
end tell]])
            
        hs.logger.i("associated with network", hs.wifi.currentNetwork())
    end
end

caffeinate_if_docked_at_home()
local docked_watcher = hs.battery.watcher.new(caffeinate_if_docked_at_home)
docked_watcher:start()

-- spotify controls
hs.eventtap
    .new({ hs.eventtap.event.types.systemDefined }, function(event)
        local type = event:getType()
        if type == hs.eventtap.event.types.systemDefined then
            local t = event:systemKey()
            if t.down then
                -- print("System key: " .. t.key)
                if hs.application.get("Spotify") ~= nil then
                    if t.key == "PLAY" then
                        hs.spotify.playpause()
                    elseif t.key == "NEXT" then
                        hs.spotify.next()
                    elseif t.key == "PREVIOUS" then
                        hs.spotify.previous()
                    end
                end
            end
        end
    end)
    :start()
