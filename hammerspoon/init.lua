hs.loadSpoon("SpoonInstall")

-- window management
-- SpoonInstall:andUse("Lunette")
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
-- local SkyRocket = SpoonInstall:andUse("SkyRocket")
sky = SkyRocket:new({
	opacity = 0.3,
	moveModifiers = { "alt" },
	moveMouseButton = "left",
	resizeModifiers = { "alt" },
	resizeMouseButton = "right",
})

-- app launching
-- alacritty = "/opt/homebrew/alacritty"
hs.hotkey.bind("alt", "F1", function()
	if hs.application.get("alacritty") == nil then
		hs.application.launchOrFocus("alacritty")
	else
		hs.execute("/opt/homebrew/bin/alacritty msg create-window")
	end
end)
hs.hotkey.bind("alt", "F2", function()
	if hs.application.get("Firefox") == nil then
		hs.application.launchOrFocus("Firefox")
	else
		hs.execute("/Applications/Firefox.app/Contents/MacOS/firefox --new-window")
	end
end)
