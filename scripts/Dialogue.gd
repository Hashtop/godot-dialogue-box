extends Control

#Define se o jogador vai conseguir controlar a escolha ou o diálogo.
export var can_control = 1

#Define se ele está lendo os diálogos.
var reading = 0

#Salva qual diálogo ele está lendo no momento.
var current_dialogue = 0

#Salva todos os textos do arquivo de diálogo.
var all_text = []

#Mostra a página do array em que ele está no momento.
var current_text = 0

#Puxa todos os nomes que podem aparecer na caixa de texto, dependendo da línguagem que foi escolhida.
var all_names = []

#Salva a ordem em que os personagens vão falando.
var talking_order = []

#Salva o id que está falando no momento. (Serve para mostrar os nomes na caixa de texto)
var current_talking = 0

#Diz se no diálogo atual tem ou não uma escolha a ser feita no final.
var current_choice = 0

#Salva todas as strings da escolha. (Título primeiro e as duas escolhas depois)
var choice_strings = ["", "", ""]

#Define qual é a sequência de diálogo que cada escolha leva.
var choice_paths = [0, 0]

#Salva no primeiro index se vai vai ativar uma quest (caso sim, qual)
#e no segundo qual resposta ativa a quest
var start_quest = [0, 0]

#Mostra qual opção de escolha está selecionada no momento.
var currently_selected = 1

const DEFAULT_WAIT_TIME = 0.05


func dialogue_start(dialogue_seq):
#	Define o diálogo atual, baseado no número que foi retornado na função.
	current_dialogue = int(dialogue_seq)
	
#	Verifica se os nomes já foram definidos, se sim, não vai fazer nada
#	e já passará direto pro for.
	if all_names == []:
		var f = File.new()
		f.open("res://strings/" + str(Global.lang) + "/special/names.list", File.READ)
		var index = 1
		while not f.eof_reached():
			var line = f.get_line()
			
			if all_names.size() == 0:
				all_names.insert(all_names.size(), str(line))
				all_names.resize(1)
			else:
				all_names.insert(all_names.size(), str(line))
				all_names.resize(all_names.size())
			
			index += 1
		
		f.close()
	
#	Enquanto ele estiver configurando o diálogo, ele pega todos os textos do diálogo, 
#	define a sequência em que aparece os nomes, define se tem ou não escolha, 
#	define as strings das escolhas, se ela inicia uma quest e, se sim, qual
#	e define também pra qual sequência de diálogo cada escolha leva.
#	Após acabar de ler o diálogo no for, vai ter um if que vai veríficar se têm ou não escolha,
#	Se não tiver ele só acaba a execução do diálogo.
	for state in ["config", "reading_dialogue"]:
		match state:
			"config":
#				Código aqui.
				var f = File.new()
				f.open("res://strings/" + str(Global.lang) + "/dialogues/d" + str(dialogue_seq) + ".dialog", File.READ)
				var index = 1
				while not f.eof_reached():
					var line = f.get_line()
					
#					Verifica se a primeira linha têm um número maior que 0,
#					pra definir se tem ou não uma escolha e o número da escolha.
					if index == 1:
						if int(line) > 0:
							current_choice = int(line)
					
					#Verifica só as linhas 3 pra frente.
					if index > 2:
						var current_char = 0
						var full_id_number = ""
						
#						Verifica o primeiro caractere e, caso ele seja um número válido,
#						adiciona o numero a uma string (que depois será convertida pra int,
#						para que se possa adicionar o id do personagem no array da ordem).
						while line.substr(current_char, 1).is_valid_integer() == true:
							full_id_number += line.substr(current_char, 1)
							
							current_char += 1
						
#						Adiciona o id de personagem atual ao array talking_order.
						if talking_order.size() == 0:
							talking_order.insert(talking_order.size(), int(full_id_number))
							talking_order.resize(1)
						else:
							talking_order.insert(talking_order.size(), int(full_id_number))
							talking_order.resize(talking_order.size())
						
