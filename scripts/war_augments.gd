extends RefCounted
const CARDS = [
 {"id":"warcry","name":"Savaş Çığlığı","tag":"ORDU","rarity":0,"max":3,"desc":"Tüm birlikler %15 daha fazla hasar verir."},
 {"id":"iron_skin","name":"Demir Disiplin","tag":"DAYANIKLILIK","rarity":0,"max":3,"desc":"Birliklerin azami canı %18 artar. Kazanılan can kadar iyileşirler."},
 {"id":"training","name":"Hızlı Eğitim","tag":"EKONOMİ","rarity":0,"max":3,"desc":"Birlik maliyetleri %10 azalır. Eğitim süresi %15 kısalır."},
 {"id":"logistics","name":"Güçlü Lojistik","tag":"EKONOMİ","rarity":0,"max":3,"desc":"Her gelir ödemesinde +4 altın."},
 {"id":"mobilization","name":"Seferberlik","tag":"ORDU","rarity":0,"max":2,"desc":"Nüfus sınırı +4. Daha geniş bir ordu kur."},
 {"id":"march","name":"Hızlı İntikal","tag":"BASKIN","rarity":0,"max":3,"desc":"Birlikler %14 daha hızlı hareket eder; önlerindeki dostlarını geçmezler."},
 {"id":"weaponsmiths","name":"Usta Silahçılar","tag":"SALDIRI HIZI","rarity":1,"max":3,"desc":"Saldırı animasyonu ve vuruş aralığı %14 hızlanır."},
 {"id":"marksmen","name":"Keskin Nişancılar","tag":"OKÇU","rarity":1,"max":2,"desc":"Okçulara %12 menzil ve %8 hasar. Tanklar hâlâ oklara dirençlidir."},
 {"id":"spoils","name":"Ganimet Avcıları","tag":"EKONOMİ","rarity":1,"max":3,"desc":"Düşman başına altın ödülü %35 artar."},
 {"id":"fortification","name":"İstihkâm Ustaları","tag":"SAVUNMA","rarity":1,"max":2,"desc":"Sunağa +150 azami can ve iyileşme; savunma hasarına %20."},
 {"id":"siege","name":"Kuşatma Ustaları","tag":"BARBAR","rarity":1,"max":2,"desc":"Barbarlara %22 hasar. Yakındaki ikinci hedefe %25 sıçrama hasarı."},
 {"id":"medics","name":"Saha Hekimleri","tag":"DAYANIKLILIK","rarity":2,"max":2,"desc":"4 saniyedir hasar almayan birlikler saniyede %1.2 can yeniler."},
 {"id":"critical","name":"Ölümcül Vuruş","tag":"KRİTİK","rarity":2,"max":2,"desc":"%10 kritik şansı. Kritik vuruşlar 1.8 kat hasar verir."},
 {"id":"war_economy","name":"Savaş Ekonomisi","tag":"EKONOMİ","rarity":2,"max":1,"desc":"Hemen 180 altın kazan; her gelir ödemesine +2 altın."},
 {"id":"bulwark","name":"Canlı Siper","tag":"BARBAR + OKÇU","rarity":1,"max":2,"desc":"Barbarlara %20 can. Yakınlarındaki dostlara gelen ok hasarı %15 azalır."},
 {"id":"hunter","name":"Arka Saf Avcısı","tag":"AKINCI","rarity":1,"max":2,"desc":"Akıncıların okçulara hasarı ayrıca %25 artar."},
 {"id":"blood_oath","name":"Kan Yemini","tag":"YAKIN DÖVÜŞ","rarity":2,"max":2,"desc":"Akıncı ve barbarlar birliklere verdikleri hasarın %15'i kadar iyileşir."},
 {"id":"last_stand","name":"Son Direniş","tag":"ORDU","rarity":2,"max":1,"desc":"Her birlik ilk kez %25 canın altına düştüğünde, hayattaysa azami canının %30'unu geri kazanır."}
]
var team := 0
var stacks: Dictionary = {}
var offered: Array = []
var rerolls := 1
var rng := RandomNumberGenerator.new()
func _init() -> void: rng.randomize()
func count(id: String) -> int: return stacks.get(id,0)
func roll(tier: int = 0) -> Array:
	var pool: Array = CARDS.filter(func(c): return c.rarity == tier and count(c.id)<c.max)
	# Repeatable fallback belongs to the same tier on both sides.
	for fallback in [
		{"id":"reserve_"+str(tier),"name":"Savaş Hazinesi","tag":"ANLIK ALTIN","rarity":tier,"max":999,"desc":"Hemen %d altın kazan." % [80,140,240][tier]},
		{"id":"repair_"+str(tier),"name":"Acil Onarım","tag":"SUNAK","rarity":tier,"max":999,"desc":"Sunağı %d can iyileştir." % [100,180,300][tier]},
		{"id":"vigor_"+str(tier),"name":"Taze Kuvvet","tag":"ORDU","rarity":tier,"max":999,"desc":"Mevcut ordunun kayıp canının %d%% kadarını iyileştir." % [25,45,70][tier]}]:
		if pool.size()<3:pool.append(fallback)
	var result: Array = []
	while result.size()<3 and not pool.is_empty():
		var i := rng.randi_range(0,pool.size()-1)
		result.append(pool[i]);pool.remove_at(i)
	offered=result
	return offered
