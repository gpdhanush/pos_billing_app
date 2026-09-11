import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'POS Billing'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Scan, bill, and manage stock offline'**
  String get appTagline;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get commonOffline;

  /// No description provided for @commonOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Your billing will continue normally.'**
  String get commonOfflineHint;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get commonPrint;

  /// No description provided for @commonReprint.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get commonReprint;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get commonNotes;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @commonActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get commonActions;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get commonPhone;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get commonAddress;

  /// No description provided for @commonQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get commonQuantity;

  /// No description provided for @commonReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get commonReason;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get commonFailed;

  /// No description provided for @commonInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get commonInProgress;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @commonStartBilling.
  ///
  /// In en, this message translates to:
  /// **'Start billing'**
  String get commonStartBilling;

  /// No description provided for @commonGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get commonGetStarted;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get navBilling;

  /// No description provided for @navStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @onboardingFastTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast & Simple Billing'**
  String get onboardingFastTitle;

  /// No description provided for @onboardingFastBody.
  ///
  /// In en, this message translates to:
  /// **'Scan products, manage your cart and complete bills in seconds.'**
  String get onboardingFastBody;

  /// No description provided for @onboardingStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Know Your Stock'**
  String get onboardingStockTitle;

  /// No description provided for @onboardingStockBody.
  ///
  /// In en, this message translates to:
  /// **'Track purchases, stock movements and available inventory with ease.'**
  String get onboardingStockBody;

  /// No description provided for @onboardingBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Your Data Safe'**
  String get onboardingBackupTitle;

  /// No description provided for @onboardingBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Back up your POS data to Google Drive and restore it when needed.'**
  String get onboardingBackupBody;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get languageTamil;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose theme'**
  String get themeTitle;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a look that is easy to use in your shop.'**
  String get themeSubtitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get themeAccent;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @accentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your store'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s get your shop ready for billing.'**
  String get setupSubtitle;

  /// No description provided for @setupStepStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get setupStepStore;

  /// No description provided for @setupStepContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get setupStepContact;

  /// No description provided for @setupStepGst.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get setupStepGst;

  /// No description provided for @setupStepInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get setupStepInvoice;

  /// No description provided for @setupComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get setupComplete;

  /// No description provided for @setupReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your POS is ready to use.'**
  String get setupReadyTitle;

  /// No description provided for @setupReadyBody.
  ///
  /// In en, this message translates to:
  /// **'You can start billing right away. Complete optional details later from Settings.'**
  String get setupReadyBody;

  /// No description provided for @storeBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Store / business name'**
  String get storeBusinessName;

  /// No description provided for @storeDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Store display name'**
  String get storeDisplayName;

  /// No description provided for @storeLogo.
  ///
  /// In en, this message translates to:
  /// **'Business logo'**
  String get storeLogo;

  /// No description provided for @storeChooseLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose logo'**
  String get storeChooseLogo;

  /// No description provided for @storeContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact & address'**
  String get storeContactTitle;

  /// No description provided for @storePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get storePhone;

  /// No description provided for @storeAltPhone.
  ///
  /// In en, this message translates to:
  /// **'Alternate phone number'**
  String get storeAltPhone;

  /// No description provided for @storeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get storeWebsite;

  /// No description provided for @storeAddress1.
  ///
  /// In en, this message translates to:
  /// **'Address line 1'**
  String get storeAddress1;

  /// No description provided for @storeAddress2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2'**
  String get storeAddress2;

  /// No description provided for @storeArea.
  ///
  /// In en, this message translates to:
  /// **'Area / locality'**
  String get storeArea;

  /// No description provided for @storeCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get storeCity;

  /// No description provided for @storeDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get storeDistrict;

  /// No description provided for @storeState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get storeState;

  /// No description provided for @storeCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get storeCountry;

  /// No description provided for @storePostalCode.
  ///
  /// In en, this message translates to:
  /// **'PIN / postal code'**
  String get storePostalCode;

  /// No description provided for @storeGstTitle.
  ///
  /// In en, this message translates to:
  /// **'GST / tax'**
  String get storeGstTitle;

  /// No description provided for @storeGstRegistered.
  ///
  /// In en, this message translates to:
  /// **'GST registered?'**
  String get storeGstRegistered;

  /// No description provided for @storeGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get storeGstin;

  /// No description provided for @storeBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Business type'**
  String get storeBusinessType;

  /// No description provided for @storeBusinessRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get storeBusinessRegular;

  /// No description provided for @storeBusinessComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get storeBusinessComposition;

  /// No description provided for @storeBusinessOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storeBusinessOther;

  /// No description provided for @storeDefaultTax.
  ///
  /// In en, this message translates to:
  /// **'Default tax rate (%)'**
  String get storeDefaultTax;

  /// No description provided for @storeInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice settings'**
  String get storeInvoiceTitle;

  /// No description provided for @storeInvoicePrefix.
  ///
  /// In en, this message translates to:
  /// **'Invoice prefix'**
  String get storeInvoicePrefix;

  /// No description provided for @storeStartingNumber.
  ///
  /// In en, this message translates to:
  /// **'Starting invoice number'**
  String get storeStartingNumber;

  /// No description provided for @storeReceiptFooter.
  ///
  /// In en, this message translates to:
  /// **'Receipt footer message'**
  String get storeReceiptFooter;

  /// No description provided for @storeReceiptPreview.
  ///
  /// In en, this message translates to:
  /// **'Receipt preview'**
  String get storeReceiptPreview;

  /// No description provided for @storeThankYouDefault.
  ///
  /// In en, this message translates to:
  /// **'Thank you for shopping with us!'**
  String get storeThankYouDefault;

  /// No description provided for @storeSetupReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Store setup {percent}% complete'**
  String storeSetupReminderTitle(int percent);

  /// No description provided for @storeSetupReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your business profile to improve your receipts.'**
  String get storeSetupReminderBody;

  /// No description provided for @storeCompleteSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete setup'**
  String get storeCompleteSetup;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock (optional)'**
  String get securityTitle;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect the app with a PIN. You can skip this and enable it later.'**
  String get securitySubtitle;

  /// No description provided for @securityEnablePin.
  ///
  /// In en, this message translates to:
  /// **'Enable PIN lock'**
  String get securityEnablePin;

  /// No description provided for @securityPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get securityPin;

  /// No description provided for @securityConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get securityConfirmPin;

  /// No description provided for @securityBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics when available'**
  String get securityBiometric;

  /// No description provided for @securitySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get securitySkip;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get lockTitle;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// No description provided for @lockUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get lockUseBiometric;

  /// No description provided for @lockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get lockWrongPin;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardTodaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get dashboardTodaySales;

  /// No description provided for @dashboardBillsToday.
  ///
  /// In en, this message translates to:
  /// **'Bills today'**
  String get dashboardBillsToday;

  /// No description provided for @dashboardItemsInStock.
  ///
  /// In en, this message translates to:
  /// **'Items in stock'**
  String get dashboardItemsInStock;

  /// No description provided for @dashboardLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get dashboardLowStock;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardNewBill.
  ///
  /// In en, this message translates to:
  /// **'New bill'**
  String get dashboardNewBill;

  /// No description provided for @dashboardScanProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan product'**
  String get dashboardScanProduct;

  /// No description provided for @dashboardAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get dashboardAddProduct;

  /// No description provided for @dashboardAddStock.
  ///
  /// In en, this message translates to:
  /// **'Add stock'**
  String get dashboardAddStock;

  /// No description provided for @dashboardRecentBills.
  ///
  /// In en, this message translates to:
  /// **'Recent bills'**
  String get dashboardRecentBills;

  /// No description provided for @dashboardNoBills.
  ///
  /// In en, this message translates to:
  /// **'No bills yet today'**
  String get dashboardNoBills;

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'New bill'**
  String get billingTitle;

  /// No description provided for @billingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number}'**
  String billingInvoice(String number);

  /// No description provided for @billingSearchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product'**
  String get billingSearchProduct;

  /// No description provided for @billingScan.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode / QR'**
  String get billingScan;

  /// No description provided for @billingCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get billingCart;

  /// No description provided for @billingEmptyCart.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get billingEmptyCart;

  /// No description provided for @billingEmptyCartHint.
  ///
  /// In en, this message translates to:
  /// **'Scan or search to add products.'**
  String get billingEmptyCartHint;

  /// No description provided for @billingSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get billingSubtotal;

  /// No description provided for @billingDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get billingDiscount;

  /// No description provided for @billingTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get billingTax;

  /// No description provided for @billingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get billingTotal;

  /// No description provided for @billingCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get billingCheckout;

  /// No description provided for @billingClearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get billingClearCart;

  /// No description provided for @billingClearCartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all items from this bill?'**
  String get billingClearCartConfirm;

  /// No description provided for @billingItemDiscount.
  ///
  /// In en, this message translates to:
  /// **'Item discount'**
  String get billingItemDiscount;

  /// No description provided for @billingBillDiscount.
  ///
  /// In en, this message translates to:
  /// **'Bill discount'**
  String get billingBillDiscount;

  /// No description provided for @billingQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get billingQty;

  /// No description provided for @billingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get billingCustomer;

  /// No description provided for @billingWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get billingWalkIn;

  /// No description provided for @billingSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get billingSelectCustomer;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get checkoutTitle;

  /// No description provided for @checkoutTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get checkoutTotalAmount;

  /// No description provided for @checkoutCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get checkoutCash;

  /// No description provided for @checkoutUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get checkoutUpi;

  /// No description provided for @checkoutCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get checkoutCard;

  /// No description provided for @checkoutCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get checkoutCredit;

  /// No description provided for @checkoutMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed payment'**
  String get checkoutMixed;

  /// No description provided for @checkoutReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get checkoutReceived;

  /// No description provided for @checkoutChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get checkoutChange;

  /// No description provided for @checkoutPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get checkoutPaid;

  /// No description provided for @checkoutBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get checkoutBalance;

  /// No description provided for @checkoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get checkoutComplete;

  /// No description provided for @checkoutSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get checkoutSuccessTitle;

  /// No description provided for @checkoutPrintBill.
  ///
  /// In en, this message translates to:
  /// **'Print bill'**
  String get checkoutPrintBill;

  /// No description provided for @checkoutNewBill.
  ///
  /// In en, this message translates to:
  /// **'New bill'**
  String get checkoutNewBill;

  /// No description provided for @checkoutPrinterFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to printer.'**
  String get checkoutPrinterFailed;

  /// No description provided for @checkoutRetryPrint.
  ///
  /// In en, this message translates to:
  /// **'Retry print'**
  String get checkoutRetryPrint;

  /// No description provided for @checkoutPrintLater.
  ///
  /// In en, this message translates to:
  /// **'Print later'**
  String get checkoutPrintLater;

  /// No description provided for @checkoutCreditNeedsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select a customer for credit sales.'**
  String get checkoutCreditNeedsCustomer;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @productsAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productsAddProduct;

  /// No description provided for @productsEditProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productsEditProduct;

  /// No description provided for @productsProductName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productsProductName;

  /// No description provided for @productsSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get productsSku;

  /// No description provided for @productsBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get productsBarcode;

  /// No description provided for @productsQr.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get productsQr;

  /// No description provided for @productsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productsCategory;

  /// No description provided for @productsUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get productsUnit;

  /// No description provided for @productsPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get productsPurchasePrice;

  /// No description provided for @productsSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get productsSellingPrice;

  /// No description provided for @productsTaxGst.
  ///
  /// In en, this message translates to:
  /// **'Tax / GST (%)'**
  String get productsTaxGst;

  /// No description provided for @productsMinimumStock.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock'**
  String get productsMinimumStock;

  /// No description provided for @productsOpeningStock.
  ///
  /// In en, this message translates to:
  /// **'Opening stock'**
  String get productsOpeningStock;

  /// No description provided for @productsImage.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get productsImage;

  /// No description provided for @productsStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get productsStock;

  /// No description provided for @productsLowStockFilter.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productsLowStockFilter;

  /// No description provided for @productsOutOfStockFilter.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get productsOutOfStockFilter;

  /// No description provided for @productsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productsEmptyTitle;

  /// No description provided for @productsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start managing inventory.'**
  String get productsEmptyBody;

  /// No description provided for @productsInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get productsInactive;

  /// No description provided for @productsDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate product'**
  String get productsDeactivate;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoriesAdd;

  /// No description provided for @categoriesName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoriesName;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get inventoryTitle;

  /// No description provided for @inventoryStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get inventoryStockIn;

  /// No description provided for @inventoryAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get inventoryAdjust;

  /// No description provided for @inventoryHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get inventoryHistory;

  /// No description provided for @inventoryCurrentStock.
  ///
  /// In en, this message translates to:
  /// **'Current stock'**
  String get inventoryCurrentStock;

  /// No description provided for @inventoryAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get inventoryAdjustment;

  /// No description provided for @inventoryReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for this adjustment.'**
  String get inventoryReasonRequired;

  /// No description provided for @inventorySaveAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Save adjustment'**
  String get inventorySaveAdjustment;

  /// No description provided for @inventoryPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get inventoryPurchase;

  /// No description provided for @inventorySale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get inventorySale;

  /// No description provided for @inventoryReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get inventoryReturn;

  /// No description provided for @inventorySaved.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get inventorySaved;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan product'**
  String get scannerTitle;

  /// No description provided for @scannerAlign.
  ///
  /// In en, this message translates to:
  /// **'Align barcode inside the frame'**
  String get scannerAlign;

  /// No description provided for @scannerFlashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get scannerFlashlight;

  /// No description provided for @scannerEnterManual.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode manually'**
  String get scannerEnterManual;

  /// No description provided for @scannerNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get scannerNotFoundTitle;

  /// No description provided for @scannerNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Barcode: {barcode}'**
  String scannerNotFoundBody(String barcode);

  /// No description provided for @scannerAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get scannerAddProduct;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get customersAdd;

  /// No description provided for @customersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get customersEdit;

  /// No description provided for @customersCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get customersCreditLimit;

  /// No description provided for @customersOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get customersOpeningBalance;

  /// No description provided for @customersOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get customersOutstanding;

  /// No description provided for @customersHistory.
  ///
  /// In en, this message translates to:
  /// **'Purchase history'**
  String get customersHistory;

  /// No description provided for @customersPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get customersPayments;

  /// No description provided for @customersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersEmpty;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get customersSearchHint;

  /// No description provided for @salesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesTitle;

  /// No description provided for @salesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sales found'**
  String get salesEmpty;

  /// No description provided for @salesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try another date or filter.'**
  String get salesEmptyHint;

  /// No description provided for @salesToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get salesToday;

  /// No description provided for @salesYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get salesYesterday;

  /// No description provided for @salesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get salesThisWeek;

  /// No description provided for @salesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get salesThisMonth;

  /// No description provided for @salesCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get salesCustom;

  /// No description provided for @salesDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice details'**
  String get salesDetails;

  /// No description provided for @salesRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get salesRefund;

  /// No description provided for @salesCancelInvoice.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale'**
  String get salesCancelInvoice;

  /// No description provided for @salesCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'This keeps the original bill and records a reversal. Continue?'**
  String get salesCancelConfirm;

  /// No description provided for @salesRefundConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record a refund and return stock for this invoice?'**
  String get salesRefundConfirm;

  /// No description provided for @salesPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get salesPaymentMethod;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsTopProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get reportsTopProducts;

  /// No description provided for @reportsOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get reportsOutOfStock;

  /// No description provided for @reportsStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value'**
  String get reportsStockValue;

  /// No description provided for @reportsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily sales'**
  String get reportsDaily;

  /// No description provided for @reportsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly sales'**
  String get reportsWeekly;

  /// No description provided for @reportsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly sales'**
  String get reportsMonthly;

  /// No description provided for @reportsCash.
  ///
  /// In en, this message translates to:
  /// **'Cash sales'**
  String get reportsCash;

  /// No description provided for @reportsUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI sales'**
  String get reportsUpi;

  /// No description provided for @reportsCard.
  ///
  /// In en, this message translates to:
  /// **'Card sales'**
  String get reportsCard;

  /// No description provided for @reportsCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit sales'**
  String get reportsCredit;

  /// No description provided for @reportsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsExpenses;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @expensesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expensesAdd;

  /// No description provided for @expensesCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense category'**
  String get expensesCategory;

  /// No description provided for @expensesPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get expensesPaymentMethod;

  /// No description provided for @expensesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expensesEmpty;

  /// No description provided for @printerTitle.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get printerTitle;

  /// No description provided for @printerName.
  ///
  /// In en, this message translates to:
  /// **'Printer name'**
  String get printerName;

  /// No description provided for @printerConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection type'**
  String get printerConnection;

  /// No description provided for @printerBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get printerBluetooth;

  /// No description provided for @printerUsb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get printerUsb;

  /// No description provided for @printerNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get printerNetwork;

  /// No description provided for @printerPaperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get printerPaperSize;

  /// No description provided for @printerConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect printer'**
  String get printerConnect;

  /// No description provided for @printerDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get printerDisconnect;

  /// No description provided for @printerTest.
  ///
  /// In en, this message translates to:
  /// **'Test print'**
  String get printerTest;

  /// No description provided for @printerLastBill.
  ///
  /// In en, this message translates to:
  /// **'Print last bill'**
  String get printerLastBill;

  /// No description provided for @printerNone.
  ///
  /// In en, this message translates to:
  /// **'No printer connected'**
  String get printerNone;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupTitle;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get backupNow;

  /// No description provided for @backupLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backupLast;

  /// No description provided for @backupView.
  ///
  /// In en, this message translates to:
  /// **'View backups'**
  String get backupView;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get backupRestore;

  /// No description provided for @backupAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupAutomatic;

  /// No description provided for @backupOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get backupOff;

  /// No description provided for @backupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get backupDaily;

  /// No description provided for @backupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backupWeekly;

  /// No description provided for @backupGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get backupGoogle;

  /// No description provided for @backupConnectGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive'**
  String get backupConnectGoogle;

  /// No description provided for @backupDisconnectGoogle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Drive'**
  String get backupDisconnectGoogle;

  /// No description provided for @backupLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local encrypted backup is always available. Google Drive needs internet and a signed-in account.'**
  String get backupLocalOnly;

  /// No description provided for @backupConfirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup? A safety copy of the current data will be created first.'**
  String get backupConfirmRestore;

  /// No description provided for @backupNone.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backupNone;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get settingsBusiness;

  /// No description provided for @settingsStoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Store details'**
  String get settingsStoreDetails;

  /// No description provided for @settingsInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice settings'**
  String get settingsInvoice;

  /// No description provided for @settingsTax.
  ///
  /// In en, this message translates to:
  /// **'Tax settings'**
  String get settingsTax;

  /// No description provided for @settingsPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get settingsPos;

  /// No description provided for @settingsBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get settingsBilling;

  /// No description provided for @settingsPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get settingsPayment;

  /// No description provided for @settingsBarcodeScanner.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanner'**
  String get settingsBarcodeScanner;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsAllowNegativeStock.
  ///
  /// In en, this message translates to:
  /// **'Allow selling when stock is zero'**
  String get settingsAllowNegativeStock;

  /// No description provided for @errorsDatabase.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this yet. Please try again.'**
  String get errorsDatabase;

  /// No description provided for @errorsPrinter.
  ///
  /// In en, this message translates to:
  /// **'The printer is not available.'**
  String get errorsPrinter;

  /// No description provided for @errorsScanner.
  ///
  /// In en, this message translates to:
  /// **'The scanner could not be started.'**
  String get errorsScanner;

  /// No description provided for @errorsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup could not be completed.'**
  String get errorsBackup;

  /// No description provided for @errorsDriveAuth.
  ///
  /// In en, this message translates to:
  /// **'Google Drive sign-in was cancelled or failed.'**
  String get errorsDriveAuth;

  /// No description provided for @errorsValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errorsValidation;

  /// No description provided for @errorsInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock for {product}.'**
  String errorsInsufficientStock(String product);

  /// No description provided for @errorsDuplicateBarcode.
  ///
  /// In en, this message translates to:
  /// **'This barcode is already used by another product.'**
  String get errorsDuplicateBarcode;

  /// No description provided for @errorsInvalidGstin.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 15-character GSTIN.'**
  String get errorsInvalidGstin;

  /// No description provided for @errorsRestore.
  ///
  /// In en, this message translates to:
  /// **'This backup could not be restored.'**
  String get errorsRestore;

  /// No description provided for @errorsInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorsInvalidEmail;

  /// No description provided for @errorsInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get errorsInvalidPhone;

  /// No description provided for @errorsInvalidWebsite.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid website address.'**
  String get errorsInvalidWebsite;

  /// No description provided for @errorsPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PIN and confirmation do not match.'**
  String get errorsPinMismatch;

  /// No description provided for @errorsBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter your store or business name.'**
  String get errorsBusinessName;

  /// No description provided for @errorsCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add at least one product before checkout.'**
  String get errorsCartEmpty;

  /// No description provided for @errorsPaymentShort.
  ///
  /// In en, this message translates to:
  /// **'Paid amount is less than the total.'**
  String get errorsPaymentShort;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'This app stores billing data on your device. Google Drive is used only when you choose to back up or restore. No sale depends on the internet.'**
  String get privacyBody;

  /// No description provided for @sampleDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'Sample products loaded for development.'**
  String get sampleDataLoaded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
