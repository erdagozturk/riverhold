# Yaşayan köy — 29 Eylül 2026

## Kullanım

F8 → F5 ile yeniden başlatın. Fare tekerleği artık 6–44 kamera boyutu aralığında çalışır;
varsayılan 36'dan savaşçıları yaklaşık altı kat büyük gösterecek kadar yaklaşılabilir.
Yakınlaşma fareyle işaret edilen bölgeye yönelir. Orta tuş döndürür; Shift + orta tuş kaydırır.
Kaydırma sınırları köyler ve tarlaları incelemek için genişletildi. Home/üst düğme başlangıç açısını getirir.

## Yapılar

- Şato kompleksleri, evler ve pazar tezgâhları kamera yerine karşı tarafa bakar. Kapı/pencere, çatı, arma ve baca aynı dönüşe dahildir.
- Şatoya giden yollar yeni kapı yönüne göre bağlandı; iç surda geçit bırakıldı.
- Üs binasının çatısı ve yeni kapısı da düşman yönüne bakar. Üs hasarı, menzili ve oyun konumu değişmedi.
- Her köye uzun kışla ve eğitim hedefleri, ekili tarla, kuyu ve rıhtım eklendi.
- Rıhtımlar su seviyesinde, üst kıyıya basamaklarla bağlanır.
- Girişlerdeki dört taret noktasına ek olarak dört geniş katapult platformu ayrıldı. Silah/üretim/hasar davranışı henüz etkin değildir.
- Ahşap köprü, trim atlasının yalnız ahşap şeridini örnekler; tam atlas tekrarından doğan renk bantları giderildi.

## Sakinler ve doğa

- İki köy toplam: 6 gezinen sakin, 2 çiftçi rolü, 2 kedi, 2 köpek, 8 civciv; vadi üstünde 7 animasyonlu kuş.
- İnsanlar mevcut KayKit modelini kullanır; özel köylü/çiftçi kıyafeti paketi henüz yoktur. Çiftçi şapkası eklendi, tarla duraklarında Interact animasyonu kullanılır.
- Hayvanlar Quaternius'un CC0 hazır animasyonlu modelleridir. Lisans ve kaynaklar `licenses/ANIMAL_ASSETS_CC0.txt` içinde.
- Cat/Dog/Chick kaynak modelleri +X yönüne baktığından, görsel eksenleri +Z hareket yönüne düzeltildi.
- Sakinler belirlenmiş güzergâhlarda yürür ve durur. Nüfusa, altına veya savaş hedef listesine katılmazlar.
- Yaklaşık 977 çim kümesi ve 160 ekin kümesi gerçek kanat geometrisiyle çizilir. Kökler sabit, uçlar ortak rüzgâr alanıyla eğilir.
- Ağaç rüzgârı çimle aynı temel yön/zaman alanını izler. Yeşillik rengi ve aşırı genel doygunluk azaltıldı.
- Nehir yüzeyi kıvrımı izleyen akış alanı ve 24 kaya çevresinde yön sapması/arkada köpük izi kullanır. Bu gerçek zamanlı görsel akış modelidir; tam fiziksel sıvı simülasyonu değildir.

## Kontrol

`tools/validate_living_village.gd`: yapı cepheleri, platformlar, animasyon anahtarları, sakinlerin zeminde kalması, çim/akıntı verisi ve yakın zoom.
Mevcut `--smoke-test`: birlik sırası, yakın/uzak saldırı, ölüm temizliği, üs savunması ve kart seçimi.
Vulkan/Forward+ açılışında shader/çalışma hatası ayrıca kontrol edilir. Görsel başarı otomatik testlerden çıkarılmaz; kullanıcı görüntü değerlendirmesi gerekir.
