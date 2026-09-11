import 'package:pos_billing/core/utils/time.dart';

class StoreProfile {
  const StoreProfile({
    required this.id,
    required this.businessName,
    this.displayName,
    this.logoPath,
    this.addressLine1,
    this.addressLine2,
    this.area,
    this.city,
    this.district,
    this.state,
    this.country = 'India',
    this.postalCode,
    this.phone,
    this.alternatePhone,
    this.email,
    this.website,
    this.isGstRegistered = false,
    this.gstin,
    this.businessType,
    this.defaultTaxRateBp = 0,
    this.invoicePrefix = 'INV',
    this.nextInvoiceNumber = 1,
    this.receiptFooter,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.isSetupCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String businessName;
  final String? displayName;
  final String? logoPath;
  final String? addressLine1;
  final String? addressLine2;
  final String? area;
  final String? city;
  final String? district;
  final String? state;
  final String country;
  final String? postalCode;
  final String? phone;
  final String? alternatePhone;
  final String? email;
  final String? website;
  final bool isGstRegistered;
  final String? gstin;
  final String? businessType;
  final int defaultTaxRateBp;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final String? receiptFooter;
  final String currencyCode;
  final String currencySymbol;
  final bool isSetupCompleted;
  final int createdAt;
  final int updatedAt;

  String get name =>
      (displayName != null && displayName!.trim().isNotEmpty) ? displayName! : businessName;

  int get completionPercent {
    var filled = 1; // business name
    const total = 8;
    if ((phone ?? '').trim().isNotEmpty) filled++;
    if ((addressLine1 ?? '').trim().isNotEmpty) filled++;
    if ((city ?? '').trim().isNotEmpty) filled++;
    if ((email ?? '').trim().isNotEmpty) filled++;
    if (logoPath != null) filled++;
    if (isGstRegistered ? (gstin ?? '').isNotEmpty : true) filled++;
    if ((receiptFooter ?? '').trim().isNotEmpty) filled++;
    return ((filled / total) * 100).round().clamp(0, 100);
  }

  factory StoreProfile.fromMap(Map<String, Object?> map) {
    return StoreProfile(
      id: map['id'] as int,
      businessName: map['business_name'] as String,
      displayName: map['display_name'] as String?,
      logoPath: map['logo_path'] as String?,
      addressLine1: map['address_line_1'] as String?,
      addressLine2: map['address_line_2'] as String?,
      area: map['area'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      state: map['state'] as String?,
      country: (map['country'] as String?) ?? 'India',
      postalCode: map['postal_code'] as String?,
      phone: map['phone'] as String?,
      alternatePhone: map['alternate_phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      isGstRegistered: intToBool(map['is_gst_registered']),
      gstin: map['gstin'] as String?,
      businessType: map['business_type'] as String?,
      defaultTaxRateBp: (map['default_tax_rate'] as int?) ?? 0,
      invoicePrefix: (map['invoice_prefix'] as String?) ?? 'INV',
      nextInvoiceNumber: (map['next_invoice_number'] as int?) ?? 1,
      receiptFooter: map['receipt_footer'] as String?,
      currencyCode: (map['currency_code'] as String?) ?? 'INR',
      currencySymbol: (map['currency_symbol'] as String?) ?? '₹',
      isSetupCompleted: intToBool(map['is_setup_completed']),
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, Object?> toMap() => {
        'business_name': businessName,
        'display_name': displayName,
        'logo_path': logoPath,
        'address_line_1': addressLine1,
        'address_line_2': addressLine2,
        'area': area,
        'city': city,
        'district': district,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'phone': phone,
        'alternate_phone': alternatePhone,
        'email': email,
        'website': website,
        'is_gst_registered': boolToInt(isGstRegistered),
        'gstin': gstin,
        'business_type': businessType,
        'default_tax_rate': defaultTaxRateBp,
        'invoice_prefix': invoicePrefix,
        'next_invoice_number': nextInvoiceNumber,
        'receipt_footer': receiptFooter,
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'is_setup_completed': boolToInt(isSetupCompleted),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  StoreProfile copyWith({
    String? businessName,
    String? displayName,
    String? logoPath,
    String? addressLine1,
    String? addressLine2,
    String? area,
    String? city,
    String? district,
    String? state,
    String? country,
    String? postalCode,
    String? phone,
    String? alternatePhone,
    String? email,
    String? website,
    bool? isGstRegistered,
    String? gstin,
    String? businessType,
    int? defaultTaxRateBp,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? receiptFooter,
    bool? isSetupCompleted,
    int? updatedAt,
    bool clearLogo = false,
  }) {
    return StoreProfile(
      id: id,
      businessName: businessName ?? this.businessName,
      displayName: displayName ?? this.displayName,
      logoPath: clearLogo ? null : logoPath ?? this.logoPath,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      area: area ?? this.area,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      website: website ?? this.website,
      isGstRegistered: isGstRegistered ?? this.isGstRegistered,
      gstin: gstin ?? this.gstin,
      businessType: businessType ?? this.businessType,
      defaultTaxRateBp: defaultTaxRateBp ?? this.defaultTaxRateBp,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
