local SpoonInstall = hs.loadSpoon("SpoonInstall")

require("hs.spaces")
require("hs.logger")
require("hs.window.filter")
require("hs.menubar")

local logger = hs.logger.new("myconfig", "debug")

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

hs.window.animationDuration = 0

-- hotkeys

--[[
hs.hotkey.bind("alt", "q", function()
    local focused = hs.window.frontmostWindow()
    local focused_screen = focused:screen()
    focused:close()
    local newly_focused = hs.window.frontmostWindow()
    if newly_focused:screen() == focused_screen then
        newly_focused:focus()
    end
end)
]]

function busyloop(count)
	local i = 0
	for j = 0, count do
		i = i + j
	end
	return i
end

-- app launching
-- alacritty = "/opt/homebrew/alacritty"
-- hs.hotkey.bind("alt", "F1", function()
-- 	-- check if alacritty is running
-- 	if hs.application.get("alacritty") == nil then
-- 		hs.application.launchOrFocus("alacritty")
-- 	else
-- 		-- if alacritty is running use the internal mechanism to create a new window
-- 		hs.execute("/opt/homebrew/bin/alacritty msg create-window")
-- 		-- busyloop(1000)
-- 		-- hs.application.launchOrFocus("alacritty")
-- 	end
-- end)
-- hs.hotkey.bind("alt", "F2", function()
-- 	if hs.application.get("Firefox") == nil then
-- 		hs.application.launchOrFocus("Firefox")
-- 	else
-- 		hs.execute("/Applications/Firefox.app/Contents/MacOS/firefox --new-window")
-- 		-- busyloop(1000)
-- 		-- hs.application.launchOrFocus("Firefox")
-- 	end
-- end)

-- caffeination

-- menubar to toggle caffeination
caffeinate_bar = hs.menubar.new(true, "caffeinate_bar")
coffee_icon = hs.image.imageFromPath("~/.hammerspoon/coffee.svg"):setSize({ w = 16, h = 16 })
sleep_icon = hs.image.imageFromPath("~/.hammerspoon/sleep.svg"):setSize({ w = 16, h = 16 })
caffeinate_enabled = hs.caffeinate.get("systemIdle")
if caffeinate_enabled == nil then
	logger:e("caffeinate API returned nil!")
	-- we need a bool; so we set to false
	caffeinate_enabled = false
end
if caffeinate_enabled then
	caffeinate_bar:setIcon(coffee_icon)
else
	caffeinate_bar:setIcon(sleep_icon)
end

function set_caffeinate_to(val)
	caffeinate_enabled = val
	hs.caffeinate.set("systemIdle", caffeinate_enabled, false)
	logger:i("caffeinate_enabled:", caffeinate_enabled)
	if caffeinate_enabled then
		caffeinate_bar:setIcon(coffee_icon)
	else
		caffeinate_bar:setIcon(sleep_icon)
	end
end

function toggle_caffeinate()
	set_caffeinate_to(not caffeinate_enabled)
end

caffeinate_bar:setClickCallback(
	function(kbdmodifies) -- If a menu has been attached to the menubar item, this callback will never be called
		toggle_caffeinate()
	end
)

function caffeinate_if_docked_at_home()
	local am_i_docked = false -- find out if docked at home office
	if hs.battery.powerSource() == "AC Power" then
		local external_screen = "C34H89x"
		for i, screen in ipairs(hs.screen.allScreens()) do
			if screen:name() == external_screen then
				am_i_docked = true
			end
		end

		-- TODO: check if docked at office?
	end

	if am_i_docked then
		logger:i("detected docked")

		-- prevent sleep on systemIdle if docked at home office
		-- hs.caffeinate.set("systemIdle", true, false)
		set_caffeinate_to(true)

		-- disconnect from wifi if we are docked and have ethernet available
		if hs.wifi.currentNetwork() == "Kaspresknoedl-5" or hs.wifi.currentNetwork() == "Kaspresknoedl-5" then
			logger:i("disassociated from network", hs.wifi.currentNetwork())
			hs.wifi.disassociate()
		end
	else
		-- else allow it
		-- hs.caffeinate.set("systemIdle", false, false)
		set_caffeinate_to(false)

		-- https://github.com/Hammerspoon/hammerspoon/issues/1214
		-- bit of a hack with applescript...
		hs.osascript.applescript([[
tell application "System Events"
    tell process "SystemUIServer"
        click (menu bar item 1 of menu bar 1 whose description contains "Wi-Fi")
        click menu item "Kaspresknoedl-5" of menu 1 of result
    end tell
end tell]])

		logger:i("associated with network", hs.wifi.currentNetwork())
	end
end

caffeinate_if_docked_at_home()
local docked_watcher = hs.battery.watcher.new(caffeinate_if_docked_at_home)
docked_watcher:start()

local caffeinate_watcher = hs.caffeinate.watcher.new(function(event)
	if event == hs.caffeinate.watcher.systemDidWake then
		caffeinate_if_docked_at_home()
	end
end)
caffeinate_watcher:start()

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

require("aeromenu")
