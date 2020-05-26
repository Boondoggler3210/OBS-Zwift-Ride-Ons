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
--
-- Add script to OBS studio - parses the Zwift log file recording received ride ons.
-- log file directory and other parameters can be updated via OBS studio UI
-- Can't seem to get a path to populate the UI by default, the script will assumes a default directory if one has not set in UI
-- On Windows 10, this will be something like C:\Users\USerName\Documents\Zwift\Logs\Log.txt
-- Parsing the log file starts when any mapped source is activated and stops when one is deactivated
-- Reset button also disables reading the log file.
--------------------------------------------------------------------------------------------

obs = obslua
source_name   = ""
activated = false
ride_on_count_source_name = ""
ride_on_count = 0
ride_ons = {}
total_ride_ons_given = 0
last_end_pos = 0
log_directory = ""
log_default = os.getenv("HOMEDRIVE") .. os.getenv("HOMEPATH").."\\Documents\\Zwift\\Logs\\Log.txt"
end_of_file = 0
file_check_sleep_time = 5
release_ride_on_interval = 1
last_index = 0
last_ride_on = ""

--------------------------------------------------------------------------------------------

-- Set the ride On giver name text, update the ride on count and total Ride Ons given
function set_ride_on_text(tt)

   local latest_ride_on = tt

   if latest_ride_on ~= last_ride_on then
      local source = obs.obs_get_source_by_name(source_name)
         if source ~= nil then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", latest_ride_on)
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
         end
	end
	last_ride_on = latest_ride_on

	local r_count = ride_on_count
		local source = obs.obs_get_source_by_name(ride_on_count_source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", r_count)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end

	local g_count = total_ride_ons_given
		local source = obs.obs_get_source_by_name(total_ride_ons_given_source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", g_count)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
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
			reset()
			get_ride_ons()
		else
			get_ride_ons()
		end
	else
		print("Log file does not exist or cannot be opened log file Directory: " .. log_directory)
	end
end
-- Called by activation of source and triggers the update to the text source for ride on name and count
function release_ride_on_callback()
--	print("release Ride on Callback")
	release_ride_on()
end

-- Activating the source creates a timer call back which triggers at intervals specified in file_check_sleep_time and release_ride_on_interval through front end properties
function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		last_end_pos = 0
		last_index = 0
		ride_ons = {}
		ride_on_count = 0
		total_ride_ons_given = 0
		set_ride_on_text("")
		local file_check_sleep_time_MS = file_check_sleep_time*1000
		local release_ride_on_interval_MS = release_ride_on_interval*1000

		obs.timer_add(file_check_callback, file_check_sleep_time_MS)
		obs.timer_add(release_ride_on_callback, release_ride_on_interval_MS)
	else
		obs.timer_remove(file_check_callback)
		obs.timer_remove(release_ride_on_callback)
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		elseif (name == ride_on_count_source_name) then
			activate(activating)
		elseif (name == total_ride_ons_given_source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end


-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_path(props, "log_file_location", "Location of Zwift Log File", obs.OBS_PATH_FILE,("*.txt"),nil)
	obs.obs_properties_add_int(props, "ride_on_update_interval", "Min Time to Display Ride On", 1, 100000, 1)
	obs.obs_properties_add_int(props, "file_check_interval", "Check Interval", 1, 100000, 1)

	local p = obs.obs_properties_add_list(props, "source", "Ride On Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local q = obs.obs_properties_add_list(props, "ride_on_count_source", "Total Ride Ons Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local r = obs.obs_properties_add_list(props, "total_ride_ons_given_source", "Total Ride Ons Given Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)

	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			source_id_2 = obs.obs_source_get_unversioned_id(source)
			source_id_3 = obs.obs_source_get_unversioned_id(source)

			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
			if source_id_2 == "text_gdiplus" or source_id_2 == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(q, name, name)
			end
			if source_id_3 == "text_gdiplus" or source_id_2 == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(r, name, name)
			end
		end
	end
	obs.source_list_release(sources)
	obs.obs_properties_add_button(props, "reset_button", "Reset Values", reset_button_clicked)
	return props
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "ride_on_update_interval", file_check_sleep_time)
	obs.obs_data_set_default_int(settings, "file_check_interval", release_ride_on_interval)
end


-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Reads Zwift Log file and outputs Ride On giver names and counts for total Ride Ons received and given to the selected Text Sources.\n\n--- Made by MattP ---"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)

	activate(false)

	release_ride_on_interval = obs.obs_data_get_int(settings, "ride_on_update_interval")
	file_check_sleep_time = obs.obs_data_get_int(settings, "file_check_interval")
	source_name = obs.obs_data_get_string(settings, "source")
	ride_on_count_source_name = obs.obs_data_get_string(settings, "ride_on_count_source")
	total_ride_ons_given_source_name = obs.obs_data_get_string(settings, "total_ride_ons_given_source")

	if obs.obs_data_get_string(settings, "log_file_location") ~= "" then
		log_directory = obs.obs_data_get_string(settings, "log_file_location")
	else
		log_directory = log_default
	end

end


-- A function named script_load will be called on startup
function script_load(settings)
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
					ride_on_count = ride_on_count + 1
					local i, j = string.find(line, "HUD_Notify: ")
					j=j+1
					ride_on_giver = string.sub(line, j)
					table.insert(ride_ons,ride_on_giver)
				end
			elseif string.match(line, "Total Ride Ons Given: ") then
				local k, l = string.find(line, "Total Ride Ons Given: ")
				l = l+1
				total_ride_ons_given = string.sub(line, l)
			end
		end
	else
		print("Log file does not exist or cannot be opened - log file Directory: " .. log_directory)
	end
	io.close(log_file)
end

-- Controls the output of ride on names based on the ride_on_update_interval reading out from table ride_ons
-- rate is controlled using the release_ride_on_interval value from properties
function release_ride_on()
	local row_count = ride_on_count
	if (row_count == 0) then
		set_ride_on_text("")
	else
		set_ride_on_text(ride_ons[last_index])
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
	local source_1 = obs.obs_get_source_by_name(source_name)
	local source_2 = obs.obs_get_source_by_name(ride_on_count_source_name)
	local source_3 = obs.obs_get_source_by_name(total_ride_ons_given_source_name)

	if source_1 ~= nil then
		local active = obs.obs_source_active(source_1)
		obs.obs_source_release(source)
		activate(active)
	elseif source_2 ~= nil then
		local active = obs.obs_source_active(source_2)
		obs.obs_source_release(source)
		activate(active)
	elseif source_3 ~= nil then
		local active = obs.obs_source_active(source_3)
		obs.obs_source_release(source)
		activate(active)
	end
end

function reset_button_clicked()
	reset(true)
	return false
end
