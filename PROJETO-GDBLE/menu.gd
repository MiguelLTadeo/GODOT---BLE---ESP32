extends Control

@onready var input_nome = $VBoxContainer/LineEdit
@onready var leitura_label = $VBoxContainer/LEITURA

@onready var padrao_label = $Label_Padrao


func _process(_delta: float) -> void:
	leitura_label.text = "LEITURA: "+Bluetooth.posicao
	padrao_label.text = "DISPOSITIVO PADRÃO: "+Bluetooth.target_device_name

func _on_conectar_esp_32_miguel_pressed() -> void:
	var nome_disp = input_nome.text
	print("Nome: ", nome_disp)
	Bluetooth.conectar(nome_disp)

func _on_desconectar_pressed() -> void:
	Bluetooth._exit_tree()
