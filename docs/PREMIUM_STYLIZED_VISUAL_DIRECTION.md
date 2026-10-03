# Fetih Game — Premium Stylized Görsel Yön

## 1. Sorun Analizi

1. **Odak hiyerarşisi zayıf.** Kale, sunak, ev ve dekorlar benzer görsel ağırlıkta. Kale ekranın birincil, sunak oynanışın ikincil odağı olmalı.
2. **Aset paketleri aynı sanat dilini konuşmuyor.** Taş, sıva, çatı ve karakter materyallerinin doygunluğu, pürüzlülüğü ve detay ölçeği farklı.
3. **Yerleşim silueti parçalı.** Evlerin tek tek okunması var; yoğun, yaşayan bir köy kümesi algısı yeterince güçlü değil.
4. **Zemin fazla prosedürel görünüyor.** Tekrarlayan çim/toprak dağılımı yollarla, bina girişleriyle ve kullanım izleriyle yeterince ilişki kurmuyor.
5. **Karakterler uzaktan sınıfını yeterince hızlı anlatmıyor.** Okçu, hızlı birlik ve tankın siluet farkı ekipman dışında zayıf.
6. **Karakter–çevre ölçek dili tutarsız.** Kapı, pencere, silah, ağaç ve karakter baş oranları tek bir stil ölçeğine bağlanmamış.
7. **Aydınlatmada yerel hikâye eksik.** Sıcak köy ışıkları ile soğuk vadi/nehir ışığı arasında kontrollü kontrast yetersiz.
8. **Su kıyı teması zayıf.** Su, kayalara ve kıyıya oturmak yerine yüzey levhası gibi okunabiliyor.
9. **VFX aynı şekil diline bağlı değil.** Vuruş, takım ışıltısı, sunak saldırısı ve ödül efektleri için ortak kalınlık, renk ve zamanlama standardı yok.
10. **HUD dünya ile yarışıyor.** Büyük, düz paneller oyun alanını sıkıştırıyor; bilgi hiyerarşisi ve kartların nadirlik dili daha tutarlı olmalı.

## 2. Hedef Stil Tanımı

Nihai dil: **premium mobile stylized cartoon fantasy city-builder**, chibi kahraman koleksiyonu ve izlenebilir otomatik savaş karışımı.

- Genel oran: gerçek dünyadan %20–30 daha kalın, yuvarlak ve okunaklı formlar.
- Büyük şekiller önce, orta detaylar ikinci, küçük detaylar yalnızca yakın kamerada.
- Gün ışığında sıcak bal/kehribar ana ışık; gölgelerde mavi–camgöbeği dolgu.
- Taşlar büyük, yumuşak kenarlı bloklar; çatılar iri ve hafif eğri kiremitler; ahşap kirişler kalın.
- Kale, sunak ve köprü en güçlü üç landmark. Köy binaları bunlara doğru yükselen siluet ritmi kurar.
- Materyaller metal dışında yüksek pürüzlülükte; aşırı fotogerçekçi mikro detay ve keskin normal kullanılmaz.
- Kontur siyah değil, lacivert-kömür renginde ve düşük opaklıkta.
- Bloom yalnızca büyü, ateş, ödül ve kritik vuruşlarda görülür.

## 3. Karakter Stili

### Oran

- Hızlı birlik: 2.8–3 kafa boyu, ince gövde, büyük el ve ayak.
- Okçu: 3–3.2 kafa boyu, üçgen/çevik siluet, yay karakter boyunun %70–80’i.
- Tank: 2.5–2.8 kafa boyu, omuz genişliği kafa çapının 2.1–2.4 katı.
- Kahraman adayları: normal askerden %15 daha büyük kafa, %10 daha uzun silah ve belirgin omuz aksesuarı.

### Yüz

- Gözler büyük fakat anime düzeyinde değil; göz genişliği yüzün yaklaşık %18’i.
- Burun tek kama/küre formu; delik ve gerçekçi burun anatomisi kullanılmaz.
- Ağız kısa bir eğri veya kalın dudak yarığıdır.
- Kaşlar ifadeyi taşır; saldırıda içe ve aşağı, boşta hafif asimetrik.
- Yanak, burun ve kulaklarda sıcak renk geçişi; sert cilt gözenekleri kullanılmaz.

### Saç ve kostüm

