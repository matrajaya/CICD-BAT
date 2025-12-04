Siap! Berikut **README.md lengkap**, khusus untuk script `.bat` yang kamu berikan.
Tinggal copy–paste ke GitHub — sudah rapi, jelas, dan profesional.

---

# 🚀 **CI/CD Deployment Script for IIS (Windows Server)**

Script ini digunakan untuk melakukan proses **deploy otomatis** aplikasi Web & Service pada IIS, lengkap dengan:

* Load konfigurasi dari file `cicd.config`
* Backup otomatis sebelum deploy
* Restore (rollback) otomatis bila deploy gagal
* Log file otomatis
* Mendukung parameter:

  * `web` → deploy Web saja
  * `service` → deploy Service saja
  * tanpa parameter → deploy keduanya

---

## 📁 **Struktur Folder**

Pastikan struktur foldernya seperti berikut:

```
/
├── cicd.bat                # Script utama deploy
├── cicd.config             # File konfigurasi
├── deploy-log.txt          # (akan dibuat otomatis)
├── backup/                 # (akan dibuat otomatis)
│   ├── WEB_timestamp/
│   └── SERVICE_timestamp/
├── web/                    # Folder source WEB
└── service/                # Folder source SERVICE
```

---

## ⚙️ **File Konfigurasi (cicd.config)**

Isi contoh:

```
WEB_TARGET=D:\IIS\SIP.PKSharian\FRG
SERVICE_TARGET=D:\IIS\SIP.Services\FR

APP_POOL_WEB=PIMS-SIP
APP_POOL_SERVICE=SIP.Service
```

Keterangan:

| Key                | Fungsi                          |
| ------------------ | ------------------------------- |
| `WEB_TARGET`       | Folder tujuan deploy Web        |
| `SERVICE_TARGET`   | Folder tujuan deploy Service    |
| `APP_POOL_WEB`     | Nama IIS App Pool untuk Web     |
| `APP_POOL_SERVICE` | Nama IIS App Pool untuk Service |

---

## ▶️ **Cara Menjalankan Script Deploy**

### **1. Deploy Web saja**

```
cicd.bat web
```

### **2. Deploy Service saja**

```
cicd.bat service
```

### **3. Deploy keduanya (default jika tanpa parameter)**

```
cicd.bat
```

---

## 🔄 **Alur Kerja Script**

### **1. Load file config**

Script membaca semua key dari file:

```
cicd.config
```

dan otomatis membuat variabel:

* `WEB_TARGET`
* `SERVICE_TARGET`
* `APP_POOL_WEB`
* `APP_POOL_SERVICE`

Jika file tidak ditemukan → script berhenti.

---

### **2. Menentukan mode deploy (berdasarkan parameter)**

| Parameter | Deploy Web | Deploy Service |
| --------- | ---------- | -------------- |
| `web`     | ✔          | ✘              |
| `service` | ✘          | ✔              |
| kosong    | ✔          | ✔              |

---

### **3. Backup sebelum deploy**

Backup dilakukan **tanpa menghentikan app pool dulu**, supaya aman dan tidak mengganggu aplikasi.

Folder backup dibuat otomatis:

```
backup\WEB_YYYY-MM-DD_HH-MM\
backup\SERVICE_YYYY-MM-DD_HH-MM\
```

---

### **4. Stop App Pool**

Jika deploy Web → stop `APP_POOL_WEB`
Jika deploy Service → stop `APP_POOL_SERVICE`

Perintah:

```
appcmd stop apppool /apppool.name:"{NAMA_POOL}"
```

---

### **5. Copy file dari source → target**

Menggunakan:

```
robocopy /E /IS /IT
```

Artinya:

* Hanya replace file yang berubah
* Tidak menghapus file di target
* Aman untuk environment production

Jika robocopy return code ≥ 8 → dianggap gagal, masuk rollback.

---

### **6. Validasi hasil deploy**

Jika ada error → rollback otomatis
Jika semua sukses → lanjut start app pool.

---

### **7. Start App Pool kembali**

Pool Web dan/atau Service akan dinyalakan kembali setelah deploy selesai.

---

### **8. Logging**

Semua proses dicatat ke:

```
deploy-log.txt
```

---

## ♻️ **Rollback Otomatis**

Jika deploy gagal:

1. File backup dipulihkan kembali ke target
2. App pool dinyalakan lagi
3. Log dicatat sebagai “rollback applied”

Script menjamin kondisi server **kembali normal** meski deploy gagal.

---

## 🧪 Contoh Penggunaan

### **Deploy Web saja:**

```
cicd.bat web
```

### **Deploy Service saja:**

```
cicd.bat service
```

### **Backup + Deploy keduanya:**

```
cicd.bat
```

---

## 📝 NOTES PENTING

* Pastikan folder `web` dan `service` berisi file yang benar sebelum deploy.
* Jangan memindahkan file `cicd.config` — wajib berada 1 folder dengan script `.bat`.
* App Pool harus sudah dibuat di IIS.

---

Kalau kamu mau, saya bisa otomatis **generate versi PDF**, **DOCX**, atau membuatkan **diagram flow CI/CD** untuk README ini.
