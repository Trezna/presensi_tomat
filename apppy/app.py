"""
Backend Flask untuk app "presensi_kebun_tomat".
Menggunakan MySQL via Flask-SQLAlchemy + PyMySQL.

============================================================
AKUN ADMIN DEFAULT:
  username : admin
  password : Admin@kebun2026
============================================================

Endpoint:
  GET    /api/pengumuman
  POST   /api/pengumuman            (JSON: judul, isi)
  DELETE /api/pengumuman/<id>
  GET    /api/presensi              (?id_petugas=<id> dan/atau ?tanggal=YYYY-MM-DD)
  POST   /api/presensi              (multipart: nama_petugas, foto, id_petugas?, latitude?, longitude?)
  POST   /api/login                 (JSON: username, password)
  GET    /api/petugas               (list semua petugas tanpa password)
  POST   /api/petugas               (JSON: username, password, nama, role?)
  PUT    /api/petugas/<id>          (JSON: nama?, role?, password?)
  DELETE /api/petugas/<id>
  GET    /api/petugas/<id>
  POST   /api/petugas/<id>/foto     (multipart: foto)
  GET    /api/jadwal                (?tanggal=YYYY-MM-DD opsional)
  POST   /api/jadwal                (JSON: tanggal, judul, jam_mulai, jam_selesai, keterangan?)
  DELETE /api/jadwal/<id>
  GET    /uploads/<filename>
"""

import json
import os
from datetime import datetime, time as dtime, date

import pymysql  # noqa: F401 — diperlukan agar SQLAlchemy pakai driver PyMySQL
from flask import Flask, jsonify, request, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename

# ─── Konfigurasi Koneksi Database ────────────────────────────────────────────
# Sesuaikan nilai-nilai ini dengan environment lokal kamu.
DB_HOST = "localhost"
DB_PORT = 3306
DB_USER = "root"          # ganti dengan username MySQL kamu
DB_PASSWORD = ""          # ganti dengan password MySQL kamu (bisa kosong jika tidak ada)
DB_NAME = "presensi_kebun_tomat"
# ─────────────────────────────────────────────────────────────────────────────

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
DATA_DIR = os.path.join(BASE_DIR, "data")