- Saç tek tek tellerden değil 5–9 büyük tutamdan oluşur.
- Kumaş katları kalın, kenarlar yuvarlak; deri kayışlar gerçek kalınlığa sahip.
- Kemik, metal ve kürk aynı karakterde bile farklı pürüzlülük ve renk sıcaklığıyla ayrılır.
- Takım rengi bütün kostümü boyamaz; omuz, kemer, tüy, atkı ve küçük kumaş parçalarda kullanılır.

### Sınıf siluetleri

- Hızlı: öne eğimli gövde, alçak omuz, iki yana açılan hançer, sivri saç/kapüşon.
- Okçu: dik yay yayı, sırt oku ve omuzdan dışarı taşan tüyler; gövde çevresinde boş negatif alan.
- Tank: kare omuz, geniş silah, kısa bacak algısı, ağır kürk veya zırh kütlesi.
- Gelecekte büyücü: uzun dikey asa, geniş başlık, ince gövde ve dairesel büyü şekilleri.

### Materyal ve renk

- Cilt: yumuşak el boyaması geçiş; roughness 0.55–0.7.
- Kumaş: roughness 0.8–0.95; geniş renk lekeleri.
- Deri/ahşap: roughness 0.65–0.85; yalnızca kenarlarda sıcak aşınma.
- Metal: roughness 0.28–0.5; geniş boyalı highlight, küçük fotogerçekçi çizik yok.
- Her karakterde bir baskın, bir destek ve bir vurgu rengi. Takım rengi vurgu rengidir.

### Animasyon hissi

- Hazırlık %15, ana hareket %35, takip/settle %50 zaman dağılımı.
- Vuruştan 2–3 kare önce kısa duruş; temasta hızlı silah izi ve 0.06–0.10 saniye hit-stop.
- Tank hareketleri ağır ease-in/ease-out; hızlı birlikler keskin ve yaylı; okçu bırakışında gövde geri tepmesi.
- Idle sırasında nefes, ağırlık değişimi ve ekipman gecikmesi olmalı.
- Ölümde anında ragdoll yerine belirgin poz, ağırlık düşüşü ve kısa çözülme.

### VFX

- Hızlı birlik: ince sarı-beyaz çizgi ve küçük yıldız kıvılcımı.
- Okçu: açık kehribar iz, hedefte küçük yönlü kıvılcım.
- Tank: turuncu çekirdekli kalın yay, taş/toz patlaması ve daha güçlü kamera darbesi.
- Sunak: takım renginde elektrik çekirdeği, beyaz merkez, geniş düşük opaklıklı halo.
- Efektler karakter siluetini 0.25 saniyeden uzun kapatmamalı.

### Karakter–çevre ortak kuralları

- Karakter ve binalarda aynı kenar yumuşaklığı kullanılmalı.
- Ortak gölge rengi soğuk lacivert; saf siyah kontur ve saf siyah gölge kullanılmamalı.
- Ahşap, taş ve metal paletleri iki sistem arasında paylaşılmalı.
- Karakter detaylarının ekrandaki piksel yoğunluğu bina detaylarından yaklaşık %25 daha yüksek olmalı.
- En parlak değerler yüz, silah kenarı, ateş ve büyüye ayrılmalı.

## 4. Çevre ve Bina Stili

- **Kale:** köy çatılarından en az 1.8 kat yüksek; üç güçlü kule, büyük kapı, sıcak pencereler ve takım sancağı.
- **Sunak:** çevresinde boş oynanış meydanı; zeminde taş halka; aktifken dikey ışık ve küçük yörüngesel parçalar.
- **Evler:** 3–5 model ailesi, her ailede çatı eğimi, baca, çıkma ve giriş varyasyonu. Birbirinden kopuk serpiştirme yapılmaz; 3–7 binalık mahalle kümeleri kurulur.
- **Yollar:** her işlevsel kapıyı meydana veya ana caddeye bağlar. Kenarlarda çamur, teker izi, ezilmiş çim ve taş geçişi olur.
- **Pazar:** renkli tente, kasa, fıçı ve NPC dolaşımı ile orta yoğunluk noktası.
- **Kışla:** talim alanı, hedefler, silah rafı ve birlik çıkış koridoru.
- **Tarla:** ev arkasında düzenli şeritler; çiftçi yolu ve çit ile köye bağlanır.
- **Ağaçlar:** 3 ölçek sınıfı; landmark arkasında koyu büyük kütle, köy içinde orta, yol kenarında küçük.
- **Çim:** sürekli zemin dokusu + bina ve yol dışında kümelenen rüzgârlı geometri. Savaş şeridinde seyrekleştirilir.
- **Su:** derinlik rengi, iki yönlü normal dalga, kıyı köpüğü, kayaların arkasında akış izi ve koyu temas bandı.

