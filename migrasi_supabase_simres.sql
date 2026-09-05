-- =========================================================================
-- SCRIPT MIGRASI DATABASE SUPABASE POSTGRESQL - SIMRES STPL BEKASI
-- =========================================================================
-- Jalankan seluruh script ini di menu: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- Script ini aman dijalankan berulang kali (Idempotent: IF NOT EXISTS).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. PEMBARUAN KOLOM PADA TABEL MASTER_PM (Kontrak, Vokasional & Terminasi)
-- -------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.master_pm 
ADD COLUMN IF NOT EXISTS tgl_kontrak_mulai DATE,
ADD COLUMN IF NOT EXISTS tgl_kontrak_habis DATE,
ADD COLUMN IF NOT EXISTS surat_kontrak_url TEXT,
ADD COLUMN IF NOT EXISTS vokasional TEXT,
ADD COLUMN IF NOT EXISTS tgl_terminasi DATE;

-- -------------------------------------------------------------------------
-- 2. PEMBARUAN KOLOM PADA TABEL ASESMEN_DETIL (Kontrak & Vokasional)
-- -------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.asesmen_detil 
ADD COLUMN IF NOT EXISTS tgl_kontrak_mulai DATE,
ADD COLUMN IF NOT EXISTS tgl_kontrak_habis DATE,
ADD COLUMN IF NOT EXISTS surat_kontrak_url TEXT,
ADD COLUMN IF NOT EXISTS vokasional TEXT;

-- -------------------------------------------------------------------------
-- 3. PEMBUATAN TABEL MASTER_VOKASIONAL (Kelola Program Vokasional di Role Admin)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.master_vokasional (
    id TEXT PRIMARY KEY,
    nama TEXT NOT NULL,
    kategori TEXT DEFAULT 'Umum',
    instruktur TEXT DEFAULT 'Instruktur Vokasi',
    deskripsi TEXT,
    status TEXT DEFAULT 'Aktif',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed Data Awal 9 Program Vokasional (Jika Belum Ada)
INSERT INTO public.master_vokasional (id, nama, kategori, instruktur, deskripsi, status)
VALUES 
    ('VOK-01', 'Menjahit & Konveksi', 'Konveksi & Sablon', 'Instruktur Tata Busana', 'Pembuatan pakaian, perbaikan busana, dan jahit seragam.', 'Aktif'),
    ('VOK-02', 'Barista & Olahan Kopi', 'Tata Boga & Minuman', 'Instruktur Barista', 'Teknik racik kopi, seduh espresso, dan pelayanan kedai kopi.', 'Aktif'),
    ('VOK-03', 'Tata Boga & Pembuatan Roti/Kue', 'Tata Boga & Minuman', 'Instruktur Kuliner', 'Pengolahan kue kering, roti manis, dan aneka snack makanan.', 'Aktif'),
    ('VOK-04', 'Pertanian Hidroponik & Kebun Sayur', 'Pertanian & Peternakan', 'Instruktur Pertanian', 'Budi daya tanaman sayuran metode hidroponik modern.', 'Aktif'),
    ('VOK-05', 'Kerajinan Keset & Tekstil Daur Ulang', 'Kerajinan Tangan', 'Instruktur Kriya', 'Anyaman keset perca, suvenir, dan produk anyaman tangan.', 'Aktif'),
    ('VOK-06', 'Perbengkelan Sepeda Motor Ringan', 'Jasa & Bengkel', 'Instruktur Otomotif', 'Servis dasar, tune up, ganti oli, dan perbaikan ringan.', 'Aktif'),
    ('VOK-07', 'Sablon & Percetakan Kaos/Merchandise', 'Konveksi & Sablon', 'Instruktur Grafis', 'Teknik cetak sablon manual dan digital apparel.', 'Aktif'),
    ('VOK-08', 'Desain Grafis & Komputer Dasar', 'Teknologi Informasi', 'Instruktur Digital', 'Aplikasi perkantoran, editing foto canva/photoshop, dan entri data.', 'Aktif'),
    ('VOK-09', 'Pangkas Rambut & Barbershop', 'Jasa & Bengkel', 'Instruktur Grooming', 'Teknik potong rambut pria modern, styling, dan pencukuran.', 'Aktif')
ON CONFLICT (id) DO NOTHING;

-- -------------------------------------------------------------------------
-- 4. PEMBUATAN TABEL REASESMEN_PM (Riwayat Re-Asesmen Berkala Pekerja Sosial)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reasesmen_pm (
    id TEXT PRIMARY KEY,
    id_pm TEXT NOT NULL,
    nama_pm TEXT,
    peksos TEXT NOT NULL,
    tahap TEXT NOT NULL,
    tgl_reasesmen DATE NOT NULL,
    fisik TEXT,
    psikologis TEXT,
    sosial TEXT,
    vokasional TEXT,
    kesimpulan TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index Pencarian Re-asesmen per PM agar pemuatan cepat
CREATE INDEX IF NOT EXISTS idx_reasesmen_id_pm ON public.reasesmen_pm(id_pm);

-- -------------------------------------------------------------------------
-- 5. KONFIGURASI ROW LEVEL SECURITY (RLS) UNTUK TABEL BARU
-- -------------------------------------------------------------------------
ALTER TABLE public.master_vokasional ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reasesmen_pm ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public all master_vokasional') THEN
        CREATE POLICY "Allow public all master_vokasional" ON public.master_vokasional FOR ALL USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public all reasesmen_pm') THEN
        CREATE POLICY "Allow public all reasesmen_pm" ON public.reasesmen_pm FOR ALL USING (true) WITH CHECK (true);
    END IF;
END $$;

-- -------------------------------------------------------------------------
-- 6. KONFIGURASI HAK AKSES TABEL AKUN (MANAJEMEN USER CRUD ROLE ADMIN)
-- -------------------------------------------------------------------------
-- Memastikan operasi SELECT, INSERT, UPDATE, dan DELETE pada tabel akun diizinkan via Supabase API
ALTER TABLE IF EXISTS public.akun ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public all akun') THEN
        CREATE POLICY "Allow public all akun" ON public.akun FOR ALL USING (true) WITH CHECK (true);
    END IF;
END $$;

-- Index username pada tabel akun agar proses login & pencarian user instan
CREATE INDEX IF NOT EXISTS idx_akun_username ON public.akun(username);

-- =========================================================================
-- SELESAI: Seluruh tabel & kolom pendukung SIMRES siap digunakan 100%!
-- =========================================================================
