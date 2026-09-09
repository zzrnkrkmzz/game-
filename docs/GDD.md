# Ada Blast — Oyun Tasarım Dokümanı (GDD)

**Versiyon**: 0.3 · **Durum**: Faz 1-3 uygulandı (çekirdek prototip, Ada ekranı, biyom/görev/koleksiyon sistemleri) — Faz 4 (Monetizasyon) bekliyor
**Çalışma adı**: Ada Blast (kesinleşmemiş)

---

## 1. Oyun Özeti (Elevator Pitch)

**Ada Blast**, Block Blast'ın rahatlatıcı, kısa turlu blok yerleştirme mekaniğini bir ada/üs kurma katmanıyla birleştiren casual strateji oyunudur.

> Blok yerleştir, sırayı temizle, adanı büyüt.

- **Hedef kitle**: Casual mobil oyuncular, özellikle Block Blast / Merge / idle-strateji türlerini oynayan geniş kitle (yaş aralığı geniş, ağırlıklı 18-45).
- **Benzersiz satış noktası (USP)**: Piyasadaki "saf" Block Blast klonlarının aksine, her turdan kazanılan kaynaklar kalıcı bir ada inşasına dönüşür. Oyun kısa oturumlarla oynanır ama uzun vadeli bir ilerleme/koleksiyon hissi taşır.
- **Platform**: iOS (App Store) + Android (Play Store), Flutter ile tek kod tabanından.
- **İş modeli**: Ücretsiz (F2P) + Reklam + IAP + isteğe bağlı Ada Pass aboneliği (bkz. Bölüm 6).
- **Tasarım ilkesi**: "Yormasın." Her sistem bu ilkeye göre sınırlanır — zorunlu zaman baskısı yok, agresif bildirim yok, zorunlu abonelik duvarı yok.

---

## 2. Çekirdek Döngü (Core Loop)

Bir turun anatomisi, ortalama 1-3 dakika sürer:

1. **Tahtaya Yerleştir** — Tepsideki 3 parçadan birini 8×8 grid üzerine sürükle. Yerleştirme zorunludur (parça atlama/geçme hakkı yoktur).
2. **Sırayı Temizle** — Dolan satır, sütun veya bölge patlar; art arda temizlemede puan çarpanı artar (kombo sistemi).
3. **Kaynak Topla** — Temizlenen blokların rengine göre kaynak kazanılır: **Ahşap** (coral bloklar), **Taş** (seafoam bloklar), **Kristal** (amber bloklar). Renk seçimi, hangi kaynağa öncelik verileceğini belirleyen stratejik bir karardır.
4. **Adayı Büyüt** — Kazanılan kaynaklarla Ada ekranında bina inşa/yükselt. Binalar tahtaya dönerek pasif bonus sağlar (döngü kapanır).

**Oyun sonu**: Tahtada hiçbir parça için yer kalmayınca tur biter. Gem karşılığı yumuşak bir "devam et" opsiyonu sunulur (zorlayıcı değildir, reddedilebilir).

**Zorluk eğrisi — Yumuşak Anti-Frustration**: Parçalar ağırlıklı rastgele seçilir. Tahta doluluk oranı ~%75'i geçtiğinde sistem, mevcut boşluğa kesin sığan en az bir parçayı tepsiye garanti eder. Oyuncu bu müdahaleyi fark etmez; amaç ani ve "haksız" hissettiren oyun bitişlerini azaltmaktır. Tamamen rastgele veya skor bazlı dinamik zorluk modelleri değerlendirildi, bu yaklaşımın basitlik/adalet dengesi en iyi kurduğu için tercih edildi.

---

## 3. Meta Katman: Üs/Ada Kurma

Ayrı bir "Ada" ekranında, kazanılan kaynaklarla bina inşa edilir/yükseltilir.

| Bina | Etkisi |
|---|---|
| **Depo** | Tahtada ekstra undo hakkı verir |
| **Değirmen** | Zamanla pasif kaynak üretir (oyun kapalıyken de birikir) |
| **Pazar** | Kaynağı gem'e çevirme imkânı sunar |
| **Fener** | Günlük giriş ödülüne çarpan ekler |
| *(+1-2 bina daha, prototip aşamasında netleşecek)* | |

- Binalar oyun mekaniğine **dokunmadan** pasif bonuslar verir — stratejik derinlik katar ama micro-yönetim gerektirmez.
- Ada büyüdükçe görsel olarak zenginleşir; bu, idle oyunlardaki gibi düşük bilişsel yükle tatmin sağlayan bir ilerleme hissi yaratır.
- **Ada, tüm oyuncular için ücretsizdir** — bu katman, oyunun farklılaşmasını sağlayan temel unsur olduğu için hiçbir ödeme duvarının arkasına kilitlenmez (bkz. Bölüm 6, Ada Pass tasarım kararı).

