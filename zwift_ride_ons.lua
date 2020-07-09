--------------------------------------------------------------------------------------------
-- 0.01 Matt Page 18/05/2020 - first version.
-- 0.02 Matt Page 20/05/2020 - Added output for Ride on count.
-- 0.03 Matt Page 21/05/2020 - Changed log file directory parameter to Path selector.
-- 0.04 Matt Page 22/05/2020 - Added check if log file doesn't exist or can't be opened.
-- 0.05 Matt Page 24/05/2020 - Added output for total  ride ons given.
-- 0.06 Matt Page 25/05/2020 - Added reset() called when a new log file is detected.
-- 0.07 Matt Page 26/05/2020 - Added reset button to ui and changed reset behaviour to reset every time source is activated.
-- 0.08 Matt Page 26/05/2020 - ensure ride ons given update when none are received..
-- 0.09 Matt Page 27/05/2020 - tidy up directory references
-- 0.10 Matt Page 29/05/2020 - Added option to display list n of most recent ride ons.
-- 0.11 Matt Page 30/05/2020 - Fixed issue where most recent ride on name was repeated until limit reached
-- 0.12 Matt Page 08/06/2020 - Added Lap Counter with option display current or completed lap, tidied up source list in props
-- 0.13 Matt Page 09/06/2020 - Added Current Route name, changed naming convention of sources for consistency
-- 0.14 Matt Page 09/06/2020 - Added Route Length (km), leadin(km) and Ascent(m) - these are written to the 'route stats' source
-- 0.15 Matt Page 10/06/2020 - Added Rounding to Route Length and Leadin values to limit to 2 dp
-- 0.16 Matt Page 15/06/2020 - Added reset for lap counter when current route changes
-- 0.17 Matt Page 15/06/2020 - Changed activation logic - added an enalbed flag in script settings - no longer controlled by activating /deactivating a source
-- 0.18 Matt Page 15/06/2020 - Changed types for timing of file check and displkay time for ride on names - support down to 100ms
-- 0.19 Matt Page 02/07/2020 - Added parsing for Chat messages with option to filter by user Zwift ID.
-- 0.20 Matt Page 02/07/2020 - Added parsing for Timining Arch lines in log file, outputs name, time and avg power. Name not always populated.
-- 0.21 Matt Page 05/07/2020 - Fixed issue where ride ons and route would not reset on loading script.
-- 0.22 Matt Page 06/07/2020 - Restructured function that writes output to text sources to make more compact
-- 0.23 Matt Page 06/07/2020 - Made text displayed after the name of user giving ride on user definable - will deafuly to ' says Ride On!'
-- 0.24 Matt Page 06/07/2020 - Changed Lap counter logic, now ignores the log files lap count figure as this lags behind the game. 
-- 0.25 Matt Page 06/07/2020 - Added mitigation for strings not found where changing character position causes arithmetic issues. 
-- 0.26 Matt Page 07/07/2020 - Added option to include or exclude chat types (world, Paddock and GroupEvent)
-- 0.27 Matt Page 08/07/2020 - Added formatting to arch timing and changed output string to be more concise. 
-- 0.28 Matt Page 08/07/2020 - Added parsing for group event name and name of subgroup
-- 0.29 Matt Page 09/07/2020 - Added mitigation for when obs_source_get_unversioned_id returns a nil

-- Add script to OBS studio - parses the Zwift log file recording received ride ons.
-- log file directory and other parameters can be updated via OBS studio UI
-- Can't seem to get a path to populate the UI by default, the script will assumes a default directory if one has not set in UI
-- On Windows 10, this will be something like C:\Users\UserName\Documents\Zwift\Logs\Log.txt
-- Parsing the log file starts when any mapped source is activated and stops when one is deactivated
-- Reset button also disables reading the log file.
--------------------------------------------------------------------------------------------

obs = obslua
enabled = false
active = false
last_end_pos = 0
log_directory = ""
log_default = os.getenv("HOMEDRIVE") .. os.getenv("HOMEPATH").."\\Documents\\Zwift\\Logs\\Log.txt"
end_of_file = 0
file_check_sleep_time = 5
release_ride_on_interval = 1
ride_on_names_source_name   = ""
ride_on_count_source_name = ""
ride_on_count = 0
ride_ons = {}
total_ride_ons_given_source_name =""
total_ride_ons_given = 0
last_index = 0
last_ride_on = ""
number_of_names = 1
names_list = {}
list_size = 0
last_name = ""
lap_count = 0
display_current_lap = false
lap_count_source_name = ""
current_route = ""
current_route_source_name = ""
route_stats = ""
route_length = 0
route_leadin = 0
route_ascent = 0
route_stats_source_name = ""
chat_user_ids = ""
chat_text = ""
chat_text_source_name = ""
chat_count = 0
segment_comp = ""
segment_comp_source_name = ""
ride_on_name_suffix = " says Ride On!"
include_world_chat = true
include_paddock_chat = true
include_group_event_chat = true
chat_types = {}
group_event_source_name = ""
group_event_name = ""
sub_group_source_name = ""
sub_group_name = ""
--------------------------------------------------------------------------------------------

