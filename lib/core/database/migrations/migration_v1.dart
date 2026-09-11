import 'package:sqflite/sqflite.dart';

class MigrationV1 {
  static Future<void> apply(Database db) async {
    for (final sql in statements) {
      await db.execute(sql);
    }
  }

  static const statements = <String>[
    '''
CREATE TABLE stores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_name TEXT NOT NULL,
  display_name TEXT,
  logo_path TEXT,
  address_line_1 TEXT,
  address_line_2 TEXT,
  area TEXT,
  city TEXT,
  district TEXT,
  state TEXT,
  country TEXT NOT NULL DEFAULT 'India',
  postal_code TEXT,
  phone TEXT,
  alternate_phone TEXT,
  email TEXT,
  website TEXT,
  is_gst_registered INTEGER NOT NULL DEFAULT 0,
  gstin TEXT,
  business_type TEXT,
  default_tax_rate INTEGER NOT NULL DEFAULT 0,
  invoice_prefix TEXT NOT NULL DEFAULT 'INV',
  next_invoice_number INTEGER NOT NULL DEFAULT 1,
  receipt_footer TEXT,
  currency_code TEXT NOT NULL DEFAULT 'INR',
  currency_symbol TEXT NOT NULL DEFAULT '₹',
  is_setup_completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (store_id) REFERENCES stores(id)
)
''',
    '''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  sku TEXT,
  category_id INTEGER,
  unit TEXT NOT NULL DEFAULT 'pcs',
  purchase_price INTEGER NOT NULL DEFAULT 0,
  selling_price INTEGER NOT NULL DEFAULT 0,
  tax_rate INTEGER NOT NULL DEFAULT 0,
  minimum_stock INTEGER NOT NULL DEFAULT 0,
  current_stock INTEGER NOT NULL DEFAULT 0,
  image_path TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (store_id) REFERENCES stores(id),
  FOREIGN KEY (category_id) REFERENCES categories(id)
)
''',
    '''
CREATE TABLE product_barcodes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  barcode TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
)
''',
    '''
CREATE TABLE stock_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  transaction_type TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  reference_type TEXT,
  reference_id INTEGER,
  unit_cost INTEGER,
  note TEXT,
  created_at INTEGER NOT NULL,
  created_by INTEGER,
  FOREIGN KEY (product_id) REFERENCES products(id)
)
''',
    '''
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  credit_limit INTEGER NOT NULL DEFAULT 0,
  outstanding_balance INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (store_id) REFERENCES stores(id)
)
''',
    '''
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id INTEGER NOT NULL,
  invoice_number TEXT NOT NULL,
  customer_id INTEGER,
  subtotal INTEGER NOT NULL,
  discount INTEGER NOT NULL DEFAULT 0,
  tax INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL,
  status TEXT NOT NULL,
  original_invoice_id INTEGER,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(store_id, invoice_number),
  FOREIGN KEY (store_id) REFERENCES stores(id),
  FOREIGN KEY (customer_id) REFERENCES customers(id)
)
''',
    '''
CREATE TABLE invoice_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  product_id INTEGER,
  product_name_snapshot TEXT NOT NULL,
  barcode_snapshot TEXT,
  quantity INTEGER NOT NULL,
  unit_price INTEGER NOT NULL,
  discount INTEGER NOT NULL DEFAULT 0,
  tax INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id)
)
''',
    '''
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  payment_method TEXT NOT NULL,
  amount INTEGER NOT NULL,
  received_amount INTEGER,
  change_amount INTEGER,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id)
)
''',
    '''
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id INTEGER NOT NULL,
  category TEXT NOT NULL,
  amount INTEGER NOT NULL,
  payment_method TEXT NOT NULL,
  note TEXT,
  spent_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (store_id) REFERENCES stores(id)
)
''',
    '''
CREATE TABLE printers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  connection_type TEXT NOT NULL,
  address TEXT,
  paper_size TEXT NOT NULL DEFAULT '58mm',
  is_default INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''',
    '''
CREATE TABLE backup_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_name TEXT NOT NULL,
  drive_file_id TEXT,
  local_path TEXT,
  backup_version INTEGER NOT NULL,
  database_version INTEGER NOT NULL,
  file_size INTEGER,
  checksum TEXT,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  error_message TEXT
)
''',
    '''
CREATE TABLE audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id INTEGER,
  metadata TEXT,
  created_at INTEGER NOT NULL,
  user_id INTEGER
)
''',
    'CREATE INDEX idx_products_sku ON products(sku)',
    'CREATE INDEX idx_products_name ON products(name)',
    'CREATE INDEX idx_products_is_active ON products(is_active)',
    'CREATE INDEX idx_products_store ON products(store_id)',
    'CREATE UNIQUE INDEX idx_product_barcodes_barcode ON product_barcodes(barcode)',
    'CREATE INDEX idx_invoices_number ON invoices(invoice_number)',
    'CREATE INDEX idx_invoices_created_at ON invoices(created_at)',
    'CREATE INDEX idx_invoices_customer ON invoices(customer_id)',
    'CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id)',
    'CREATE INDEX idx_invoice_items_product ON invoice_items(product_id)',
    'CREATE INDEX idx_payments_invoice ON payments(invoice_id)',
    'CREATE INDEX idx_payments_method ON payments(payment_method)',
    'CREATE INDEX idx_stock_product ON stock_transactions(product_id)',
    'CREATE INDEX idx_stock_created ON stock_transactions(created_at)',
    'CREATE UNIQUE INDEX idx_products_store_sku ON products(store_id, sku) WHERE sku IS NOT NULL AND sku != ""',
  ];
}