#						Adiciona o texto atual (formatado sem o id) ao array all_text.
						if all_text.size() == 0:
							all_text.insert(all_text.size(), str(line.replace(full_id_number + ": ", "")))
							all_text.resize(1)
						else:
							all_text.insert(all_text.size(), str(line.replace(full_id_number + ": ", "")))
							all_text.resize(all_text.size())
					
					index += 1
				
				f.close()
				
#			Inicia a leitura do diálogo na função _process.
#			Reinicia o current_text e o número de carácteres visíveis do texto.
#			E toca a animação de entrada da caixa de texto também.
			"reading_dialogue":
				$Text.visible_characters = 0
				current_text = 0
				current_talking = talking_order[current_text]
				$Name.bbcode_text = all_names[int(current_talking)]
				$TextBoxAnims.play("OpenTextBox")
				
				reading = 1

func anim_ended(anim):
	match (anim):
		"OpenTextBox":
			text_filter("filter")
		
		"CloseTextBox":
			all_text.resize(0)
			talking_order.resize(0)
			if current_choice != 0:
			
#				Só acontece se tiver uma escolha a ser feita.
				choice_start()
			else:
				match get_tree().get_current_scene().get_name():
					"TestRoom":
						get_tree().get_root().get_node("TestRoom").dialogue_ended()
				reading = 0
		
		"ChoiceStart":
			$T.interpolate_property($ChoiceAnswer1, "rect_position",
					$ChoiceAnswer1.rect_position, $ChoiceAnswer1.rect_position + Vector2(20, 0), 0.25,
					Tween.TRANS_EXPO, Tween.EASE_OUT)
			$T.start()
			reading = 2
		
		"ChoiceEnd":
			if start_quest[0] == 0:
				current_choice = 0
				dialogue_start(choice_paths[currently_selected - 1])
			else:
#				Acontece só se o que o jogador selecionou ativava a quest.
#				E se a quest não foi ativada.
				if start_quest[1] == currently_selected or start_quest[1] == 3:
					if Quests.active_quests.has(start_quest[0]) == false:
						if Quests.active_quests.size() == 0:
							Quests.active_quests.insert(0, start_quest[0])
							Quests.active_quests.resize(1)
						else:
							if Quests.active_quests.size() != 3:
								Quests.active_quests.insert(Quests.active_quests.size(), start_quest[0])
								Quests.active_quests.resize(Quests.active_quests.size())
				
				current_choice = 0
				dialogue_start(choice_paths[currently_selected - 1])

func text_filter(action):
	match action:
		
#		Filtra o texto pra verificar se existe um comando no próximo caráctere.
		"filter":
#			Define o texto da caixa de texto, removendo os comandos de dentro do texto.
			var formatted_text = all_text[current_text]
			
#			Filtra os "{W" e seus respectivos "}".
			while formatted_text.find("{W", 0) > -1:
				
#				Pega a posição onde inicia o comando e a posição onde termina com as "}".
				var init_pos = formatted_text.find("{W", 0)
				var end_pos = formatted_text.find("}", init_pos)
				
				formatted_text.erase(init_pos, (end_pos + 1) - init_pos)
			
#			Filtra os "{V" e seus respectivos "}".
			while formatted_text.find("{V", 0) > -1:
				
#				Pega a posição onde inicia o comando e a posição onde termina com a "}".
				var init_pos = formatted_text.find("{V", 0)
				var mid_pos = formatted_text.find("=", init_pos)
				var end_pos = formatted_text.find("}", mid_pos)
				
				formatted_text.erase(end_pos, 1)
				formatted_text.erase(init_pos, (mid_pos + 1) - init_pos)
				
			
			$Text.bbcode_text = formatted_text.replace("{b}", "\n")
			
#			Remove os comandos do bbcode do array all_text.
			while all_text[current_text].find("[", 0) > -1:
				var formatted_var = all_text[current_text]
				var init_pos = formatted_var.find("[", 0)
				var end_pos = formatted_var.find("]", init_pos)
				
				formatted_var.erase(init_pos, (end_pos + 1) - init_pos)
				all_text[current_text] = formatted_var
			
			text_filter("check")
			
		"check":
