# 📬 StampsHunter — Platform Koleksi & Pembuatan Perangko Digital

[![Flutter](https://img.shields.io/badge/Flutter-v3.19+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-v0.100+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Supabase](https://img.shields.io/badge/Supabase-Storage-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**StampsHunter** adalah platform berbasis mobile (Android & iOS) bagi kolektor untuk membuat, menghias, dan membagikan koleksi perangko digital secara sosial. Aplikasi ini memproses foto perangko fisik biasa menjadi format digital dengan tepi gerigi, filter vintage, dan tipografi kustom.

---

## ✨ Fitur Utama (Key Features)

### 📸 Kamera & Pemotong Foto (Cropping)
* Mengambil foto perangko fisik menggunakan kamera HP secara langsung.
* Memotong (crop) area foto secara manual untuk memfokuskan objek perangko sebelum masuk ke editor.

### 🎨 Editor Perangko Digital
* **Bingkai Gerigi (Perforasi)**: Mengatur ukuran gigi gerigi (*tooth size*), jarak gerigi (*tooth spacing*), lebar border, dan warna border secara interaktif.
* **Filter Vintage**: Menerapkan filter sepia, intensitas butiran kertas (*grain*), kehangatan warna (*warmth*), dan efek vignette retro.
* **Overlay Teks**: Menambahkan tulisan bergaya klasik pada perangko dengan pilihan font (Serif, Monospace, Script, dll.) beserta pengaturan posisi dan margin.

### 🌐 Feed Sosial & Galeri Kolektor
* **Feed Publik & Following**: Melihat perangko terbaru atau terpopuler (berdasarkan jumlah like) dari kolektor lain, serta melihat perangko khusus dari akun yang diikuti.
* **Interaksi Sosial**: Fitur untuk memberikan Like dan menuliskan komentar (mendukung balasan komentar bertingkat).
* **Profil Pengguna**: Menampilkan galeri perangko yang telah dibuat, bio, dan edit nama/foto profil.

### 🛡️ Penyimpanan Gambar dengan Fallback Lokal
* Menyimpan gambar asli, gambar stamp hasil edit, dan thumbnail ke **Supabase Storage**.
* Dilengkapi *fallback* otomatis ke penyimpanan lokal backend jika unggahan ke Supabase mengalami kegagalan atau koneksi internet bermasalah.

---

## 🛠️ Tech Stack & Arsitektur

### Frontend (Mobile App)
* **Framework**: Flutter (Dart)
* **State Management**: Riverpod (Notifier & AsyncNotifier)
* **Routing**: GoRouter
* **Networking**: Dio (dengan interseptor autentikasi dan timeout)
* **UI**: Google Fonts (Montserrat & Playfair Display), CustomPainter untuk menggambar gerigi perangko secara dinamis.

### Backend (API Server)
* **Framework**: FastAPI (Python)
* **ORM**: SQLAlchemy + aiosqlite (async)
* **Database Migrations**: Alembic
* **Cloud Storage**: Supabase Storage Client (dengan timeout koneksi)
* **Image Processing**: Pillow (PIL) untuk pemrosesan filter, gerigi, dan teks pada gambar.

---

## 🚀 Panduan Memulai (Getting Started)

### Prerequisites
* Flutter SDK (v3.19 atau lebih baru)
* Python (v3.10 atau lebih baru)
* Proyek Supabase (opsional, server akan otomatis beralih ke penyimpanan lokal jika tidak dikonfigurasi)

---

### 1. Konfigurasi Backend (FastAPI)

1. Masuk ke direktori backend:
   ```bash
   cd backend
   ```
2. Buat Virtual Environment dan aktifkan:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```
3. Instal dependensi:
   ```bash
   pip install -r requirements.txt
   ```
4. Buat file `.env` di dalam folder `backend` (salin dari `.env.example`):
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_KEY=your-service-role-key
   ```
5. Jalankan migrasi database SQLite lokal:
   ```bash
   alembic upgrade head
   ```
6. Jalankan server FastAPI:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

---

### 2. Konfigurasi Frontend (Flutter)

1. Kembali ke direktori root proyek.
2. Unduh paket dependensi Flutter:
   ```bash
   flutter pub get
   ```
3. Hubungkan perangkat fisik atau aktifkan emulator.
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 🧪 Pengujian (Testing)
* **Backend API & Unit Tests**:
  ```bash
  cd backend && pytest
  ```
* **Frontend Unit & Widget Tests**:
  ```bash
  flutter test
  ```
* **Integration Tests (End-to-End)**:
  ```bash
  flutter test integration_test/app_test.dart
  ```

---

## 📄 Lisensi (License)
Proyek ini menggunakan **Lisensi MIT** - lihat file [LICENSE](LICENSE) jika ada.
