#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- UUIDs ---
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// --- Objetos e Variáveis Globais ---
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
unsigned long lastUpdate = 0;

// --- Classe de Callbacks para Conexão ---
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

void setup() {
  Serial.begin(115200);
  
  // Inicializa o dispositivo
  BLEDevice::init("teste_blu");

  // Cria o Servidor BLE
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Cria o Serviço
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Cria a Característica com NOTIFY
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY 
                    );
  
  // Adiciona o descritor 2902 (Obrigatório para Notify em muitos clientes)
  pCharacteristic->addDescriptor(new BLE2902());

  // Inicia o Serviço
  pService->start();

  // Configura e inicia o Advertising (Visibilidade)
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE Ativo. Aguardando conexão...");
}

void loop() {
  if (deviceConnected) {
    BLEDescriptor *pDesc = pCharacteristic->getDescriptorByUUID("2902");
    uint8_t* descValue = pDesc->getValue();

    // Verifica se o bit 0 (Notificação) está em 1
    bool isSubscribed = (descValue[0] & 0x01);
    if(isSubscribed) {
      if (millis() - lastUpdate > 30) { // Envia a cada 1 segundo
        lastUpdate = millis();

       // Exemplo de dado: Coordenadas simuladas  
        String texto = String(random(0, 500)) + "," + String(random(0, 500));
      
        // Define o valor e envia a notificação
        pCharacteristic->setValue(texto.c_str());
          pCharacteristic->notify(); 
        
        Serial.print("Notificação enviada: ");
        Serial.println(texto);
      }
    }
  }
  // 1. Envio de dados via Notify
 

  // 2. Gerenciamento de Desconexão (Reinicia o Advertising)
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Tempo para o stack resetar
    pServer->startAdvertising(); 
    Serial.println("Dispositivo desconectado. Reiniciando advertising...");
    oldDeviceConnected = deviceConnected;
  }
  
  // Atualiza o estado da conexão
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("Dispositivo conectado!");
  }
}