#			Se ele detectar nos próximos 2 carácteres "{W", o cooldown será ativado.
			if all_text[current_text].substr($Text.get_visible_characters(), 2) == "{W":
				var cooldown_time = all_text[current_text]
				var init_pos = cooldown_time.find("{W", 0)
				var end_pos = cooldown_time.find("}", init_pos)
				var full_size = (end_pos + 1) - init_pos
				
				
				cooldown_time = cooldown_time.substr(init_pos + 2, end_pos - (init_pos + 2))
				
				$CooldownTimer.wait_time = float(cooldown_time)
				$CooldownTimer.start()
				
#				Apaga a ocorrência do comando atual na variável.
				var edited_var_text = all_text[current_text]
				edited_var_text.erase(init_pos, full_size)
				all_text[current_text] = edited_var_text
				
			else:
#				Se ele encontrar um "{V", a velocidade em que o texto é mostrado muda,
#				até que seja encontrado uma "}", que volta a velocidade ao normal.
				if all_text[current_text].substr($Text.get_visible_characters(), 2) == "{V":
					var text_velocity = all_text[current_text]
					var init_pos = text_velocity.find("{V", 0)
					var mid_pos = text_velocity.find("=", init_pos)
					
					text_velocity = text_velocity.substr(init_pos + 2, mid_pos - (init_pos + 2))
					
					$CharTimerText.wait_time = float(text_velocity)
					$CharTimerText.start()
					
#					Remove parte do comando do texto, deixando só a "}".
					var edited_var_text = all_text[current_text]
					edited_var_text.erase(init_pos, (mid_pos + 1) - init_pos)
					all_text[current_text] = edited_var_text
					
				else:
					if all_text[current_text].substr($Text.get_visible_characters(), 1) == "}":
						if $CharTimerText.wait_time != DEFAULT_WAIT_TIME:
							$CharTimerText.wait_time = DEFAULT_WAIT_TIME
							$CharTimerText.start()
							
#							Remove a "}" do texto.
							var edited_var_text = all_text[current_text]
							edited_var_text.erase($Text.get_visible_characters(), 1)
							all_text[current_text] = edited_var_text
					else:
						$CharTimerText.start()

func _process(delta: float) -> void:
	match reading:
		1:
			get_keys("text_box")
		2:
			get_keys("choice")
		3:
			if $T.is_active() == false and $T2.is_active() == false:
				$TextBoxAnims.play("ChoiceEnd")
				reading = 0
	

func get_keys(type):
	if can_control == 1:
		match type:
			"text_box":
				if Input.is_action_just_pressed("ui_accept"):
					text_box_action()
			
			"choice":
				if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
					choice_actions("select")
				else:
					if Input.is_action_just_pressed("ui_accept"):
						choice_actions("accept")

func text_box_action():
	if $Text.visible_characters != $Text.get_total_character_count():
		$Text.visible_characters = $Text.get_total_character_count()
	else:
		if $Text.visible_characters == $Text.get_total_character_count():
			
#			Se o texto atual não chegou no fim dos textos do array, passa pra outra página.
			if current_text < all_text.size() - 1:
				current_text += 1
				$Text.visible_characters = 0
				current_talking = talking_order[current_text]
				$Name.bbcode_text = all_names[int(current_talking)]
				$Text.bbcode_text = all_text[current_text]
				$CharTimerText.wait_time = DEFAULT_WAIT_TIME
				text_filter("filter")
			else:
				
#				Acaba o diálogo e para todos os timers, para evitar conflitos.
				$CharTimerText.stop()
				$CooldownTimer.stop()
				$TextBoxAnims.play("CloseTextBox")
				reading = -1
				

