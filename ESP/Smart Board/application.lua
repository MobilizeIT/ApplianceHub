-- file : application.lua
local cjson = require "cjson"
local module = {}  

m = nil
local sn = nil
local initStatus = true
local toArduino = ""
local fromArd = ""
local owner = ""
local tempMsg = ""
local tempPinNo = 0
local tempPinState = 0
local tempUpdateInterval = 0
local setPinStatus = false
local setIntervalStatus = false
local buffBoardStatus = ""
local flagDC = false
local flagSerialSet = false
local publishAllowed = true

local function initAll()
	sn = nil
	initStatus = true
	toArduino = ""
	fromArd = ""
	owner = ""
	tempMsg = ""
	tempPinNo = 0
	tempPinState = 0
	tempUpdateInterval = 0
	setPinStatus = false
	setIntervalStatus = false
	buffBoardStatus = ""
	flagDC = false
    publishAllowed = true
end

local function publishData(topic,payload)
    flagDC = true
    m:publish(config.ENDPOINT .. topic,payload,1,0,function(conn)
        flagDC = false
    end)
end

local function subscribeTopic(topic)  
    m:subscribe(config.ENDPOINT .. topic,1,function(conn)
    end)
end

local function convertMACToSN(mac)
	return (mac:gsub('%:', '')):sub(1,12)
end

local function initBoardState()
	tempPinNo = 0
	tempPinState = 0
	tempUpdateInterval = 0
	setPinStatus = false
	setIntervalStatus = false
end

local function mqtt_start()
	initAll() 
	
	m = mqtt.Client(config.ID, 120,config.applianceType.."#"..sn,config.pass)
	
    m:on("message", function(conn, topic, data) 
		if (data ~= nil) then
			jobj = cjson.decode(data)
			if (topic == config.ENDPOINT.."/"..sn) then
				if (jobj.msg == "owner" and jobj.owner ~= "NOTFOUND") then
					owner = jobj.owner
					subscribeTopic("/"..owner)
					snd = "{\"msg\":\"getBoardStatus\",\"owner\":\""..owner.."\",\"applianceserial\":\""..sn.."\"}"
					publishData("/"..owner,snd)
				end
			elseif (topic == config.ENDPOINT.."/"..owner and jobj.applianceserial == sn) then
				if (jobj.msg == "setPinOutput" and not setPinStatus) then
					initBoardState()
					tempMsg = jobj.msg
					tempPinNo = jobj.opn
					tempPinState = jobj.ops
					setPinStatus = true
				elseif(jobj.msg == "setBoardUpdateInterval" and not setIntervalStatus) then
					initBoardState()
					tempMsg = jobj.msg
					tempUpdateInterval = jobj.updateinterval
					setIntervalStatus = true	
				elseif (jobj.msg == "cmdid" and jobj.cmdid ~= -1) then
					if(tempMsg == "setPinOutput" and setPinStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"opn\":" .. tempPinNo .. ",\"ops\":".. tempPinState .."}"
						initBoardState()
					elseif(tempMsg == "setBoardUpdateInterval" and setIntervalStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"updateinterval\":"..tempUpdateInterval.."}"
						initBoardState()
					end
					print(toArduino)
					tempMsg = ""
				elseif(jobj.msg=="boardStatus" and initStatus)then
					buffBoardStatus = cjson.encode(jobj)
					initStatus = true
					if(flagSerialSet)then
						print(buffBoardStatus)
						buffBoardStatus = ""
					end
					initBoardState()
				end
			end
		end
	end)
    
    m:lwt("/lwt","{\"msg\":\"offline\",\"applianceserial\":\""..sn.."\"}",1)
	
    m:connect(config.HOST, config.PORT,1 ,1, function(con)
        
    end) 
	
	m:on("connect", function(client)
        subscribeTopic("/"..sn)
		snd = "{\"msg\":\"getOwner\",\"applianceserial\":\""..sn.."\"}"
		publishData("/"..sn,snd)
		initStatus = false
		flagDC = false
        publishAllowed = true
	end)
	
end

local function checkFlagDC()
	if flagDC and wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then
		--md = "{\"msg\":\"mqttdisconnected\"}"
		--print(md)
        flagDC = false
        publishAllowed = false
		wifi.sta.disconnect()
        tmr.delay(1000000)
        wifi.sta.connect()
	end
end

function module.start()
	sn = convertMACToSN(wifi.sta.getmac())
	
	uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
	uart.on("data","}",function(data)
		fromArd = cjson.decode(data)
		if(fromArd.msg=="ready") then     
			--print("}") 
			giveSN = "{\"msg\":\"setApplianceSerial\",\"applianceserial\":\""..sn.."\"}"
			print(giveSN)
		elseif(fromArd.msg=="serialSet")then
			flagSerialSet = true
			if(buffBoardStatus ~= "")then
				print(buffBoardStatus)
				buffBoardStatus = ""
			end			
		else
			if publishAllowed then
				publishData("/"..owner,data)
			end
		end
	end,0)
	
	wifi.setmode(wifi.STATION)
	wifi.sta.autoconnect(1)
	wifi.nullmodesleep(false)
	wifi.sleeptype(wifi.NONE_SLEEP)
	wifi.sta.config(config.SSID,config.SSIDPass)
	wifi.sta.connect()
	
	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,function(T)
		mqtt_start()
	end)
	
	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED,function(T)
		flagDC = true
        publishAllowed = false
        if(m ~= nil)then
		    m:close()
            m = nil
        end
	end)
	
	tmr.alarm(1, 30000, 1,checkFlagDC)
end

return module
