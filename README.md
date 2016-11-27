# ApplianceHub
ApplianceHub is a wireless communcation system for smart appliances.
Everything is built with open-source components.

There are three main components of this system, which are the smart device itself (embedded with Arduino microcontroller and ESP8266 NodeMCU DevKit WiFi Module), a Node.js based server with MySQL database, and an Android based application (using paho MQTT)  as the controller. Communication methods which are used to connect smart devices with ApplianceHub system are Wi-Fi communication protocol and MQTT messaging protocol in JSON data format, encrypted with OpenSSL certificate to ensure security.

The purpose of this repo is to share the ApplianceHub learning kit (Smart Board) code samples for Arduino, ESP8266 NodeMCU Devkit, and Node.js-based MQTT broker. This repo also contains some tutorials, e.g. tutorial for creating OpenSSL certificate, setting up the MQTT broker on Ubuntu, flashing and building NodeMCU firmware, etc.
