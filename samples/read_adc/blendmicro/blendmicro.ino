#include <SPI.h>
#include <boards.h>
#include <RBL_nRF8001.h>

void setup()
{
  ble_set_name("BlendMicro");
  ble_begin();
}

void loop()
{
  ble_do_events();

  if(ble_connected()){
    ble_printInt(analogRead(0));
    pinMode(13, true);
    digitalWrite(13, true);
  }
  else{
    pinMode(13, false);
    digitalWrite(13, false);
  }

}

void ble_print(char *str){
  char i = 0;
  while(char c = str[i]){
    ble_write(str[i]);
    i++;
  }
}

char buf[12];
void ble_printInt(int num){
  ble_print(itoa(num, buf, 10));
}
