extends Node

## Autoload (bkz. project.godot [autoload]). Reklam SDK'sı entegrasyonu için
## tek nokta — music_manager.gd / sfx_manager.gd ile aynı felsefe: dışarıdan
## çağıran kod (main.gd) hiç değişmeden kalır, sadece bu dosyanın içi gerçek
## SDK çağrılarıyla değiştirilir.
##
## ŞU AN GERÇEK BİR REKLAM SDK'SI (AdMob vb.) BAĞLI DEĞİL:
## - show_rewarded_ad(): kısa bir "izleniyor" gecikmesinden sonra ödülü
##   OTOMATİK veriyor — geliştirme/test akışı hiç bloklanmasın diye.
## - show_interstitial(): şimdilik sadece print yapıyor.
##
## GERÇEK ENTEGRASYON İÇİN (ör. Google AdMob):
## 1. Bir Godot Admob eklentisi ekle, Android/iOS export ayarlarını yap.
## 2. AdMob hesabında uygulamayı kaydet, ödüllü + interstitial reklam
##    birimi ID'lerini al.
## 3. show_rewarded_ad() ve show_interstitial()'ın içini gerçek SDK
##    çağrılarıyla değiştir (reklam başarıyla izlenince on_reward çağrılmalı,
##    reklam başarısız/iptal olursa hiç çağrılmamalı).

const GAMES_PER_INTERSTITIAL := 2

var _games_since_interstitial := 0


## Ödüllü reklam gösterir; izlenip ödül hak edilince on_reward çağrılır.
## Reklam iptal/başarısız olursa on_reward hiç çağrılmaz (gerçek SDK'da da
## böyle olmalı — "izlemeden ödül" yok).
func show_rewarded_ad(on_reward: Callable) -> void:
	await get_tree().create_timer(0.6).timeout
	if on_reward.is_valid():
		on_reward.call()


## Her level tamamlandığında çağrılır; her GAMES_PER_INTERSTITIAL levelde
## bir interstitial tetikler.
func notify_level_completed() -> void:
	_games_since_interstitial += 1
	if _games_since_interstitial >= GAMES_PER_INTERSTITIAL:
		_games_since_interstitial = 0
		show_interstitial()


func show_interstitial() -> void:
	print("[AdManager] Interstitial reklam gösterilecekti (SDK henüz bağlı değil).")
