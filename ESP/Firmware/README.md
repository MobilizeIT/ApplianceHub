##How to flash the firmware to ESP8266 NodeMCU DevKit (ESP-12)?
1. Download and open this tool https://github.com/nodemcu/nodemcu-flasher
2. On the config tab, choose the binary file(s) you want to flash with a correct address*. 
   
   If you use the firmware I provided, you just need to flash one file (choose between integer or float**) on address 0x00000
   
   You can also build your own custom firmware at https://nodemcu-build.com/
3. On the advanced tab, you can customize the Baud Rate parameter, Flash Size, Flash Speed, and SPI Mode.
    
    My Configuration:
    
    Baudrate: 115200
    
    Flash Size: 4MByte
    
    Flash Speed: 40MHz
    
    SPI Mode: DIO
4. On the operation tab, choose the serial port which your ESP connected to
5. Hit the flash button, wait the progress bar until full
6. Congratulations, you have flashed your firmware!

*)
(ref: https://nodemcu.readthedocs.io/en/master/en/flash/)

**)
The integer version which supports only integer operations and the float version which contains support for floating point calculations. From a performance point of view, the integer version should be better. It’s also smaller and most of the time, you will not need to work with floating point numbers.
(ref: http://greyfocus.com/2015/10/starting-out-with-nodemcu/)
