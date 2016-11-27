-- file : init.lua
app = require("application")  
config = require("config")

function startup()
    app.start()
end
tmr.alarm(0,5000,0,startup)