-- Set the ride On giver name text, update the ride on count and total Ride Ons given
function set_ride_on_text(tt)
    source_values = { [ride_on_names_source_name] = tt,
        [current_route_source_name] = current_route, 
        [route_stats_source_name] = route_stats, 
        [ride_on_count_source_name] = ride_on_count,
        [total_ride_ons_given_source_name] = total_ride_ons_given,
        [lap_count_source_name] = lap_count,
        [chat_text_source_name] = chat_text,
        [segment_comp_source_name] = segment_comp,
        [group_event_source_name] = group_event_name,
        [sub_group_source_name] = sub_group_name
    }

    for sn, sv in pairs (source_values) do 
        local source = obs.obs_get_source_by_name(sn)
	    if source ~= nil then
            if sn == ride_on_names_source_name then 
                local latest_ride_on = sv
                if latest_ride_on ~= last_ride_on or latest_ride_on == "" then
                    local settings = obs.obs_data_create()
		            obs.obs_data_set_string(settings, "text", sv)
		            obs.obs_source_update(source, settings)
		            obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                	last_ride_on = latest_ride_on
                end
            else
                local settings = obs.obs_data_create()
    		    obs.obs_data_set_string(settings, "text", sv)
    		    obs.obs_source_update(source, settings)
    		    obs.obs_data_release(settings)
             obs.obs_source_release(source)
            end
        end
    end
end


-- Called by the activation of the source and checks the end character position has changed in the log file,
-- also checks if last recorded end position was larger than the latest, indicating a new file
function file_check_callback()
	local f = io.open(log_directory, "r")

	if f ~= nil then
		end_of_file = f:seek("end")
		io.close(f)
		if last_end_pos == end_of_file then
			return
		elseif last_end_pos > end_of_file then
			last_end_pos = 0
			reset(true)
			get_ride_ons()
		else
			get_ride_ons()
		end
	else
		print("Log file does not exist or cannot be opened. log file Directory: " .. log_directory)
	end
end

-- Called by activation of source and triggers the update to the text source for ride on name and count
function release_ride_on_callback()
	release_ride_on()
end


function activate(activating)
	if activating then
		last_end_pos = 0
		last_index = 0
		ride_ons = {}
		ride_on_count = 0
		total_ride_ons_given = 0
		lap_count = 0
		route_length_kilometers = 0
		route_leadin_kilometers = 0
		route_ascent_meters = 0
		route_length = 0
		route_leadin = 0
		route_ascent = 0
		route_stats = ""
        current_route = ""
        chat_text = ""
		chat_count = 0
        segment_comp = ""
        group_event_name = ""
        sub_group_name = ""
        local file_check_sleep_time_MS = file_check_sleep_time*1000
        local release_ride_on_interval_MS = release_ride_on_interval*1000
        set_ride_on_text("")
        if enabled == true then
            obs.timer_add(file_check_callback, file_check_sleep_time_MS)
		    obs.timer_add(release_ride_on_callback, release_ride_on_interval_MS)
			    -- ADD A CALLBACK TO POPULATE OTHER VALUES AND MOVE OTHER VALUES OUTSIDE OF THE SET RIDE ON TEXT FUNCTION
		else
		   	obs.timer_remove(file_check_callback)
			obs.timer_remove(release_ride_on_callback)
        end
    end   
end


