# PuzzBoard — Geliştirme Durumu

Bu dosya, projeye yeni katılan biri (ör. takım arkadaşı) için "kaldığımız yer"
özetidir. Genel proje tanıtımı ve dosya yapısı için `README.md`'ye bak — burada
sadece **şu ana kadar neler yapıldığını** ve **sırada ne olduğunu** anlatıyoruz.

Son güncelleme: 2026-08-05

## Projeye başlarken

- Godot **4.7**, proje kökü `puzzleboard/` klasörü (`project.godot` orada).
- Godot'ta "Var Olan Projeyi İçe Aktar" ile `puzzleboard/` klasörünü aç.
- Git kullanıcı bilgini ayarlamayı unutma:
  `git config --global user.name "Ad Soyad"` /
  `git config --global user.email "mail@ornek.com"`
- Repo: `https://github.com/UmutEfeDemir/PuzzleBoard`

## Proje ne durumda

Kod üzerinden çizilen (sprite/tileset asset'i olmayan), Sokoban tarzı kutu
itme bulmacası. Mobil hedefli (Godot mobile rendering + swipe input +
titreşim). Şu an **400 level** var (16 bölüm x 25 level), tüm temel oyun
döngüsü (hareket/itme/undo/redo/yıldız/kayıt/deadlock uyarısı) çalışıyor.

## Bu oturumda yapılan değişiklikler

### 1. Git / GitHub kurulumu
- Yerel git kimliği ayarlandı, proje `UmutEfeDemir/PuzzleBoard` reposuna
  bağlandı ve push edildi.

### 2. Level 5-8 eklendi
- `puzzleboard/levels/level_05.tres` … `level_08.tres`.
- `scripts/level_generator.gd`'nin `_make_levels()` fonksiyonuna da aynı
  levellar eklendi (editörden "File > Run" ile tekrar üretilebilsin diye).
- Her level, elle yazılan küçük bir **BFS Sokoban çözücüyle** (bu oturumda
  kullanılıp silinen bir scratch script) doğrulandı — yani hepsi garanti
  çözülebilir. Yıldız eşikleri (`moves_for_3_stars` / `moves_for_2_stars`)
  optimal hamle sayısına göre, mevcut level3/level4 oranıyla (~1.4x) tutarlı
  şekilde ayarlandı.
- Zorluk eğrisi: Level 5 tek kutu + ilk "dönüş" (sağa it, dolaş, aşağı it),
  Level 6-7 aynı mekanik + artan kutu sayısı, Level 8 ilk kez tek koridor
  değil — haç şeklinde oda, farklı sütunlardan aşağı itme.

### 3. Mobil ekran / ortalama düzeltmesi
Sorun: board (oyun tahtası) her zaman ekranın sol üstünde sabit bir pikselde
duruyordu (`Vector2(40, 160)`), ekran boyutuna göre ortalanmıyordu; ayrıca
`project.godot`'ta hiç dikey (portre) çözünürlük tanımlı değildi.
- `project.godot`: `window/size/viewport_width=720`,
  `viewport_height=1280`, `window/handheld/orientation="portrait"` eklendi.
- `scripts/main.gd`: `_fit_board_to_screen()` fonksiyonu eklendi — board'u
  HUD'un altında kalan alana göre ortalar, ekrana sığmayan (geniş) levelları
  otomatik küçültür (`board_layer.scale`), büyük ekranlarda gereksiz
  büyütmez (1.0 ile sınırlı).

### 4. "MusicManager" derleme hatası düzeltildi
`scripts/music_manager.gd` bir autoload (singleton) olarak yazılmıştı ama
`project.godot`'ta hiç autoload olarak kayıtlı değildi. Bu yüzden
`settings.gd` parse hatası veriyordu ve bu da sahne geçişlerini (Level Seç,
Ayarlar açılmıyordu) kilitliyordu.
- Düzeltme: `project.godot`'a `[autoload]` bölümü eklendi:
  `MusicManager="*res://scripts/music_manager.gd"`.

### 5. Level Seç ekranı sola yapışma sorunu
`scripts/level_select.gd`'de zigzag yolun genişliği `PATH_WIDTH := 340.0`
diye sabitti, gerçek ekran genişliği hiç hesaba katılmıyordu. Artık
`_ready()` içinde `get_viewport_rect().size.x`'ten hesaplanıyor
(`_path_width`, `_left_x`, `_right_x` — instance var, const değil).

### 6. Tamamlandı kartına "Level Seçime Dön" butonu
`scripts/main.gd`'deki tamamlandı overlay'inde sadece "Tekrar" ve "Sonraki
Level" vardı — son levelde ("Sonraki" gizliyken) ya da genel olarak geri
dönecek bir yol yoktu (üstteki "X" overlay'in altında kalıp erişilemiyordu).
Artık overlay'in altında her zaman görünen bir "Level Seçime Dön" butonu var.

### 7. Ayarlar'a "İlerlemeyi Sıfırla"
- `scripts/save_manager.gd`: `reset_progress()` eklendi — sadece level
  yıldız/rekor verisini siler, ses/müzik/titreşim/tema tercihlerine
  dokunmaz (`_settings` anahtarı korunuyor).
- `scripts/settings.gd`: yeni bir kart + kırmızı "İlerlemeyi Sıfırla" satırı,
  basınca `ConfirmationDialog` ile onay alıyor (yanlışlıkla silinmesin diye).

### 8. Bulut senkronizasyonu için hazırlık (henüz gerçek entegrasyon YOK)
`scripts/save_manager.gd`'ye `static var cloud_sync_handler: Callable`
eklendi. Set edilirse her yerel kayıttan (`_save_data`) sonra güncel
veriyle çağrılır. Şu an boş (`Callable()`), yani hiçbir şey değişmedi —
sadece Google Play Games / Game Center gibi bir servis eklenmek istendiğinde
kancalanacak tek nokta hazır.

### 9. Açılış (splash) ekranı eklendi
- Yeni `scripts/splash.gd` + `scenes/Splash.tscn`: proje artık direkt Ana
  Menü ile değil, önce **DMR Studio rozeti** sonra **PuzzBoard logosu**
  (`art/PuzzBoardLOGO.png`) ile açılıyor — ikisi de hafifçe dönerek/
  büyüyerek belirip birkaç saniye sonra sönüyor. Ekrana dokunmak/tıklamak
  splash'ı atlayıp direkt Ana Menü'ye geçiriyor.
- `project.godot`'ta `run/main_scene` artık `Splash.tscn`.
- PuzzBoard logosu proje köküne konmuştu, Godot dışında kaldığı için
  `res://` ile erişilemiyordu — `puzzleboard/art/` klasörüne kopyalandı.
- Düzeltilen bir bug: `TextureRect`'in varsayılan `expand_mode`'u
  (`EXPAND_KEEP_SIZE`) minimum boyutu `custom_minimum_size` yerine
  texture'ın gerçek (çok büyük) piksel boyutundan alıyordu, bu yüzden logo
  ekrana sığmayıp yakınlaştırılmış/kırpılmış görünüyordu. Düzeltme:
  `expand_mode = TextureRect.EXPAND_IGNORE_SIZE`.
- **DMR Studio rozeti önce SVG olarak denendi** (`dmr_studio_logo_dark_badge.svg`,
  kullanıcı tarafından sağlandı) ama Godot'un yerleşik SVG içe aktarıcısı
  (ThorVG) `<text>` elemanlarını render etmiyor — sadece şekiller (arkaplan,
  çizgi, daire) görünüyor, yazılar kayboluyor. Bu **bilinen bir Godot
  kısıtlaması**, SVG dosyasının kendisinde hata yok. Çözüm: rozet, projenin
  geri kalanıyla aynı yöntemle — kod içinde Panel + Label ile — çizildi
  (`splash.gd`'deki `_build_studio_badge()`). SVG dosyası projeden
  kaldırıldı (kullanılmıyor).
- **Not**: Godot'u ilk açtığında `PuzzBoardLOGO.png`'yi otomatik import
  edecek (bir `.import` dosyası oluşacak) — bu normal, commit'e dahil et.

### 10. Oyun mekaniği: Redo + deadlock tespiti
- `scripts/grid_manager.gd`: `_redo_stack` eklendi. `undo()` artık geri alınan
  komutu redo stack'e atıyor; yeni bir hamle (`_apply_command`) redo stack'i
  temizliyor (mantıken doğrusu bu — ileri gidilecek eski bir gelecek kalmadı).
  `redo()` / `can_redo()` eklendi. Ortak uygulama mantığı `_apply_move()`'a
  çıkarıldı (hem `try_move` hem `redo` kullanıyor).
- Basit **köşe deadlock tespiti** eklendi (`_check_deadlock`): bir kutu
  hedefte değilse ve yatayda (sol VEYA sağ) + dikeyde (üst VEYA alt) duvar
  varsa, o kutu bir daha asla itilemez — `box_deadlocked` sinyali yayınlanır.
  **Not**: sadece duvara karşı köşe durumunu tespit ediyor, iki kutunun
  birbirini kilitlemesi gibi daha karmaşık "freeze deadlock" durumları
  kapsam dışı (false positive riskini azaltmak için bilerek basit tutuldu).
- `scripts/main.gd`: HUD'a "Geri Al"ın yanına **"İleri Al"** butonu + `Y`
  tuşu kısayolu eklendi. Deadlock sinyalinde ekranın üstünde kısa süreliğine
  görünüp sönen bir uyarı rozeti (+ hafif titreşim) gösteriliyor.

### 11. Cilalama / UX
- `scripts/main.gd`: geçersiz hamlede (duvara/kilitli kutuya çarpınca)
  oyuncu figürü artık o yöne hafifçe sarsılıyor (`_shake_player`) — hem
  swipe hem klavye girişleri artık `try_move`'un dönüş değerini kontrol
  ediyor (`_attempt_move`).
- `scripts/level_select.gd`: header'ın altına, listeyi kaydırırken
  kaybolmayan sabit bir **ilerleme özeti kartı** eklendi (`_build_progress_summary`)
  — "X / Y Level Tamamlandı" + "★ kazanılan/toplam" + ince bir ilerleme
  çubuğu.

### 12. Ses efektleri altyapısı
- Yeni `scripts/sfx_manager.gd` (autoload `SFXManager`), `music_manager.gd`
  ile aynı felsefede: `res://audio/sfx/` altında dosya yoksa `play(...)`
  sessizce hiçbir şey yapmaz, hata vermez. Ayarlar'daki "Ses Efektleri"
  toggle'ı (`sound_effects`) kapalıysa da çalmaz.
- `scripts/main.gd`'deki oyun olaylarına (hareket, kutu itme, geçersiz
  hamle, geri al, ileri al, level bitişi, deadlock uyarısı) `SFXManager.play(...)`
  çağrıları eklendi.
- **Kapsam dışı bırakıldı**: menü ekranlarındaki (Ana Menü, Level Seç,
  Ayarlar) genel buton tıklama sesleri henüz bağlanmadı — gerçek ses
  dosyaları eklenince aynı yöntemle (`SFXManager.play("click")` gibi) kolayca
  eklenebilir, şimdilik sadece oynanış (gameplay) tarafına odaklanıldı.

### 15. Yer tutucu ses efekti dosyaları üretildi
Daha önce `SFXManager` doğru olayları çağırıyordu ama `res://audio/sfx/`
altında hiçbir gerçek ses dosyası yoktu (oyun sessizdi). Bir PowerShell
script'iyle (bu oturumda kullanılıp silindi) **7 basit, kod-üretilen
`.wav` dosyası** (sinüs tonlar + tık sesini azaltan atak/sönme zarfı)
üretilip `puzzleboard/audio/sfx/` altına yazıldı: `move.wav`, `push.wav`,
`invalid.wav`, `undo.wav`, `redo.wav`, `win.wav`, `deadlock.wav`.
- Bunlar **gerçek ses tasarımı değil** — sadece oyun artık tamamen sessiz
  olmasın diye. `sfx_manager.gd`'deki `SFX_FILES` sözlüğü `.ogg`'dan
  `.wav`'a güncellendi (Godot `.wav`'ı ek bir encoder gerekmeden içe
  aktarabiliyor, bu yüzden `.wav` seçildi).
- Gerçek ses dosyaların hazır olunca aynı isimle (`move.wav` vb.) üzerine
  yazman yeterli — istersen `.ogg`/`.mp3` de kullanabilirsin, sadece
  `SFX_FILES`'taki uzantıyı güncellemen gerekir.
- **Not**: Godot'u ilk açtığında bu 7 dosyayı otomatik import edecek (her
  biri için bir `.import` dosyası oluşacak) — bu normal, commit'e dahil et.