func cost_multiplier() -> float: return pow(0.9,count("training"))
func reward_amount() -> int: return roundi(15*pow(1.35,count("spoils")))
func apply_unit(unit: BattleUnit) -> void:
	if unit.team!=team or unit.is_base: return
	unit.apply_damage_multiplier(pow(1.15,count("warcry")))
	unit.apply_health_multiplier(pow(1.18,count("iron_skin")))
	unit.move_speed *= pow(1.14,count("march"))
	var speed: float = pow(1.14,count("weaponsmiths"))
	unit.attack_duration /= speed;unit.attack_contact /= speed;unit.attack_cooldown /= speed
	if unit.role==1:
		unit.attack_range *= pow(1.12,count("marksmen"));unit.damage *= pow(1.08,count("marksmen"))
	if unit.role==2:
		unit.damage *= pow(1.22,count("siege"));unit.apply_health_multiplier(pow(1.2,count("bulwark")))
func choose(game: Node,index: int) -> bool:
	if index<0 or index>=offered.size(): return false
	var card: Dictionary = offered[index]
	if count(card.id)>=card.max:return false
	stacks[card.id]=count(card.id)+1
	if card.id.begins_with("reserve_"):
		if team==0:game.player_gold += [80,140,240][card.rarity]
		else:game.enemy_gold += [80,140,240][card.rarity]
	if card.id.begins_with("repair_"):
		var base: BattleUnit = game.blue_base if team==0 else game.red_base
		base.health=minf(base.max_health,base.health+[100,180,300][card.rarity])
	if card.id.begins_with("vigor_"):
		for u in game.units:
			if is_instance_valid(u) and not u.dead and u.team==team and not u.is_base:
				u.health+=(u.max_health-u.health)*[0.25,0.45,0.7][card.rarity]
	for unit in game.units:
		if not is_instance_valid(unit) or unit.dead or unit.team!=team or unit.is_base:continue
		match card.id:
			"warcry":unit.apply_damage_multiplier(1.15)
			"iron_skin":unit.apply_health_multiplier(1.18)
			"march":unit.move_speed*=1.14
			"weaponsmiths":unit.attack_duration/=1.14;unit.attack_contact/=1.14;unit.attack_cooldown/=1.14
			"marksmen":
				if unit.role==1:unit.attack_range*=1.12;unit.damage*=1.08
			"siege":
				if unit.role==2:unit.damage*=1.22
			"bulwark":
				if unit.role==2:unit.apply_health_multiplier(1.2)
	match card.id:
		"mobilization":
			game.team_caps[team]+=4
			game.population_cap=game.team_caps[0]
		"logistics":game.team_income[team]+=4
		"war_economy":
			if team==0:game.player_gold+=180
			else:game.enemy_gold+=180
			game.team_income[team]+=2
		"fortification":
			var base: BattleUnit = game.blue_base if team==0 else game.red_base
			base.max_health+=150;base.health+=150;base.damage*=1.2
	if team==0:game.feedback_label.text=card.name+" seçildi"
	return true
