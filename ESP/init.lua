-- File					: init.lua
-- Version				: 1.0
-- Template Created By	: Michael Aditya Sutiono
-- Date created			: 27th November 2016
-- Contact				: mike.sutiono@gmail.com
-- Description			: This file will be executed on device startup
-- You may delete the comments to free some storage space.
-- DO NOT COMPILE THIS FILE.

-- We will call these two files:
-- application.lua/.lc	: File that contains your code
-- config.lua/.lc		: File that contains your connection parameters. e.g. WiFi SSID and password, MQTT broker host, port, etc.
app = require("application")  
config = require("config")

-- startup() function will call start() function in application.lua/.lc
function startup()
    app.start()
end

-- This gives us 5 seconds to remove init.lua and restart if anything goes wrong with our application code
-- After 5 seconds, it will execute startup() function above
tmr.alarm(0,5000,0,startup)

