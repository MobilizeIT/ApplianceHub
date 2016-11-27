#include <Time.h>
#include <TimeLib.h>
#include <Wire.h>
#include<ArduinoJson.h>
#include<DS3232RTC.h>

#define MAX_BUFF 255
const int IN_BUF_SIZE =  JSON_OBJECT_SIZE(5);
const int OUT_BUF_SIZE =  JSON_OBJECT_SIZE(10)+JSON_ARRAY_SIZE(16);

String inputString = "";
String ctimestamp,rtimestamp;
boolean stringComplete = false;
char crecv[MAX_BUFF];
char msg[30];
char applianceserial[15];
int cmdid=0;
int outPinState = 0;
int outPinNo = 0;
int doutstate[6]={0,0,0,0,0};
bool updateAllowed = false;
int updateInterval=1;

void serialEvent(){
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if(inChar != '>'){
      inputString += inChar;  
    }
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}

void setNextUpdateTime(){
  int s = second();
  int m = minute();
  int h = hour();
  int d = day();
  
//  if(updateInterval == 0){
//    if(s+1 >= 60){
//      if(m+1 >= 60){
//        if(h+1 >= 24){
//          RTC.setAlarm(ALM1_MATCH_SECONDS,(s+1)%60,(m+1)%60,(h+1)%24,d+1);
//        }else{
//          RTC.setAlarm(ALM1_MATCH_SECONDS,(s+1)%60,(m+1)%60,h+1,d);
//        } 
//      }else{
//        RTC.setAlarm(ALM1_MATCH_SECONDS,(s+1)%60,m+1,h,d);
//      }
//    }else{
//      RTC.setAlarm(ALM1_MATCH_SECONDS,s+1,m,h,d);
//    }
//    RTC.setAlarm(ALM1_EVERY_SECOND,m,h,d);
//  }else{
//    if(m+updateInterval >= 60){
//      int hplus = (m+updateInterval)/60;
//      if(h+1 >= 24){
//        RTC.setAlarm(ALM1_MATCH_HOURS,s,(m+updateInterval)%60,(h+hplus)%24,d+1);
//      }else{
//        RTC.setAlarm(ALM1_MATCH_HOURS,s,(m+updateInterval)%60,h+hplus,d);
//      }
//      
//    }else{
//      RTC.setAlarm(ALM1_MATCH_HOURS,s,m+updateInterval,h,d);
//    }
//  }
    if(updateInterval == 0){
      RTC.setAlarm(ALM1_EVERY_SECOND,m,h,d);
    }else{
      int hplus = (m+updateInterval)/60;
      RTC.setAlarm(ALM1_MATCH_HOURS,s,(m+updateInterval)%60,(h+hplus)%24,d);
    }
}

void updateBoardStatus(){
  if(updateAllowed){
    StaticJsonBuffer<OUT_BUF_SIZE> outjbuff;
    JsonObject& outjobj = outjbuff.createObject();
    outjobj["msg"] = "boardStatus";
    outjobj["applianceserial"]=applianceserial;
    rtimestamp = year();
    rtimestamp += "-";
    rtimestamp += month();
    rtimestamp += "-";
    rtimestamp += day();
    rtimestamp += " ";
    rtimestamp += hour();
    rtimestamp += ":";
    rtimestamp += minute();
    rtimestamp += ":";
    rtimestamp += second();
    outjobj["rtimestamp"] = rtimestamp;
    outjobj["cmdid"]=cmdid;
  
    JsonArray& din = outjobj.createNestedArray("dinputs");
    for(int i = 2;i<8;i++){
      din.add(digitalRead(i));
    }
    JsonArray& dout = outjobj.createNestedArray("doutputs");
//    for(int i = 8;i<13;i++){
//      dout.add(digitalRead(i));
//    }
    for(int i = 0;i<5;i++){
      dout.add(doutstate[i]);
    }
    JsonArray& ain = outjobj.createNestedArray("ainputs");
    for(int i = 0;i<4;i++){
      ain.add(analogRead(i));
    }
    outjobj["upint"]=updateInterval;
    outjobj.printTo(Serial);
    cmdid=0;
  }
}

void commReady(){
  StaticJsonBuffer<OUT_BUF_SIZE> outjbuff;
  JsonObject& outjobj = outjbuff.createObject();
  outjobj["msg"] = "ready";
  outjobj.printTo(Serial);
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  setSyncProvider(RTC.get);
  inputString.reserve(MAX_BUFF);
  ctimestamp.reserve(20);
  rtimestamp.reserve(20);
  RTC.alarmInterrupt(ALARM_1,true);
  RTC.alarmInterrupt(ALARM_2, false);
  pinMode(2,INPUT);
  digitalWrite(2,HIGH);
  pinMode(3,INPUT);
  digitalWrite(3,HIGH);
  pinMode(4,INPUT);
  digitalWrite(4,HIGH);
  pinMode(5,INPUT);
  digitalWrite(5,HIGH);
  pinMode(6,INPUT);
  digitalWrite(6,HIGH);
  pinMode(7,INPUT);
  digitalWrite(7,HIGH);

  pinMode(A0,INPUT);
  pinMode(A1,INPUT);
  pinMode(A2,INPUT);
  pinMode(A3,INPUT);

  pinMode(8,OUTPUT);
  pinMode(9,OUTPUT);
  pinMode(10,OUTPUT);
  pinMode(11,OUTPUT);
  pinMode(12,OUTPUT);

  pinMode(13,OUTPUT);
  digitalWrite(13,LOW);
  delay(10000);
  digitalWrite(13,HIGH);
  commReady();
}

void loop() {
  // put your main code here, to run repeatedly:
  if (stringComplete) {
    inputString.toCharArray(crecv,inputString.length());
    
    StaticJsonBuffer<IN_BUF_SIZE> injbuff;
    JsonObject& injobj = injbuff.parseObject(crecv);
    if (!injobj.success()){
      inputString = "";
      memset(crecv, 0, sizeof(crecv));
      stringComplete = false;
      return;
    }
  
    strcpy(msg,injobj["msg"]);
    
    if(strcmp(msg,"setPinOutput") == 0){
      cmdid = injobj["cmdid"];
      outPinNo = injobj["opn"];
      outPinState = injobj["ops"];
      doutstate[outPinNo-8]=outPinState;
      digitalWrite(outPinNo,outPinState);
      updateBoardStatus();
      setNextUpdateTime();
    }
    else if(strcmp(msg,"setBoardUpdateInterval") == 0){
      updateInterval=injobj["updateinterval"];
      cmdid = injobj["cmdid"];
      updateAllowed = true;
      updateBoardStatus();
      setNextUpdateTime();
    }
    else if(strcmp(msg,"setApplianceSerial")==0){
      strcpy(applianceserial,injobj["applianceserial"]);
      StaticJsonBuffer<OUT_BUF_SIZE> outjbuff;
      JsonObject& outjobj = outjbuff.createObject();
      outjobj["msg"] = "serialSet";
      outjobj.printTo(Serial);
    }
    else if(strcmp(msg,"boardStatus")==0){
      updateAllowed = true;
      for(int n = 0; n<5;n++){
        doutstate[n] = injobj["doutputs"][n];
        digitalWrite(n+8,doutstate[n]);
      }
      updateBoardStatus();
      setNextUpdateTime();
    }
    inputString = "";
    memset(crecv, 0, sizeof(crecv));
    stringComplete = false;
  }
  if (RTC.alarm(ALARM_1)){
    updateBoardStatus();
    setNextUpdateTime();
  }
}
