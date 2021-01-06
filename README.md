# OBS-Zwift-Ride-Ons
OBS Studio Lua script that monitors a Zwift log file.  Extracts the below info and outputs it to mapped OBS txt sources

1. Names of users giving Ride Ons
2. Count of Ride Ons received
3. Count of Ride Ons Given
4. Current Route Name
5. Route Length, Leadin and Ascent 
6. Lap Counter
7. Chat messages - optionally filtered by Zwift Users ID - enter IDs as comma separated list and filter by type
8. Timing Arch messages
9. 'says Ride On!' in ride on names message now optional
10. Added Event name

Updates OBS text sources with each value at a user definable interval. 

All of the ride ons are read in from the log file and the rate that each name is displayed can be configured, meaning if, unlike me, you're really popular and get loads of them, you can guarantee everyone gets a mention for a minimum amount of time. 

You can also change the interval at which the script checks the log file for updates - this might be useful if for whatever reason you find having this running every second all the time in the background to be problematic. 

The log file directory is assumed to be your windows home directory\documents\Zwift\logs - you can change this in the script settings (the default directory won't populate the path field in ui - so if it's left blank the script assumes this one). 

If the script detects a log file that has shrunk it will also reset (possible if you leave it running through multiple Zwift sessions)

Added the option to control how many ride on names are show on screen at once.  These are replaced one at a time at the interval set with the eariest dropping off the list when the maximum is reached.

Updated Since version 0.21
-- 0.22 - Restructured function that writes output to text sources to make more compact
-- 0.23 - Made text displayed after the name of user giving ride on user definable - will deafuly to ' says Ride On!'
-- 0.24 - Changed Lap counter logic, now ignores the log files lap count figure as this lags behind the game. 
-- 0.25 - Added mitigation for strings not found where changing character position causes arithmetic issues. 
-- 0.26 - Added option to include or exclude chat types (world, Paddock and GroupEvent)
-- 0.27 - Added formatting to arch timing and changed output string to be more concise. 
-- 0.28 - Added parsing for group event name and name of subgroup
-- 0.29 - Added mitigation if obs_source_get_unversioned_id returns nil
-- 0.30 - Added logic for setting default log file location to avoid script failing on MacOS