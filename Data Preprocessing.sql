SELECT * 
FROM rakamindataanalyst.RakaminDA.KantorCabang 
LIMIT 100;

-- STEP 1: PENGGABUNGAN DATA (DATA GATHERING)
-- Membuat tabel analisa baru di dataset RakaminDA.
CREATE OR REPLACE TABLE `rakamindataanalyst.RakaminDA.tabel_analisa` AS
WITH base_data AS (
  SELECT
    t.transaction_id,
    t.date,
    t.branch_id,
    c.branch_name,
    c.kota,
    c.provinsi,
    c.rating AS rating_cabang, 
    t.customer_name,
    t.product_id,
    p.product_name,
    t.price AS actual_price,    
    t.discount_percentage,
    t.rating AS rating_transaksi 
  FROM 
    `rakamindataanalyst.RakaminDA.FinalTransaction` t
  LEFT JOIN 
    `rakamindataanalyst.RakaminDA.KantorCabang` c 
    ON t.branch_id = c.branch_id
  LEFT JOIN 
    `rakamindataanalyst.RakaminDA.Product` p 
    ON t.product_id = p.product_id
),

-- STEP 2: PERHITUNGAN LOGIKA BISNIS (LOGICAL MAPPING)
-- Menghitung persentase gross laba berdasarkan rentang harga produk
-- serta menghitung total penjualan bersih (nett_sales) setelah diskon.
financial_calculations AS (
  SELECT
    *,
    CASE
      WHEN actual_price <= 50000 THEN 0.10
      WHEN actual_price > 50000 AND actual_price <= 100000 THEN 0.15
      WHEN actual_price > 100000 AND actual_price <= 300000 THEN 0.20
      WHEN actual_price > 300000 AND actual_price <= 500000 THEN 0.25
      WHEN actual_price > 500000 THEN 0.30
    END AS persentase_gross_laba,

    -- Menghitung harga setelah diskon (nett_sales)
    actual_price * (1 - discount_percentage) AS nett_sales
  FROM 
    base_data
)

-- STEP 3: FINALISASI & PROYEKSI DATA (FINAL SELECTION)
-- Mengambil seluruh kolom wajib dan menghitung keuntungan bersih (nett_profit).
SELECT
  transaction_id,
  date,
  branch_id,
  branch_name,
  kota,
  provinsi,
  rating_cabang,
  customer_name,
  product_id,
  product_name,
  actual_price,
  discount_percentage,
  persentase_gross_laba,
  nett_sales,
  -- Formula: Keuntungan Bersih = Penjualan Bersih x Persentase Laba
  (nett_sales * persentase_gross_laba) AS nett_profit,
  rating_transaksi
FROM 
  financial_calculations;