---

## 4. Tema/Biyom İlerlemesi ve Koleksiyon

**Durum: Faz 3'te uygulandı** (`lib/island/models/biome.dart`, `lib/board/models/placed_block.dart`, `lib/collection/`).

- Ada seviye eşiklerinde biyom değişir: **Orman (0-4) → Çöl (5-9) → Kar (10-14) → Uzay (15-20)** toplam bina seviyesine göre (tüm bina seviyelerinin toplamı, `IslandState.totalLevel`).
- **Buz bloğu** (Kar ve Uzay biyomunda, tepside %15 olasılıkla): `PlacedBlock` modeli her hücreye bir "dayanıklılık" (remainingHits) değeri ekler. Normal blok 1 vuruşta (satırı/sütunu tamamlayan ilk temizlikte), buz bloğu 2 vuruşta temizlenir — satır/sütun ilk tamamlanışında sadece 1 hasar alır ve kalır, skor/kombo yine de sayılır.
- **Bonus blok** (her biyomda %8 olasılıkla): tamamen temizlendiğinde normal 1 kaynağa ek olarak +3 ekstra kaynak verir.
- Basitleştirme notu: buz/bonus özelliği prototipte hücre bazlı değil, **parça bazlı** uygulandı (parçanın tüm hücreleri aynı özel türde) — gerçek sanat/asset aşamasında hücre bazlı hale getirilmesi değerlendirilebilir.
- **Koleksiyon albümü** (`lib/collection/`): 11 öge (9'u ada toplam seviyesine, 2'si görev serisine bağlı) — emoji + isimle temsil ediliyor, gerçek sanat varlıkları ileri fazda eklenecek. Kilitli ögeler "???" olarak gösterilir.

---

## 5. Retention Mekanikleri

**Durum: Günlük görevler ve seri Faz 3'te uygulandı** (`lib/quests/`); liderlik tablosu ve push bildirimleri backend/native entegrasyonu gerektirdiği için ileri faza bırakıldı.

- **Günlük görevler**: her gün 5 görev türünden (satır temizle, blok yerleştir, bina yükselt, puan topla, tur bitir) rastgele 3'ü seçilir, hedefleri de aralık içinden rastgele belirlenir. İlerleme, Board ve Island ekranlarındaki aksiyonlardan otomatik olarak beslenir.
- **Seri (streak) sistemi**: bir günün tüm görevleri tamamlanınca seri 1 artar; bir gün atlanırsa (görevler tamamlanmadan gün değişirse) seri sıfırlanır. *Not: gün değişimi şu an yalnızca uygulama açılışında kontrol ediliyor — kalıcı depolama (Hive) eklenene kadar tam bir "günlük giriş" akışı değil.*
- **Liderlik tablosu**: haftalık sıfırlanan, cezasız, asenkron sıralama (arkadaşlar + global). Gerçek zamanlı PvP yoktur, stres yaratmaz. *(Henüz uygulanmadı — backend/kimlik doğrulama gerektiriyor.)*
- **Bildirimler**: "adan seni bekliyor" tonunda nazik geri çağırma — agresif/sık bildirim yok. *(Henüz uygulanmadı — native push altyapısı Faz 4+ ile birlikte.)*

---

## 6. Monetizasyon (F2P + Reklam + IAP + Ada Pass Aboneliği)

Tasarım ilkesi: reklam ve ödeme sıklığı bilinçli olarak düşük tutulur — "yormasın" hedefi, gelir modelinin sınırını da çizer.

### 6.1 Ödüllü Reklamlar (Rewarded)
Ekstra undo, parça yenileme, devam hakkı, günlük ödülü 2 katına çıkarma.

### 6.2 Geçiş Reklamları (Interstitial)
Seyrek gösterilir, yalnızca tur sonunda. **Banner reklam kullanılmaz** — kalıcı olarak akışı bozduğu için bilinçli olarak dışarıda bırakılmıştır.

### 6.3 IAP (Tek Seferlik Satın Alma)
Gem paketleri, reklamları kaldır, başlangıç paketi, kozmetik skin'ler, sezonluk "ada geçişi" (battle-pass-lite).

### 6.4 Ada Pass (Aylık Abonelik, ~5-10 TL/ay)

**Tasarım kararı**: Ada/üs kurma katmanı **herkese ücretsiz** kalır — abonelik bu katmanı kilitlemez, yalnızca hızlandırır ve süsler. Gerekçe: bu katman oyunun asıl farklılaşma unsuru; eğer yalnızca abonelerin erişebildiği bir özellik olsaydı, oyuncuların büyük çoğunluğu için oyun "sıradan bir Block Blast klonu" olarak kalır, organik büyüme ve mağaza puanları bundan zarar görürdü.

