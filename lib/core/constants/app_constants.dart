class SettingKeys {
  static const onboardingComplete = 'onboarding_complete';
  static const localeCode = 'locale_code';
  static const themeMode = 'theme_mode';
  static const accentColor = 'accent_color';
  static const pinEnabled = 'pin_enabled';
  static const biometricEnabled = 'biometric_enabled';
  static const allowNegativeStock = 'allow_negative_stock';
  static const autoBackup = 'auto_backup';
  static const lastAutoBackupAt = 'last_auto_backup_at';
  static const googleAccountEmail = 'google_account_email';
  static const paperSize = 'paper_size';
  static const sampleDataLoaded = 'sample_data_loaded';
  static const lastInvoiceId = 'last_invoice_id';
  static const premiumUnlocked = 'premium_unlocked';
  static const installId = 'install_id';
  static const premiumLicenseToken = 'premium_license_token';
}

/// Free tier caps and one-time unlock price (paise).
class PremiumLimits {
  static const freeItemLimit = 10;
  static const unlockPricePaise = 9900; // ₹99 one-time
}

class DbConstants {
  static const fileName = 'pos_billing.db';
  static const schemaVersion = 1;
  static const backupFormatVersion = 1;
  static const appVersion = '1.0.0';
}

class PaymentMethods {
  static const cash = 'cash';
  static const upi = 'upi';
  static const card = 'card';
  static const credit = 'credit';
}

class InvoiceStatus {
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const refunded = 'refunded';
}

class StockTxn {
  static const purchase = 'PURCHASE';
  static const sale = 'SALE';
  static const adjustment = 'ADJUSTMENT';
  static const opening = 'OPENING';
  static const refund = 'RETURN';
}

class AuditActions {
  static const productCreated = 'PRODUCT_CREATED';
  static const productUpdated = 'PRODUCT_UPDATED';
  static const priceChanged = 'PRICE_CHANGED';
  static const stockAdjusted = 'STOCK_ADJUSTED';
  static const saleCreated = 'SALE_CREATED';
  static const paymentReceived = 'PAYMENT_RECEIVED';
  static const saleCancelled = 'SALE_CANCELLED';
  static const refundCreated = 'REFUND_CREATED';
  static const backupCreated = 'BACKUP_CREATED';
  static const backupRestored = 'BACKUP_RESTORED';
  static const userLogin = 'USER_LOGIN';
  static const settingsChanged = 'SETTINGS_CHANGED';
}

class AppLinks {
  static const playStore =
      'https://play.google.com/store/apps/details?id=com.gk.pos_billing';
  static const shareTagline =
      'Billed with POS Billing - get the app: $playStore';
  static const supportEmail = 'agprakash406@gmail.com';
  static const supportPhone = '7845456609';
  static const supportPhoneE164 = '+917845456609';
  static const supportAddress = 'Velachery, Chennai 600042';
}
