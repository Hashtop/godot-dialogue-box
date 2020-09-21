extends Node2D

var answer = 0
var dialog_or_choice
var dialogue_num
var old_lang = Global.lang

#Salva todas as strings.
var strings = ["", ""]

func _ready() -> void:
	$Control/Popup/FileDialog.set_filters(PoolStringArray(["*.dialog ; DIALOGUE Files","*.choice ; CHOICE Files"]))
	var f = File.new()
	f.open("res://strings/global/hm.secret", File.READ)
	var index = 1
	while f.eof_reached() == false:
		var line = f.get_line()
		
		match index:
			1:
				strings[0] = line
			2:
				strings[1] = line
		
		index += 1
	f.close()
	
	answer = 1
	
#	Eu substituo o "{b}" pelo "\n", porque se eu utilizar o "\n" direto, não funciona. Faze oq né.
	if Global.lang == "pt":
		$Control/Help.bbcode_text = strings[0].replace("{b}", "\n")
	else:
		$Control/Help.bbcode_text = strings[1].replace("{b}", "\n")

func _on_Button_pressed() -> void:
	$Control/Popup/FileDialog.popup_centered_minsize(Vector2(400, 400))


func _on_FileDialog_file_selected(path: String) -> void:
	var type = path.get_extension()
	var number = path.get_file()
	var language = path
	
	if language.find("en", 0) != -1:
		Global.lang = "en"
	else:
		Global.lang = "pt"
	
	number.erase(number.find(".", 0), 1)
	number.erase(0, 1)
	number = number.replace(type, "")
	
	$Control/Help.hide()
	$Control/Button.hide()
	$Control/Popup/FileDialog.hide()
	
	match type:
		"choice":
			$Control/TextBox.current_choice = number
			$Control/TextBox.choice_start()
		"dialog":
			$Control/TextBox.dialogue_start(number)

func dialogue_ended():
	$Control/Button.show()
	$Control/Help.show()
	Global.lang = old_lang
