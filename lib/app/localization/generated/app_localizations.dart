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
  /// **'Inventory'**
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
  /// **'Inventory'**
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

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// No description provided for @commonScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get commonScan;

  /// No description provided for @commonAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get commonAllow;

  /// No description provided for @commonLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get commonLater;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @commonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get commonRestore;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get commonHelp;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get commonExporting;

  /// No description provided for @commonCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get commonCamera;

  /// No description provided for @commonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get commonOpenInBrowser;

  /// No description provided for @commonOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get commonOpenSettings;

  /// No description provided for @commonSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get commonSelectDate;

  /// No description provided for @commonExitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit app?'**
  String get commonExitApp;

  /// No description provided for @commonGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get commonGoHome;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get commonSharePdf;

  /// No description provided for @commonNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get commonNoCategory;

  /// No description provided for @commonPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get commonPermissionNeeded;

  /// No description provided for @themeLightHint.
  ///
  /// In en, this message translates to:
  /// **'Bright & clear'**
  String get themeLightHint;

  /// No description provided for @themeDarkHint.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get themeDarkHint;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Match device setting'**
  String get themeSystemHint;

  /// No description provided for @themeAccentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred color'**
  String get themeAccentHint;

  /// No description provided for @languageEnglishNative.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishNative;

  /// No description provided for @languageTamilNative.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamilNative;

  /// No description provided for @salesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices & payment history'**
  String get salesSubtitle;

  /// No description provided for @salesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search invoice or customer'**
  String get salesSearchHint;

  /// No description provided for @salesStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get salesStatusCompleted;

  /// No description provided for @salesStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get salesStatusCancelled;

  /// No description provided for @salesStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get salesStatusRefunded;

  /// No description provided for @invoiceDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice & payment details'**
  String get invoiceDetailSubtitle;

  /// No description provided for @invoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice No.'**
  String get invoiceNumberLabel;

  /// No description provided for @invoiceItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get invoiceItemsTitle;

  /// No description provided for @invoiceItemColumn.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get invoiceItemColumn;

  /// No description provided for @invoiceQtyPriceColumn.
  ///
  /// In en, this message translates to:
  /// **'Qty × Price'**
  String get invoiceQtyPriceColumn;

  /// No description provided for @invoiceBillingDetails.
  ///
  /// In en, this message translates to:
  /// **'Billing details'**
  String get invoiceBillingDetails;

  /// No description provided for @invoiceItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String invoiceItemCount(int count);

  /// No description provided for @billingRoundOff.
  ///
  /// In en, this message translates to:
  /// **'Round off'**
  String get billingRoundOff;

  /// No description provided for @checkoutUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get checkoutUnpaid;

  /// No description provided for @checkoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose method & collect amount'**
  String get checkoutSubtitle;

  /// No description provided for @billingCheckoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review cart & continue to payment'**
  String get billingCheckoutSubtitle;

  /// No description provided for @billingProceedCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to checkout'**
  String get billingProceedCheckout;

  /// No description provided for @billingNoProductsAdded.
  ///
  /// In en, this message translates to:
  /// **'No products added'**
  String get billingNoProductsAdded;

  /// No description provided for @billingNoProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Add Product to select items'**
  String get billingNoProductsHint;

  /// No description provided for @billingNoCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'No customers yet. Add a new one.'**
  String get billingNoCustomersHint;

  /// No description provided for @billingEmptyCartContinueHint.
  ///
  /// In en, this message translates to:
  /// **'Add products from billing to continue.'**
  String get billingEmptyCartContinueHint;

  /// No description provided for @billingTaxPercent.
  ///
  /// In en, this message translates to:
  /// **'Tax %'**
  String get billingTaxPercent;

  /// No description provided for @billingSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String billingSelectedCount(int count);

  /// No description provided for @billingLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave billing?'**
  String get billingLeaveConfirm;

  /// No description provided for @billingAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get billingAddProduct;

  /// No description provided for @billingScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get billingScanBarcode;

  /// No description provided for @dashboardTagline.
  ///
  /// In en, this message translates to:
  /// **'Manage your business with ease'**
  String get dashboardTagline;

  /// No description provided for @dashboardTodayOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s overview'**
  String get dashboardTodayOverview;

  /// No description provided for @dashboardWeekRange.
  ///
  /// In en, this message translates to:
  /// **'Sunday – Saturday'**
  String get dashboardWeekRange;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardGetStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Set up your shop by adding products and categories.'**
  String get dashboardGetStartedBody;

  /// No description provided for @productsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog, prices & stock'**
  String get productsSubtitle;

  /// No description provided for @productsEmptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get productsEmptySearchTitle;

  /// No description provided for @productsEmptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Add products to start billing and track stock.'**
  String get productsEmptySearchBody;

  /// No description provided for @productsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get productsViewDetails;

  /// No description provided for @productsViewDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing, stock & movements'**
  String get productsViewDetailsSubtitle;

  /// No description provided for @productsEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit product details'**
  String get productsEditDetails;

  /// No description provided for @productsActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate product'**
  String get productsActivate;

  /// No description provided for @productsDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate product'**
  String get productsDeactivateTitle;

  /// No description provided for @productsDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productsDetailsTitle;

  /// No description provided for @productsDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage product information'**
  String get productsDetailsSubtitle;

  /// No description provided for @productsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productsNotFound;

  /// No description provided for @productsNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed.'**
  String get productsNotFoundHint;

  /// No description provided for @productsPricingSection.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get productsPricingSection;

  /// No description provided for @productsPricingSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Cost and selling price details.'**
  String get productsPricingSectionHint;

  /// No description provided for @productsStockSection.
  ///
  /// In en, this message translates to:
  /// **'Stock Information'**
  String get productsStockSection;

  /// No description provided for @productsStockSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Current stock and alert settings.'**
  String get productsStockSectionHint;

  /// No description provided for @productsMinStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Min Stock Alert'**
  String get productsMinStockAlert;

  /// No description provided for @productsStockHealth.
  ///
  /// In en, this message translates to:
  /// **'Stock Health'**
  String get productsStockHealth;

  /// No description provided for @productsRecentMovements.
  ///
  /// In en, this message translates to:
  /// **'Recent Stock Movements'**
  String get productsRecentMovements;

  /// No description provided for @productsRecentMovementsHint.
  ///
  /// In en, this message translates to:
  /// **'Latest in and out transactions.'**
  String get productsRecentMovementsHint;

  /// No description provided for @productsMovementsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load movements'**
  String get productsMovementsLoadFailed;

  /// No description provided for @productsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo?'**
  String get productsRemovePhoto;

  /// No description provided for @productsPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get productsPhotoTitle;

  /// No description provided for @productsPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Take a new photo or choose from gallery'**
  String get productsPhotoHint;

  /// No description provided for @productsGenerateSku.
  ///
  /// In en, this message translates to:
  /// **'Generate SKU'**
  String get productsGenerateSku;

  /// No description provided for @productsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get productsRemove;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your product catalog'**
  String get categoriesSubtitle;

  /// No description provided for @categoriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get categoriesSearchHint;

  /// No description provided for @categoriesRename.
  ///
  /// In en, this message translates to:
  /// **'Rename this category'**
  String get categoriesRename;

  /// No description provided for @categoriesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoriesDeleteConfirm;

  /// No description provided for @categoriesRemoveFromForms.
  ///
  /// In en, this message translates to:
  /// **'Remove from product forms'**
  String get categoriesRemoveFromForms;

  /// No description provided for @categoriesExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Electronics, Groceries'**
  String get categoriesExampleHint;

  /// No description provided for @customersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts, credit & dues'**
  String get customersSubtitle;

  /// No description provided for @customersEmptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get customersEmptySearchTitle;

  /// No description provided for @customersEmptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Add customers to track credit and billing history.'**
  String get customersEmptySearchBody;

  /// No description provided for @customersViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get customersViewDetails;

  /// No description provided for @customersViewDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orders, contact & history'**
  String get customersViewDetailsSubtitle;

  /// No description provided for @customersEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit customer details'**
  String get customersEditDetails;

  /// No description provided for @customersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete customer'**
  String get customersDeleteTitle;

  /// No description provided for @customersRemoveFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from customer list'**
  String get customersRemoveFromList;

  /// No description provided for @customersDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customersDetailsTitle;

  /// No description provided for @customersDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View customer information'**
  String get customersDetailsSubtitle;

  /// No description provided for @customersNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found'**
  String get customersNotFound;

  /// No description provided for @customersNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed.'**
  String get customersNotFoundHint;

  /// No description provided for @customersCreateOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Order'**
  String get customersCreateOrder;

  /// No description provided for @customersTotalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get customersTotalOrders;

  /// No description provided for @customersTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get customersTotalSpent;

  /// No description provided for @customersOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get customersOrderHistory;

  /// No description provided for @customersNoOrders.
  ///
  /// In en, this message translates to:
  /// **'This customer has not placed any orders yet.\nStart billing to see history here.'**
  String get customersNoOrders;

  /// No description provided for @customersDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get customersDue;

  /// No description provided for @customersSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get customersSettled;

  /// No description provided for @customersStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get customersStatusPaid;

  /// No description provided for @customersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get customersStatusPending;

  /// No description provided for @inventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Products, availability & stock'**
  String get inventorySubtitle;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products by name, SKU, or barcode'**
  String get inventorySearchHint;

  /// No description provided for @inventoryAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get inventoryAllCategories;

  /// No description provided for @inventoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory items'**
  String get inventoryEmptyTitle;

  /// No description provided for @inventoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add products to track stock levels.'**
  String get inventoryEmptyBody;

  /// No description provided for @inventoryHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock in, stock out & adjustments'**
  String get inventoryHistorySubtitle;

  /// No description provided for @inventoryAddMovement.
  ///
  /// In en, this message translates to:
  /// **'Add movement'**
  String get inventoryAddMovement;

  /// No description provided for @inventoryAddMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Stock Movement'**
  String get inventoryAddMovementTitle;

  /// No description provided for @inventoryStockOut.
  ///
  /// In en, this message translates to:
  /// **'Stock OUT'**
  String get inventoryStockOut;

  /// No description provided for @inventoryMovementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stock movements'**
  String get inventoryMovementsEmpty;

  /// No description provided for @inventorySaveMovement.
  ///
  /// In en, this message translates to:
  /// **'Save Movement'**
  String get inventorySaveMovement;

  /// No description provided for @inventoryCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get inventoryCostPrice;

  /// No description provided for @inventoryNotesRequired.
  ///
  /// In en, this message translates to:
  /// **'Notes (Required)'**
  String get inventoryNotesRequired;

  /// No description provided for @inventorySearchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, SKU, or barcode'**
  String get inventorySearchProductHint;

  /// No description provided for @expensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shop spending & costs'**
  String get expensesSubtitle;

  /// No description provided for @expensesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get expensesSearchHint;

  /// No description provided for @expensesEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No expenses found'**
  String get expensesEmptySearch;

  /// No description provided for @expensesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Record shop spending to track your costs.'**
  String get expensesEmptyHint;

  /// No description provided for @expensesEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit expense details'**
  String get expensesEditDetails;

  /// No description provided for @expensesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get expensesDeleteTitle;

  /// No description provided for @expensesRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'Remove this expense'**
  String get expensesRemoveHint;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your business insights'**
  String get reportsSubtitle;

  /// No description provided for @reportsFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reportsFrom;

  /// No description provided for @reportsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reportsTo;

  /// No description provided for @reportsCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get reportsCollections;

  /// No description provided for @reportsTopProductsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No top products yet'**
  String get reportsTopProductsEmpty;

  /// No description provided for @reportsExpensesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period'**
  String get reportsExpensesEmptyHint;

  /// No description provided for @reportsExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF ({range})'**
  String reportsExportPdf(String range);

  /// No description provided for @reportsDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get reportsDateRange;

  /// No description provided for @moreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shop tools & preferences'**
  String get moreSubtitle;

  /// No description provided for @moreSectionShop.
  ///
  /// In en, this message translates to:
  /// **'Shop Management'**
  String get moreSectionShop;

  /// No description provided for @moreSectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get moreSectionBusiness;

  /// No description provided for @moreSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data & Tools'**
  String get moreSectionData;

  /// No description provided for @moreSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get moreSectionSupport;

  /// No description provided for @morePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get morePreferences;

  /// No description provided for @moreAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get moreAppearance;

  /// No description provided for @moreAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get moreAbout;

  /// No description provided for @moreDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get moreDangerZone;

  /// No description provided for @moreProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog & prices'**
  String get moreProductsSubtitle;

  /// No description provided for @moreCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your products'**
  String get moreCategoriesSubtitle;

  /// No description provided for @moreCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buyers & credit'**
  String get moreCustomersSubtitle;

  /// No description provided for @moreExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shop spending'**
  String get moreExpensesSubtitle;

  /// No description provided for @moreReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales & business overview'**
  String get moreReportsSubtitle;

  /// No description provided for @moreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get moreBackupTitle;

  /// No description provided for @moreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive, local backup'**
  String get moreBackupSubtitle;

  /// No description provided for @moreExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get moreExportTitle;

  /// No description provided for @moreExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share reports & files'**
  String get moreExportSubtitle;

  /// No description provided for @morePrinterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer settings'**
  String get morePrinterSubtitle;

  /// No description provided for @moreHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get moreHelpTitle;

  /// No description provided for @moreHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guides, FAQs and support'**
  String get moreHelpSubtitle;

  /// No description provided for @moreStoreSettings.
  ///
  /// In en, this message translates to:
  /// **'Store Settings'**
  String get moreStoreSettings;

  /// No description provided for @moreStoreSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business profile and invoice setup'**
  String get moreStoreSettingsSubtitle;

  /// No description provided for @moreAppLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or face unlock'**
  String get moreAppLockSubtitle;

  /// No description provided for @moreThemeValueHint.
  ///
  /// In en, this message translates to:
  /// **'Light, Dark or System default'**
  String get moreThemeValueHint;

  /// No description provided for @morePrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get morePrivacySubtitle;

  /// No description provided for @moreSendLogs.
  ///
  /// In en, this message translates to:
  /// **'Send app logs'**
  String get moreSendLogs;

  /// No description provided for @moreSendLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share diagnostics for support'**
  String get moreSendLogsSubtitle;

  /// No description provided for @moreFooterTagline.
  ///
  /// In en, this message translates to:
  /// **'Offline-first billing for everyday shops.'**
  String get moreFooterTagline;

  /// No description provided for @moreDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get moreDeleteAllTitle;

  /// No description provided for @moreDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes products, sales, customers and settings on this device.'**
  String get moreDeleteAllBody;

  /// No description provided for @moreLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out & reset app?'**
  String get moreLogoutTitle;

  /// No description provided for @moreLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'You will return to setup. Local data can be deleted as part of reset.'**
  String get moreLogoutBody;

  /// No description provided for @moreDeleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get moreDeleteEverything;

  /// No description provided for @moreLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get moreLogout;

  /// No description provided for @moreLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out…'**
  String get moreLoggingOut;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your data safe and accessible'**
  String get backupSubtitle;

  /// No description provided for @backupDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete backup?'**
  String get backupDeleteTitle;

  /// No description provided for @backupDeleteDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Drive backup?'**
  String get backupDeleteDriveTitle;

  /// No description provided for @backupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get backupDeleted;

  /// No description provided for @backupDriveDeleted.
  ///
  /// In en, this message translates to:
  /// **'Drive backup deleted'**
  String get backupDriveDeleted;

  /// No description provided for @backupDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete backup'**
  String get backupDeleteFailed;

  /// No description provided for @backupDriveDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete Drive backup'**
  String get backupDriveDeleteFailed;

  /// No description provided for @backupWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi‑Fi only'**
  String get backupWifiOnly;

  /// No description provided for @backupWifiOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup only when connected to Wi‑Fi'**
  String get backupWifiOnlyHint;

  /// No description provided for @backupAutomaticSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically backup your data'**
  String get backupAutomaticSubtitle;

  /// No description provided for @backupDriveSection.
  ///
  /// In en, this message translates to:
  /// **'Drive backups'**
  String get backupDriveSection;

  /// No description provided for @backupLocalSection.
  ///
  /// In en, this message translates to:
  /// **'Local backups'**
  String get backupLocalSection;

  /// No description provided for @backupDifferentStore.
  ///
  /// In en, this message translates to:
  /// **'Different store?'**
  String get backupDifferentStore;

  /// No description provided for @backupRefreshDrive.
  ///
  /// In en, this message translates to:
  /// **'Refresh Drive backups'**
  String get backupRefreshDrive;

  /// No description provided for @backupComplete.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get backupComplete;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportTitle;

  /// No description provided for @exportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share reports & CSV files'**
  String get exportSubtitle;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Export all'**
  String get exportAll;

  /// No description provided for @exportAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ZIP with products, orders, customers & stocks'**
  String get exportAllSubtitle;

  /// No description provided for @exportProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog, prices, and stock qty'**
  String get exportProductsSubtitle;

  /// No description provided for @exportOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get exportOrders;

  /// No description provided for @exportOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices and payments'**
  String get exportOrdersSubtitle;

  /// No description provided for @exportCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts and balances'**
  String get exportCustomersSubtitle;

  /// No description provided for @exportStocks.
  ///
  /// In en, this message translates to:
  /// **'Stocks'**
  String get exportStocks;

  /// No description provided for @exportStocksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock movement ledger'**
  String get exportStocksSubtitle;

  /// No description provided for @printerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer settings'**
  String get printerSubtitle;

  /// No description provided for @printerDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect printer?'**
  String get printerDisconnectConfirm;

  /// No description provided for @printerTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test print sent'**
  String get printerTestSent;

  /// No description provided for @printerNoBillToReprint.
  ///
  /// In en, this message translates to:
  /// **'No completed bill to reprint'**
  String get printerNoBillToReprint;

  /// No description provided for @printerTestHint.
  ///
  /// In en, this message translates to:
  /// **'Print a sample receipt'**
  String get printerTestHint;

  /// No description provided for @printerLastBillHint.
  ///
  /// In en, this message translates to:
  /// **'Reprint your last completed bill'**
  String get printerLastBillHint;

  /// No description provided for @printerDisconnectHint.
  ///
  /// In en, this message translates to:
  /// **'Stop using this printer'**
  String get printerDisconnectHint;

  /// No description provided for @permissionsCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Scan product barcodes during billing.'**
  String get permissionsCameraHint;

  /// No description provided for @permissionsBluetoothScan.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scan'**
  String get permissionsBluetoothScan;

  /// No description provided for @permissionsBluetoothScanHint.
  ///
  /// In en, this message translates to:
  /// **'Find nearby Bluetooth receipt printers.'**
  String get permissionsBluetoothScanHint;

  /// No description provided for @permissionsBluetoothConnect.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth connect'**
  String get permissionsBluetoothConnect;

  /// No description provided for @permissionsBluetoothConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Connect and print to paired printers.'**
  String get permissionsBluetoothConnectHint;

  /// No description provided for @permissionsAllowAll.
  ///
  /// In en, this message translates to:
  /// **'Allow all'**
  String get permissionsAllowAll;

  /// No description provided for @permissionsContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get permissionsContinueAnyway;

  /// No description provided for @permissionsAllowTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow permissions'**
  String get permissionsAllowTitle;

  /// No description provided for @contactUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUsTitle;

  /// No description provided for @contactUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guides, FAQs and support'**
  String get contactUsSubtitle;

  /// No description provided for @contactMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get contactMobile;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @contactWhatsAppHint.
  ///
  /// In en, this message translates to:
  /// **'Chat with us'**
  String get contactWhatsAppHint;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts & updates'**
  String get notificationsSubtitle;

  /// No description provided for @securityEnableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric lock'**
  String get securityEnableBiometric;

  /// No description provided for @securityBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended for shop security'**
  String get securityBiometricHint;

  /// No description provided for @storeLogoTitle.
  ///
  /// In en, this message translates to:
  /// **'Store logo'**
  String get storeLogoTitle;

  /// No description provided for @storeLogoHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from gallery'**
  String get storeLogoHint;

  /// No description provided for @storeRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove logo'**
  String get storeRemoveLogo;

  /// No description provided for @googleDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get googleDisconnect;

  /// No description provided for @googleSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get googleSkipForNow;

  /// No description provided for @passphraseMinHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get passphraseMinHint;

  /// No description provided for @passphraseReenter.
  ///
  /// In en, this message translates to:
  /// **'Re-enter passphrase'**
  String get passphraseReenter;

  /// No description provided for @passphraseSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set recovery passphrase'**
  String get passphraseSetTitle;

  /// No description provided for @passphraseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter recovery passphrase'**
  String get passphraseEnterTitle;

  /// No description provided for @passphraseDisconnectDrive.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Drive?'**
  String get passphraseDisconnectDrive;

  /// No description provided for @manualBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8901234567890'**
  String get manualBarcodeHint;

  /// No description provided for @connectivityBackOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get connectivityBackOnline;

  /// No description provided for @connectivityBackOnlineBody.
  ///
  /// In en, this message translates to:
  /// **'You are connected again.'**
  String get connectivityBackOnlineBody;

  /// No description provided for @connectivityOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get connectivityOfflineTitle;

  /// No description provided for @connectivityOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Billing continues offline on this device.'**
  String get connectivityOfflineBody;

  /// No description provided for @errorsSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Unable to share PDF'**
  String get errorsSharePdf;

  /// No description provided for @errorsStoreNotReady.
  ///
  /// In en, this message translates to:
  /// **'Complete store setup first'**
  String get errorsStoreNotReady;

  /// No description provided for @errorsBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock is not available on this device.'**
  String get errorsBiometricUnavailable;

  /// No description provided for @errorsBiometricNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock was not confirmed.'**
  String get errorsBiometricNotConfirmed;

  /// No description provided for @errorsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get errorsExportFailed;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @reportsPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Report'**
  String get reportsPdfTitle;

  /// No description provided for @reportsPdfPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period: {range}'**
  String reportsPdfPeriod(String range);

  /// No description provided for @reportsPdfGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {when}'**
  String reportsPdfGenerated(String when);

  /// No description provided for @reportsPdfSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportsPdfSummary;

  /// No description provided for @reportsPdfTodaySales.
  ///
  /// In en, this message translates to:
  /// **'Today sales'**
  String get reportsPdfTodaySales;

  /// No description provided for @reportsPdfBillsToday.
  ///
  /// In en, this message translates to:
  /// **'Bills today'**
  String get reportsPdfBillsToday;

  /// No description provided for @reportsPdfStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value'**
  String get reportsPdfStockValue;

  /// No description provided for @reportsPdfExpensesTotal.
  ///
  /// In en, this message translates to:
  /// **'Expenses total'**
  String get reportsPdfExpensesTotal;

  /// No description provided for @reportsPdfTopProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products (by quantity)'**
  String get reportsPdfTopProducts;

  /// No description provided for @reportsPdfNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period'**
  String get reportsPdfNoSales;

  /// No description provided for @reportsPdfExpensesSection.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsPdfExpensesSection;

  /// No description provided for @backupCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your POS data was backed up to Google Drive.'**
  String get backupCompleteBody;

  /// No description provided for @commonInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get commonInStock;

  /// No description provided for @commonNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get commonNoPhone;

  /// No description provided for @commonNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get commonNoEmail;

  /// No description provided for @billingLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your current cart will be discarded.'**
  String get billingLeaveBody;

  /// No description provided for @commonExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get commonExit;

  /// No description provided for @commonStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get commonStay;

  /// No description provided for @invoiceBillTo.
  ///
  /// In en, this message translates to:
  /// **'BILL TO'**
  String get invoiceBillTo;

  /// No description provided for @invoiceStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get invoiceStatusLabel;

  /// No description provided for @invoiceThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for shopping with us!'**
  String get invoiceThankYou;

  /// No description provided for @invoiceThankYouShort.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get invoiceThankYouShort;

  /// No description provided for @invoiceSubject.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number}'**
  String invoiceSubject(String number);

  /// No description provided for @commonPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get commonPrice;

  /// No description provided for @commonCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get commonCustomer;
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
