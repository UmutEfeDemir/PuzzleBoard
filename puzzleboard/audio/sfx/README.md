# Ses efektleri

`scripts/sfx_manager.gd` bu klasördeki dosyaları isme göre arıyor. Şu an
burada bulunan `.wav` dosyaları **basit, kod-üretilen yer tutucular**
(sinüs tonlar) — gerçek ses tasarımı değil, sadece oyun artık tamamen
sessiz olmasın diye. Kendi gerçek ses dosyanı eklediğinde **aynı isimle**
üzerine yazman yeterli, kod değişikliği gerekmez (`.ogg`/`.mp3` de olur,
sadece `sfx_manager.gd`'deki `SFX_FILES` sözlüğündeki dosya adını
güncellemen gerekir).

| Dosya          | Ne zaman çalar                            |
|----------------|--------------------------------------------|
| `move.wav`     | Oyuncu boş kareye hareket eder              |
| `push.wav`     | Kutu itilir                                 |
| `invalid.wav`  | Geçersiz hamle (duvar / itilemeyen kutu)    |
| `undo.wav`     | Geri al                                     |
| `redo.wav`     | İleri al                                    |
| `win.wav`      | Level tamamlanır                            |
| `deadlock.wav` | Kutu sıkışma uyarısı                        |

Dosya yoksa `SFXManager.play(...)` sessizce hiçbir şey yapmaz (hata vermez).
