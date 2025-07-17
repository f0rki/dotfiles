local logger = hs.logger.new("aeromenu", "info")

-- useful hammerpsoon APIs
--
-- hs.json.decode("<json string>") -> table
-- hs.execute("/etc/profiles/per-user/michaelrodler/bin/aerospace <command>")
-- hs.task.new(
-- aerospace commands:
-- * list-monitors --json -> { "monitor-id: <N>, "monitor-name": "<name>, }
-- * list-workspaces --json --monitor <N> -> [ { "workspace" : "<W>" }, ... ]
-- * list-windows --all --json
-- * list-windows --workspace <W> --json --> [ { "app-name": "<name>", "window-id": <X>, "window-title": "<title>" }, ... ]
--[[
> aerospace list-monitors --json
[
  {
    "monitor-id" : 1,
    "monitor-name" : "Built-in Retina Display"
  },
  {
    "monitor-id" : 2,
    "monitor-name" : "C34H89x"
  }
]

> aerospace list-workspaces --json --monitor 1
[
  {
    "workspace" : "0"
  },
  {
    "workspace" : "1"
  },
  {
    "workspace" : "2"
  },
  {
    "workspace" : "3"
  },
  {
    "workspace" : "4"
  },
  {
    "workspace" : "5"
  },
  {
    "workspace" : "6"
  },
  {
    "workspace" : "7"
  },
  {
    "workspace" : "8"
  },
  {
    "workspace" : "9"
  }
]

> aerospace list-windows --workspace 0 --json
[
  {
    "app-name" : "Logseq",
    "window-id" : 60,
    "window-title" : "Whatever"
  },
  {
    "app-name" : "Microsoft Outlook",
    "window-id" : 160,
    "window-title" : "Calendar"
  },
]


> aerospace list-windows --focused --json --format "%{app-name} %{window-title} %{window-id} %{app-pid} %{workspace} %{app-bundle-id} %{monitor-name} %{monitor-id}"
[
  {
    "app-bundle-id" : "com.1password.1password",
    "app-name" : "1Password",
    "app-pid" : 88789,
    "monitor-id" : 1,
    "monitor-name" : "Built-in Retina Display",
    "window-id" : 10535,
    "window-title" : "xxx 1Password",
    "workspace" : "9"
  },

  ....

  ]

]]

-- aembar:setTitle("")

local aerospace_bin_path = "/etc/profiles/per-user/michaelrodler/bin/aerospace"
local aerospace_bin = hs.fs.pathToAbsolute(aerospace_bin_path)

logger:d("using aerospace binary at", aerospace_bin)

function aerospace_cmd(cmd)
	local result = hs.execute(string.format("%s %s", aerospace_bin, cmd))
	-- logger:d("result is: " .. result)
	if result then
		return hs.json.decode(result)
	else
		return nil
	end
end

function aerospace_task(args, callback_fn, nojson)
	if not nojson then
		table.insert(args, "--json")
	end
	-- logger:d("starting aerospace task with args:", aerospace_bin, table.concat(args, " "))
	local task = hs.task.new(aerospace_bin, callback_fn, args)
	if not task then
		logger:e("failed to create task")
	end
	local started = task:start()
	if not started then
		logger:e("failed to start task")
	end
	return started
end

-- globals :S
aembar_menu_table = {}
ainfo = {}


-- this is slow af for some reason
function get_aero_info()
	local ainfo = {}
	-- get list of monitors
	local data = aerospace_cmd(
		'list-windows --all --json --format "%{app-name} %{window-title} %{window-id} %{app-pid} %{workspace} %{app-bundle-id} %{monitor-name} %{monitor-id}"'
	)
	if not data then
		return nil
	end
	for _, window in ipairs(data) do
		local monitor_id = window["monitor-id"]
		if ainfo[monitor_id] then
			local workspace_id = tonumber(window["workspace"])
			if ainfo[monitor_id].workspaces[workspace_id] then
				table.insert(ainfo[monitor_id].workspaces[workspace_id], window)
			else
				ainfo[monitor_id].workspaces[workspace_id] = {
					[1] = window,
				}
			end
		else
			ainfo[monitor_id] = {
				name = window["monitor-name"],
				workspaces = {},
			}
		end
	end

	-- return a table that represents the hierarchy monitor -> workspaces -> windows
	return ainfo
end

function get_ainfo_async()
	-- local tasks = {}
	local t = aerospace_task(
		{
			"list-windows",
			"--all",
			"--json",
			"--format",
			"%{app-name} %{window-title} %{window-id} %{app-pid} %{workspace} %{app-bundle-id} %{monitor-name} %{monitor-id}",
		},
		function(_exitCode, result, _stdErr)
			local data = hs.json.decode(result)
			if not data then
				logger:e("failed to json decode aerospace result:", data)
				return nil
			end
			ainfo = {}
			-- get list of monitors
			if not data then
				return nil
			end
			for _, window in ipairs(data) do
				local monitor_id = window["monitor-id"]
				if ainfo[monitor_id] then
					local workspace_id = tonumber(window["workspace"])
					if ainfo[monitor_id].workspaces[workspace_id] then
						table.insert(ainfo[monitor_id].workspaces[workspace_id], window)
					else
						ainfo[monitor_id].workspaces[workspace_id] = {
							[1] = window,
						}
					end
				else
					ainfo[monitor_id] = {
						name = window["monitor-name"],
						workspaces = {},
					}
				end
			end
		end,
		true
	)
    return t
end

function update_aembar(aembar, ainfo)
	local menu_table = {}

	-- Iterate over monitors and their workspaces
	for monitor_id, data in ipairs(ainfo) do
		-- TODO: use hs.styledtext to set to bold
		table.insert(menu_table, {
			title = hs.styledtext.new(string.format("%s - %s", monitor_id, data.name), {
				color = { red = 1 },
			}),
		})

		for workspace_name, workspace_data in pairs(data.workspaces) do
			-- TODO: use hs.styledtext to set to cursive
			local workspace_title = string.format("workspace %s", workspace_name)
			table.insert(menu_table, {
				title = hs.styledtext.new(workspace_title, {
					color = { blue = 1 },
				}),
			})

			for _, window_info in ipairs(workspace_data) do
				local window_title = window_info["window-title"]
				if #window_title > 32 then
					window_title = string.sub(window_title, 1, 32)
				end
				local sub_menu_title = string.format("%s - %s", window_info["app-name"], window_title)
				table.insert(menu_table, {
					title = sub_menu_title,
					fn = function(modifies, item)
						aerospace_task(
							{ "focus", "--window-id", tostring(window_info["window-id"]) },
							function() end,
							true
						)
					end,
				})
			end
		end

		-- for next monitor
		if #ainfo > 1 then
			table.insert(menu_table, { title = "-" })
		end
	end

	-- logger:d("aembar update - ainfo = ", hs.inspect(table.pack(ainfo)))
	-- logger:d("aembar update - menu = ", hs.inspect(table.pack(menu_table)))

	-- logger:d("aembar update")

	-- Set the menu using aemo_bar:setMenu
	-- aembar:setMenu(menu_table)
	aembar_menu_table = menu_table
	return menu_table
end




logger:i("hello from aeromenu")
-- update_aembar_async(aembar)
get_ainfo_async()
aembar = hs.menubar.new(true, "hs_aero")
aembar:setTitle("aero")
-- aembar:setIcon("~/.hammerpsoon/aerospace-icon.png")
-- aembar:setClickCallback(function(kbdmodifies) -- If a menu has been attached to the menubar item, this callback will never be called
-- 	update_aembar_async(aembar)
-- end)
aembar:setMenu(function()
    local t = get_ainfo_async()
    -- t:waitUntilExit() -- this is too slow...
    busyloop(10000)
	return update_aembar(aembar, ainfo)
end)

ainfo_timer = hs.timer.new(60, function() 
    get_ainfo_async()
end)
ainfo_timer:start()
