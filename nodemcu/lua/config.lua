local module = {}

-- Make your adjustments below here: DHT, DHT-YL, BME, BME-GD, BME-BAT
module.Model = "BME"
module.Version = "1.6"

-- LED state
module.ledState = 0 -- 0: fully disabled, 1: LEDs on, 2: Connected off (Boot/Error only)

-- BME280 settings
module.bme280scl = 5  -- D5
module.bme280sda = 6  -- D6

-- DHT22 settings
module.DHT22 = 2

-- YL69 Moisture Sensor
module.YL69 = 0 -- adc pin 0
module.YL69Power = 7 -- D7

-- No changes should be needed below this line

module.ID = wifi.sta.gethostname()

module.ledRed = 0 -- gpio16
module.ledBlue = 4 -- gpio2

return module