### 13. Level 9-100 toplu üretimi + Level Seç'te "Bölüm" sistemi
- **92 yeni level** (9-100) tek seferlik bir PowerShell script'iyle
  (bu oturumda kullanılıp silindi, mantığı burada özetleniyor) toplu
  üretildi. Elle 92 level tasarlamak yerine iki "doğruluğu inşa yoluyla
  garanti" geometrik şablon kullanıldı:
  - **stack**: K kutu, her biri kendi satırında, tek yöne düz itme
    (level3/4'ün genellemesi).
  - **turn**: K kutu, paylaşılan tek odada, sağa + aşağı itme
    (level5/6/7'nin genellemesi).
  Her şablonun optimal hamle sayısı **analitik bir formülle** hesaplandı
  (BFS her level için tek tek çalıştırılmadı — çok yavaş olurdu). Formül,
  BFS ile birden fazla noktada (K=2 ve K=3, hem stack hem turn) **birebir
  doğrulandı**, sonra ölçekte güvenle kullanıldı.
- **İlk versiyonda iki sorun çıktı, ikisi de düzeltildi:**
  1. Levellar arasında bariz tekrar hissi vardı (aynı K/tip kombinasyonu
     hep aynı boyutta çıkıyordu). Çözüm: her level ayrıca **transpose**
     (x/y takası) + **yatay/dikey ayna** ile dönüştürülüyor — aynı doğrulanmış
     geometri "geniş-yatay" da olabiliyor "dar-dikey" de (hamle sayısını
     DEĞİŞTİRMEZ, sadece görünümü çeşitlendirir).
  2. Bazı levellar telefon ekranı için fazla büyüktü (ör. 30 sütun, 13 satır).
     Çözüm: tüm levellar **13x11 hücreyi asla aşmayacak** şekilde (genişlik
     bütçesi K'ya göre dinamik hesaplanarak) sınırlandı; zorluk artışı boyut
     büyütmek yerine daha çok kutu + daha uzun itme mesafesiyle sağlanıyor.
- **Dosya adlandırma**: Level 1-8 `level_01.tres` → `level_001.tres` olarak
  yeniden adlandırıldı (3 haneli) — 100'e çıkınca metin sıralaması
  bozulmasın diye (`level_100` artık `level_2`'den önce gelmiyor).
  `scripts/level_generator.gd` da bu isimlendirmeye güncellendi (sadece
  Level 1-8'i tanımlıyor, 9-100 için başlığındaki nota bak).
- **Level Seç ekranı "Bölüm"lere ayrıldı** (`scripts/level_select.gd`):
  100 level tek uzun listede değil, her biri 25 levellik 4 bölümde
  (`SEGMENT_SIZE = 25`). Bir bölümün kilidi, bir önceki bölümde en az
  **`STARS_REQUIRED_TO_UNLOCK_SEGMENT = 40` yıldız** kazanılmış olmasına
  bağlı (sadece son leveli bitirmek yetmiyor — kullanıcı isteği). Kilitli
  bir bölüme de gidilebilir, kaç yıldız gerektiği gösterilir (levellar
  kilitli görünür, oynanamaz).
  - **İlk versiyon yatay kaydırılabilir sekme şeridiydi, kullanıcı bunun
    bölüm sayısı artınca (ileride 300-400 levele çıkılırsa, ~12-16 bölüm)
    kullanışsız kalacağını fark etti.** Onun yerine `< Bölüm N (başlangıç-
    bitiş) >` şeklinde bir **pager** (ok navigasyonu) kullanılıyor — kaç
    bölüm olursa olsun aynı genişlikte kalıyor, ölçeklenme sorunu yok.

### 14. Ödüllü reklam ile geri alma (monetizasyon altyapısı)
Kullanıcı fikri: her leveldeki ilk geri alma ücretsiz, ikincisinden itibaren
ödüllü reklam izleyerek hak kazanılsın; ayrıca her ~2 levelde bir
interstitial reklam gösterilsin.
- Yeni `scripts/ad_manager.gd` (autoload `AdManager`) — `music_manager.gd`/
  `sfx_manager.gd` ile aynı felsefe: dışarıdan çağıran kod hiç değişmeden,
  bu dosyanın içi gerçek bir reklam SDK'sıyla (ör. AdMob) değiştirilecek.
  **Şu an gerçek reklam SDK'sı bağlı değil**:
  - `show_rewarded_ad(on_reward)`: kısa bir gecikmeden sonra ödülü OTOMATİK
    veriyor — test/geliştirme akışı hiç bloklanmasın diye (kullanıcıyla
    üzerinde anlaşılan davranış: gerçek SDK bağlanana kadar simüle et).
  - `show_interstitial()`: şimdilik sadece print yapıyor.
  - `notify_level_completed()`: her `GAMES_PER_INTERSTITIAL` (=2) level
    tamamlanmasında bir `show_interstitial()` tetikler.
- `scripts/main.gd`: `_do_undo()` artık ilk çağrıda direkt geri alıyor,
  sonrakilerde `ConfirmationDialog` ile "Reklamı İzle" onayı alıp
  `AdManager.show_rewarded_ad(...)` çağırıyor. Ücretsiz hak level başına
  sıfırlanıyor (`_free_undo_used`, her level yeni bir Main sahnesi olduğu
  için otomatik sıfırlanıyor). **Redo (İleri Al) gate'lenmedi** — kullanıcı
  sadece geri almadan bahsetti, ileri alma zaten geri almanın telafisi
  olduğu için serbest bırakıldı.
- **Gerçek AdMob entegrasyonu için gereken** (henüz yapılmadı): Godot Admob
  export eklentisi + Android/iOS export ayarları, AdMob hesabında uygulama
  kaydı + ödüllü/interstitial reklam birimi ID'leri — Google Play Games
  entegrasyonuyla aynı kategoride, mağaza tarafı kurulum gerektiren ayrı bir
  iş paketi.

### 16. Genel gözden geçirme (bug avı)
Yeni özellik eklemeden önce, bu oturumda değişen tüm dosyalar (grid_manager,
main.gd, level_select, save_manager, settings, splash, ad_manager,
level_generator, project.godot, birkaç .tres örneği) tekrar okunup
tutarlılık kontrolü yapıldı.
- **Bulunan ve düzeltilen tek gerçek hata**: `scripts/main.gd`'deki level
  yükleme fallback'i hâlâ eski 2 haneli dosya adını kullanıyordu
  (`"res://levels/level_01.tres"`). Level 1-8'i 3 haneliye yeniden
  adlandırdığımızda (bkz. bölüm 13) bu satır gözden kaçmıştı — dosya artık
  yok, yani Main sahnesi Level Seç'ten geçilmeden direkt açılırsa (GameState
  boşken) `load()` null dönüp çökerdi. `"res://levels/level_001.tres"`
  olarak düzeltildi. Proje genelinde başka eski isim kalıntısı kalmadığı
  grep ile doğrulandı.
- Kontrol edilip **sorun bulunmayan** yerler: redo/deadlock mantığı
  (grid_manager), undo/redo + reklam onay akışı, segment kilit zinciri
  (`_find_initial_segment` yeni 40 yıldız kuralından bağımsız doğru
  çalışıyor — sebebi doküman içinde açıklandı), sahne dosyalarının script
  bağlantıları, autoload isimlerinin her çağrıda tutarlı yazılması
  (`SFXManager`/`AdManager`/`MusicManager`), örnek olarak incelenen
  transpose+ayna uygulanmış bir level'ın (level_095) geometri bütünlüğü.

## Bilinen sınırlamalar / henüz yapılmayanlar

- **Ses efektleri şu an yer tutucu** — `puzzleboard/audio/sfx/*.wav`
  altında basit, kod-üretilen sinüs tonlar var (gerçek ses tasarımı değil).
  Gerçek dosyalar hazır olunca aynı isimle üzerine yazman yeterli. Müzik
  hâlâ tamamen eksik: `music_manager.gd` autoload artık düzgün kayıtlı ama
  `res://audio/music.ogg` dosyası projede yok.
- **Google Play Games / Game Center bulut kayıt** entegre değil. Bunun için
  gereken: Android tarafında "Play Game Services" export eklentisi, iOS
  tarafında Game Center eklentisi, ayrıca Google Play Console / App Store
  Connect'te uygulamayı kayıt edip OAuth/servis ayarlarını yapmak — yani hem
  kod hem de mağaza tarafı (hesap sahibinin yapması gereken) adımlar var.
- **Deadlock tespiti sınırlı** — sadece duvara karşı köşe durumu, kutu-kutu
  freeze deadlock'ları tespit edilmiyor.
- Gerçek lokalizasyon sistemi yok, proje tamamen Türkçe.

### 17. Level çeşitliliği: gerçek 2. mekanik (Z-Corridor)
Kullanıcı haklı bir eleştiri getirdi: 100 level'ın tamamı sadece 2 kalıbın
(düz itme / sağ+aşağı tek dönüş) boyut+yön varyasyonlarıydı — gerçekten
farklı hissettiren yeni bir mekanik yoktu.

- **Önce "S-Turn" (sağ-aşağı-sağ, 2 dönüş) denendi ve BAŞARISIZ oldu.**
  Sebep matematiksel: açık bir odada aynı eksendeki iki bacak (iki "sağ")
  her zaman tek harekette birleştirilebiliyor — BFS her seferinde 2. dönüşü
  atlayıp kestirmeden gidiyordu (bir duvarla bile engellenemedi, çünkü
  kestirme farklı bir sütunda gerçekleşiyordu). **Açık alanda 1 dönüşten
  fazlasını zorlamak Sokoban'da imkansız** — bunu görmek epey BFS
  denemesi/path-trace gerektirdi.
- **Çözüm: `New-ZCorridorLevel`** — gerçek, dar (1 hücre genişliğinde),
  duvarla çevrili bir Z/S koridoru. Kutunun geçebileceği HER hücre tek tek
  beyaz listeye alınıp geri kalan her şey duvar yapıldı (whitelist yöntemi
  — "aç, sonra kapat" yerine "sadece izin verileni aç"). Dönüş
  noktalarında oyuncunun kutunun etrafına dolaşabilmesi için tek hücrelik
  "cep"ler eklendi (klasik Sokoban köşe dönüşü prensibi). 5 farklı a/b/c
  parametre setinde BFS ile test edildi, hepsinde **formül (a+b+c+4) ile
  BFS birebir eşleşti** — yani gerçek 2 dönüşlü zorluk garantili.
- Level 9-100, artık **3 kalıp döngüsü** (stack / turn / zcorridor) +
  8 yönlü ayna/transpose ile yeniden üretildi. Üretim scripti bu oturumda
  kullanılıp silindi (kalıcı değil), ama yöntem burada belgeli — aynı
  yaklaşımla (whitelist + BFS doğrulama) yeni şablonlar eklenebilir.
- **Öğrenilen genel ders**: Sokoban'da gerçek zorluk (birden fazla dönüş,
  sıra bağımlılığı) SADECE gerçek duvar/labirent yapılarıyla mümkün — açık
  odalarda "daha fazla bacak eklemek" hiçbir şey ZORLAMAZ, BFS her zaman en
  kısa (Manhattan-optimal) yolu bulur. İleride daha fazla çeşitlilik
  isteniyorsa (300-400 level hedefi), yeni şablonlar da bu whitelist +
  BFS-doğrulama yöntemiyle inşa edilmeli, formüle asla körü körüne
  güvenilmemeli.

### 18. Level 101-400 eklendi (400'e tamamlandı)
Kullanıcının uzun vadeli hedefi: oyuncu "level bitti" duvarına çarpmasın
diye elde bol miktarda içerik olsun. 100'de kurulan aynı üretim yöntemi
(3 kalıp: stack/turn/zcorridor, formülle BFS-doğrulanmış hamle sayıları,
8 yönlü ayna/transpose, hepsi 13x11 mobil sınırı içinde) 101-400 için de
aynen kullanıldı — **0 boyut uyarısı**, hepsi sığıyor.

- Zorluk parametreleri (K, itme mesafeleri) tier 4'te (level 76-100'de
  ulaşılan değerler) **plato yapıyor** — 13x11 sınırı içinde bundan daha
  zor bir versiyon üretilemez, bu yüzden 101-400 aynı "azami" aralığı
  kullanıyor, sadece $L (level numarası) her hesaba girdiği için tam
  aynı parametreler tekrar etmiyor (farklı K/mesafe/yön kombinasyonları).
- `level_select.gd` hiç değişmedi — zaten tamamen dinamik
  (`res://levels/` klasörünü tarayıp `SEGMENT_SIZE=25`'e göre otomatik
  bölümlere ayırıyor), 400 level otomatik olarak 16 Bölüm'e ayrıldı.
- **Dürüst not (bkz. bölüm 17)**: bu 300 level de aynı 3 mekanik
  kalıbının varyasyonu — miktar arttı, mekanik çeşitlilik artmadı.
  Kullanıcı bunu bilerek kabul etti ("kalıbı olabildiğince fazla tutup
  gereğinden fazla oyun üretmemiz lazım... level bitti hissi yaratmasın").
  Gerçek yeni mekanik (4. bir kalıp) istenirse whitelist+BFS yöntemiyle
  eklenip mevcut havuza sonradan karıştırılabilir.
- Level dosyaları `level_101.tres` … `level_400.tres` (3 haneli, zaten
  001-100 ile aynı format).

## Yol haritası (kullanıcıyla üzerinde anlaşılan sıra)

1. ~~Daha fazla level~~ ✅ (Level 5-8, sonra 9-100, sonra 101-400 — toplam 400)
2. ~~Oyun mekaniği iyileştirmeleri~~ ✅ (redo + basit deadlock tespiti)
3. ~~Cilalama / UX~~ ✅ (shake animasyonu + level select ilerleme göstergesi)
4. ~~Ses efektleri altyapısı~~ ✅ (`SFXManager` + olaylara bağlandı — gerçek
   .ogg dosyaları hâlâ eksik, eklenince otomatik çalışır)
5. **Google Play Games / Game Center bulut kayıt** — kullanıcı bilerek
   ERTELEDİ ("oyunu bitirmem gerekmekte" dedi), şimdilik dokunulmuyor.
   `SaveManager.cloud_sync_handler` kancası hazır bekliyor, ne zaman
   istenirse (muhtemelen Play Games Cloud Save ile, kod gerektirmeyen
   Google'ın hazır sistemi) devreye sokulabilir.
6. **Şu an sırada: uçtan uca elle test** — bu oturumda çok fazla değişiklik
   art arda geldi (100→400 level, redo/deadlock, SFX, segment sistemi),
   hiçbiri birlikte gerçek cihazda/editörde test edilmedi. Kullanıcı
   yorgun olduğu için bu adımı henüz yapmadı.

## Test ederken dikkat

- Godot'u kapat/aç (ya da projeyi yeniden içe aktar) — yeni eklenen autoload'lar
  (`MusicManager`, `SFXManager`) ve viewport ayarlarının editöre yansıması
  için gerekebilir.
- `Splash.tscn` (ya da `MainMenu.tscn`) çalıştır, Level Seç'te artık **16
  Bölüm** ve toplam **400 level** görünmeli. Bölüm 2'den itibaren hepsi
  başta kilitli olmalı (bir önceki bölümde en az 40 yıldız kazanılmadan
  açılmamalı — bkz. `STARS_REQUIRED_TO_UNLOCK_SEGMENT`).
- Pager'ın (`< Bölüm N >`) 16 bölüm arasında düzgün gezindiğini, kilitli
  bir bölüme gidilebildiğini ama içindeki levellerin kilitli göründüğünü
  doğrula.
- Ayarlar ekranında "İlerlemeyi Sıfırla"yı test edeceksen, önce birkaç level
  bitirip yıldız kazan, sonra sıfırlayıp Level Seç'in kilitli duruma
  döndüğünü doğrula.
- Yeni üretilen levellardan birkaçını (özellikle Bölüm 3-4'ten büyük olanları)
  gerçekten oynayıp board'un ekrana sığdığını ve hücrelerin dokunulabilir
  boyutta kaldığını gözle kontrol et.

## Sıradaki konuşulan fikir (henüz kodlanmadı)

Kullanıcı önerisi: **geri al (undo) monetizasyonu** — ilk geri alma ücretsiz,
ikinciden itibaren ödüllü reklam izleterek hak kazanma; ayrıca her ~2 oyunda
bir 10 saniyelik reklam. Bunun için gereken: bir reklam SDK'sı (ör. Google
AdMob) + Godot export eklentisi + hesap/uygulama kaydı (mağaza tarafı,
kullanıcının yapması gerekiyor) — Google Play Games entegrasyonuyla aynı
kategoride, ayrı bir iş paketi olarak ele alınacak.
