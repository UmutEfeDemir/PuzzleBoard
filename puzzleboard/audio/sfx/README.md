# Ses efektleri

`scripts/sfx_manager.gd` bu klasördeki dosyaları isme göre arıyor. Bir
dosyayı tam bu isimle buraya koyduğunda otomatik çalmaya başlar — kod
değişikliği gerekmez.

| Dosya         | Ne zaman çalar                          |
|---------------|------------------------------------------|
| `move.ogg`    | Oyuncu boş kareye hareket eder            |
| `push.ogg`    | Kutu itilir                               |
| `invalid.ogg` | Geçersiz hamle (duvar / itilemeyen kutu)  |
| `undo.ogg`    | Geri al                                   |
| `redo.ogg`    | İleri al                                  |
| `win.ogg`     | Level tamamlanır                          |
| `deadlock.ogg`| Kutu sıkışma uyarısı                      |

Dosya yoksa `SFXManager.play(...)` sessizce hiçbir şey yapmaz (hata vermez).