func choice_actions(key):
	match key:
		"select":
			match currently_selected:
				1:
					$ChoiceAnswer1.modulate = Color(1, 1, 1, 1)
					$ChoiceAnswer2.modulate = Color(1, 1, 0, 1)
					
					$T.interpolate_property($ChoiceAnswer1, "rect_position",
							Vector2(84, 576), Vector2(64, 576), 0.25,
							Tween.TRANS_EXPO, Tween.EASE_OUT)
					$T.start()
					
					$T2.interpolate_property($ChoiceAnswer2, "rect_position",
							Vector2(64, 704), Vector2(84, 704), 0.25,
							Tween.TRANS_EXPO, Tween.EASE_OUT)
					$T2.start()
					
					currently_selected = 2
				
				2:
					$ChoiceAnswer1.modulate = Color(1, 1, 0, 1)
					$ChoiceAnswer2.modulate = Color(1, 1, 1, 1)
					
					$T.interpolate_property($ChoiceAnswer1, "rect_position",
							Vector2(64, 576), Vector2(84, 576), 0.25,
							Tween.TRANS_EXPO, Tween.EASE_OUT)
					$T.start()
					
					$T2.interpolate_property($ChoiceAnswer2, "rect_position",
							Vector2(84, 704), Vector2(64, 704), 0.25,
							Tween.TRANS_EXPO, Tween.EASE_OUT)
					$T2.start()
					
					currently_selected = 1
	
		"accept":
			$T.interpolate_property($ChoiceAnswer1, "rect_position",
					$ChoiceAnswer1.rect_position, Vector2(64, 576), 0.5,
					Tween.TRANS_ELASTIC, Tween.EASE_OUT)
			$T.start()
			
			$T2.interpolate_property($ChoiceAnswer2, "rect_position",
					$ChoiceAnswer2.rect_position, Vector2(64, 704), 0.5,
					Tween.TRANS_ELASTIC, Tween.EASE_OUT)
			$T2.start()
			
			reading = 3

func cooldown_ended() -> void:
	text_filter("check")

func char_timeout() -> void:
	var default_volume = -14
	if $Text.visible_characters != $Text.get_total_character_count():
		if $CharTimerText.wait_time > DEFAULT_WAIT_TIME:
			$Audio/TextBoxText.volume_db = default_volume - 3
			$Audio/TextBoxText.pitch_scale = 2
			$Audio/TextBoxText.play()
		else:
			if $CharTimerText.wait_time == DEFAULT_WAIT_TIME:
				$Audio/TextBoxText.volume_db = default_volume
				$Audio/TextBoxText.pitch_scale = 1
				$Audio/TextBoxText.play()
			else:
				$Audio/TextBoxText.volume_db = default_volume + 3
				$Audio/TextBoxText.pitch_scale = 0.8
				$Audio/TextBoxText.play()
		$Text.visible_characters += 1
		text_filter("check")

func choice_start():
	var f = File.new()
	f.open("res://strings/" + str(Global.lang) + "/choices/c" + str(current_choice) + ".choice", File.READ)
	var index = 1
	while not f.eof_reached():
		var line = f.get_line()
		
		match index:
			1:
#				A quest que vai ativar (se tiver quest pra ativar).
				start_quest[0] = int(line)
			2:
#				Qual resposta ativa a quest.
#				0 pra nenhuma, 1 pra resposta 1, 2 pra resposta 2
#				e 3 pras duas respostas ativarem a quest.
				start_quest[1] = int(line)
			3:
#				Título da escolha.
				choice_strings[0] = line
			4:
#				Texto da resposta 1.
				choice_strings[1] = line
			5:
#				Texto da resposta 2.
				choice_strings[2] = line
			6:
#				Qual sequência de diálogo será chamada, caso a resposta seja a 1.
				choice_paths[0] = int(line)
			7:
#				Qual sequência de diálogo será chamada, caso a resposta seja a 2.
				choice_paths[1] = int(line)
		
		index += 1
	
	f.close()
	
	$ChoiceTitle.bbcode_text = "[center]" + choice_strings[0].replace("{b}", "\n")
	$ChoiceAnswer1.bbcode_text = "[center]" + choice_strings[1].replace("{b}", "\n")
	$ChoiceAnswer2.bbcode_text = "[center]" + choice_strings[2].replace("{b}", "\n")
	
	$TextBoxAnims.play("ChoiceStart")
