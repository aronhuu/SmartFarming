/*
    ------ Waspmote Pro Code Example --------

    Explanation: This is the basic Code for Waspmote Pro

    Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L.
    http://www.libelium.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Put your libraries here (#include ...)

// ------ Libraries Included -------

#include <WaspWIFI_PRO.h>
#include <WaspFrame.h>
#include <Countdown.h>
#include <FP.h>
#include <MQTTFormat.h>
#include <MQTTLogging.h>
#include <MQTTPacket.h>
#include <MQTTPublish.h>
#include <MQTTSubscribe.h>
#include <MQTTUnsubscribe.h>


// ------ Variables definition -------
#define TIMEOUT 5000.00;
char WASPMOTE_ID[] = "Bracelet";
char topicList[1][45];
unsigned char payloadList[1][200]={'\0'};
uint8_t status;
unsigned long previous;
uint16_t socket_handle = 0;
uint8_t errorWiFi;

char animalID[8];
char name[10];
char type[10];
int age;
float animalLatitude;
float animalLongitude;
float bodytemp=0;
int steps =0;
float weight=0;

//-----------constantes---------
//----------IDENTIFICATION------------------
const char ANIMALID[8] = "123456A"; //field1
const char NAME[10] = "JULIA";//field2
const char TYPE[10] = "VACA";//field3
const int AGE = 84; //meses//field4
//----------FREQUENT MEASURES----------------
const float LATITUDE = 40.416358;//field5
const float LONGITUDE = -3.650009;//field6
//----------AVERAGE MEASURES-----------------
//const float BODYTEMP = 43; //grados centigrados //field7
//const int STEPS = 9000; ////field8
//const float WEIGHT = 400; //Kilos ////field9



// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket = SOCKET1;
///////////////////////////////////////

// choose TCP server settings
///////////////////////////////////////
char HOST[]        = "138.100.48.251";//"10.49.1.26";//"138.100.48.251";//"10.151.127.208";//"192.168.1.54";//MQTT Broker
char REMOTE_PORT[] = "1883";  //MQTT
char LOCAL_PORT[]  = "3000";
///////////////////////////////////////
void publish(char *topic, unsigned char *payload){
  if (status == true)
  {
    MQTTString topicString = MQTTString_initializer;
    unsigned char buf[200]={'\0'};
    int buflen = sizeof(buf);

    topicString.cstring = (char *)topic;

    USB.print(F("\n\t\tTOPIC "));
    USB.println(topicString.cstring);
    USB.print(F("\n\t\tPAYLOAD "));
    USB.println((char *)payload);
    
    int payloadlen = strlen((const char*)payload);

    int len = MQTTSerialize_publish(buf, buflen, 0, 0, 0, 0, topicString, payload, payloadlen); /* 2 */

    USB.println(F("\n\t\tSending Data"));
    
    for(int i=0; i<3;i++){
      errorWiFi=WIFI_PRO.send( socket_handle, buf, len)!=0;
      if (errorWiFi == 0){
        USB.println(F("\n\t\tSend data OK      "));
        break;
      }else{
        USB.println(F("\n\t\tErrorWiFi calling 'send' function"));
        WIFI_PRO.printErrorCode();
        //disconnectMQTT();
        delay(2000);
        USB.println(F("\n\t\tRetrying"));
        //configureWiFi();
        //connectMQTT();
      }
    }
  }
}


void cleanPayload(){
     for(int j=0; j <100;j++){
      payloadList[0][j]='\0';
  }
}

void sendMessages(){
  if(!WIFI_PRO.isConnected()){
    while(!configureWiFi()){
      delay(1000);
    }
    connectMQTT();
  }
    if(strlen((char *)payloadList[0])>0){
      USB.print(F("\n\t\tPAYLOAD MAYOR A CERO "));
      publish(topicList[0], payloadList[0]);
    }
  //disconnectMQTT();
  cleanPayload();
}

