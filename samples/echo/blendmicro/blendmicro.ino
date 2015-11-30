#include <SPI.h>
#include <boards.h>
#include <RBL_nRF8001.h>

void setup()
{
  pinMode(13, OUTPUT); // onboard LED
  pinMode(0, OUTPUT);  // external LED on pin-0

  ble_set_name("BlendMicro");
  ble_begin();
}

char recv_data;
void loop()
{
  if(ble_connected()) digitalWrite(13, true);
  else digitalWrite(13, false);

  ble_do_events();

  if ( ble_available() ){
    ble_print("echo>");
    while ( ble_available() ){
      recv_data = ble_read();

      switch(recv_data){ // controll LED
      case 'o':
        digitalWrite(0, true);
        break;
      case 'x':
        digitalWrite(0, false);
        break;
      }

      ble_write(recv_data); // echo data
    }
  }

  delay(100);
}

void ble_print(char *str){
  char i = 0;
  while(char c = str[i]){
    ble_write(str[i]);
    i++;
  }
}
