# Presensi Kebun Tomat

Aplikasi presensi petugas kebun tomat berbasis Flutter + Flask backend.

---

## Setup Backend (Flask + MySQL)

### Prasyarat
- Python 3.9+
- MySQL Server (bisa pakai XAMPP / MySQL Community / MariaDB)

### 1. Buat database kosong di MySQL

```sql
CREATE DATABASE presensi_kebun_tomat CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Sesuaikan konfigurasi koneksi

Buka `apppy/app.py` dan edit bagian ini sesuai environment lokal kamu:

```python
DB_HOST     = "localhost"
DB_PORT     = 3306
DB_USER     = "root"         # username MySQL kamu
DB_PASSWORD = ""             # password MySQL kamu (kosongkan jika tidak ada)
DB_NAME     = "presensi_kebun_tomat"
```

### 3. Install dependencies

```bash
cd apppy
pip install -r Requirements.txt
```

### 4. Jalankan pertama kali

```bash
python app.py
```

Saat pertama dijalankan, Flask akan otomatis:
- Membuat semua tabel di database (`petugas`, `jadwal`, `pengumuman`, `presensi`)
- Meng-import data dari `data/petugas.json` & `data/jadwal.json` ke MySQL
- Membuat akun admin baru

### Akun Admin Default

| Field    | Nilai            |
|----------|------------------|
| Username | `admin`          |
| Password | `Admin@kebun2026`|
| Role     | `admin`          |

> **Catatan:** Password petugas lama dari `petugas.json` akan di-hash otomatis saat seed. Login masih bisa pakai username dan password lama yang sama.

---

## Endpoint API

| Method | URL | Keterangan |
|--------|-----|------------|
| GET | `/api/pengumuman` | Daftar pengumuman |
| POST | `/api/pengumuman` | Tambah pengumuman (admin) |
| DELETE | `/api/pengumuman/<id>` | Hapus pengumuman (admin) |
| GET | `/api/presensi` | Daftar presensi (`?id_petugas=`, `?tanggal=`) |
| POST | `/api/presensi` | Submit presensi baru |
| POST | `/api/login` | Login |
| GET | `/api/petugas` | List semua petugas (admin) |
| POST | `/api/petugas` | Tambah petugas baru (admin) |
| GET | `/api/petugas/<id>` | Detail petugas |
| POST | `/api/petugas/<id>/foto` | Upload foto profil |
| GET | `/api/jadwal` | Daftar jadwal (`?tanggal=`) |
| POST | `/api/jadwal` | Tambah jadwal (admin) |
| DELETE | `/api/jadwal/<id>` | Hapus jadwal (admin) |

---

## Logika Status Presensi (Hadir/Telat)

Status dihitung otomatis di backend saat `POST /api/presensi`:
1. Ambil semua jadwal dengan tanggal = hari ini
2. Kalau ada jadwal, ambil `jam_mulai` paling awal
3. Toleransi = jam_mulai_awal + 15 menit
4. Kalau tidak ada jadwal hari ini → fallback ke batas default **08:00**

---

## Setup Flutter

### Tambah packages baru

```bash
flutter pub get
```

### Android permissions (sudah terkonfigurasi)
- `CAMERA` — untuk foto presensi
- `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` — untuk GPS

### Target emulator
Backend berjalan di `10.0.2.2:8000` dari sisi emulator Android (alias `localhost` di host machine).
Untuk device fisik, ganti `baseUrl` di `lib/endpoints/endpoints.dart` ke IP lokal jaringan kamu (contoh: `192.168.x.x:8000`).