## 5. UI Stili

- HUD üç adadan oluşur: sol kale bilgisi, orta ekonomi/ilerleme, sağ düşman kale bilgisi.
- Alt birlik kartları aynı yükseklik ve 9-slice çerçeve kullanır; maliyet sol altta, sınıf ikonu üstte, bekleme süresi kart üzerinde radial veya dikey maske ile görünür.
- Ana palet: gece laciverti panel, sıcak altın çerçeve, krem metin. Mavi/kırmızı yalnızca takım durumunda.
- Normal butonlarda tek vurgu; saldırı kırmızı, savunma mavi, kart seçimi altın.
- Kart nadirlikleri: gümüş = soğuk çelik, altın = kehribar, prizmatik = mor/camgöbeği hareketli kenar.
- Font: başlıkta gösterişli serif; sayılarda ve küçük açıklamada yüksek okunurluklu yarı serif/sans.
- Hasar alan birliklerin can barı görünür; tam canlı ve savaş dışında olanlarda gizlenir.
- Altın ödülü dünya üzerinde büyük sikke + kısa sayı animasyonu olarak çıkar; kalıcı HUD metni kullanılmaz.

## 6. Master Prompt

Premium stylized cartoon fantasy medieval city-builder battlefield, polished mobile game quality, two opposing cozy fortified villages facing each other across a long narrow stone bridge and a lively turquoise river, strong landmark castles and magical altar plazas, dense but logically planned neighborhoods, barracks with training yard, market stalls, farms, windmill, docks, walls and turret sockets, lush continuous grass, worn connected roads, large soft-edged stones, oversized curved terracotta roofs, warm glowing windows and torches against cool blue valley shadows, chibi collectible hero units with large expressive heads, readable class silhouettes, hand-painted materials, soft bevels, warm golden-hour key light, cool ambient fill, subtle atmospheric depth, controlled bloom, soft contact shadows, premium fantasy UI with navy panels and gold trim, clear gameplay readability, cinematic isometric perspective, cohesive art direction, high detail without visual noise.

## 7. Negative Prompt

photorealism, realistic human anatomy, tiny heads, thin limbs, generic low-poly prototype, flat unlit materials, plastic surfaces, random building placement, disconnected roads, empty village, identical houses, texture repetition, sharp noisy normal maps, oversaturated neon, pure black outlines, excessive bloom, washed-out fog, giant UI blocks, inconsistent asset packs, realistic skin pores, muddy colors, floating buildings, grass through roads, buildings facing the camera without street logic, unreadable silhouettes, weapons held backwards, arrows facing backwards, overlapping units, five-wide bridge formation, modern architecture, sci-fi elements, text, watermark, logo.

## 8. Step-by-step Improvement Plan

1. **Teknik temel:** su temas bandı, rüzgârlı çim, mobil outline, sunak yıldırımı ve karakter silah yönleri.
2. **Karakter standardı:** üç mevcut sınıfta ölçek, ekipman, takım vurgusu ve materyal pürüzlülüğünü eşitle.
3. **Vuruş hissi:** sınıf bazlı iz, kıvılcım, hit-stop, kamera darbesi ve ses katmanlarını ayır.
4. **Landmark geçişi:** kale ve sunağı tekil siluet, ışık ve çevresel boşlukla güçlendir.
5. **Mahalle düzeni:** evleri kümelere ayır; her kapıyı yola bağla; pazar, kışla, tarla ve liman çevresini işlevsel dekore et.
6. **Malzeme birliği:** tüm asetleri ortak taş, sıva, ahşap, kiremit ve metal değer aralığına normalize et.
7. **Zemin geçişleri:** sürekli çim, yol kenarı kir maskesi, bina diplerinde aşınma ve savaş köprüsünde kullanım izi.
8. **Aydınlatma:** sıcak yerel ışıklar, soğuk gölge dolgusu, kontrollü sis ve landmark vurgusu.
9. **UI yeniden düzeni:** tek 9-slice sistemi, ortak ikon ölçüsü, tutarlı boşluklar ve net bilgi önceliği.
10. **Yakın kamera kalite kapısı:** her karakter, silah, VFX ve malzeme yakın savaş kamerasında ayrı ayrı incelenip onaylanmadan yeni çağ içeriğine geçme.
