extends Node

var bluetooth_manager: BluetoothManager
#Nome padrão para conexão
@export var target_device_name: String = "teste_blu"
var device: BleDevice

const UUID_SERVICO = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
const UUID_CHAR    = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
	
#Variável global para acesso a leitura
@export var posicao: String = "3"

#Função para a conexão ao dispositivo

func conectar(nome_disp: String):
	#cria uma nova instância do nó bluetooth manager
	bluetooth_manager = BluetoothManager.new()
	#adição do nó bluetooth manager
	add_child(bluetooth_manager)
	#Com a inicialização do adaptador bluetooth, a função _on_initialized é chamada
	bluetooth_manager.adapter_initialized.connect(_on_initialized)
		
	#Com a descoberta de dispositivos pelo scan, a função _on_device_found é chamada
	bluetooth_manager.device_discovered.connect(_on_device_found)
		
	#Com o fim do scan, a função _on_scan_found é chamada
	bluetooth_manager.scan_stopped.connect(_on_scan_done)
	
	#nome a ser usado na conexão
	if nome_disp!="":
		target_device_name = nome_disp

	#Inicializa o adaptador bluetooth
	bluetooth_manager.initialize()

func _on_initialized(success: bool, error: String):
	#o erro sai em mandarimkk
	#faz um scan de dispositivos por 5 segundos
	if success:
		bluetooth_manager.start_scan(5.0)
	else:
		print(error)
		print("Erro na inicialização do bluetooth!")

func _on_device_found(info: Dictionary):
	#Comparação entre o nome dos dispositivos encontrados com o dispositivo alvo
	var name_device = info.get("name", "")
	print(info.get("name",""))
	if name_device == target_device_name:
		print("Dispositivo alvo encontrado!")
		bluetooth_manager.stop_scan()	
		#Com o dispositivo encontrado a função connect_to_target é chamada
		connect_to_target(info.get("address"))


func _on_scan_done():
	print("Scan completo.")

func connect_to_target(address: String):
	disconnect_esp()
	#A variável device do tipo BleDevice conecta ao endereço fornecido
	device = bluetooth_manager.connect_device(address)
	if device:
		#Se o dispositivo existe, e está conectado, a função _on_connected é chamada
		device.connected.connect(_on_connected)
		
		#Com os serviços descobertos, a função _on_services_found é chamada
		device.services_discovered.connect(_on_services_found)
			
		#Com novas notificações da característica alvo, a função _on_data_update é chamada
		device.characteristic_notified.connect(_on_data_update)
		
		#Conexão assíncrona ao dispositivo
		device.connect_async()
		
func _on_services_found(services:Array):
	#Usamos a função subscribe_characteristic para inscrever a notificações 
	#da característica que temos como alvo
	print("Serviços encontrados.")
	print(services)
	device.subscribe_characteristic(UUID_SERVICO, UUID_CHAR)

func _on_data_update(char_uuid: String, data: PackedByteArray):
	if char_uuid.to_lower() == UUID_CHAR.to_lower():
		var leitura = data.get_string_from_utf8()
		
		#Armazenamento global da leitura
		Bluetooth.posicao = leitura
		
		print("Dado recebido: ", leitura)

func _on_connected():
	#Aqui é realizada a descoberta dos serviços
	print("Dispositivo Conectado!")
	device.discover_services()
	
#Função para desconexão segura do dispositivo
func disconnect_esp():
	if device:
		device.disconnect()

#Função para desinscrição da característica e desconexão
func _exit_tree():
	device.unsubscribe_characteristic(UUID_SERVICO,UUID_CHAR)
	disconnect_esp()
	
