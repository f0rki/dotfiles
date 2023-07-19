local SpoonInstall = hs.loadSpoon("SpoonInstall")

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


hs.hotkey.bind("alt", "q", function()
    local focused = hs.window.frontmostWindow();
    local focused_screen = focused:screen();
    focused:close();
    local newly_focused = hs.window.frontmostWindow();
    if newly_focused:screen() == focused_screen then
        newly_focused:focus();
    end
end)


function busyloop(count)
    local i = 0
    for j=0,count do
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

function caffeinate_if_docked_at_home() 
    local am_i_docked = false -- find out if docked at home office
    if hs.battery.powerSource() == "AC Power" then
        local external_screen = "C34H89x"
        for i,screen in ipairs(hs.screen.allScreens()) do
            if screen:name() == external_screen then
                am_i_docked = true
            end
        end
    end

    if am_i_docked then
        -- prevent sleep on systemIdle if docked at home office
        hs.caffeinate.set("systemIdle", true, false)

        -- disconnect from wifi if we are docked and have ethernet available
        if hs.wifi.currentNetwork() == "Kaspresknoedl-5" or hs.wifi.currentNetwork() == "Kaspresknoedl-5" then
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

    end
end

caffeinate_if_docked_at_home()
local docked_watcher = hs.battery.watcher.new(caffeinate_if_docked_at_home)
docked_watcher:start()