boolean configureWiFi(){
  errorWiFi=1;
  while((errorWiFi = WIFI_PRO.ON(socket))){
    if ( errorWiFi == 0 )
    {
      USB.println(F("\n\tWiFi switched ON"));
      break;
    }
    else
    {
      USB.println(F("\n\tWiFi did not initialize correctly"));
    }
  }

  //////////////////////////////////////////////////
  // 2. Check if connected
  //////////////////////////////////////////////////

  // get actual time
  previous = millis();

  // check connectivity
  while(!WIFI_PRO.isConnected()){
    delay(100);
    USB.print(".");
  }
  status=WIFI_PRO.isConnected();

  if ( status == true )
  {
    USB.print(F("\n\tWiFi is connected OK"));
    USB.print(F("\n\t Time(ms):"));
    USB.println(millis() - previous);

    // get IP address
    errorWiFi = WIFI_PRO.getIP();

    if (errorWiFi == 0)
    {
      USB.print(F("\n\tIP address: "));
      USB.println( WIFI_PRO._ip );
    }
    else
    {
      USB.println(F("\n\tgetIP errorWiFi"));
    }
  }
  else
  {
    USB.print(F("\n\tWiFi is connected ERROR ---"));
    USB.print(F("\n\tTime(ms):"));
    USB.println(millis() - previous);
  }

  // Check if module is connected
  if (status == true)
  {
    ////////////////////////////////////////////////
    // 3.1. Open TCP socket
    ////////////////////////////////////////////////
    errorWiFi = WIFI_PRO.setTCPclient( HOST, REMOTE_PORT, LOCAL_PORT);

    // check response
    if (errorWiFi == 0)
    {
      // get socket handle (from 0 to 9)
      socket_handle = WIFI_PRO._socket_handle;

      USB.print(F("\n\tOpen TCP socket OK in handle: "));
      USB.println(socket_handle, DEC);
    }
    else
    {
      USB.println(F("\n\tError calling 'setTCPclient' function"));
      WIFI_PRO.printErrorCode();
      status = false;
    }
  }
  return status;
}

void connectMQTT(){
  if (status == true)
  {
    MQTTPacket_connectData data = MQTTPacket_connectData_initializer;
    MQTTPacket_willOptions will = MQTTPacket_willOptions_initializer;
    unsigned char buf[200];
    int buflen = sizeof(buf);

    // options
    will.retained = 0;
    will.qos=0;
    data.will = will;
    data.clientID.cstring = (char*)"g2";
    data.keepAliveInterval = 30;
    data.cleansession = 1;
    data.willFlag = 0;
    int len = MQTTSerialize_connect(buf, buflen, &data);
    errorWiFi = WIFI_PRO.send( socket_handle, buf, len);
  }
}

void addFloatField(unsigned char * payload, float value, int field){
  unsigned char aux[18]={'\0'};
  char valueStr[6]={'\0'};
  if( value >= 100){
    dtostrf(value, 3, 6, valueStr);  
  }else if( value >= 10){
    dtostrf(value, 2, 6, valueStr);  
  }else if (value >=0  ){
    dtostrf(value, 1, 6, valueStr);  
  }else if (value>-10){
    dtostrf(value, 1, 6, valueStr);
  }else if (value >-100){
    dtostrf(value, 2, 6, valueStr);
  }else{
    dtostrf(value, 3, 6, valueStr);
  }
  
  if(strlen((char *)payload)>0){
    snprintf((char *)aux, 18, "&field%d=%s", field, valueStr);
  }else{
    snprintf((char *)aux, 18, "field%d=%s", field, valueStr);  
  }
  strcat((char *)payload, (char *)aux);
}

void addIntField(unsigned char * payload, int value, int field){
  unsigned char aux[18]={'\0'};
  if(strlen((char *)payload)>0){
    snprintf((char *)aux, 18, "&field%d=%d", field, value);
  }else{
    snprintf((char *)aux, 18, "field%d=%d", field, value);  
  }
  strcat((char *)payload, (char *)aux);
}

