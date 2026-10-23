# RP Gemini

Aplikasi Android native (Flutter / Dart) untuk roleplay chat dengan Google Gemini.

## Fitur
- **Set Karakter**: nama, umur, kepribadian, kesukaan, dan rahasia (bisa diedit kapan saja).
- **Set Cerita**: genre (pilih beberapa), tempat, dan latar waktu.
- **Reset**: menghapus semua percakapan (tombol tempat sampah di tab Chat, atau di tab Setelan). Karakter dan cerita tetap tersimpan.
- **Mode**: Normal (SFW) atau Gelap (tema dewasa tanpa seks eksplisit).
- Tampilan gelap Material 3, narasi *miring*, **pikiran** tebal.

## Struktur
```
assets/
  genres.txt                  daftar genre, satu per baris (edit di sini)
  prompts/
    system_prompt.txt         aturan utama AI
    mode_normal.txt           aturan mode Normal
    mode_gelap.txt            aturan mode Gelap
    character_template.txt    template blok karakter ({{name}}, {{age}}, ...)
    story_template.txt        template blok cerita ({{genres}}, {{place}}, {{time}})
    opening_prompt.txt        pesan tersembunyi saat menekan "Mulai Cerita"
lib/
  main.dart                   tema dan navigasi
  app_state.dart              state, penyimpanan lokal, kirim pesan
  gemini_service.dart         panggilan ke Gemini API
  prompt_builder.dart         menyusun prompt dari file di assets/prompts
  models.dart, widgets.dart
  screens/                    chat, karakter, cerita, setelan
.github/workflows/build-apk.yml
```

## Cara build APK lewat GitHub
1. Buat repository baru di GitHub, upload semua isi folder ini (pastikan folder `.github` ikut).
2. Push ke branch `main`. Workflow **Build APK** jalan otomatis (atau jalankan manual di tab Actions).
3. Setelah selesai, buka run tersebut dan unduh artifact `rp-gemini-apk`. Isinya `app-release.apk`, tinggal install di HP.

Folder `android/` dibuat otomatis oleh workflow (`flutter create`), jadi tidak perlu ada di repo.

## Mengubah prompt dan genre
Edit file `.txt` di `assets/prompts/` atau `assets/genres.txt` langsung di GitHub, commit, lalu workflow akan membuat APK baru. Di `character_template.txt` dan `story_template.txt`, tulisan `{{nama}}` akan diganti dengan isi dari form di aplikasi.

## Catatan
- API key dibuat di aistudio.google.com dan disimpan lokal di perangkat. Percakapan hanya dikirim ke Google Gemini.
- Gemini punya filter keamanan sendiri. Jika balasan diblokir, aplikasi menampilkan alasannya.
- APK memakai signing debug bawaan Flutter. Untuk Play Store perlu signing key sendiri, dan ganti `--org com.example` di workflow dengan ID milikmu.
