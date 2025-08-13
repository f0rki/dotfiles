
--[[
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
]]

--[[
SpoonInstall:andUse("WindowHalfsAndThirds"):bindHotkeys({
    left_half = {window_modkey}, "h",
    bottom_half = {window_modkey}, "j",
    top_half = {window_modkey}, "k",
    right_half = {window_modkey}, "l",
})
]]

-- TODO: do I really need Lunette for this? something better?
-- https://github.com/TobiasBales/dotfiles/blob/b8083b7f05c8fe6ef01674f16c518f7f60e59ef1/hammerspoon/init.lua#L60
-- https://github.com/marromlam/dotfiles/blob/f8d04272d0732e6dd5bf754872c6d59800bfcdc1/files/.hammerspoon/init.lua#L191
-- https://medium.com/@jhkuperus/window-management-with-hammerspoon-personal-productivity-c77adc436888
-- https://github.com/jhkuperus/dotfiles/blob/master/hammerspoon/window-management.lua
-- https://gist.githubusercontent.com/deepdmistry/becc7d4c9dae03c4fd3b5a948a056cf3/raw/b75f6035996bb05cd225e4b25dcb51729e1409ab/init.lua

--[[
-- set up your windowfilter
-- switcher = hs.window.switcher.new() -- default windowfilter: only visible windows, all Spaces
switcher = hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter({}))
hs.hotkey.bind("alt", "tab", function()
    switcher:next()
end)
hs.hotkey.bind("alt-shift", "tab", function()
    switcher:previous()
end)

local visibleCurrentSpace = hs.window.filter.new():setOverrideFilter({
    visible = true,
    currentSpace = true,
})

-- switch between visible and unoccluded windows
hs.hotkey.bind("alt", "h", function()
    visibleCurrentSpace:focusWindowWest(nil, true, true)
end)
hs.hotkey.bind("alt", "j", function()
    visibleCurrentSpace:focusWindowSouth(nil, true, true)
end)
hs.hotkey.bind("alt", "k", function()
    visibleCurrentSpace:focusWindowNorth(nil, true, true)
end)
hs.hotkey.bind("alt", "l", function()
    visibleCurrentSpace:focusWindowEast(nil, true, true)
end)
]]


-- SpoonInstall:andUse("MouseFollowsFocus"):start()

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
