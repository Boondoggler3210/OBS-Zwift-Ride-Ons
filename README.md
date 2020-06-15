# OBS-Zwift-Ride-Ons
OBS Studio Lua script that monitors a Zwift log file.  Extracts the below info and outputs it to mapped OBS txt sources

1. Names of users giving Ride Ons
2. Count of Ride Ons received
3. Count of Ride Ons Given
4. Current Route Name
5. Route Length, Leadin and Ascent 
6. Lap Counter

Updates OBS text sources with each value at a user definable interval. 

All of the ride ons are read in from the log file and the rate that each name is displayed can be configured, meaning if, unlike me, you're really popular and get loads of them, you can guarantee everyone gets a mention for a minimum amount of time. 

You can also change the interval at which the script checks the log file for updates - this might be useful if for whatever reason you find having this running every second all the time in the background to be problematic. 

The log file directory is assumed to be your windows home directory\documents\Zwift\logs - you can change this in the script settings (the default directory won't populate the path field in ui - so if it's left blank the script assumes this one). 

Deactivating and reactivating one of the sources will reset the values and cause the log file to be read again from the begining.

If the script detects a log file that has shrunk it will also reset (possible if you leave it running through multiple Zwift sessions)

Added the option to control how many ride on names are show on screen at once.  These are replaced one at a time at the interval set with the eariest dropping off the list when the maximum is reached.

Updated Since version 0.11
1. -- 0.12 - Added Lap Counter with option display current or completed lap, tidied up source list in props
2. -- 0.13 - Added Current Route name, changed naming convention of sources for consistency
3. -- 0.14 - Added Route Length (km), leadin(km) and Ascent(m) - these are written to the 'route stats' source
4. -- 0.15 - Added Rounding to Route Length and Leadin values to limit to 2 dp
5. -- 0.16 - Added reset for lap counter when current route changes
6. -- 0.17 - Changed activation logic - added an enabled flag in script settings - no longer controlled by activating /deactivating a source
7. -- 0.18 15/06/2020 - Changed types for timing of file check and display time for ride on names - support down to 100ms
