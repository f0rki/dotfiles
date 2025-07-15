local logger = hs.logger.new("aeromenu", "debug")

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
    "app-name" : "Firefox",
    "window-id" : 2509,
    "window-title" : "Multi-Agentic system Threat Modeling Guide v1.0 - OWASP Gen AI Security Project"
  },
  {
    "app-name" : "Firefox",
    "window-id" : 102,
    "window-title" : "Projektzeiten - ZEP - ZeitErfassung für Projekte - Cologne Intelligence GmbH (CI)"
  },
  {
    "app-name" : "Logseq",
    "window-id" : 60,
    "window-title" : "Threat Modelling"
  },
  {
    "app-name" : "Microsoft Outlook",
    "window-id" : 160,
    "window-title" : "Calendar"
  },
  {
    "app-name" : "Microsoft Teams",
    "window-id" : 107,
    "window-title" : "Chat | CI Corporate News | Cologne Intelligence | mrodler@cologne-intelligence.de | Microsoft Teams"
  }
]
michaelrodle
]]

-- aembar:setTitle("")

local aerospace_bin_path = "/etc/profiles/per-user/michaelrodler/bin/aerospace"
local aerospace_bin = hs.fs.pathToAbsolute(aerospace_bin_path)

logger:d("using aerospace binary at", aerospace_bin)

function aerospace_cmd(cmd)
	local result = hs.execute(string.format("%s %s --json", aerospace_bin, cmd))
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

-- this is slow af for some reason
function get_aero_info()
	local ainfo = {}
	-- get list of monitors
	local monitors = aerospace_cmd("list-monitors")
	if monitors then
		-- loop over each monitor
		for _, monitor in ipairs(monitors) do
			-- get list of workspace per monitor
			local workspaces_command = string.format("list-workspaces --monitor %s", monitor["monitor-id"])
			local workspaces = {}
			local workspaces_res = aerospace_cmd(workspaces_command)
			if workspaces_res then
				for _, workspace in ipairs(workspaces_res) do
					-- get list of windows per workspace
					local window_command = string.format("list-windows --workspace %s", workspace.workspace)
					local window_res = aerospace_cmd(window_command)
					workspaces[tonumber(workspace.workspace)] = window_res
				end
			end
			ainfo[monitor["monitor-id"]] = {
				name = monitor["monitor-name"],
				workspaces = workspaces,
			}
		end
		-- return a table that represents the hierarchy monitor -> workspaces -> windows
		return ainfo
	end
end

aembar_menu_table = {}

function update_aembar(aembar, ainfo)
	-- local ainfo = get_aero_info()

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
						aerospace_task({ "focus", "--window-id", tostring(window_info["window-id"]) }, function() end, true)
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
end

ainfo = {}

function update_aembar_async(aembar)
	-- local tasks = {}
	local t = aerospace_task({ "list-monitors" }, function(_exitCode, result, _stdErr)
		local monitors = hs.json.decode(result)
		if monitors then
			-- loop over each monitor
			for _, monitor in ipairs(monitors) do
				-- logger:d("got monitor", hs.inspect(table.pack(monitor)))
				local mnum = tonumber(monitor["monitor-id"])
				ainfo[mnum] = { name = monitor["monitor-name"], workspaces = {} }
				local args = { "list-workspaces", "--monitor", tostring(monitor["monitor-id"]) }
				aerospace_task(args, function(_exitCode, result, _stdErr)
					local workspaces = hs.json.decode(result)
					if workspaces then
						ainfo[mnum].workspaces = {}
						for _, workspace_data in ipairs(workspaces) do
							local workspace_name = tonumber(workspace_data.workspace)
							ainfo[mnum].workspaces[workspace_name] = {}
							local args = { "list-windows", "--workspace", tostring(workspace_name) }
							aerospace_task(args, function(_exitCode, result, _stdErr)
								local windows = hs.json.decode(result)
								-- logger:d("got windows for workspace", workspace_name, hs.inspect(table.pack(windows)))
								if windows then
									ainfo[mnum].workspaces[workspace_name] = windows
								else
									logger:e("aerospace list-windows - failed")
								end
							end)
						end
					else
						logger:e("aerospace list-workspaces - failed")
					end
				end)
			end
		else
			logger:e("aerospace list-monitors - failed json decode")
		end
	end)
end

logger:i("hello from aeromenu")
update_aembar_async(aembar)
update_aembar(aembar, ainfo)
aembar = hs.menubar.new(true, "hs_aero")
aembar:setTitle("aero")
-- aembar:setIcon("~/.hammerpsoon/aerospace-icon.png")
-- aembar:setClickCallback(function(kbdmodifies) -- If a menu has been attached to the menubar item, this callback will never be called
-- 	update_aembar_async(aembar)
-- end)
aembar:setMenu(function()
    update_aembar_async(aembar)
    busyloop(1000)
	update_aembar(aembar, ainfo)
    return aembar_menu_table
end)