-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_bool(props, "enabled", "Enabled")
	obs.obs_properties_add_path(props, "log_file_location", "Location of Zwift Log File", obs.OBS_PATH_FILE,("*.txt"),nil)
	obs.obs_properties_add_float(props, "ride_on_update_interval", "Min Time to Display Ride On", 0.1, 100000, 0.1)
	obs.obs_properties_add_float(props, "file_check_interval", "Check Interval", 0.1, 100000, 0.1)
    obs.obs_properties_add_int(props, "number_of_names_to_display", "Max names to display", 1, 1000, 1)
    obs.obs_properties_add_text(props, "ride_on_name_suffix", "Suffix for Ride on names", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "chat_user_ids", "Chat users to display", obs.OBS_TEXT_MULTILINE)
	obs.obs_properties_add_bool(props, "include_world_chat", "Include World chats")
	obs.obs_properties_add_bool(props, "include_paddock_chat", "Include Paddock chats")
	obs.obs_properties_add_bool(props, "include_group_event_chat", "Include Group Event chats")

	local p = obs.obs_properties_add_list(props, "ride_on_names_source_name", "Ride On Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local q = obs.obs_properties_add_list(props, "ride_on_count_source_name", "Total Ride Ons Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local r = obs.obs_properties_add_list(props, "total_ride_ons_given_source_name", "Total Ride Ons Given Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local s = obs.obs_properties_add_list(props, "lap_count_source_name", "Lap Counter Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local t = obs.obs_properties_add_list(props, "current_route_source_name", "Current Route Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local u = obs.obs_properties_add_list(props, "route_stats_source_name", "Current Route Stats Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local v = obs.obs_properties_add_list(props, "chat_text_source_name", "Chat Messages Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local w = obs.obs_properties_add_list(props, "segment_comp_source_name", "Segment Completed Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local x = obs.obs_properties_add_list(props, "group_event_source_name", "Group Event Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local y = obs.obs_properties_add_list(props, "sub_group_source_name", "Sub Group Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)

	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			local source_id = obs.obs_source_get_unversioned_id(source)
			if source_id ~= nil then 
				if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
					local name = obs.obs_source_get_name(source)
					obs.obs_property_list_add_string(p, name, name)
					obs.obs_property_list_add_string(q, name, name)
					obs.obs_property_list_add_string(r, name, name)
					obs.obs_property_list_add_string(s, name, name)
					obs.obs_property_list_add_string(t, name, name)
					obs.obs_property_list_add_string(u, name, name)
					obs.obs_property_list_add_string(v, name, name)
    	            obs.obs_property_list_add_string(w, name, name)
    	            obs.obs_property_list_add_string(x, name, name)
       	         	obs.obs_property_list_add_string(y, name, name)
				end
			end
		end
	end
	obs.source_list_release(sources)
	obs.obs_properties_add_bool(props, "display_current_lap", "Display Current Lap")
	obs.obs_properties_add_button(props, "reset_button", "Reset Values", reset_button_clicked)
	return props
end


-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.obs_data_set_default_double(settings, "ride_on_update_interval", file_check_sleep_time)
	obs.obs_data_set_default_double(settings, "file_check_interval", release_ride_on_interval)
	obs.obs_data_set_default_int(settings, "number_of_names_to_display", number_of_names)
	obs.obs_data_set_default_bool(settings, "display_current_lap", display_current_lap)
	obs.obs_data_set_default_bool(settings, "enabled", enabled)
    obs.obs_data_set_default_string(settings, "chat_user_ids", chat_user_ids)
    obs.obs_data_set_default_string(settings, "ride_on_name_suffix", ride_on_name_suffix)
	obs.obs_data_set_default_bool(settings, "include_world_chat", include_world_chat)
	obs.obs_data_set_default_bool(settings, "include_paddock_chat", include_paddock_chat)
	obs.obs_data_set_default_bool(settings, "include_group_event_chat", include_group_event_chat)
	--update_chat_types(include_world_chat, include_paddock_chat, include_group_event_chat)
end


-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Reads Zwift Log file and outputs Ride On giver names and counts for total Ride Ons received and given to the selected Text Sources.\n\n--- Made by MattP ---"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)

	activate(false)

	release_ride_on_interval = obs.obs_data_get_double(settings, "ride_on_update_interval")
	file_check_sleep_time = obs.obs_data_get_double(settings, "file_check_interval")
	number_of_names	= obs.obs_data_get_int(settings, "number_of_names_to_display")
    ride_on_name_suffix = obs.obs_data_get_string(settings, "ride_on_name_suffix")
    ride_on_names_source_name = obs.obs_data_get_string(settings, "ride_on_names_source_name")
	ride_on_count_source_name = obs.obs_data_get_string(settings, "ride_on_count_source_name")
	total_ride_ons_given_source_name = obs.obs_data_get_string(settings, "total_ride_ons_given_source_name")
	lap_count_source_name = obs.obs_data_get_string(settings, "lap_count_source_name")
	current_route_source_name = obs.obs_data_get_string(settings, "current_route_source_name")
	route_stats_source_name = obs.obs_data_get_string(settings, "route_stats_source_name")
	display_current_lap = obs.obs_data_get_bool(settings, "display_current_lap")
	chat_text_source_name = obs.obs_data_get_string(settings, "chat_text_source_name")
	chat_user_ids = obs.obs_data_get_string(settings, "chat_user_ids")
	segment_comp_source_name = obs.obs_data_get_string(settings, "segment_comp_source_name")
	include_world_chat = obs.obs_data_get_bool(settings, "include_world_chat")
	include_paddock_chat = obs.obs_data_get_bool(settings, "include_paddock_chat")
	include_group_event_chat = obs.obs_data_get_bool(settings, "include_group_event_chat")
    group_event_source_name = obs.obs_data_get_string(settings, "group_event_source_name")
    sub_group_source_name = obs.obs_data_get_string(settings, "sub_group_source_name")
    
    enabled = obs.obs_data_get_bool(settings, "enabled")

	if obs.obs_data_get_string(settings, "log_file_location") ~= "" then
		log_directory = obs.obs_data_get_string(settings, "log_file_location")
	else
		log_directory = log_default
	end
	
	update_chat_types(include_world_chat, include_paddock_chat, include_group_event_chat)
	
	reset(true)
	
end


-- A function named script_load will be called on startup
function script_load(settings)
	reset(true)
	-- Connect activation/deactivation signal callbacks
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)
end


-- Loops over Zwift log file looking for Ride Ons received and adds them to table 'ride_ons'.
-- Updates ride on count and total given.
function get_ride_ons()
	local log_file = io.open (log_directory, "r")
	if log_file ~= nil then
		log_file:seek("set", last_end_pos)
		while true do
			local ride_on_giver = ""
			local line = log_file:read()
			if line == nil then
				last_end_pos = log_file:seek("cur")
				break
			elseif string.match(line,'HUD_Notify: ') then
				if string.match(line, 'Ride On!.-$') then
                    local i, j = string.find(line, "HUD_Notify: .- says Ride On!")
                    if i ~= nil then
                        ride_on_giver = string.sub(line, i+12, j-14)
                        ride_on_giver = ride_on_giver..ride_on_name_suffix
                        table.insert(ride_ons,ride_on_giver)
                        ride_on_count = ride_on_count + 1
                    end
                end
			elseif string.match(line, "Total Ride Ons Given: ") then
				local i, j = string.find(line, "Total Ride Ons Given: ")
                if i ~= nil then
                    j = j+1
				    total_ride_ons_given = string.sub(line, j)
                end
            elseif string.match(line, "Route Completed") then
				if lap_count == 0 and display_current_lap == true then
                    lap_count = 1
                    lap_count = lap_count + 1
                else
                    lap_count = lap_count + 1
                end
			elseif string.match(line, "Setting Route:") then
				local i, j = string.find(line, "Setting Route:%s+")
                if i ~= nil then
                    local updated_current_route = string.sub(line, j+1)
    				if current_route == updated_current_route then
    					current_route = updated_current_route
    				else
					current_route = updated_current_route
					    if display_current_lap == true then
					    	lap_count = 1
					    else
					    	lap_count = 0
					    end
                    end
                end
			elseif string.match(line, "Route stats: ") then
				local i, j = string.find(line, "%d*%d.?%d+cm long")
                if i ~= nil then 
                    route_length = string.sub(line, i,j-7)
                    route_length_kilometers = round(route_length/100000,2)
                end
                local k, l = string.find(line, "%d*%d.?%d+cm leadin")
                if k ~= nil then
                    route_leadin = string.sub(line, k,l-9)
                    route_leadin_kilometers = round(route_leadin/100000, 2)
                end
                local m, n = string.find(line, "%d*%d.?%d+cm ascent")
                    route_ascent = string.sub(line, m,n-9)
                if m ~= nil then 
                    route_ascent_meters = round(route_ascent/100, 0)
                end
     
                route_stats = "Length: "..route_length_kilometers.."km\nLead-in: "..route_leadin_kilometers.."km\nAscent: "..route_ascent_meters.."m"


			elseif string.match(line, "Chat: ") then
				for c_offset, c_type in pairs(chat_types) do 
					ct = string.match(line, c_type)
					if ct ~= nil then 
						local i, j = string.find(line, c_type)
						local chat_user_id = string.sub(line, i+1, j - c_offset)
						local k, l = string.find(line,"Chat: .-%s%d+%s%(")
                   		if k ~= nil then   
							chat_user_name = string.gsub(string.sub(line, k+6, l), "%s%d+%s%($", "")
							if chat_user_name == nil then 
								chat_user_name = chat_user_id	
							end
						else 
							chat_user_name = chat_user_id
						end   
						local m, n = string.find(line, c_type)
						local chat_message = string.sub(line, n+1)
               	    	if chat_user_ids ~= "" then
                        	if string.match(chat_user_ids, chat_user_id) then
					    		chat_text = chat_text..chat_user_name..": "..chat_message.."\n"
					    		chat_count = chat_count + 1
					    	end 
                    	else
					    	chat_text = chat_text..chat_user_name..": "..chat_message.."\n"
                        	chat_count = chat_count + 1 
                    	end
					end
				end
			elseif string.match(line, "TimingArch:") then
				local i, j = string.find(line,"line for %a")
				if j ~= nil then
					arch_name = string.sub(line, j)
				else
					arch_name = "Arch with No name"
                end
			elseif string.match(line, "TIMING ARCH:") then
				local i, j = string.find(line, "in %d+%.%d+%s%a+")
				local k, l = string.find(line, "%s%(avg watts %d+%.%d+%)")
                if i ~= nil and k ~= nil then 
					comp_time = string.sub(line, i+3, j-8)
                    comp_time = get_formatted_time(comp_time)
                    comp_avg_power = string.sub(line, k+2, l-1)
                end
                	segment_comp = "Timing Arch: "..arch_name.." in "..comp_time.." @ "..comp_avg_power.."\n"
            elseif string.match(line, 'for group %"') then 
                local i, j = string.find(line, 'for group "([^"]+)"') 
                local k, l = string.find(line, 'subgroup "([^"]+)"')
                if i ~= nil then
                    group_event_name = string.sub(line, i+11, j-1)  
                end
                if k~= nil then 
                    sub_group_name = string.sub(line, k+10, l-1)
                end
            end
		end
	else
		print("Log file does not exist or cannot be opened. Log file Directory: " .. log_directory)
	end
	io.close(log_file)
end

-- Controls the output of ride on names based on the ride_on_update_interval reading out from table ride_ons
-- rate is controlled using the release_ride_on_interval value from properties
function release_ride_on()
	local ride_on_names_list = ""
	local list_size = 1
	if (ride_on_count == 0) then
		set_ride_on_text("")
	else
		for _,_ in ipairs(names_list) do
			list_size = list_size +1
		end

		if list_size <= (number_of_names) and ride_ons[last_index] ~= last_name then
			table.insert(names_list, 1, ride_ons[last_index])

		elseif ride_ons[last_index] ~= last_name then
				table.insert(names_list, 1, ride_ons[last_index])
				table.remove(names_list, list_size)
		end

		for key, value in ipairs(names_list) do
				ride_on_names_list = ride_on_names_list..value.."\n"
		end
		set_ride_on_text(ride_on_names_list)
		last_name = ride_ons[last_index]

		if last_index == ride_on_count then
			last_index = last_index
		else
		last_index = last_index + 1
		end
	end
end

-- resets values in script - useful where you are starting a new ride in the same OBS session
-- This is called automatically called when a smaller log file is detected.
function reset(pressed)
	if not pressed then
		return
	end
		activate(false)
		activate(true)
end


function reset_button_clicked()
	reset(true)
	return false
end

-- no built in rouding funtion in Lua, this handles rounding the route lengths and leadin.
function round(x, y)
	y = math.pow(10, y or 0)
	x = x * y
	if x >=0 then
		x = math.floor(x+ 0.5)
	else
		x = math.ceil(x - 0.5)
	end
	return x / y
end

--Converting seconds to minutes hours
function get_formatted_time(s)
    s = tonumber(s)
    hours = math.floor(s/(60*60))
    mins = math.floor((s/60)-(hours*60))
    secs = math.floor(s - ((hours*3600) + (mins*60)))
    hsecs = (s*100 - (((hours*3600)*100) + ((mins*60)*100) + (secs*100))) % 100

    if hours < 1 and mins > 1 then 
		formatted_time = string.format("%02.f", mins)..":"..string.format("%02.f",secs).."."..string.format("%02.f", hsecs)
	elseif hours < 1 and mins < 1 then
        formatted_time = string.format("%02.f", secs).."."..string.format("%02.f", hsecs)
    else
        formatted_time = string.format("%02.f", hours)..":"..string.format("%02.f",mins)..":"..string.format("%02.f",secs).."."..string.format("%02.f", hsecs)
	end
	
	return formatted_time
end	

-- called on script update and adds patterns to table for matching chat types indexes are set to the offsets needed to get the value before it.
function update_chat_types(w, p, g)
	if w ~= true then 
		chat_types[10] = nil	
	else
		chat_types[10] = "%s%d+%s%(World%): " 
	end
	
	if p ~= true then 
		chat_types[12] = nil
	else
		chat_types[12] = "%s%d+%s%(Paddock%): "
	end

	if g ~= true then 
		chat_types[15] = nil
	else 
		chat_types[15] = "%s%d+%s%(GroupEvent%): "
	end
end
