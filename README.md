# Fetih Game — Godot prototipi

Godot 4.7.2 ile hazırlanan fare ağırlıklı 3D savaş prototipi.

- Üç birlik kartı: Hızlı, Menzilli, Tank
- Beş paralel sıra ve dost birlik aralığı
- Saldır / üs önünde savun emri
- Görünür ok ve çarpışmada hasar
- Ölüm animasyonundan sonra yavaş küçülüp zemine inme
- Ekonomi, nüfus, öldürme ödülü ve iki üs
- 30 saniyede bir tüm savaşı durduran kalıcı gelişim kartı
- Zafer/Yenilgi ve yeniden başlatma

Hazır varlıklar KayKit ve Quaternius CC0 paketlerinden gelir. Lisans kopyaları `licenses/` klasöründedir.

## Geçiş durumu — 29 Eylül 2026

Unreal prototipi silinmedi ve referans olarak korunuyor. Aktif geliştirme bu Godot projesinde devam ediyor. İlk çalışma testi şu sonucu verdi:

```json
{"damage_card_multiplier":1.2,"death_cleanup":true,"full_card_pause":true,"lanes":5,"minimum_spawn_spacing":1.05,"passed":true,"projectile_damage":true}
```

KayKit Rogue ve Quaternius doğa FBX dosyaları projeye aktarıldı. Ücretsiz KayKit Adventurers 2.0 paketindeki iri Barbarian ve diğer rol adayları sonraki karakter eşleme adımıdır.

## Planlı köy yerleşimi

Güncel sürümü Oyunu Baslat.cmd ile veya Godot'ta F5 ile açın. Köy meydanındaki sunak maçın hedefidir; birlikler arka kışladan çıkar. Ayrıntılar: docs/PLANNED_VILLAGE.md.

