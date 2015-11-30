// read AD converter sample for BLENano

#include <stdlib.h>

#define TXRX_BUF_LEN 20
#define TX_POWER 4 // [-40, -20, -16, -12, -8, -4, 0, 4]

static const uint8_t ble_name[] = "BLENano";

BLE ble;
Ticker ticker;

static const uint8_t service_uuid[]    = {0x71, 0x3D, 0, 0, 0x50, 0x3E, 0x4C, 0x75, 0xBA, 0x94, 0x31, 0x48, 0xF1, 0x8D, 0x94, 0x1E};
static const uint8_t service_tx_uuid[] = {0x71, 0x3D, 0, 3, 0x50, 0x3E, 0x4C, 0x75, 0xBA, 0x94, 0x31, 0x48, 0xF1, 0x8D, 0x94, 0x1E};
static const uint8_t service_rx_uuid[] = {0x71, 0x3D, 0, 2, 0x50, 0x3E, 0x4C, 0x75, 0xBA, 0x94, 0x31, 0x48, 0xF1, 0x8D, 0x94, 0x1E};

uint8_t tx_value[TXRX_BUF_LEN] = {0,};
uint8_t rx_value[TXRX_BUF_LEN] = {0,};
uint8_t buf[TXRX_BUF_LEN];

GattCharacteristic tx_characteristic(service_tx_uuid, tx_value, 1, TXRX_BUF_LEN, GattCharacteristic::BLE_GATT_CHAR_PROPERTIES_WRITE | GattCharacteristic::BLE_GATT_CHAR_PROPERTIES_WRITE_WITHOUT_RESPONSE );
GattCharacteristic rx_characteristic(service_rx_uuid, rx_value, 1, TXRX_BUF_LEN, GattCharacteristic::BLE_GATT_CHAR_PROPERTIES_NOTIFY);
GattCharacteristic *characteristics[] = {&tx_characteristic, &rx_characteristic};
GattService service(service_uuid, characteristics, sizeof(characteristics) / sizeof(GattCharacteristic *));

static void disconnectionCallBack(Gap::Handle_t handle, Gap::DisconnectionReason_t reason){
  ble.startAdvertising();
}

void ble_loop(){
  if(ble.getGapState().connected){
    digitalWrite(13, false); // turn ON on-board LED
    char buf[8];
    sprintf(buf, "%d", analogRead(A4));
    ble.updateCharacteristicValue(rx_characteristic.getValueAttribute().getHandle(), (const uint8_t *)buf, 8);
  }
  else{
    digitalWrite(13, true);  // turn OFF
  }
}

void setup(){
  ble.init();
  ble.onDisconnection(disconnectionCallBack);

  ble.accumulateAdvertisingPayload(GapAdvertisingData::BREDR_NOT_SUPPORTED);
  ble.accumulateAdvertisingPayload(GapAdvertisingData::SHORTENED_LOCAL_NAME,
                                   (const uint8_t *)ble_name, sizeof(ble_name) - 1);

  ble.setAdvertisingType(GapAdvertisingParams::ADV_CONNECTABLE_UNDIRECTED);
  ble.addService(service);
  ble.setDeviceName(ble_name);

  ble.setTxPower(TX_POWER);
  ble.setAdvertisingInterval(160);
  ble.setAdvertisingTimeout(0);
  ble.startAdvertising();

  ticker.attach(&ble_loop, 0.1);
}

void loop(){
  ble.waitForEvent();
}
