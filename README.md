# OBS-Zwift-Ride-Ons
OBS Studio Lua script that monitors a Zwift log file and counts Ride Ons given, received and the names of those giving you the thumbs up. 

Updates OBS text sources with each value at a user definable interval.

All of the ride ons are read in from the log file and the rate that each name is displayed can be configured, meaning if, unlike me, you're really popular and get loads of them, you can guarantee everyone gets a mention for a minimum amount of time. 

You can also change the interval at which the script checks the log file for updates - this might be useful if for whatever reason you find having this running every second all the time in the background to be problematic. 

The log file directory is assumed to be your windows home directory\documents\Zwift\logs - you can change this in the script settings (the default directory won't populate the path field in ui - so if it's left blank the script assumes this one). 

The script is set running parsing the log file by activating one of (any of) the text sources linked to it. The same is true of deactivating the script. 

Deactivating and reactivating one of the sources will reset the values and cause the log file to be read again from the begining.

If the script detects a log file that has shrunk it will also reset (possible if you leave it running through multiple Zwift sessions)

Added the option to control how many ride on names are show on screen at once.  These are replaced one at a time at the interval set with the eariest dropping off the list when the maximum is reached.
