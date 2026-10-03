# Referans vadi haritası — 29 Eylül 2026

Hedef: kullanıcının iki kale, nehir vadisi ve uzun taş köprü görselindeki yerleşim ve atmosfer.
Bu bir 3D uyarlamadır; görselle birebir eşleşme veya sanat kalitesi otomatik testlerden çıkarılamaz.

## Çalıştırma ve kamera

Godot'ta çalışan oyunu F8 ile durdurup F5 ile yeniden başlatın. Proje Forward+ kullanır.
İlk açılışta shader derlemesi biraz sürebilir.

- Orta fare tuşunu basılı tutup sürükleme: köprü merkezinin etrafında dönüş.
- Shift + orta fare tuşu: kaydırma. WASD/ok tuşları da kaydırır.
- Fare tekerleği: sınırlı yakınlaşma/uzaklaşma.
- Üstteki “Görünümü sıfırla” veya Home: başlangıç açısı.
- Kart seçimi veya pencere odağı kaybı, yakalanmış fareyi serbest bırakır.

## Yerleşim ve denge

- `scripts/reference_battlefield.gd`: deterministik sahne yerleşimi ve varlık normalizasyonu.
- `scripts/battle_camera.gd`: kamera kontrolleri; savaş hareketinden bağımsızdır.
- Oyun düzlemi y=0.35; nehir y=-6.4; köprü **20.4 x 6.4 m** ve üç gerçek açıklıklı kemer.
- Önceki köprü 14.4 m idi; yeni köprü yaklaşık %42 daha uzun. Nehir kıyıları buna göre genişledi.
- Varsayılan kamera ortografik, boyut 36, yatay açı 10.5°, düşey açı 35°; hedef köprü merkezi.
- Kamera boyutu 6–44, düşey açı 22–62°; yatay dönüş tam tur serbest.
- Üsler x=±14, giriş surları x=±12.6. İki tarafın yol genişliği, mesafeleri, kapı yüksekliği ve savaş arazisi eşittir.
- İki kalenin ana yapıları ayna düzenindedir. Bayraklar, bazı dekor dönüşleri ve uzak nehir kıvrımları kozmetiktir.
- Süsler çarpışma, örtü, hedef seçimi veya hasar avantajı eklemez. Savaş kodu bu harita değişikliğinde değiştirilmedi.
- Her girişte iki `future_turret_sockets` Marker3D noktası var. Konumları karşılıklı eşit; taret davranışı henüz etkin değil.
- Güncel yaşayan köy düzenlemesi ve yeni varlıklar için LIVING_VILLAGE.md dosyasına bakın.

## Su ve ışık

- Çizilmiş sinüs çizgileri kaldırıldı. İki kayan normal dokusu yüzeyin ışık yansımasını hareketlendirir.
- Derinliğe bağlı renk emilimi, hafif kırılma, kıyı/taş temasında düzensiz köpük ve su altı tabanı eklendi.
- Gökyüzü ve çevre yansıması için bir kez güncellenen ReflectionProbe kullanılır.
- Su ve şelale spreyi katman 2'dedir; yansıma yakalaması katman 1'i görür.
- Şelaleler uçurum kenarlarından akar; düz çizgiler yerine kayan gürültü, değişken saydamlık ve taban spreyi kullanılır.
- Yükseklik sisi kaldırıldı, uzaklık sisi azaltıldı. ACES ton eşleme ve ölçülü doygunluk/kontrast uygulanır.

## Dokular ve lisanslar

Quaternius Medieval Village MegaKit Standard: mevcut ücretsiz CC0 paket.
Godot için sağlanan normal haritaları kullanılıyor. Yanlış metalik varsayılanlar sıfırlandı.
Quaternius Ultimate Stylized Nature: mevcut AllModels.blend kaynak dosyası.
Eksik PineTree/MapleTree/Rock dokuları aynı CC0 paketin dağıtım kopyasından tamamlandı:
https://quaternius.com/packs/ultimatestylizednature.html
https://eddiejr-digiarts.itch.io/free-stylized-nature
Resmi Drive indirmesi kota uyarısı verdi. Dağıtım kopyasının License.txt dosyası
`licenses/NatureTextures_CC0.txt` olarak saklandı. Ücretli varlık kullanılmadı.

## Doğrulama

- Mevcut `--smoke-test`: savaş, formasyon, oklar, üs savunması, ölüm temizliği ve kart duraklaması başarılı.
- `tools/validate_map.gd`: gerçek giriş olaylarıyla orta tuş, Shift kaydırma, tekerlek, sıfırlama düğmesi ve birlik kartı; kapı simetrisi, kadraj ve merkez kontrolü başarılı.
- RTX 3050 üzerinde 90 kare Vulkan/Forward+ açılışı: shader veya çalışma hatası yok.
- Görsel değerlendirmeyi kullanıcı yapar; ekran görüntüsü veya video kaydı alınmadı.

