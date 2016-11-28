-- file : application.lua
local cjson = require "cjson"
local module = {}  

m = nil
local sn = nil
local flagSerialSet = false
local toArduino = ""
local buffRoomStatus = ""
local fromArd = ""
local owner = ""
local tempMsg = ""
local setLampStatus = false
local setFanStatus = false
local setACStatus = false
local setLockStatus = false
local setIntervalStatus = false
local setLockScheduleStatus = false
local clearLockScheduleStatus = false
local tempLampNo = 0
local tempLampState = 0
local tempFanState = 0
local tempACState = 0
local tempLockState = 0
local tempUpdateInterval = 0
local initStatus = false
local tempLockSchedule = ""
local tempUnlockSchedule = ""
local tempACFan = 0
local tempWantedTemp = 0
local flagDC = false
local publishAllowed = true

local function initAll()
	toArduino = ""
	buffRoomStatus = ""
	fromArd = ""
	owner = ""
	tempMsg = ""
	setLampStatus = false
	setFanStatus = false
	setACStatus = false
	setLockStatus = false
	setIntervalStatus = false
	setLockScheduleStatus = false
	clearLockScheduleStatus = false
	tempLampNo = 0
	tempLampState = 0
	tempFanState = 0
	tempACState = 0
	tempLockState = 0
	tempUpdateInterval = 0
	initStatus = false
	tempLockSchedule = ""
	tempUnlockSchedule = ""
	tempACFan = 0
	tempWantedTemp = 0
	flagDC = false
    publishAllowed = true
end

local function publishData(topic,payload)
    flagDC = true
    m:publish(config.ENDPOINT .. topic,payload,1,0,function(conn)
        flagDC = false
        --c2 = "{\"msg\":\"puback\"}"
        --print(c2)
    end)
end

local function subscribeTopic(topic)  
    m:subscribe(config.ENDPOINT .. topic,1,function(conn)
    end)
end

local function convertMACToSN(mac)
	return (mac:gsub('%:', '')):sub(1,12)
end

local function initRoomState()
	setLampStatus = false
	setFanStatus = false
	setACStatus = false
	setLockStatus = false
	setIntervalStatus = false
	setLockScheduleStatus = false
	clearLockScheduleStatus = false
	tempLampNo = 0
	tempLampState = 0
	tempFanState = 0
	tempACState = 0
	tempLockState = 0
	tempUpdateInterval = 0
	tempLockSchedule = ""
	tempUnlockSchedule = ""
	tempACFan = 0
	tempWantedTemp = 0
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
					snd = "{\"msg\":\"getRoomStatus\",\"owner\":\""..owner.."\",\"applianceserial\":\""..sn.."\"}"
					publishData("/"..owner,snd)			
				end
			elseif (topic == config.ENDPOINT.."/"..owner and jobj.applianceserial == sn) then
				if (jobj.msg == "setLamp" and not setLampStatus) then
					initRoomState()
					tempMsg = jobj.msg
					tempLampNo = jobj.lampno
					tempLampState = jobj.lampstate
					setLampStatus = true
				elseif(jobj.msg == "setFan" and not setFanStatus) then
					initRoomState()
					tempMsg = jobj.msg
					tempFanState = jobj.fanstate
					setFanStatus = true
				elseif(jobj.msg == "setAC" and not setACStatus) then
					initRoomState()
					tempMsg = jobj.msg
					tempACState = jobj.acstate
					tempACFan = jobj.acfan
					tempWantedTemp = jobj.wantedtemp
					setACStatus = true
				elseif(jobj.msg == "setLock" and not setLockStatus) then
					initRoomState()
					tempMsg = jobj.msg
					tempLockState = jobj.lockstate
					setLockStatus = true	
				elseif(jobj.msg == "setUpdateInterval" and not setIntervalStatus) then
					initRoomState()
					tempMsg = jobj.msg
					tempUpdateInterval = jobj.updateinterval
					setIntervalStatus = true	
				elseif(jobj.msg == "setLockSchedule" and not setLockScheduleStatus) then
					initRoomState()
					tempMsg = jobj.msg
					tempLockSchedule = jobj.lockschedule
					tempUnlockSchedule = jobj.unlockschedule
					setLockScheduleStatus = true
				elseif(jobj.msg == "clearLockSchedule" and not clearLockScheduleStatus) then
					initRoomState()
					tempMsg = jobj.msg
					clearLockScheduleStatus = true
				elseif (jobj.msg == "cmdid" and jobj.cmdid ~= -1) then
					if(tempMsg == "setLamp" and setLampStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"lampno\":" .. tempLampNo .. ",\"lampstate\":".. tempLampState .."}"
						initRoomState()
					elseif(tempMsg == "setFan" and setFanStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"fanstate\":"..tempFanState.."}"
						initRoomState()
					elseif(tempMsg == "setAC" and setACStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"acstate\":"..tempACState..",\"acfan\":"..tempACFan..",\"wantedtemp\":"..tempWantedTemp.."}"
						initRoomState()
					elseif(tempMsg == "setLock" and setLockStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"lockstate\":"..tempLockState.."}"
						initRoomState()
					elseif(tempMsg == "setUpdateInterval" and setIntervalStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"updateinterval\":"..tempUpdateInterval.."}"
						initRoomState()
					elseif(tempMsg == "setLockSchedule" and setLockScheduleStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid..",\"ls\":\""..tempLockSchedule.."\",\"us\":\""..tempUnlockSchedule.."\"}"
						initRoomState()
					elseif(tempMsg == "clearLockSchedule" and clearLockScheduleStatus)then
						toArduino = "{\"msg\":\""..tempMsg.."\",\"cmdid\":"..jobj.cmdid.."}"
						initRoomState()
					end
					print(toArduino)
					tempMsg = ""
				elseif(jobj.msg=="roomStatus" and not initStatus)then
					--toArduino = "{\"msg\":\"setUpdateInterval\",\"cmdid\":"..jobj.cmdid..",\"updateinterval\":"..jobj.upint.."}"
					buffRoomStatus = cjson.encode(jobj)
					initStatus = true
					if(flagSerialSet)then
						print(buffRoomStatus)
						buffRoomStatus = ""
					end
					initRoomState()
				end
			end
		end
	end)
    
    m:lwt("/lwt","{\"msg\":\"offline\",\"applianceserial\":\""..sn.."\"}",1)
	
    m:connect(config.HOST, config.PORT,1 ,1, function(con)
        
    end) 
	
	m:on("connect", function(client)
        --c = "{\"msg\":\"connected\"}"
		--print(c)
		subscribeTopic("/"..sn)
		snd = "{\"msg\":\"getOwner\",\"applianceserial\":\""..sn.."\"}"
		publishData("/"..sn,snd)
		initStatus = false
		flagDC = false
        publishAllowed = true
	end)
	
	--m:on("offline",function(client)
        --flagDC = true
        --md = "{\"msg\":\"mqttdisconnected\"}"
		--print(md)
        --m:close()
        --m = nil
        --mqtt_start()
	--end)
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
			--snd = "{\"msg\":\"getRoomStatus\",\"owner\":\""..owner.."\",\"applianceserial\":\""..sn.."\"}"
			--publishData("/"..owner,snd)
			flagSerialSet = true
			if(buffRoomStatus ~= "")then
				print(buffRoomStatus)
				buffRoomStatus = ""
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
            --d = "{\"msg\":\"disconnected\"}"
            --print(d)
		    m:close()
            m = nil
        end
	end)
	
	tmr.alarm(1, 30000, 1,checkFlagDC)
end

return module
