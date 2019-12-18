local module = {}

local warmup = tmr.create()

function module.start()
  -- git_branch, git_release, git_commit_id, node_version_minor, git_commit_dts, node_version_revision, node_version_major
  local infoSw = node.info("sw_version")
  -- flash_size, chip_id, flash_mode, flash_speed, flash_id
  local infoHw = node.info("hw")
  -- ssl, lfs_size, modules, number_type
  local infoBuild = node.info("build_config")
  print("Heap Available:" .. node.heap())
  print("====================================")
  for k,v in pairs(infoSw)    do print("   sw."..k,v) end
  for k,v in pairs(infoHw)    do print("   hw."..k,v) end
  for k,v in pairs(infoBuild) do print("build."..k,v) end
  print("====================================")
  
  -- Turn off YL-69
  if string.find(config.Model, "YL") then
    gpio.mode(config.YL69Power, gpio.OUTPUT)
    gpio.write(config.YL69Power, gpio.LOW)
  end

  -- Start a simple http server
  print("Web Server Started")
  local srv = net.createServer(net.TCP)
  srv:listen(80, function(conn)
    conn:on("receive", function(conn, payload)
      led.flashRed()
      print(payload)

      -- Turn on YL-69
      if string.find(config.Model, "YL") then
        gpio.write(config.YL69Power, gpio.HIGH)
      end

      warmup:register(90, tmr.ALARM_SINGLE, function()

        local batteryString = ""
        if string.find(config.Model, "BAT") then
          local battery = adc.readvdd33()
          battery = battery + adc.readvdd33()
          battery = battery + adc.readvdd33()
          batteryString = ", \"Battery\": "..math.floor( battery / 3 )
          --  print(batteryString)
        end
        
        local moist_value = 0
        if string.find(config.Model, "YL") then
          moist_value = adc.read(config.YL69)
          moist_value = moist_value + adc.read(config.YL69)
          moist_value = moist_value + adc.read(config.YL69)
          moist_value = math.floor( moist_value / 3 )
          gpio.write(config.YL69Power, gpio.LOW)
        end

        local tempString =  ""
        if string.find(config.Model, "BME") then
          status, temp, humi, baro, barol, dew = bme.read()
          if status == 0 then
            tempString = "\"Status\": "..status..", \"Temperature\": "..temp
            ..", \"Humidity\": "..humi..", \"Moisture\": "..moist_value
            ..", \"Barometer\": "..baro..", \"Barometer Locl\": "..barol..", \"Dew\": "..dew
          else
            tempString = "\"Status\": "..status
          end
        else
          status, temp, humi, temp_dec, humi_dec = dht.read(config.DHT22)
          if status == 0 then
            tempString = "\"Status\": "..status..", \"Temperature\": "..temp
            ..", \"Humidity\": "..humi..", \"Moisture\": "..moist_value
          else
            tempString = "\"Status\": "..status
          end
        end

        --      print("Heap Available:" .. node.heap())
        local gdString = ""
        if string.find(config.Model, "GD") then
          local green, red = gd.getDoorStatus()
          gdString = ", \"Green\": \""..green.."\", \"Red\": \""..red.."\""
        end
        --      print("35")
        local responseData = "{ \"Hostname\": \""..config.ID..
        "\", \"Model\": \""..config.Model..
        "\", \"Version\": \""..config.Version..
        "\", \"Firmware\": \""..infoSw.node_version_major.."."..infoSw.node_version_minor.."."..infoSw.node_version_revision..
        "\", \"Data\": {"..tempString..gdString..batteryString.."}}\n"
        local response = { 
          "HTTP/1.1 200 OK\n", 
          "Server: ESP (nodeMCU) "..infoHw.chip_id.."\n",
          "Content-Type: application/json\n",
          "Access-Control-Allow-Origin: *\n\n",
          responseData
        }
        print("Heap Available:" .. node.heap())
        print(responseData)
        -- print(table.concat(response,", "))
        

        local function sender (conn)
          if #response > 0 then conn:send(table.remove(response, 1))
          else conn:close()
          end
        end
        conn:on("sent", sender)
        sender(conn)
      end) -- End of timer

      warmup:start()
    end)

    conn:on("sent", function(conn) conn:close() end)
  end)

end


return module
