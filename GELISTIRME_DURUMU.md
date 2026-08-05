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
titreşim). Şu an **8 level** var, tüm temel oyun döngüsü (hareket/itme/undo/
yıldız/kayıt) çalışıyor.

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
- Beklenen dosya adları `puzzleboard/audio/sfx/README.md`'de listeli:
  `move.ogg`, `push.ogg`, `invalid.ogg`, `undo.ogg`, `redo.ogg`, `win.ogg`,
  `deadlock.ogg`. Bu isimle dosya eklendiğinde otomatik çalmaya başlar.
- `scripts/main.gd`'deki oyun olaylarına (hareket, kutu itme, geçersiz
  hamle, geri al, ileri al, level bitişi, deadlock uyarısı) `SFXManager.play(...)`
  çağrıları eklendi.
- **Kapsam dışı bırakıldı**: menü ekranlarındaki (Ana Menü, Level Seç,
  Ayarlar) genel buton tıklama sesleri henüz bağlanmadı — gerçek ses
  dosyaları eklenince aynı yöntemle (`SFXManager.play("click")` gibi) kolayca
  eklenebilir, şimdilik sadece oynanış (gameplay) tarafına odaklanıldı.

## Bilinen sınırlamalar / henüz yapılmayanlar

- **Ses efektleri altyapısı var ama gerçek ses dosyası yok** — `SFXManager`
  doğru olayları çağırıyor, sadece `res://audio/sfx/*.ogg` dosyaları eksik
  (bkz. `puzzleboard/audio/sfx/README.md`). Müzik de aynı durumda:
  `music_manager.gd` autoload artık düzgün kayıtlı ama `res://audio/music.ogg`
  dosyası projede yok.
- **Google Play Games / Game Center bulut kayıt** entegre değil. Bunun için
  gereken: Android tarafında "Play Game Services" export eklentisi, iOS
  tarafında Game Center eklentisi, ayrıca Google Play Console / App Store
  Connect'te uygulamayı kayıt edip OAuth/servis ayarlarını yapmak — yani hem
  kod hem de mağaza tarafı (hesap sahibinin yapması gereken) adımlar var.
- **Deadlock tespiti sınırlı** — sadece duvara karşı köşe durumu, kutu-kutu
  freeze deadlock'ları tespit edilmiyor.
- Gerçek lokalizasyon sistemi yok, proje tamamen Türkçe.

## Yol haritası (kullanıcıyla üzerinde anlaşılan sıra)

1. ~~Daha fazla level~~ ✅ (Level 5-8 eklendi)
2. ~~Oyun mekaniği iyileştirmeleri~~ ✅ (redo + basit deadlock tespiti)
3. ~~Cilalama / UX~~ ✅ (shake animasyonu + level select ilerleme göstergesi)
4. ~~Ses efektleri altyapısı~~ ✅ (`SFXManager` + olaylara bağlandı — gerçek
   .ogg dosyaları hâlâ eksik, eklenince otomatik çalışır)
5. **Google Play Games / Game Center bulut kayıt** ← sırada — büyük iş
   paketi, mağaza tarafı kurulum gerektiriyor, ayrı ele alınacak

## Test ederken dikkat

- Godot'u kapat/aç (ya da projeyi yeniden içe aktar) — yeni eklenen autoload
  (`MusicManager`) ve viewport ayarlarının editöre yansıması için gerekebilir.
- `MainMenu.tscn`'i çalıştır, Level Seç'te artık 8 level görünmeli.
- Ayarlar ekranında "İlerlemeyi Sıfırla"yı test edeceksen, önce birkaç level
  bitirip yıldız kazan, sonra sıfırlayıp Level Seç'in kilitli duruma
  döndüğünü doğrula.
