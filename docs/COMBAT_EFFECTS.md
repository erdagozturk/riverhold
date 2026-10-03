# Hazır savaş efektleri — 30 Eylül 2026

Uygulananlar:
- Binbun Hit FX Free sahneleri gerçek hasar alımında tetiklenir. Ağır birlik/üs darbesi ayrı impact sahnesini kullanır. Ok isabet etmeden darbe efekti çıkmaz.
- Binbun Loot VFX ile altın renkli ölüm ödülü ışığı; beş kozmetik altın parçacığı saçılır, seker ve kaybolur. +15 yazısı yükselir. Sayaca uçuş henüz yok.
- Kenney RPG Audio: knifeSlice, chop ve handleCoins2 sesleri. Aynı anda en fazla 10 ses çalar; perde küçük ölçüde değişir.
- Altın hesabı yalnız main.on_unit_died içinde kalır. Efekt sistemi ekonomi değiştirmez. Ölüye ikinci hasar ikinci ödül üretmez.
- Aynı anda çalışan efektlerin malzemeleri sahneye özeldir. Efektler 1.1–1.5 saniyede temizlenir; toplam aktif nesne sayısı sınırlandırılır.
- Muzzle Flash paketi indirilmiş olsa da orta çağ oklarının ucuna silah ateşi eklenmedi. Taret entegrasyonu henüz yok.

Çevre: planned_battlefield içindeki ev gövdeleri hazır ahşap/sıva duvar modülleriyle kurulur; büyük yapılarda balkon, küçük yapılarda sundurma vardır. Her bina girişinin sokak ağına bağlantısı çizilir. Duvar diplerine kir, yollara değişken toz ve yosun katmanları eklendi. Harita bu değişiklikte genişletilmedi; karakter modellerinin ayrıştırılması da henüz tamamlanmadı.

Kaynaklar (CC0):
- https://binbun3d.itch.io/hit-fx
- https://binbun3d.itch.io/loot-vfx
- https://kenney.nl/assets/rpg-audio
- Quaternius mevcut Medieval Village Standard varlıkları.

Kontrol: savaş smoke testi geçti; ayrı efekt testi ödülün tek verilmesini, bağımsız malzemeleri ve temizliği doğruladı. Yerleşim testi 40 birliğin savaşa ulaşmasını, simetriyi, kamera kapsamını ve giriş yönlerini doğruladı. Forward+ GPU çalıştırması tamamlandı. Sandbox sertifika/önbellek yazma uyarıları ve motor kapanışında 7 Texture RID uyarısı görüldü; shader derleme veya oyun script hatası görülmedi. Görsel/ses kalite değerlendirmesi kullanıcı tarafından yapılacak; ekran kaydı alınmadı.
