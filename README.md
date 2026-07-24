# 📬 StampsHunter — Digital Stamp Collector & Creator Platform

[![Flutter](https://img.shields.io/badge/Flutter-v3.19+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-v0.100+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Supabase](https://img.shields.io/badge/Supabase-Storage-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**StampsHunter** adalah platform modern berbasis mobile (iOS & Android) bagi para filatelis dan pencinta seni untuk berburu, membuat, menghias, dan membagikan koleksi perangko digital secara sosial. 

Dengan menggabungkan kekuatan pemrosesan gambar di backend dan estetika premium di frontend, StampsHunter mengubah foto biasa dari kamera menjadi mahakarya perangko digital bernilai tinggi dengan gerigi presisi, filter vintage antik, dan tipografi kustom.

---

## ✨ Fitur Utama (Key Features)

### 📸 Kamera & Pemangkas Foto Pintar
* Tangkap gambar perangko fisik Anda secara instan menggunakan kamera internal.
* Fitur *Cropping* (pemotongan gambar) yang presisi untuk memfokuskan objek perangko sebelum diedit.

### 🎨 Modifikasi Perangko Digital (*Stamp Editor*)
* **Perforasi Klasik (Gerigi)**: Sesuaikan ukuran gigi (*tooth size*), jarak gerigi (*tooth spacing*), lebar border, dan warna border secara interaktif.
* **Filter Vintage Khusus**: Berikan nuansa antik menggunakan filter sepia, intensitas butiran kertas (*grain*), kehangatan warna (*warmth*), dan efek vignette retro.
* **Tipografi Kustom (Text Overlay)**: Tambahkan tulisan pos bergaya klasik dengan opsi font Serif, Monospace, Script, dll., beserta pengaturan letak dan margin.

### 🌐 Feed Sosial & Galeri Kolektor
* **Trending & Following Feeds**: Lihat karya perangko terpopuler dari kolektor lain atau pantau linimasa dari kolektor yang Anda ikuti.
* **Interaksi Sosial**: Berikan apresiasi berupa *Like* dan diskusikan keunikan perangko di kolom komentar interaktif (mendukung balasan komentar bertingkat).
* **Arsip Koleksi Pribadi**: Profil lengkap yang menampilkan galeri seluruh perangko Anda beserta bio dan foto profil kustom.

### 🛡️ Offline-First & Cloud Sync Hybrid
* Pengunggahan file menggunakan **Supabase Storage** terenkripsi di cloud.
* Dilengkapi *fallback* otomatis ke **Penyimpanan Lokal (Local Storage)** jika Anda sedang berada di daerah minim koneksi (offline-first).

---

## 🛠️ Tech Stack & Arsitektur

### Frontend (Mobile App)
* **Framework**: Flutter (Dart)
* **State Management**: Flutter Riverpod (Notifier & AsyncNotifier)
* **Routing**: GoRouter
* **Networking**: Dio (dengan interseptor token dan konfigurasi timeout terpusat)
* **UI/Aesthetics**: Google Fonts (Montserrat & Playfair Display), Custom Painter untuk simulasi gerigi perangko presisi.

### Backend (API Server)
* **Framework**: FastAPI (Python)
* **Asynchronous ORM**: SQLAlchemy 2.0 + aiosqlite
* **Database Migrations**: Alembic
* **Cloud Storage Integration**: Supabase Storage Client (dengan penanganan *non-blocking thread timeout*)
* **Image Processing Engine**: Pillow (PIL)

---

## 🚀 Panduan Memulai (Getting Started)

### Prerequisites
* Flutter SDK (v3.19 atau lebih baru)
* Python (v3.10 atau lebih baru)
* Akun proyek Supabase (opsional, server akan otomatis beralih ke penyimpanan lokal jika tidak dikonfigurasi)

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
3. Hubungkan perangkat fisik Anda atau nyalakan Android Emulator / iOS Simulator.
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 🧪 Strategi Pengujian (Testing Strategy)
Aplikasi ini dibangun menggunakan prinsip *test-driven* untuk menjamin stabilitas:

* **Backend Unit & API Tests**:
  ```bash
  cd backend && pytest
  ```
* **Frontend Widget & Unit Tests**:
  ```bash
  flutter test
  ```
* **Integration Tests (End-to-End)**:
  ```bash
  flutter test integration_test/app_test.dart
  ```

---

## 📄 Lisensi (License)
Proyek ini dilisensikan di bawah **Lisensi MIT** - lihat file [LICENSE](LICENSE) untuk detail lebih lanjut.
