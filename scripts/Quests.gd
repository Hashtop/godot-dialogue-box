extends Node

#Salva todas as quests ativas fora de ordem (suportando no máximo 3 quests)
var active_quests = []
#Salva o progresso de cada quest em ordem de número.
#Se você quiser olhar o progresso da quest 4, procure no index 4
#O index 0 não vai ter nenhuma quest. REPITO. NENHUMA QUEST USARÁ O NÚMERO 0.
var quest_progress =  ["Inexistente", 0, 0, 0]
#Salva o progresso máximo de cada quest
var max_quest_progress = ["Inexistente", 1, 20, 3]
#Salva todas as quests finalizadas fora de ordem
var finished_quests = []

func end_quest(quest_number):
	if active_quests.has(quest_number):
		var quest_pos = active_quests.find(quest_number, 0)
		
		active_quests.remove(quest_pos)
		if finished_quests.size() == 0:
			finished_quests.insert(0, quest_number)
			finished_quests.resize(1)
		else:
			finished_quests.insert(finished_quests.size(), quest_number)
			finished_quests.resize(finished_quests.size())
		
