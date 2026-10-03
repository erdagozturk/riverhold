# Köy yerleşimi — 29 Eylül 2026

Aktif sahne `planned_battlefield.gd`; bina, yol ve asker çıkışları `village_plan.gd` içindeki ortak plandan üretilir. Önceki çevre betiği ortak yapı parçaları için korunur.

## Yerleşim ve oyun

- Ortadaki 20,4 m köprü korunur. İki köy aynı savaş mesafeleri ve zemin yüksekliklerine sahiptir.
- Kaleler geride, kışlalar arka avludadır. Köprü başında asker üreten ev yoktur.
- Birlikler kışla avlusunda doğar, geniş talim yolundan meydana yaklaşır ve sunağın yanından savaş yoluna katılır. Daha sonra mevcut yakın dövüş, okçu, sıra, savunma ve ölüm sistemini kullanır.
- Maç hedefi x ±24'teki meydan sunağıdır. Mevcut otomatik taş savunması korunur. Sunak yıkılınca maç biter. Kapıdaki savunma çizgisi x ±15'tir.
- Binaların yönünü sokağa açılan kapıları belirler. Kale, kışla, pazar, evler, çiftlik ve depo ayrı bölgelerdir.
- Pazar sokakları, tarla, kuyu, depo, rıhtım yolu, çevre surları ve merdivenli topçu platformları eklenmiştir. Platformlarda henüz silah davranışı yoktur.
- Ağaçlar tanımlı korularda bulunur. Yol, bina, meydan ve tarla alanları bitki dağıtımından hariçtir. Tohumlu küçük çeşitlilik yalnız uygun bölgeler içinde kullanılır.

## Görünüm ve yaşam

- Geniş kaya katmanları, daha yeşil zemin ve ağaçlar, su akışındaki parçalı köpük izleri.
- Perspektif başlangıç kamerası iki kale ve sunağı kapsar. Orta tuş döndürür; Shift + orta tuş kaydırır; tekerlek yakınlaştırır. Home/görünümü sıfırla varsayılan kadraja döner.
- Köylü ve hayvan güzergâhları sokaklara bağlıdır. Kartallar uzak dağlarda, küçük kuşlar korular çevresindedir. Uçan hayvanların boyutu kanat açıklığıyla normalize edilir ve dönüş yönü hareket teğetine uyar.
- Köylüler hâlâ geçici KayKit karakterlerini kullanır. Bu değişiklik referans atmosferine yönelik bir yerleşim çalışmasıdır; referansla birebir görsel eşleşme doğrulanmış değildir.

## Kontroller

`tools/validate_planned_village.gd`: 40 birliğin çıkış rotası, savaşa katılımı, sunak çevresinden geçiş, maç bitişi, bina kapıları, kamera kadrajı, iki tarafın zemin/platform simetrisi ve yol üstüne ağaç gelmemesi.

`tools/validate_map.gd`: fareyle birlik üretimi, kamera döndürme/yakınlaşma/kaydırma/sıfırlama, kart ekranında fare bırakılması.

`tools/validate_living_village.gd`: hayvan animasyonları, yere basma, yaşam rotaları, yakın zoom, çim ve su bileşenleri.

`--smoke-test`: savaş, ok/taş hasarı, sıra, ölüm temizliği, kart duraklatması ve tekrar üretim.

Kullanıcının isteğiyle ekran görüntüsü/video kaydı alınmaz; görsel değerlendirmeyi kullanıcı yapar. GPU testi yalnız sahnenin ve efektlerin hatasız açılmasını kontrol eder.

## Görsel karşılaştırma sonrası ikinci geçiş

- Yol üçgenlerinin aşağı bakan yüzleri düzeltildi. Önceki kontroller yolların varlığını kontrol ediyor, yönlerini kontrol etmiyordu. validate_composition.gd artık tüm yol normallerini kontrol ediyor.
- Taş döşeme dünya konumundan üretilir; küçük tekrar eden yol dokusu kaldırıldı. Duvar taşlarının tekrar ölçeği büyütüldü.
- Boş arazi 0,62 m aralıklı sık, rüzgârlı çim örtüsüne geçti. Yapı, tarla, avlu ve yolların kullanım alanları korunur. Çimlerin ayrı gölge üretimi kapatılarak koyu çizgi gürültüsü azaltıldı.
- Zemin rengi çok ölçekli geçişlerden oluşur; sıva dokusunun toprak gibi tekrarlanması kaldırıldı.
- Dış sur x ±38'e taşındı; konutların yanında bahçe ve bahçeye bağlanan yürüyüş yolu eklendi. Savaş hedefleri ve kışla mesafeleri değişmedi.
- Yaz yeşili geniş yapraklı ağaçlar, bitkili kıyı katmanları, kale terasları ve kameraya bakan üç şelale.
- Başlangıç kamera boyutu 48, eğimi 27 derece, görüş açısı 44 derece. Hafif yakın/uzak alan derinliği yakınlaşırken odak mesafesine göre güncellenir.
- API kaynağı: https://docs.godotengine.org/en/stable/classes/class_cameraattributespractical.html
- Yol/kadraj kontrolü, kamera/fare testi, 40 birlikle çıkış-savaş testi ve Vulkan çalıştırması geçti. Ekran görüntüsü alınmadı; görsel eşleşme ve oynanış sırasında hissedilen performans kullanıcı tarafından değerlendirilmelidir.