os.makedirs(UPLOAD_DIR, exist_ok=True)

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = (
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

# ─── Model ORM ───────────────────────────────────────────────────────────────

class Petugas(db.Model):
    __tablename__ = "petugas"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    nama = db.Column(db.String(100), nullable=False)
    role = db.Column(db.Enum("admin", "petugas"), nullable=False, default="petugas")
    foto_profil_url = db.Column(db.String(255), nullable=True)
    bergabung_sejak = db.Column(db.Date, nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "nama": self.nama,
            "role": self.role,
            "foto_profil_url": self.foto_profil_url,
            "bergabung_sejak": (
                self.bergabung_sejak.isoformat() if self.bergabung_sejak else ""
            ),
        }


class Jadwal(db.Model):
    __tablename__ = "jadwal"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    tanggal = db.Column(db.Date, nullable=False)
    judul = db.Column(db.String(150), nullable=False)
    jam_mulai = db.Column(db.Time, nullable=False)
    jam_selesai = db.Column(db.Time, nullable=False)
    keterangan = db.Column(db.Text, nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "tanggal": self.tanggal.isoformat(),
            "judul": self.judul,
            "jam_mulai": self.jam_mulai.strftime("%H:%M"),
            "jam_selesai": self.jam_selesai.strftime("%H:%M"),
            "keterangan": self.keterangan or "",
        }


class Pengumuman(db.Model):
    __tablename__ = "pengumuman"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    judul = db.Column(db.String(150), nullable=False)
    isi = db.Column(db.Text, nullable=False)
    tanggal = db.Column(db.Date, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "judul": self.judul,
            "isi": self.isi,
            "tanggal": self.tanggal.isoformat(),
        }


class Presensi(db.Model):
    __tablename__ = "presensi"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_petugas = db.Column(db.Integer, db.ForeignKey("petugas.id"), nullable=True)
    nama_petugas = db.Column(db.String(100), nullable=False)
    tanggal = db.Column(db.Date, nullable=False)
    jam = db.Column(db.Time, nullable=False)
    latitude = db.Column(db.Double, nullable=True)
    longitude = db.Column(db.Double, nullable=True)
    foto_url = db.Column(db.String(255), nullable=False)
    status = db.Column(db.Enum("Hadir", "Telat"), nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "id_petugas": self.id_petugas,
            "nama_petugas": self.nama_petugas,
            "tanggal": self.tanggal.isoformat(),
            "jam": self.jam.strftime("%H:%M"),
            "latitude": self.latitude,
            "longitude": self.longitude,
            "foto_url": self.foto_url,
            "status": self.status,
        }


# ─── Seed Data ────────────────────────────────────────────────────────────────

def _seed_database():
    """
    Dijalankan sekali saat tabel masih kosong.
    Seed: petugas dari data/petugas.json, jadwal dari data/jadwal.json,
    pengumuman awal, dan akun admin baru.

    Password admin: Admin@kebun2026
    """
    # --- Petugas ---
    petugas_file = os.path.join(DATA_DIR, "petugas.json")
    if os.path.exists(petugas_file) and Petugas.query.count() == 0:
        with open(petugas_file, "r") as f:
            try:
                daftar = json.load(f)
            except json.JSONDecodeError:
                daftar = []

        for p in daftar:
            raw_role = p.get("role", "petugas")
            # 'pengawas' di data lama → diperlakukan sebagai 'petugas'
            role = "petugas" if raw_role == "pengawas" else raw_role
            if role not in ("admin", "petugas"):
                role = "petugas"

            bergabung = None
            bj = p.get("bergabung_sejak")
            if bj:
                try:
                    bergabung = date.fromisoformat(bj)
                except ValueError:
                    pass

            entry = Petugas(
                username=p["username"],
                password=generate_password_hash(p["password"]),
                nama=p["nama"],
                role=role,
                foto_profil_url=p.get("foto_profil_url"),
                bergabung_sejak=bergabung,
            )
            db.session.add(entry)

        # Akun admin baru
        # ============================================================
        # AKUN ADMIN DEFAULT:
        #   username : admin
        #   password : Admin@kebun2026
        # ============================================================
        admin = Petugas(
            username="admin",
            password=generate_password_hash("Admin@kebun2026"),
            nama="Administrator",
            role="admin",
            foto_profil_url=None,
            bergabung_sejak=date.today(),
        )
        db.session.add(admin)
        db.session.commit()
        print("[SEED] Petugas + admin berhasil di-seed.")

    # --- Jadwal ---
    jadwal_file = os.path.join(DATA_DIR, "jadwal.json")
    if os.path.exists(jadwal_file) and Jadwal.query.count() == 0:
        with open(jadwal_file, "r") as f:
            try:
                daftar = json.load(f)
            except json.JSONDecodeError:
                daftar = []

        for j in daftar:
            try:
                entry = Jadwal(
                    tanggal=date.fromisoformat(j["tanggal"]),
                    judul=j["judul"],
                    jam_mulai=dtime.fromisoformat(j["jam_mulai"]),
                    jam_selesai=dtime.fromisoformat(j["jam_selesai"]),
                    keterangan=j.get("keterangan", ""),
                )
                db.session.add(entry)
            except (KeyError, ValueError):
                continue
        db.session.commit()
        print("[SEED] Jadwal berhasil di-seed.")

    # --- Pengumuman ---
    if Pengumuman.query.count() == 0:
        seed_pengumuman = [
            Pengumuman(
                judul="Jadwal Piket Minggu Ini",
                isi="Piket penyiraman dan pengecekan sensor dilakukan setiap pagi jam 07.00-08.00.",
                tanggal=date(2026, 7, 1),
            ),
            Pengumuman(
                judul="Pemeliharaan Sensor IoT",
                isi="Sensor kelembapan tanah di petak B akan dikalibrasi ulang tanggal 8 Juli.",
                tanggal=date(2026, 7, 3),
            ),
            Pengumuman(
                judul="Pengingat Presensi Foto",
                isi="Pastikan foto presensi diambil langsung di lokasi kebun, bukan dari galeri.",
                tanggal=date(2026, 7, 5),
            ),
        ]
        db.session.add_all(seed_pengumuman)
        db.session.commit()
        print("[SEED] Pengumuman berhasil di-seed.")


# ─── Helper: Hitung Status Hadir/Telat ───────────────────────────────────────

BATAS_HADIR_DEFAULT = dtime(8, 0)   # Fallback kalau tidak ada jadwal hari ini
TOLERANSI_MENIT = 15


def _hitung_status(jam_submit: dtime, tanggal_hari_ini: date) -> str:
    """
    Hitung status 'Hadir' atau 'Telat' berdasarkan jadwal hari ini.
    Logika:
      1. Ambil semua jadwal dengan tanggal == tanggal_hari_ini
      2. Kalau ada, ambil jam_mulai paling awal
      3. Batas = jam_mulai_awal + 15 menit toleransi
      4. Kalau tidak ada jadwal → fallback ke 08:00
    """
    jadwal_hari_ini = Jadwal.query.filter_by(tanggal=tanggal_hari_ini).all()

    if jadwal_hari_ini:
        jam_mulai_awal = min(j.jam_mulai for j in jadwal_hari_ini)
        # Tambah toleransi 15 menit
        total_menit = jam_mulai_awal.hour * 60 + jam_mulai_awal.minute + TOLERANSI_MENIT
        batas = dtime(total_menit // 60, total_menit % 60)
    else:
        # Tidak ada jadwal hari ini → fallback ke 08:00
        batas = BATAS_HADIR_DEFAULT

    return "Hadir" if jam_submit <= batas else "Telat"


# ─── Endpoint Pengumuman ─────────────────────────────────────────────────────

@app.route("/api/pengumuman", methods=["GET"])
def get_pengumuman():
    daftar = Pengumuman.query.order_by(Pengumuman.tanggal.desc()).all()
    return jsonify({"pengumuman": [p.to_dict() for p in daftar]})


@app.route("/api/pengumuman", methods=["POST"])
def post_pengumuman():
    body = request.get_json() or {}
    judul = (body.get("judul") or "").strip()
    isi = (body.get("isi") or "").strip()

    if not judul or not isi:
        return jsonify({"error": "judul dan isi wajib diisi"}), 400

    p = Pengumuman(judul=judul, isi=isi, tanggal=date.today())
    db.session.add(p)
    db.session.commit()
    return jsonify(p.to_dict()), 201


@app.route("/api/pengumuman/<int:pengumuman_id>", methods=["DELETE"])
def delete_pengumuman(pengumuman_id):
    p = Pengumuman.query.get(pengumuman_id)
    if p is None:
        return jsonify({"error": "Pengumuman tidak ditemukan"}), 404
    db.session.delete(p)
    db.session.commit()
    return jsonify({"message": "Pengumuman berhasil dihapus"}), 200


# ─── Endpoint Presensi ────────────────────────────────────────────────────────

@app.route("/api/presensi", methods=["GET"])
def get_presensi():
    query = Presensi.query
    id_petugas = request.args.get("id_petugas")
    tanggal_filter = request.args.get("tanggal")

    if id_petugas:
        try:
            query = query.filter_by(id_petugas=int(id_petugas))
        except ValueError:
            pass

    if tanggal_filter:
        try:
            tgl = date.fromisoformat(tanggal_filter)
            query = query.filter_by(tanggal=tgl)
        except ValueError:
            pass

    data = query.order_by(Presensi.id.desc()).all()
    return jsonify({"presensi": [p.to_dict() for p in data]})


@app.route("/api/presensi", methods=["POST"])
def post_presensi():
    nama_petugas = request.form.get("nama_petugas", "").strip()
    foto = request.files.get("foto")
    id_petugas_str = request.form.get("id_petugas", "").strip()
    latitude_str = request.form.get("latitude", "").strip()
    longitude_str = request.form.get("longitude", "").strip()

    if not nama_petugas:
        return jsonify({"error": "nama_petugas wajib diisi"}), 400
    if foto is None or foto.filename == "":
        return jsonify({"error": "foto wajib diupload"}), 400

    now = datetime.now()
    tanggal_hari_ini = now.date()
    jam_submit = now.time().replace(second=0, microsecond=0)

    status = _hitung_status(jam_submit, tanggal_hari_ini)

    ext = os.path.splitext(foto.filename)[1] or ".jpg"
    filename = secure_filename(
        f"presensi_{now.strftime('%Y%m%d%H%M%S')}{ext}"
    )
    foto.save(os.path.join(UPLOAD_DIR, filename))
    foto_url = f"{request.host_url}uploads/{filename}"

    id_petugas = None
    if id_petugas_str:
        try:
            id_petugas = int(id_petugas_str)
        except ValueError:
            pass

    latitude = None
    longitude = None
    if latitude_str:
        try:
            latitude = float(latitude_str)
        except ValueError:
            pass
    if longitude_str:
        try:
            longitude = float(longitude_str)
        except ValueError:
            pass

    record = Presensi(
        id_petugas=id_petugas,
        nama_petugas=nama_petugas,
        tanggal=tanggal_hari_ini,
        jam=jam_submit,
        latitude=latitude,
        longitude=longitude,
        foto_url=foto_url,
        status=status,
    )
    db.session.add(record)
    db.session.commit()

    return jsonify(record.to_dict()), 201


# ─── Endpoint Login ───────────────────────────────────────────────────────────

@app.route("/api/login", methods=["POST"])
def post_login():
    if request.is_json:
        body = request.get_json() or {}
    else:
        body = request.form

    username = (body.get("username") or "").strip().lower()
    password = (body.get("password") or "").strip()

    if not username or not password:
        return jsonify({"error": "username dan password wajib diisi"}), 400

    petugas = Petugas.query.filter(
        db.func.lower(Petugas.username) == username
    ).first()

    if petugas is None or not check_password_hash(petugas.password, password):
        return jsonify({"error": "Username atau password salah"}), 401

    return jsonify(petugas.to_dict()), 200


# ─── Endpoint Petugas ─────────────────────────────────────────────────────────

@app.route("/api/petugas", methods=["GET"])
def get_petugas_list():
    """Daftar semua petugas (tanpa password) — untuk Admin Dashboard."""
    daftar = Petugas.query.order_by(Petugas.id).all()
    return jsonify({"petugas": [p.to_dict() for p in daftar]})


@app.route("/api/petugas", methods=["POST"])
def post_petugas():
    """Tambah petugas baru — hanya untuk admin."""
    body = request.get_json() or {}
    username = (body.get("username") or "").strip().lower()
    password = (body.get("password") or "").strip()
    nama = (body.get("nama") or "").strip()
    role = (body.get("role") or "petugas").strip()

    if not username or not password or not nama:
        return jsonify({"error": "username, password, dan nama wajib diisi"}), 400

    if role not in ("admin", "petugas"):
        role = "petugas"

    existing = Petugas.query.filter(
        db.func.lower(Petugas.username) == username
    ).first()
    if existing:
        return jsonify({"error": f"Username '{username}' sudah digunakan"}), 409

    p = Petugas(
        username=username,
        password=generate_password_hash(password),
        nama=nama,
        role=role,
        bergabung_sejak=date.today(),
    )
    db.session.add(p)
    db.session.commit()
    return jsonify(p.to_dict()), 201


@app.route("/api/petugas/<int:petugas_id>", methods=["GET"])
def get_petugas(petugas_id):
    p = Petugas.query.get(petugas_id)
    if p is None:
        return jsonify({"error": "Petugas tidak ditemukan"}), 404
    return jsonify(p.to_dict()), 200


@app.route("/api/petugas/<int:petugas_id>", methods=["PUT"])
def put_petugas(petugas_id):
    """Edit data petugas (nama, role, password opsional) — hanya untuk admin."""
    p = Petugas.query.get(petugas_id)
    if p is None:
        return jsonify({"error": "Petugas tidak ditemukan"}), 404

    body = request.get_json() or {}
    nama = (body.get("nama") or "").strip()
    role = (body.get("role") or "").strip()
    password = (body.get("password") or "").strip()  # opsional, boleh kosong

    if nama:
        p.nama = nama
    if role in ("admin", "petugas"):
        p.role = role
    if password:
        p.password = generate_password_hash(password)

    db.session.commit()
    return jsonify(p.to_dict()), 200


@app.route("/api/petugas/<int:petugas_id>", methods=["DELETE"])
def delete_petugas(petugas_id):
    """Hapus petugas — histori presensi tetap ada, id_petugas jadi NULL."""
    p = Petugas.query.get(petugas_id)
    if p is None:
        return jsonify({"error": "Petugas tidak ditemukan"}), 404

    # Lepas keterkaitan ke presensi lama (histori TETAP ada — nama_petugas
    # sudah tersimpan sebagai teks terpisah — cuma id_petugas jadi NULL)
    Presensi.query.filter_by(id_petugas=petugas_id).update({"id_petugas": None})

    db.session.delete(p)
    db.session.commit()
    return jsonify({"message": "Petugas berhasil dihapus"}), 200


@app.route("/api/petugas/<int:petugas_id>/foto", methods=["POST"])
def upload_foto_profil(petugas_id):
    foto = request.files.get("foto")
    if foto is None or foto.filename == "":
        return jsonify({"error": "foto wajib diupload"}), 400

    p = Petugas.query.get(petugas_id)
    if p is None:
        return jsonify({"error": "Petugas tidak ditemukan"}), 404

    now = datetime.now()
    ext = os.path.splitext(foto.filename)[1] or ".jpg"
    filename = secure_filename(f"profil_{petugas_id}_{now.strftime('%Y%m%d%H%M%S')}{ext}")
    foto.save(os.path.join(UPLOAD_DIR, filename))

    p.foto_profil_url = f"{request.host_url}uploads/{filename}"
    db.session.commit()

    return jsonify(p.to_dict()), 200


# ─── Endpoint Jadwal ──────────────────────────────────────────────────────────

@app.route("/api/jadwal", methods=["GET"])
def get_jadwal():
    query = Jadwal.query
    tanggal_filter = request.args.get("tanggal")
    if tanggal_filter:
        try:
            tgl = date.fromisoformat(tanggal_filter)
            query = query.filter_by(tanggal=tgl)
        except ValueError:
            pass
    data = query.order_by(Jadwal.tanggal, Jadwal.jam_mulai).all()
    return jsonify({"jadwal": [j.to_dict() for j in data]})


@app.route("/api/jadwal", methods=["POST"])
def post_jadwal():
    body = request.get_json() or {}
    try:
        tanggal = date.fromisoformat(body.get("tanggal", ""))
        judul = (body.get("judul") or "").strip()
        jam_mulai = dtime.fromisoformat(body.get("jam_mulai", ""))
        jam_selesai = dtime.fromisoformat(body.get("jam_selesai", ""))
        keterangan = (body.get("keterangan") or "").strip()
    except (ValueError, TypeError):
        return jsonify({"error": "Format tanggal/jam tidak valid"}), 400

    if not judul:
        return jsonify({"error": "judul wajib diisi"}), 400

    j = Jadwal(
        tanggal=tanggal,
        judul=judul,
        jam_mulai=jam_mulai,
        jam_selesai=jam_selesai,
        keterangan=keterangan,
    )
    db.session.add(j)
    db.session.commit()
    return jsonify(j.to_dict()), 201


@app.route("/api/jadwal/<int:jadwal_id>", methods=["DELETE"])
def delete_jadwal(jadwal_id):
    j = Jadwal.query.get(jadwal_id)
    if j is None:
        return jsonify({"error": "Jadwal tidak ditemukan"}), 404
    db.session.delete(j)
    db.session.commit()
    return jsonify({"message": "Jadwal berhasil dihapus"}), 200


# ─── Serve Uploads ────────────────────────────────────────────────────────────

@app.route("/uploads/<path:filename>")
def serve_upload(filename):
    return send_from_directory(UPLOAD_DIR, filename)


# ─── Index ────────────────────────────────────────────────────────────────────

@app.route("/")
def index():
    return jsonify({
        "message": "Backend presensi_kebun_tomat (MySQL) jalan normal.",
        "endpoints": [
            "GET  /api/pengumuman",
            "POST /api/pengumuman",
            "DELETE /api/pengumuman/<id>",
            "GET  /api/presensi (?id_petugas=, ?tanggal=)",
            "POST /api/presensi",
            "POST /api/login",
            "GET  /api/petugas",
            "POST /api/petugas",
            "PUT  /api/petugas/<id>",
            "DELETE /api/petugas/<id>",
            "GET  /api/petugas/<id>",
            "POST /api/petugas/<id>/foto",
            "GET  /api/jadwal (?tanggal=)",
            "POST /api/jadwal",
            "DELETE /api/jadwal/<id>",
            "GET  /uploads/<filename>",
        ],
    })


# ─── Entry Point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    with app.app_context():
        db.create_all()       # Buat semua tabel kalau belum ada
        _seed_database()      # Seed data awal (hanya jika tabel masih kosong)

    # host 0.0.0.0 penting supaya bisa diakses dari emulator Android via 10.0.2.2
    app.run(host="0.0.0.0", port=8000, debug=True, threaded=True)