Ada Pass sahiplerine sunulanlar:
- **+2 ekstra bina slotu** (temel oyuncuya göre daha geniş ada)
- **Tüm reklamların kaldırılması** (ödüllü reklamlar isteğe bağlı olarak izlenmeye devam edilebilir)
- **Pasif kaynak üretiminde %25 hız artışı** (Değirmen vb. binalarda)
- **Aya özel, yalnızca abonelere açık kozmetik dekor/skin seti**
- **Günlük giriş ödülünde otomatik bonus** (reklam izlemeye gerek kalmadan)

Konumlandırma: "asıl oyunu satın al" değil, "daha hızlı ve daha güzel oyna". Düşük fiyat noktası (~5-10 TL/ay) casual oyuncuda ödeme sürtünmesini azaltır; sektörde casual/puzzle aboneliklerinin dönüşüm oranı düşük olsa da (~%1-2 bandı), öngörülebilir tekrarlayan gelir sağlar.

---

## 7. Sanat Yönü ve Ses Tasarımı

### 7.1 Sanat Yönü — Sıcak 3D Diorama
Royal Match / Township esintili bir görsel dil:
- **Ada ekranı**: yumuşak gölgeli, oyuncaklı 3D-render binalar ve dekorlar.
- **Tahta ekranı**: sade, düz renkli (flat) bloklar — okunabilirlik önceliklidir, blok rengi anında ayırt edilebilmelidir.
- Bu ayrım, iki ekranın farklı işlevlerini (biri hızlı karar, biri keyifli seyir) görsel olarak da destekler.

### 7.2 Ses/Müzik Yönü — Sakin & Rahatlatıcı
- Marimba/kalimba temelli, düşük tempolu lo-fi/ambient arka plan müziği.
- Blok temizlemede tatlı "ping" SFX; bina inşasında sıcak "pop" efekti.
- Neşeli/enerjik veya minimal/sessiz alternatifler değerlendirildi; "yormasın" hedefiyle en uyumlu seçenek olduğu için sakin ton tercih edildi.

---

## 8. Onboarding ve Navigasyon

### 8.1 Onboarding — Doğrudan Oyuna Düş
- Açılış ekranı veya hesap oluşturma yoktur; oyuncu saniyeler içinde tahtayla karşı karşıyadır.
- İlk 2-3 hamle ok/ışık ipucuyla yönlendirilir.
- İlk satır temizlenince kaynak kazanılır ve Ada ekranına geçiş otomatik olarak tetiklenir.
- Hedef: ilk 10 saniyede sürtünmeyi minimuma indirmek.

### 8.2 Navigasyon — Yatay Kaydırma (Board ↔ Ada)
- İki ana ekran (Tahta ve Ada) parmakla sağa/sola kaydırarak ya da merkezi bir buton ile geçilir — aynı dünyanın iki yakası gibi hissettirir.
- Mağaza, Koleksiyon ve Ayarlar; üst köşedeki küçük ikonlarla açılan modal/popup olarak gelir, ana akışı bölmez.

---

## 9. Teknik Mimari (Flutter)

