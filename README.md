# PuzzBoard

Kutu itme (Sokoban tarzı) bulmaca prototipi. Godot 4.7, kod üzerinden
kurulacak şekilde yazıldı — TileMap/tileset/sprite asset'i hazırlamana
gerek yok, tüm görseller Panel + StyleBoxFlat ile kod içinde çiziliyor.

## Proje konumu

Godot projesinin kökü `bulmuca-oyunu-deneme/` klasörüdür (`project.godot`
orada). Godot'ta **"Var Olan Projeyi İçe Aktar"** ile o klasörü aç.

## Dosya yapısı

```
bulmuca-oyunu-deneme/          <- Godot proje kökü (res://)
├── scripts/
│   ├── ui_theme.gd              # Ortak renk paleti + buton/kart yardımcıları
│   ├── level_data.gd            # Level verisi (Resource)
│   ├── move_command.gd          # Command pattern (undo için)
│   ├── grid_manager.gd          # Oyun mantığı (state, kurallar, undo)
│   ├── swipe_input.gd           # Mobil swipe algılama
│   ├── game_state.gd            # Sahneler arası veri taşıyıcı
│   ├── save_manager.gd          # JSON tabanlı yıldız + ayar kaydı
│   ├── main_menu.gd             # Ana Menü ekranı
│   ├── level_select.gd          # Level seçim ekranı
│   ├── settings.gd              # Ayarlar ekranı
│   ├── main.gd                  # Oyun içi sahne (board'u kod ile çizer)
│   └── level_generator.gd       # ASCII haritadan level (.tres) üretir
├── scenes/
│   ├── MainMenu.tscn             # Ana sahne (Proje Ayarları > Run > Main Scene)
│   ├── LevelSelect.tscn
│   ├── Settings.tscn
│   └── Main.tscn
└── levels/                      # level_generator.gd çalışınca dolar (.tres)
```

## Ekran akışı

```
Ana Menü ──OYNA──▶ Level Seç ──(kilitli değilse)──▶ Oyun İçi ──bitince──▶ Tamamlandı kartı
   │                    ▲                                │                    │
   └──Ayarlar──▶ Ayarlar│                                └──X (kapat)─────────┘ (Sonraki / Tekrar / Level Seçime Dön)
```

- **Ana Menü**: başlık, maskot, OYNA butonu, toplam yıldız göstergesi, Ayarlar.
- **Level Seç**: her level bir rozet (kilitli/mevcut/tamamlanmış duruma göre
  renklenir). Bir önceki level en az 1 yıldızla bitirilmeden bir sonraki
  açılmaz. `res://levels/` altındaki `.tres` dosyalarını otomatik tarar —
  yeni level eklediğinde kod değişikliği gerekmez.
- **Oyun İçi**: üstte kapat (X), level adı, hamle sayacı, Geri Al; altında
  hamle ilerleme çubuğu (yeşil = 3 yıldız sınırı, sarı = 2 yıldız, kırmızı =
  1 yıldızda kaldın).
- **Ayarlar**: Ses Efektleri/Müzik/Titreşim toggle'ları ve Dil satırı
  `user://save_data.json`'da kalıcı tutulur. Titreşim gerçekten çalışır
  (kutu itme + level bitişinde `Input.vibrate_handheld`). Ses/Müzik şu an
  gerçek bir audio sistemine bağlı değil — projede henüz ses dosyası yok,
  tercih sadece kaydediliyor.
- **Tamamlandı kartı**: yıldızlar animasyonlu açılır, hamle sayısı gösterilir,
  Tekrar / Sonraki Level / Level Seçime Dön butonları.

## Yeni level eklemek

`scripts/level_generator.gd`'yi editörde aç, **File > Run** (Ctrl+Shift+X).
Standart Sokoban ASCII notasyonu kullanılıyor (`#` duvar, `.` hedef, `$`
kutu, `@` oyuncu — dosyanın içindeki yorum satırında tüm semboller yazılı).
Yeni level `_make_levels()` fonksiyonuna bir satır eklemekten ibaret.

## Kontroller

- **PC'de test**: WASD veya ok tuşları, Z tuşu = geri al (undo)
- **Mobilde**: swipe (yukarı/aşağı/sağ/sol), ekrandaki "Geri Al" butonu

## Bilinen sınırlamalar

- Ses/Müzik ayarları kaydediliyor ama henüz hiçbir audio sistemi yok.
- Dil satırı şu an sadece bilgilendirme diyaloğu açıyor, gerçek bir
  lokalizasyon sistemi (başka dil dosyaları) yok — proje zaten tamamen
  Türkçe.
- `level_generator.gd` `@tool` + `EditorScript` — sadece editörde "Run" ile
  çalışır, oyun içinde çağrılmaz.