void addStrField(unsigned char * payload, char * value, int field){
  unsigned char aux[18]={'\0'};  
  if(strlen((char *)payload)>0){
    snprintf((char *)aux, 18, "&field%d=%s", field, value);
  }else{
    snprintf((char *)aux, 18, "field%d=%s", field, value);  
  }
  strcat((char *)payload, (char *)aux);
}

void measure(){
  USB.println(F("\n\t-->MEASURING"));
  //----------animal ID Value-----------------------
  strncpy(animalID, ANIMALID,8);
  addStrField(payloadList[0], animalID, 1);
  //----------animal name-----------------------
  strncpy(name, NAME,10);
  addStrField(payloadList[0], name, 2);
  //----------animal type-----------------------
  strncpy(type, TYPE,10);
  addStrField(payloadList[0], type, 3);
  //----------animal Age-----------------------
  age = AGE; //Meses
  addIntField(payloadList[0], age, 4);
  //----------animal position: Latitude-----------------------
  animalLatitude = LATITUDE;
  addFloatField(payloadList[0], animalLatitude, 5);
  //----------animal position: Longitude-----------------------
  animalLongitude = LONGITUDE;
  addFloatField(payloadList[0], animalLongitude, 6);
  //----------animal temperature-----------------------
  //bodytemp = BODYTEMP;
  bodytemp = 1+rand()%(45-15);
  addFloatField(payloadList[0], bodytemp, 7);
  //----------animal steps-----------------------
 // steps = STEPS;
 steps=1+rand()%(9500-2500);
  addIntField(payloadList[0], steps, 8);
  //----------animal weight-----------------------
 // weight = WEIGHT;
 weight = 1+rand()%(350-900);
  addFloatField(payloadList[0], weight, 9);

  //-----------ALERTS----------------------------
  //----------Alerta de temperatura-------------
  if(bodytemp<20 || bodytemp>45){
    addIntField(payloadList[0], 1, 10);
  }else{
    addIntField(payloadList[0], 0, 10);
  }
  //----------Alerta de pasos-------------
  if(steps>15000){
    addIntField(payloadList[0], 1, 11);
  }else{
    addIntField(payloadList[0], 0, 11);
  }
  //----------Alerta de peso-------------
  if((weight/age)<15 || (weight/age)>25){
    addIntField(payloadList[0], 1, 12);
  }else{
    addIntField(payloadList[0], 0, 12);
  }
  
 
  //Temperature
  //addFloatField(payloadList[1], Events.getTemperature(), 1);
  //Humidity
  //addFloatField(payloadList[1], Events.getHumidity(), 2);
  //Pressure
  //addFloatField(payloadList[1], Events.getPressure(), 3);
  //Battery
  //addIntField(payloadList[1], PWR.getBatteryLevel(), 4);
  //if(PWR.getBatteryLevel()<20){
  //  addIntField(payloadList[1], 3, 8);
 
}


void setup()
{
  // init USB port
  USB.ON();
  // store Waspmote identifier in EEPROM memory
  frame.setID( WASPMOTE_ID );
  // init RTC
  USB.println(F("Init RTC"));
  RTC.ON();

  // Setting time
  RTC.setTime("12:07:18:04:13:35:00");
  USB.print(F("RTC was set to this time: "));
  USB.println(RTC.getTime());
  
  strncpy(topicList[0], "smartFarming/animal",20);
  //strncpy(topicList[1], "g2/channels/666894/publish/J8J79SZWTMYLVK09",44);
  
  while(!configureWiFi()){
      delay(1000);
  }
  connectMQTT();
  //waitTime = TIMEOUT;

}


void loop()
{
  USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
  USB.println(RTC.getTime());

  PWR.deepSleep("00:00:00:50", RTC_OFFSET, RTC_ALM1_MODE1);
  USB.ON();
  USB.println(F("Waspmote wakes up"));

  measure();
  sendMessages();
  

}