- **State management**: Riverpod (öneri — prototip aşamasında değerlendirilecek).
- **Grid/animasyon**: `CustomPainter` + basit tween animasyonları. İlk aşamada Flame motoruna gerek yoktur (görsel karmaşıklık düşük).
- **Yerel kayıt**: Hive veya `shared_preferences` — offline ilerleme (kaynak/bina durumu) için.
- **İleri faz (Faz 4+)**: Firebase (Analytics, Crashlytics, Remote Config, Cloud Save, Leaderboard) + AdMob + `in_app_purchase` paketi (Ada Pass aboneliği ve diğer IAP'ler için).
- **Proje iskeleti**: `lib/` altında `board/`, `island/`, `shared/`, `data/` modülleri.

---

## 10. Ürün Metrikleri ve Analitik

### 10.1 KPI Hedefleri — Casual Puzzle Sektör Ortalaması
Soft launch öncesi genç hedefler olarak belirlenmiştir; gerçek veriyle güncellenecektir.

| Metrik | Hedef |
|---|---|
| D1 Retention | ~%35-40 |
| D7 Retention | ~%12-15 |
| D30 Retention | ~%4-6 |
| Ortalama oturum süresi | 4-6 dk/gün |
| Günlük oturum sayısı | 3-4 |

### 10.2 Analitik Olay Planı — Temel Huni + Monetizasyon Set'i
Faz 1-4'e paralel olarak eklenecek çekirdek event listesi:
`tur_başladı`, `tur_bitti` (skor, süre), `satır_temizlendi`, `bina_inşa` / `bina_yükseltme`, `günlük_giriş`, `ödüllü_reklam_izlendi`, `interstitial_gösterildi`, `iap_satın_alındı`, `ada_pass_satın_alındı`, `oyun_bitti` (sebep).

Geniş kapsamlı UI-etkileşim bazlı takip (her dokunma, her ekran geçişi) bilinçli olarak ertelenmiştir — erken aşamada geliştirme yükünü ve gizlilik kapsamını gereksiz büyütür.

---

## 11. Live-Ops (Canlı Operasyon) Takvimi — Hafif Aylık Döngü

- Ayda 7-10 günlük, sınırlı süreli bir mini-ada etkinliği (özel biyom dekoru, temalı görevler).
- Aylık sezon geçişi (battle-pass-lite, bkz. Bölüm 6.3).
- Haftalık yoğun etkinlik takvimi yerine bu hafif model tercih edildi — küçük bir ekip/tek geliştiriciyle bile sürdürülebilir, yine de düzenli "yenilik" hissi verir.

---

## 12. Yasal / Uyumluluk ve Erişilebilirlik

### 12.1 Yasal/Uyumluluk — Faz 6'da Detaylı Checklist
Şimdilik temel ilkeler:
- Hedef yaş: 13+. 13 yaş altı / COPPA kapsamlı bir sürüm hedeflenmemektedir.
- Reklam kişiselleştirme için Apple ATT (App Tracking Transparency) izni istenecek.
- Veri minimizasyonu ilkesi benimsenir (yalnızca Bölüm 10.2'deki event seti kadar veri toplanır).

Mağaza başvurusuna yakın **Faz 6**'da ayrıntılı bir uyumluluk checklist'i hazırlanacaktır: gizlilik politikası metni, izin akışları, KVKK aydınlatma metni.

### 12.2 Erişilebilirlik — Temel Sette Başlasın
Faz 1'den itibaren:
- Blok renklerine ek doku/ikon farkı eklenir — oyun mekaniği renge bağımlı kalmaz (renk körlüğü desteği).
- Arayüz yazı boyutu sistem ayarına duyarlı olur.
- Tek elle oynama, simetrik arayüz tasarımıyla doğal olarak desteklenir.

Tam renk körlüğü modu (seçilebilir palet) ve ekran okuyucu desteği gibi geniş erişilebilirlik paketi, kullanıcı geri bildirimiyle ileride değerlendirilecektir.

---

## 13. Fazlı Yol Haritası (Roadmap)

| Faz | İçerik | Durum |
|---|---|---|
| 0 | **GDD** (bu doküman) | ✅ Tamamlandı |
| 1 | Çekirdek block-blast prototipi (grid, parça yerleştirme, skor) — oynanabilir dikey dilim | ✅ Tamamlandı |
| 2 | Kaynak üretimi + temel Ada ekranı (3-5 bina) | ✅ Tamamlandı |
| 3 | Tema/biyom ilerlemesi, koleksiyon, günlük görevler | ✅ Tamamlandı |
| 4 | Monetizasyon entegrasyonu (reklam + IAP + Ada Pass) | ⏳ Sırada |
| 5 | Cilalama: animasyon, ses, haptik, onboarding/tutorial | Bekliyor |
| 6 | Mağaza hazırlığı: ikon, ekran görüntüleri, gizlilik politikası, yaş derecelendirmesi, Firebase kurulumu, yasal checklist | Bekliyor |
| 7 | Soft launch → geri bildirim → global lansman | Bekliyor |

---

## 14. Riskler ve Notlar

- **Doygun kategori**: Block Blast türü piyasada çok sayıda klonla dolu; ayrışma tamamen Ada/koleksiyon katmanının kalitesine bağlıdır — bu katman ikinci sınıf bir eklenti gibi hissettirilmemelidir.
- **Reklam/abonelik dengesi**: Çok agresif reklam veya abonelik baskısı, oyunun temel "yormasın" hedefini baltalar. Ada Pass'in isteğe bağlı ve katmanı kilitlemeyen yapısı bu riski azaltmak için tasarlandı.
- **Erken test edilebilirlik**: Faz 1 (çekirdek prototip), kaynak/bina sistemi olmadan da bağımsız test edilebilir olmalıdır — bu, oynanabilirliği erken ve izole şekilde doğrulamayı sağlar.
- **Fiyatlandırma belirsizliği**: Ada Pass'in ~5-10 TL/ay fiyat noktası bir varsayımdır; bölgesel mağaza fiyat kademeleri ve gerçek dönüşüm verisiyle Faz 4'te kesinleştirilecektir.
