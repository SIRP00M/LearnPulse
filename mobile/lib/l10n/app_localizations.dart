import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ms'),
    Locale('th'),
  ];

  /// Generic Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Generic Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Generic Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Secondary action that returns to the previous screen
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonBack;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// Retry button label while the retry runs
  ///
  /// In en, this message translates to:
  /// **'Trying again…'**
  String get commonTryingAgain;

  /// Accessibility label of loading indicators and skeletons
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// Shown when a load is slow
  ///
  /// In en, this message translates to:
  /// **'Still working… this is taking longer than usual.'**
  String get commonStillWorking;

  /// Sign out action
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonSignOut;

  /// Sign in again action
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get commonSignInAgain;

  /// Shown instead of a percentage when no data exists
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get commonNoDataYet;

  /// Value shown when something is not available
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// Heading of the build configuration error screen
  ///
  /// In en, this message translates to:
  /// **'Configuration error'**
  String get configErrorTitle;

  /// Bottom navigation: dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Bottom navigation: tasks tab
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// Bottom navigation: courses tab
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get navCourses;

  /// Bottom navigation: profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Tooltip of the avatar button in the app bar
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get navOpenProfile;

  /// Used in place of the name when a profile has no name (as in "Welcome, there")
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get homeNameFallback;

  /// Relative day label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get relativeToday;

  /// Relative day label
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get relativeTomorrow;

  /// Relative day label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get relativeYesterday;

  /// Role name
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// Role name
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// Heading of the language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Explains where the language is stored
  ///
  /// In en, this message translates to:
  /// **'Saved on this device only. The language never changes deadlines, schedules or time zones.'**
  String get languageHint;

  /// Accessible label of the language selector
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languageSelectorLabel;

  /// Small uppercase label above the welcome headline
  ///
  /// In en, this message translates to:
  /// **'LEARNPULSE ACADEMIC PORTAL'**
  String get authPortalEyebrow;

  /// Welcome headline on the sign-in screen (line break kept)
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nLearnPulse.'**
  String get authWelcomeTitle;

  /// Tagline under the headline
  ///
  /// In en, this message translates to:
  /// **'Courses, assignments and attendance. Your learning, together.'**
  String get authTagline;

  /// Sign in title and button
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// Tooltip to reveal the password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Tooltip to hide the password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Link to the reset flow
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// Button to open sign-up
  ///
  /// In en, this message translates to:
  /// **'Create a student account'**
  String get authCreateStudentAccount;

  /// Sign-up screen title
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateYourAccount;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullName;

  /// Password policy helper text
  ///
  /// In en, this message translates to:
  /// **'10+ characters with upper case, lower case and a digit'**
  String get authPasswordHelper;

  /// Note about teacher accounts on the sign-up screen
  ///
  /// In en, this message translates to:
  /// **'Teachers: use the email address your invitation was sent to. Your role is assigned by the school after you confirm your email.'**
  String get authTeacherNote;

  /// Create account button
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// Link back to sign-in
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get authHaveAccount;

  /// Forgot-password screen title
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetTitle;

  /// Button that emails a reset link
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// Link back to sign-in
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// Confirm-email screen title
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authCheckEmailTitle;

  /// Fallback when the pending email is unknown ("your email address")
  ///
  /// In en, this message translates to:
  /// **'your email address'**
  String get authYourEmailAddress;

  /// Confirm-email body
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Open it on this phone to finish signing in.'**
  String authConfirmSent(String email);

  /// Resend button
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get authResendEmail;

  /// Resend button while cooling down
  ///
  /// In en, this message translates to:
  /// **'Resend email in {seconds}s'**
  String authResendEmailIn(int seconds);

  /// Link for users who confirmed elsewhere
  ///
  /// In en, this message translates to:
  /// **'I\'ve confirmed - sign in'**
  String get authConfirmedSignIn;

  /// Set-password screen title
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authNewPasswordTitle;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// Save password button
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get authSavePassword;

  /// Title of the session-expired screen
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get authSessionExpiredTitle;

  /// Heading in the session-expired panel
  ///
  /// In en, this message translates to:
  /// **'You were signed out'**
  String get authSignedOutTitle;

  /// Body in the session-expired panel
  ///
  /// In en, this message translates to:
  /// **'For your security your session ended. Sign in again to pick up where you left off.'**
  String get authSessionEnded;

  /// Profile-load error title when offline
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach LearnPulse'**
  String get authCantReach;

  /// Profile-load error title
  ///
  /// In en, this message translates to:
  /// **'Account not ready'**
  String get authAccountNotReady;

  /// Notice after resending the confirmation email
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent to {email}.'**
  String noticeConfirmationSent(String email);

  /// Notice after requesting a reset link (same whether or not the address exists)
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that address, a reset link is on its way.'**
  String get noticeResetSent;

  /// Notice after saving a new password
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get noticePasswordUpdated;

  /// Notice after saving the display name
  ///
  /// In en, this message translates to:
  /// **'Display name saved.'**
  String get noticeNameSaved;

  /// Notice after emailing a password reset link to the signed-in user
  ///
  /// In en, this message translates to:
  /// **'A password reset link is on its way to {email}.'**
  String noticePasswordLinkSent(String email);

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'No connection to the server. Check your network and try again.'**
  String get errorNetwork;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'The server took too long to answer. Try again in a moment.'**
  String get errorTimeout;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errorInvalidCredentials;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email address first.'**
  String get errorEmailNotConfirmed;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get errorRateLimitedLong;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password (10+ characters with upper, lower case and a digit).'**
  String get errorWeakPassword;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Registration is currently closed.'**
  String get errorSignupDisabled;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to upload or open that file.'**
  String get errorFileForbidden;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'That file is too large (10 MB maximum).'**
  String get errorFileTooLarge;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'That file type is not allowed.'**
  String get errorFileType;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do that.'**
  String get errorForbidden;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'That course was not found, or you no longer have access to it.'**
  String get errorCourseNotFound;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Please check the details and try again.'**
  String get errorValidation;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'You are not signed in.'**
  String get errorNotSignedIn;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Your name could not be saved.'**
  String get errorNameNotSaved;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Your account is not ready yet. Please try again in a moment.'**
  String get errorProfileNotReady;

  /// Offline panel title
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get stateOfflineTitle;

  /// Offline panel text
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try again. Anything you have already saved is safe.'**
  String get stateOfflineMessage;

  /// Timeout panel title
  ///
  /// In en, this message translates to:
  /// **'This is taking too long'**
  String get stateTimeoutTitle;

  /// Timeout panel text
  ///
  /// In en, this message translates to:
  /// **'The connection looks slow. Try again, or move somewhere with a better signal.'**
  String get stateTimeoutMessage;

  /// Expired-session panel title
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get stateExpiredTitle;

  /// Expired-session panel text
  ///
  /// In en, this message translates to:
  /// **'For your security you were signed out. Sign in again to carry on.'**
  String get stateExpiredMessage;

  /// Forbidden panel title
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get stateForbiddenTitle;

  /// Forbidden panel text
  ///
  /// In en, this message translates to:
  /// **'Your account does not have permission to open this.'**
  String get stateForbiddenMessage;

  /// Not-found panel title
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get stateNotFoundTitle;

  /// Not-found panel text
  ///
  /// In en, this message translates to:
  /// **'This may have been removed, or you may no longer have access to it.'**
  String get stateNotFoundMessage;

  /// Conflict panel title
  ///
  /// In en, this message translates to:
  /// **'This changed elsewhere'**
  String get stateConflictTitle;

  /// Conflict panel text
  ///
  /// In en, this message translates to:
  /// **'Refresh to see the latest version, then try again.'**
  String get stateConflictMessage;

  /// Generic failure panel title
  ///
  /// In en, this message translates to:
  /// **'Could not load this'**
  String get stateUnknownTitle;

  /// Generic failure panel text
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened. Please try again.'**
  String get stateUnknownMessage;

  /// Inline warning when a refresh failed but old data is shown; {message} is a localized error sentence
  ///
  /// In en, this message translates to:
  /// **'Could not refresh: {message} Showing the last loaded figures.'**
  String stateCouldNotRefresh(String message);

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get validationEmailRequired;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get validationPasswordRequired;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters'**
  String get validationPasswordShort;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Include upper case, lower case and a digit'**
  String get validationPasswordMix;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get validationNameRequired;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get validationNameLong;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Teaching summary'**
  String get profileTeachingSummary;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Learning summary'**
  String get profileLearningSummary;

  /// Section subtitle
  ///
  /// In en, this message translates to:
  /// **'Your courses. Your impact.'**
  String get profileTeachingSubtitle;

  /// Section subtitle
  ///
  /// In en, this message translates to:
  /// **'A clear view of how you are doing.'**
  String get profileLearningSubtitle;

  /// Uppercase eyebrow on the identity card
  ///
  /// In en, this message translates to:
  /// **'YOUR TEACHING IDENTITY'**
  String get profileTeachingIdentity;

  /// Uppercase eyebrow on the identity card
  ///
  /// In en, this message translates to:
  /// **'YOUR LEARNING IDENTITY'**
  String get profileLearningIdentity;

  /// Shown when the profile has no name
  ///
  /// In en, this message translates to:
  /// **'No name set'**
  String get profileNoName;

  /// Button and page title
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get profileAccountSettings;

  /// Teacher shortcut button
  ///
  /// In en, this message translates to:
  /// **'My courses and rosters'**
  String get profileCoursesRosters;

  /// Student shortcut button
  ///
  /// In en, this message translates to:
  /// **'My courses and attendance'**
  String get profileCoursesAttendance;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Courses owned'**
  String get metricCoursesOwned;

  /// Metric hint
  ///
  /// In en, this message translates to:
  /// **'{count} archived'**
  String metricArchived(int count);

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Active students'**
  String get metricActiveStudents;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Awaiting grading'**
  String get metricAwaitingGrading;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get metricAttendanceRate;

  /// Metric hint
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open session} other{{count} open sessions}}'**
  String metricOpenSessions(int count);

  /// Footnote under the teacher figures
  ///
  /// In en, this message translates to:
  /// **'Figures cover only your own active courses and their active students.'**
  String get metricTeacherNote;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Enrolled courses'**
  String get metricEnrolledCourses;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Assignments done'**
  String get metricAssignmentsDone;

  /// Metric value
  ///
  /// In en, this message translates to:
  /// **'{done} of {published}'**
  String metricDoneOfPublished(int done, int published);

  /// Metric hint
  ///
  /// In en, this message translates to:
  /// **'Submitted or graded'**
  String get metricSubmittedOrGraded;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Awaiting grade'**
  String get metricAwaitingGrade;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get metricGraded;

  /// Metric hint
  ///
  /// In en, this message translates to:
  /// **'No grades yet'**
  String get metricNoGradesYet;

  /// Metric hint; {value} is a formatted percentage
  ///
  /// In en, this message translates to:
  /// **'Average {value}'**
  String metricAverage(String value);

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Returned for revision'**
  String get metricReturnedRevision;

  /// Footnote under the student figures
  ///
  /// In en, this message translates to:
  /// **'Done = submitted or graded, out of published assignments in your active courses. Attendance = (present + late) / (present + late + absent). Lesson completion is not tracked.'**
  String get metricStudentNote;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// List tile title
  ///
  /// In en, this message translates to:
  /// **'Registered email'**
  String get accountRegisteredEmail;

  /// List tile title
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get accountRole;

  /// Note
  ///
  /// In en, this message translates to:
  /// **'Your email and role are managed by the school administrator and cannot be changed in the app.'**
  String get accountManagedNote;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Email me a password reset link'**
  String get accountEmailResetLink;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get accountPrivacy;

  /// Privacy paragraph
  ///
  /// In en, this message translates to:
  /// **'Teachers see only students enrolled in their own courses; students see only their own work and their course teachers. Your data is not public and there is no public directory. Files are private and open only through short-lived links.'**
  String get accountPrivacyText;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get accountAbout;

  /// Version line
  ///
  /// In en, this message translates to:
  /// **'Version {version} (beta)'**
  String accountVersion(String version);

  /// Sign-out dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutTitle;

  /// Sign-out dialog text
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use LearnPulse.'**
  String get accountSignOutBody;

  /// Page header eyebrow
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountEyebrow;

  /// Page header description
  ///
  /// In en, this message translates to:
  /// **'Manage your identity, account access and privacy.'**
  String get accountDescription;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get accountPersonalDetails;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get accountDisplayName;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get accountSaveName;

  /// Mobile UI text (commonAll)
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// Mobile UI text (commonActive)
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// Mobile UI text (commonArchived)
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get commonArchived;

  /// Mobile UI text (commonDraft)
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get commonDraft;

  /// Mobile UI text (commonPublished)
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get commonPublished;

  /// Mobile UI text (commonPublish)
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get commonPublish;

  /// Mobile UI text (commonCreate)
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// Mobile UI text (commonTitle)
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commonTitle;

  /// Mobile UI text (commonCopy)
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Mobile UI text (commonDone)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Mobile UI text (commonJoin)
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get commonJoin;

  /// Mobile UI text (commonRemove)
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Mobile UI text (commonChange)
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// Mobile UI text (commonOpen)
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// Mobile UI text (commonClosed)
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get commonClosed;

  /// Mobile UI text (commonAttendance)
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get commonAttendance;

  /// Mobile UI text (commonAssignments)
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get commonAssignments;

  /// Mobile UI text (commonLessons)
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get commonLessons;

  /// Mobile UI text (commonFiles)
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get commonFiles;

  /// Mobile UI text (commonRemoveNamed)
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String commonRemoveNamed(String name);

  /// Mobile UI text (commonOpenNamed)
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String commonOpenNamed(String name);

  /// Mobile UI text (statusSubmitted)
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// Mobile UI text (statusReturned)
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get statusReturned;

  /// Mobile UI text (statusToGrade)
  ///
  /// In en, this message translates to:
  /// **'To grade'**
  String get statusToGrade;

  /// Mobile UI text (attPresent)
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attPresent;

  /// Mobile UI text (attLate)
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attLate;

  /// Mobile UI text (attExcused)
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get attExcused;

  /// Mobile UI text (attAbsent)
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attAbsent;

  /// Mobile UI text (validationTitleRequired)
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get validationTitleRequired;

  /// Mobile UI text (validationTitleLong)
  ///
  /// In en, this message translates to:
  /// **'Use at most 120 characters'**
  String get validationTitleLong;

  /// Mobile UI text (validationMaxScoreRange)
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 1000'**
  String get validationMaxScoreRange;

  /// Mobile UI text (validationJoinCodeRequired)
  ///
  /// In en, this message translates to:
  /// **'Enter the course code'**
  String get validationJoinCodeRequired;

  /// Mobile UI text (validationJoinCodeFormat)
  ///
  /// In en, this message translates to:
  /// **'Codes are 8 letters/digits (no I, O, 0 or 1)'**
  String get validationJoinCodeFormat;

  /// Mobile UI text (errorScoreWhole)
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get errorScoreWhole;

  /// Mobile UI text (errorScoreRange)
  ///
  /// In en, this message translates to:
  /// **'Score must be between 0 and {max}'**
  String errorScoreRange(int max);

  /// Mobile UI text (errorFeedbackLong)
  ///
  /// In en, this message translates to:
  /// **'Feedback is too long (5000 characters maximum).'**
  String get errorFeedbackLong;

  /// Mobile UI text (errorReturnReason)
  ///
  /// In en, this message translates to:
  /// **'Explain what the student should revise.'**
  String get errorReturnReason;

  /// Mobile UI text (errorFileLarger)
  ///
  /// In en, this message translates to:
  /// **'That file is larger than 10 MB.'**
  String get errorFileLarger;

  /// Mobile UI text (errorFileEmpty)
  ///
  /// In en, this message translates to:
  /// **'That file is empty.'**
  String get errorFileEmpty;

  /// Mobile UI text (errorWriteOrAttach)
  ///
  /// In en, this message translates to:
  /// **'Write an answer or attach a file.'**
  String get errorWriteOrAttach;

  /// Mobile UI text (errorUploadIncomplete)
  ///
  /// In en, this message translates to:
  /// **'The file didn\'t finish uploading. Tap Submit to try again.'**
  String get errorUploadIncomplete;

  /// Mobile UI text (errorSubmissionChanged)
  ///
  /// In en, this message translates to:
  /// **'Your submission was changed on another device. Reload to continue; your text is kept.'**
  String get errorSubmissionChanged;

  /// Mobile UI text (errorGradeConflict)
  ///
  /// In en, this message translates to:
  /// **'This submission changed (for example the student resubmitted). Reload to see the latest; your typed score and feedback are kept.'**
  String get errorGradeConflict;

  /// Mobile UI text (errorFileNoAccess)
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this file.'**
  String get errorFileNoAccess;

  /// Mobile UI text (errorFileTypeList)
  ///
  /// In en, this message translates to:
  /// **'That file type is not allowed. Use pdf, docx, zip, png, jpg, webp or txt.'**
  String get errorFileTypeList;

  /// Mobile UI text (errorOpenFile)
  ///
  /// In en, this message translates to:
  /// **'Could not open the file.'**
  String get errorOpenFile;

  /// Mobile UI text (noticeJoinedCourse)
  ///
  /// In en, this message translates to:
  /// **'Joined {title}.'**
  String noticeJoinedCourse(String title);

  /// Mobile UI text (noticeTheCourse)
  ///
  /// In en, this message translates to:
  /// **'the course'**
  String get noticeTheCourse;

  /// Mobile UI text (noticeSubmissionSaved)
  ///
  /// In en, this message translates to:
  /// **'Submission saved.'**
  String get noticeSubmissionSaved;

  /// Mobile UI text (noticeGradeSaved)
  ///
  /// In en, this message translates to:
  /// **'Grade saved.'**
  String get noticeGradeSaved;

  /// Mobile UI text (noticeReturnedForRevision)
  ///
  /// In en, this message translates to:
  /// **'Returned to the student for revision.'**
  String get noticeReturnedForRevision;

  /// Mobile UI text (dashHello)
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String dashHello(String name);

  /// Mobile UI text (dashActiveCourses)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active course} other{{count} active courses}}'**
  String dashActiveCourses(int count);

  /// Mobile UI text (dashTeacherHeroDetail)
  ///
  /// In en, this message translates to:
  /// **'{courses} · {grading} awaiting grading'**
  String dashTeacherHeroDetail(String courses, int grading);

  /// Mobile UI text (dashStudentHeroDetail)
  ///
  /// In en, this message translates to:
  /// **'{courses} · {done} of {published} assignments done'**
  String dashStudentHeroDetail(String courses, int done, int published);

  /// Mobile UI text (dashStatCourses)
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get dashStatCourses;

  /// Mobile UI text (dashStatToGrade)
  ///
  /// In en, this message translates to:
  /// **'To grade'**
  String get dashStatToGrade;

  /// Mobile UI text (dashStatStudents)
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get dashStatStudents;

  /// Mobile UI text (dashStatDone)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dashStatDone;

  /// Mobile UI text (dashServices)
  ///
  /// In en, this message translates to:
  /// **'Academic services'**
  String get dashServices;

  /// Mobile UI text (dashServiceGrading)
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get dashServiceGrading;

  /// Mobile UI text (dashServiceProfile)
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get dashServiceProfile;

  /// Mobile UI text (dashServiceProfileDetail)
  ///
  /// In en, this message translates to:
  /// **'Progress & account'**
  String get dashServiceProfileDetail;

  /// Mobile UI text (dashDetailActive)
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String dashDetailActive(int count);

  /// Mobile UI text (dashDetailToReview)
  ///
  /// In en, this message translates to:
  /// **'{count} to review'**
  String dashDetailToReview(int count);

  /// Mobile UI text (dashDetailOpen)
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String dashDetailOpen(int count);

  /// Mobile UI text (dashDetailEnrolled)
  ///
  /// In en, this message translates to:
  /// **'{count} enrolled'**
  String dashDetailEnrolled(int count);

  /// Mobile UI text (dashDetailPublished)
  ///
  /// In en, this message translates to:
  /// **'{count} published'**
  String dashDetailPublished(int count);

  /// Mobile UI text (dashEmptyTeacherTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get dashEmptyTeacherTitle;

  /// Mobile UI text (dashEmptyTeacherHint)
  ///
  /// In en, this message translates to:
  /// **'Create a course in the Courses tab. This page fills in as students join, submit work and attend.'**
  String get dashEmptyTeacherHint;

  /// Mobile UI text (dashNeedsAttention)
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get dashNeedsAttention;

  /// Mobile UI text (dashAllCaughtUp)
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get dashAllCaughtUp;

  /// Mobile UI text (dashSubmissionsAwaiting)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 submission awaiting grading} other{{count} submissions awaiting grading}}'**
  String dashSubmissionsAwaiting(int count);

  /// Mobile UI text (dashSubmittedLine)
  ///
  /// In en, this message translates to:
  /// **'Submitted: {received} of {expected} · attendance {rate}'**
  String dashSubmittedLine(int received, int expected, String rate);

  /// Mobile UI text (dashReviewSubmissions)
  ///
  /// In en, this message translates to:
  /// **'Review submissions'**
  String get dashReviewSubmissions;

  /// Mobile UI text (dashUpcomingDeadlines)
  ///
  /// In en, this message translates to:
  /// **'Upcoming deadlines'**
  String get dashUpcomingDeadlines;

  /// Mobile UI text (dashNoDeadlines)
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines.'**
  String get dashNoDeadlines;

  /// Mobile UI text (dashNothingDueSoon)
  ///
  /// In en, this message translates to:
  /// **'Nothing due soon.'**
  String get dashNothingDueSoon;

  /// Mobile UI text (dashRecentSubmissions)
  ///
  /// In en, this message translates to:
  /// **'Recent submissions'**
  String get dashRecentSubmissions;

  /// Mobile UI text (dashNoSubmissions)
  ///
  /// In en, this message translates to:
  /// **'No submissions yet.'**
  String get dashNoSubmissions;

  /// Mobile UI text (dashArchivedStudents)
  ///
  /// In en, this message translates to:
  /// **'Archived · {students}'**
  String dashArchivedStudents(String students);

  /// Mobile UI text (dashCountStudents)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}}'**
  String dashCountStudents(int count);

  /// Mobile UI text (dashCountAssignments)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 assignment} other{{count} assignments}}'**
  String dashCountAssignments(int count);

  /// Mobile UI text (dashCountSessions)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String dashCountSessions(int count);

  /// Mobile UI text (dashToGradeCount)
  ///
  /// In en, this message translates to:
  /// **'{count} to grade'**
  String dashToGradeCount(int count);

  /// Mobile UI text (dashAllFigures)
  ///
  /// In en, this message translates to:
  /// **'All figures'**
  String get dashAllFigures;

  /// Mobile UI text (dashActiveCoursesLabel)
  ///
  /// In en, this message translates to:
  /// **'Active courses'**
  String get dashActiveCoursesLabel;

  /// Mobile UI text (dashOutstanding)
  ///
  /// In en, this message translates to:
  /// **'Outstanding work'**
  String get dashOutstanding;

  /// Mobile UI text (dashSubmittedOf)
  ///
  /// In en, this message translates to:
  /// **'{received} of {expected} submitted'**
  String dashSubmittedOf(int received, int expected);

  /// Mobile UI text (dashPublishedAssignments)
  ///
  /// In en, this message translates to:
  /// **'Published assignments'**
  String get dashPublishedAssignments;

  /// Mobile UI text (dashGradedReturned)
  ///
  /// In en, this message translates to:
  /// **'{graded} graded · {returned} returned'**
  String dashGradedReturned(int graded, int returned);

  /// Mobile UI text (dashTeacherFootnote)
  ///
  /// In en, this message translates to:
  /// **'Only active students count. Archived courses are excluded from work and attendance figures. Attendance rate = (Present + Late) ÷ (Present + Late + Absent); Excused is not counted.'**
  String get dashTeacherFootnote;

  /// Mobile UI text (dashEmptyStudentTitle)
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get dashEmptyStudentTitle;

  /// Mobile UI text (dashEmptyStudentHint)
  ///
  /// In en, this message translates to:
  /// **'Open the Courses tab and enter the join code from your teacher.'**
  String get dashEmptyStudentHint;

  /// Mobile UI text (dashNeedsYourAttention)
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get dashNeedsYourAttention;

  /// Mobile UI text (dashYourNextStep)
  ///
  /// In en, this message translates to:
  /// **'Your next step'**
  String get dashYourNextStep;

  /// Mobile UI text (dashOverdueCount)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 assignment overdue} other{{count} assignments overdue}}'**
  String dashOverdueCount(int count);

  /// Mobile UI text (dashReadyToLearn)
  ///
  /// In en, this message translates to:
  /// **'Ready to learn?'**
  String get dashReadyToLearn;

  /// Mobile UI text (dashExploreCourses)
  ///
  /// In en, this message translates to:
  /// **'Explore your courses and pick up where you left off.'**
  String get dashExploreCourses;

  /// Mobile UI text (dashOpenCourses)
  ///
  /// In en, this message translates to:
  /// **'Open courses'**
  String get dashOpenCourses;

  /// Mobile UI text (dashStatusRevise)
  ///
  /// In en, this message translates to:
  /// **'Revise'**
  String get dashStatusRevise;

  /// Mobile UI text (dashStatusTodo)
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get dashStatusTodo;

  /// Mobile UI text (dashLearningProgress)
  ///
  /// In en, this message translates to:
  /// **'Learning progress'**
  String get dashLearningProgress;

  /// Mobile UI text (dashDoneOfPublished)
  ///
  /// In en, this message translates to:
  /// **'{done} of {published} assignments done'**
  String dashDoneOfPublished(int done, int published);

  /// Mobile UI text (dashAttendanceValue)
  ///
  /// In en, this message translates to:
  /// **'Attendance {value}'**
  String dashAttendanceValue(String value);

  /// Mobile UI text (dashMyCourses)
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get dashMyCourses;

  /// Mobile UI text (dashArchivedReadOnly)
  ///
  /// In en, this message translates to:
  /// **'Archived (read-only)'**
  String get dashArchivedReadOnly;

  /// Mobile UI text (dashCourseProgressLine)
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} assignments done · attendance {rate}'**
  String dashCourseProgressLine(int done, int total, String rate);

  /// Mobile UI text (dashRecentResults)
  ///
  /// In en, this message translates to:
  /// **'Recent results'**
  String get dashRecentResults;

  /// Mobile UI text (dashNoGraded)
  ///
  /// In en, this message translates to:
  /// **'No graded work yet.'**
  String get dashNoGraded;

  /// Mobile UI text (dashFeedbackAvailable)
  ///
  /// In en, this message translates to:
  /// **'feedback available'**
  String get dashFeedbackAvailable;

  /// Mobile UI text (dashNewLessons)
  ///
  /// In en, this message translates to:
  /// **'New lessons'**
  String get dashNewLessons;

  /// Mobile UI text (dashNotStarted)
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get dashNotStarted;

  /// Mobile UI text (dashOverdueHint)
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String dashOverdueHint(int count);

  /// Mobile UI text (dashNeedsRevision)
  ///
  /// In en, this message translates to:
  /// **'Needs revision'**
  String get dashNeedsRevision;

  /// Mobile UI text (dashStudentFootnote)
  ///
  /// In en, this message translates to:
  /// **'Course progress = assignments submitted or graded ÷ assignments published. Returned work is not done until you resubmit. Lessons are not tracked as completed.'**
  String get dashStudentFootnote;

  /// Mobile UI text (dashNothingToShow)
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet.'**
  String get dashNothingToShow;

  /// Mobile UI text (courseEyebrowTeaching)
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get courseEyebrowTeaching;

  /// Mobile UI text (courseEyebrowLearning)
  ///
  /// In en, this message translates to:
  /// **'My learning'**
  String get courseEyebrowLearning;

  /// Mobile UI text (courseYourCourses)
  ///
  /// In en, this message translates to:
  /// **'Your courses'**
  String get courseYourCourses;

  /// Mobile UI text (courseDescTeacher)
  ///
  /// In en, this message translates to:
  /// **'Manage lessons, assignments and attendance in each course.'**
  String get courseDescTeacher;

  /// Mobile UI text (courseDescStudent)
  ///
  /// In en, this message translates to:
  /// **'Open a course to continue with lessons and assignments.'**
  String get courseDescStudent;

  /// Mobile UI text (courseNew)
  ///
  /// In en, this message translates to:
  /// **'New course'**
  String get courseNew;

  /// Mobile UI text (courseJoin)
  ///
  /// In en, this message translates to:
  /// **'Join a course'**
  String get courseJoin;

  /// Mobile UI text (courseServiceLabel)
  ///
  /// In en, this message translates to:
  /// **'Course service'**
  String get courseServiceLabel;

  /// Mobile UI text (courseAllContent)
  ///
  /// In en, this message translates to:
  /// **'All course content'**
  String get courseAllContent;

  /// Mobile UI text (courseNoInCategory)
  ///
  /// In en, this message translates to:
  /// **'No courses in this category. Choose another filter.'**
  String get courseNoInCategory;

  /// Mobile UI text (courseCouldNotRefresh)
  ///
  /// In en, this message translates to:
  /// **'Could not refresh: {message}'**
  String courseCouldNotRefresh(String message);

  /// Mobile UI text (courseEmptyTeacherTitle)
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get courseEmptyTeacherTitle;

  /// Mobile UI text (courseEmptyTeacherHint)
  ///
  /// In en, this message translates to:
  /// **'Create your first course, then share its code with students.'**
  String get courseEmptyTeacherHint;

  /// Mobile UI text (courseEmptyStudentTitle)
  ///
  /// In en, this message translates to:
  /// **'You have not joined a course'**
  String get courseEmptyStudentTitle;

  /// Mobile UI text (courseEmptyStudentHint)
  ///
  /// In en, this message translates to:
  /// **'Ask your teacher for a course code and tap \"Join a course\".'**
  String get courseEmptyStudentHint;

  /// Mobile UI text (courseAreaTeachingAssignments)
  ///
  /// In en, this message translates to:
  /// **'Teaching · Assignments'**
  String get courseAreaTeachingAssignments;

  /// Mobile UI text (courseAreaLearningAssignments)
  ///
  /// In en, this message translates to:
  /// **'Learning · Assignments'**
  String get courseAreaLearningAssignments;

  /// Mobile UI text (courseAreaTeachingAttendance)
  ///
  /// In en, this message translates to:
  /// **'Teaching · Attendance'**
  String get courseAreaTeachingAttendance;

  /// Mobile UI text (courseAreaLearningAttendance)
  ///
  /// In en, this message translates to:
  /// **'Learning · Attendance'**
  String get courseAreaLearningAttendance;

  /// Mobile UI text (courseTapToManage)
  ///
  /// In en, this message translates to:
  /// **'Tap to manage'**
  String get courseTapToManage;

  /// Mobile UI text (courseTeacherName)
  ///
  /// In en, this message translates to:
  /// **'Teacher: {name}'**
  String courseTeacherName(String name);

  /// Mobile UI text (courseTeachingCourse)
  ///
  /// In en, this message translates to:
  /// **'Teaching course'**
  String get courseTeachingCourse;

  /// Mobile UI text (courseEnrolledCourse)
  ///
  /// In en, this message translates to:
  /// **'Enrolled course'**
  String get courseEnrolledCourse;

  /// Mobile UI text (courseTeachingWorkspace)
  ///
  /// In en, this message translates to:
  /// **'Your teaching workspace'**
  String get courseTeachingWorkspace;

  /// Mobile UI text (courseLearningWorkspace)
  ///
  /// In en, this message translates to:
  /// **'Your learning workspace'**
  String get courseLearningWorkspace;

  /// Mobile UI text (courseManage)
  ///
  /// In en, this message translates to:
  /// **'Manage course'**
  String get courseManage;

  /// Mobile UI text (courseOpen)
  ///
  /// In en, this message translates to:
  /// **'Open course'**
  String get courseOpen;

  /// Mobile UI text (courseLearningEyebrow)
  ///
  /// In en, this message translates to:
  /// **'Learning workspace'**
  String get courseLearningEyebrow;

  /// Mobile UI text (courseArchivedNote)
  ///
  /// In en, this message translates to:
  /// **'This course is archived. It stays visible but is read-only.'**
  String get courseArchivedNote;

  /// Mobile UI text (courseEdit)
  ///
  /// In en, this message translates to:
  /// **'Edit course'**
  String get courseEdit;

  /// Mobile UI text (courseDescriptionOptional)
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get courseDescriptionOptional;

  /// Mobile UI text (courseCreated)
  ///
  /// In en, this message translates to:
  /// **'Course created'**
  String get courseCreated;

  /// Mobile UI text (courseShareCode)
  ///
  /// In en, this message translates to:
  /// **'Share this code with your students:'**
  String get courseShareCode;

  /// Mobile UI text (courseCodeLabel)
  ///
  /// In en, this message translates to:
  /// **'Course code'**
  String get courseCodeLabel;

  /// Mobile UI text (courseRemovedMsg)
  ///
  /// In en, this message translates to:
  /// **'You were removed from this course. Ask your teacher to add you back.'**
  String get courseRemovedMsg;

  /// Mobile UI text (courseCodeInvalid)
  ///
  /// In en, this message translates to:
  /// **'That code is not valid, or the course is closed.'**
  String get courseCodeInvalid;

  /// Mobile UI text (courseArchiveTitle)
  ///
  /// In en, this message translates to:
  /// **'Archive this course?'**
  String get courseArchiveTitle;

  /// Mobile UI text (courseReopenTitle)
  ///
  /// In en, this message translates to:
  /// **'Reopen this course?'**
  String get courseReopenTitle;

  /// Mobile UI text (courseArchiveBody)
  ///
  /// In en, this message translates to:
  /// **'Students keep read-only access, but nobody new can join with the code.'**
  String get courseArchiveBody;

  /// Mobile UI text (courseReopenBody)
  ///
  /// In en, this message translates to:
  /// **'Students will be able to join with the code again.'**
  String get courseReopenBody;

  /// Mobile UI text (courseArchiveAction)
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get courseArchiveAction;

  /// Mobile UI text (courseReopenAction)
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get courseReopenAction;

  /// Mobile UI text (courseRemoveTitle)
  ///
  /// In en, this message translates to:
  /// **'Remove student?'**
  String get courseRemoveTitle;

  /// Mobile UI text (courseRemoveBody)
  ///
  /// In en, this message translates to:
  /// **'{name} will lose access to the course and cannot rejoin with the code.'**
  String courseRemoveBody(String name);

  /// Mobile UI text (courseThisStudent)
  ///
  /// In en, this message translates to:
  /// **'This student'**
  String get courseThisStudent;

  /// Mobile UI text (courseInviteTitle)
  ///
  /// In en, this message translates to:
  /// **'Invite your first students'**
  String get courseInviteTitle;

  /// Mobile UI text (courseInviteBody)
  ///
  /// In en, this message translates to:
  /// **'Share the join code below. Attendance, grading and progress fill in once students join.'**
  String get courseInviteBody;

  /// Mobile UI text (courseSvcSubmissions)
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get courseSvcSubmissions;

  /// Mobile UI text (courseSvcReviewWork)
  ///
  /// In en, this message translates to:
  /// **'Review work'**
  String get courseSvcReviewWork;

  /// Mobile UI text (courseSvcRoster)
  ///
  /// In en, this message translates to:
  /// **'Roster'**
  String get courseSvcRoster;

  /// Mobile UI text (courseSvcContent)
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get courseSvcContent;

  /// Mobile UI text (courseWeeklyAttendance)
  ///
  /// In en, this message translates to:
  /// **'Weekly attendance'**
  String get courseWeeklyAttendance;

  /// Mobile UI text (courseAdmin)
  ///
  /// In en, this message translates to:
  /// **'Course administration'**
  String get courseAdmin;

  /// Mobile UI text (courseJoinCode)
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get courseJoinCode;

  /// Mobile UI text (courseCopyCode)
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get courseCopyCode;

  /// Mobile UI text (courseCodeCopied)
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get courseCodeCopied;

  /// Mobile UI text (courseArchivedNoJoin)
  ///
  /// In en, this message translates to:
  /// **'Archived: students cannot join until you reopen the course.'**
  String get courseArchivedNoJoin;

  /// Mobile UI text (courseReopenCourse)
  ///
  /// In en, this message translates to:
  /// **'Reopen course'**
  String get courseReopenCourse;

  /// Mobile UI text (courseArchiveCourse)
  ///
  /// In en, this message translates to:
  /// **'Archive course'**
  String get courseArchiveCourse;

  /// Mobile UI text (courseStudentsTitle)
  ///
  /// In en, this message translates to:
  /// **'Students ({count})'**
  String courseStudentsTitle(int count);

  /// Mobile UI text (courseNoStudents)
  ///
  /// In en, this message translates to:
  /// **'No students yet. Share the join code above.'**
  String get courseNoStudents;

  /// Mobile UI text (courseJoinedTap)
  ///
  /// In en, this message translates to:
  /// **'Joined {date} · tap for progress'**
  String courseJoinedTap(String date);

  /// Mobile UI text (courseRemovedCount)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 removed student (no access)} other{{count} removed students (no access)}}'**
  String courseRemovedCount(int count);

  /// Mobile UI text (classYourClass)
  ///
  /// In en, this message translates to:
  /// **'Your class'**
  String get classYourClass;

  /// Mobile UI text (classArchivedReadOnly)
  ///
  /// In en, this message translates to:
  /// **'Archived · read-only'**
  String get classArchivedReadOnly;

  /// Mobile UI text (classHeroSemantics)
  ///
  /// In en, this message translates to:
  /// **'{students} students, {sessions} open attendance sessions, {toGrade} submissions to grade'**
  String classHeroSemantics(int students, int sessions, String toGrade);

  /// Mobile UI text (classUnknownNumber)
  ///
  /// In en, this message translates to:
  /// **'unknown number of'**
  String get classUnknownNumber;

  /// Mobile UI text (classOpenSessions)
  ///
  /// In en, this message translates to:
  /// **'Open sessions'**
  String get classOpenSessions;

  /// Mobile UI text (classNoSessions)
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get classNoSessions;

  /// Mobile UI text (classRateValue)
  ///
  /// In en, this message translates to:
  /// **'Class rate {value}'**
  String classRateValue(String value);

  /// Mobile UI text (classSessions)
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get classSessions;

  /// Mobile UI text (classNoAttendanceSessions)
  ///
  /// In en, this message translates to:
  /// **'No attendance sessions yet. Create one in the Attendance section to start tracking.'**
  String get classNoAttendanceSessions;

  /// Mobile UI text (classLatestSession)
  ///
  /// In en, this message translates to:
  /// **'Latest session'**
  String get classLatestSession;

  /// Mobile UI text (classSessionFallback)
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get classSessionFallback;

  /// Mobile UI text (classNotMarked)
  ///
  /// In en, this message translates to:
  /// **'Not marked {count}'**
  String classNotMarked(int count);

  /// Mobile UI text (classNothingToGrade)
  ///
  /// In en, this message translates to:
  /// **'Nothing to grade'**
  String get classNothingToGrade;

  /// Mobile UI text (classPublished)
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get classPublished;

  /// Mobile UI text (classDrafts)
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get classDrafts;

  /// Mobile UI text (classNoPublished)
  ///
  /// In en, this message translates to:
  /// **'No published assignments yet.'**
  String get classNoPublished;

  /// Mobile UI text (classSubmissionsReceived)
  ///
  /// In en, this message translates to:
  /// **'Submissions received'**
  String get classSubmissionsReceived;

  /// Mobile UI text (classDueLower)
  ///
  /// In en, this message translates to:
  /// **'due {when}'**
  String classDueLower(String when);

  /// Mobile UI text (classNoRecent)
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get classNoRecent;

  /// Mobile UI text (classNoRecentHint)
  ///
  /// In en, this message translates to:
  /// **'Submitted work will show here as students hand it in.'**
  String get classNoRecentHint;

  /// Mobile UI text (classAttendanceByStudent)
  ///
  /// In en, this message translates to:
  /// **'Attendance by student'**
  String get classAttendanceByStudent;

  /// Mobile UI text (classNoStudentsEnrolled)
  ///
  /// In en, this message translates to:
  /// **'No students enrolled yet'**
  String get classNoStudentsEnrolled;

  /// Mobile UI text (classShareCode)
  ///
  /// In en, this message translates to:
  /// **'Share the join code so students can enrol.'**
  String get classShareCode;

  /// Mobile UI text (lessonFilesCount)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String lessonFilesCount(int count);

  /// Mobile UI text (lessonNew)
  ///
  /// In en, this message translates to:
  /// **'New lesson'**
  String get lessonNew;

  /// Mobile UI text (lessonNoneYet)
  ///
  /// In en, this message translates to:
  /// **'No lessons yet'**
  String get lessonNoneYet;

  /// Mobile UI text (lessonEmptyTeacher)
  ///
  /// In en, this message translates to:
  /// **'Create a draft, add files, then publish it for students.'**
  String get lessonEmptyTeacher;

  /// Mobile UI text (lessonEmptyStudent)
  ///
  /// In en, this message translates to:
  /// **'Your teacher has not published any lessons for this course.'**
  String get lessonEmptyStudent;

  /// Mobile UI text (lessonText)
  ///
  /// In en, this message translates to:
  /// **'Lesson text'**
  String get lessonText;

  /// Mobile UI text (lessonCreateDraft)
  ///
  /// In en, this message translates to:
  /// **'Create draft'**
  String get lessonCreateDraft;

  /// Mobile UI text (lessonDeleteTitle)
  ///
  /// In en, this message translates to:
  /// **'Delete lesson?'**
  String get lessonDeleteTitle;

  /// Mobile UI text (lessonDeleteBody)
  ///
  /// In en, this message translates to:
  /// **'The lesson and its files disappear for everyone. This cannot be undone.'**
  String get lessonDeleteBody;

  /// Mobile UI text (lessonTitle)
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonTitle;

  /// Mobile UI text (lessonGone)
  ///
  /// In en, this message translates to:
  /// **'This lesson no longer exists.'**
  String get lessonGone;

  /// Mobile UI text (lessonNoFilesAttached)
  ///
  /// In en, this message translates to:
  /// **'No files attached.'**
  String get lessonNoFilesAttached;

  /// Mobile UI text (lessonAttach)
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get lessonAttach;

  /// Mobile UI text (lessonPublication)
  ///
  /// In en, this message translates to:
  /// **'Publication & access'**
  String get lessonPublication;

  /// Mobile UI text (lessonSaveFirst)
  ///
  /// In en, this message translates to:
  /// **'Save your content before changing its visibility.'**
  String get lessonSaveFirst;

  /// Mobile UI text (lessonUnpublish)
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get lessonUnpublish;

  /// Mobile UI text (lessonDelete)
  ///
  /// In en, this message translates to:
  /// **'Delete lesson'**
  String get lessonDelete;

  /// Mobile UI text (lessonEditEyebrow)
  ///
  /// In en, this message translates to:
  /// **'Edit lesson'**
  String get lessonEditEyebrow;

  /// Mobile UI text (lessonPublishedDesc)
  ///
  /// In en, this message translates to:
  /// **'Published · Students can read this lesson.'**
  String get lessonPublishedDesc;

  /// Mobile UI text (lessonDraftDesc)
  ///
  /// In en, this message translates to:
  /// **'Draft · Only you can see this lesson.'**
  String get lessonDraftDesc;

  /// Mobile UI text (lessonContent)
  ///
  /// In en, this message translates to:
  /// **'Learning content'**
  String get lessonContent;

  /// Mobile UI text (lessonSaveChanges)
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get lessonSaveChanges;

  /// Mobile UI text (lessonCourseEyebrow)
  ///
  /// In en, this message translates to:
  /// **'{course} · Lesson'**
  String lessonCourseEyebrow(String course);

  /// Mobile UI text (lessonReadExplore)
  ///
  /// In en, this message translates to:
  /// **'Read, explore, then put it into practice.'**
  String get lessonReadExplore;

  /// Mobile UI text (lessonNoText)
  ///
  /// In en, this message translates to:
  /// **'No lesson text.'**
  String get lessonNoText;

  /// Mobile UI text (lessonSupporting)
  ///
  /// In en, this message translates to:
  /// **'Supporting resources for this lesson.'**
  String get lessonSupporting;

  /// Mobile UI text (lessonNoFiles)
  ///
  /// In en, this message translates to:
  /// **'No files for this lesson.'**
  String get lessonNoFiles;

  /// Mobile UI text (asgNotSubmitted)
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get asgNotSubmitted;

  /// Mobile UI text (asgGradedScore)
  ///
  /// In en, this message translates to:
  /// **'Graded {score}/{max}'**
  String asgGradedScore(int score, int max);

  /// Mobile UI text (asgReturnedForRevision)
  ///
  /// In en, this message translates to:
  /// **'Returned for revision'**
  String get asgReturnedForRevision;

  /// Mobile UI text (asgNone)
  ///
  /// In en, this message translates to:
  /// **'No assignments yet'**
  String get asgNone;

  /// Mobile UI text (asgStudentEmptyHint)
  ///
  /// In en, this message translates to:
  /// **'New work from your teacher will appear here.'**
  String get asgStudentEmptyHint;

  /// Mobile UI text (asgNoDeadline)
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get asgNoDeadline;

  /// Mobile UI text (asgDue)
  ///
  /// In en, this message translates to:
  /// **'Due {when}'**
  String asgDue(String when);

  /// Mobile UI text (asgResultGraded)
  ///
  /// In en, this message translates to:
  /// **'Graded: {score}/{max}'**
  String asgResultGraded(int score, int max);

  /// Mobile UI text (asgFeedbackLine)
  ///
  /// In en, this message translates to:
  /// **'Feedback: {text}'**
  String asgFeedbackLine(String text);

  /// Mobile UI text (asgGradedLocked)
  ///
  /// In en, this message translates to:
  /// **'This submission is graded and locked.'**
  String get asgGradedLocked;

  /// Mobile UI text (asgReviseResubmit)
  ///
  /// In en, this message translates to:
  /// **'Revise your work below and resubmit.'**
  String get asgReviseResubmit;

  /// Mobile UI text (asgSavedSubmission)
  ///
  /// In en, this message translates to:
  /// **'Your saved submission'**
  String get asgSavedSubmission;

  /// Mobile UI text (asgSavedLine)
  ///
  /// In en, this message translates to:
  /// **'Saved {when} · version {version}'**
  String asgSavedLine(String when, int version);

  /// Mobile UI text (asgReload)
  ///
  /// In en, this message translates to:
  /// **'Reload my submission'**
  String get asgReload;

  /// Mobile UI text (asgEyebrowWorkspace)
  ///
  /// In en, this message translates to:
  /// **'Assignment / Your workspace'**
  String get asgEyebrowWorkspace;

  /// Mobile UI text (asgMaxScore)
  ///
  /// In en, this message translates to:
  /// **'Max score {score}'**
  String asgMaxScore(int score);

  /// Mobile UI text (asgDeadlinePassed)
  ///
  /// In en, this message translates to:
  /// **'The deadline has passed. Submissions are closed.'**
  String get asgDeadlinePassed;

  /// Mobile UI text (asgBrief)
  ///
  /// In en, this message translates to:
  /// **'The brief'**
  String get asgBrief;

  /// Mobile UI text (asgNoInstructions)
  ///
  /// In en, this message translates to:
  /// **'No instructions.'**
  String get asgNoInstructions;

  /// Mobile UI text (asgUploading)
  ///
  /// In en, this message translates to:
  /// **'Uploading file…'**
  String get asgUploading;

  /// Mobile UI text (asgSaving)
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get asgSaving;

  /// Mobile UI text (asgSubmit)
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get asgSubmit;

  /// Mobile UI text (asgResubmit)
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get asgResubmit;

  /// Mobile UI text (asgYourResponse)
  ///
  /// In en, this message translates to:
  /// **'Your response'**
  String get asgYourResponse;

  /// Mobile UI text (asgFirstHint)
  ///
  /// In en, this message translates to:
  /// **'Write your answer or attach your work. Submit when you are ready.'**
  String get asgFirstHint;

  /// Mobile UI text (asgUpdateHint)
  ///
  /// In en, this message translates to:
  /// **'Update your answer below. Your saved version stays available until you resubmit.'**
  String get asgUpdateHint;

  /// Mobile UI text (asgYourAnswer)
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get asgYourAnswer;

  /// Mobile UI text (asgAnswerHint)
  ///
  /// In en, this message translates to:
  /// **'Start with your approach, then explain what you found…'**
  String get asgAnswerHint;

  /// Mobile UI text (asgUploadPrivately)
  ///
  /// In en, this message translates to:
  /// **'{size} · will be uploaded privately'**
  String asgUploadPrivately(String size);

  /// Mobile UI text (asgRemoveAttachmentTip)
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get asgRemoveAttachmentTip;

  /// Mobile UI text (asgReplaceFile)
  ///
  /// In en, this message translates to:
  /// **'Replace attached file'**
  String get asgReplaceFile;

  /// Mobile UI text (asgAttachFile)
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get asgAttachFile;

  /// Mobile UI text (asgRemoveSaved)
  ///
  /// In en, this message translates to:
  /// **'Remove my saved attachment'**
  String get asgRemoveSaved;

  /// Mobile UI text (asgSavedOnSubmit)
  ///
  /// In en, this message translates to:
  /// **'Your work is saved when you submit.'**
  String get asgSavedOnSubmit;

  /// Mobile UI text (asgNewTitle)
  ///
  /// In en, this message translates to:
  /// **'New assignment'**
  String get asgNewTitle;

  /// Mobile UI text (asgEditTitle)
  ///
  /// In en, this message translates to:
  /// **'Edit assignment'**
  String get asgEditTitle;

  /// Mobile UI text (asgInstructions)
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get asgInstructions;

  /// Mobile UI text (asgMaxScoreLabel)
  ///
  /// In en, this message translates to:
  /// **'Maximum score'**
  String get asgMaxScoreLabel;

  /// Mobile UI text (asgSetDeadline)
  ///
  /// In en, this message translates to:
  /// **'Set deadline'**
  String get asgSetDeadline;

  /// Mobile UI text (asgRemoveDeadline)
  ///
  /// In en, this message translates to:
  /// **'Remove deadline'**
  String get asgRemoveDeadline;

  /// Mobile UI text (asgSaveDraft)
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get asgSaveDraft;

  /// Mobile UI text (asgTeacherEmptyHint)
  ///
  /// In en, this message translates to:
  /// **'Create a draft, then publish it for students.'**
  String get asgTeacherEmptyHint;

  /// Mobile UI text (asgPublishTitle)
  ///
  /// In en, this message translates to:
  /// **'Publish assignment?'**
  String get asgPublishTitle;

  /// Mobile UI text (asgPublishBody)
  ///
  /// In en, this message translates to:
  /// **'Enrolled students will see it and can start submitting work.'**
  String get asgPublishBody;

  /// Mobile UI text (asgGone)
  ///
  /// In en, this message translates to:
  /// **'This assignment is no longer available.'**
  String get asgGone;

  /// Mobile UI text (asgSubmissionsCount)
  ///
  /// In en, this message translates to:
  /// **'Submissions ({count})'**
  String asgSubmissionsCount(int count);

  /// Mobile UI text (asgTeachingEyebrow)
  ///
  /// In en, this message translates to:
  /// **'Teaching / Assignment'**
  String get asgTeachingEyebrow;

  /// Mobile UI text (asgReviewDesc)
  ///
  /// In en, this message translates to:
  /// **'Review submissions and move learning forward.'**
  String get asgReviewDesc;

  /// Mobile UI text (asgPrepareDesc)
  ///
  /// In en, this message translates to:
  /// **'Prepare your brief, then publish it to your course.'**
  String get asgPrepareDesc;

  /// Mobile UI text (asgBriefTitle)
  ///
  /// In en, this message translates to:
  /// **'Assignment brief'**
  String get asgBriefTitle;

  /// Mobile UI text (asgDraftsHidden)
  ///
  /// In en, this message translates to:
  /// **'Students cannot see drafts. Publish to receive submissions.'**
  String get asgDraftsHidden;

  /// Mobile UI text (asgNoSubmissions)
  ///
  /// In en, this message translates to:
  /// **'No submissions yet'**
  String get asgNoSubmissions;

  /// Mobile UI text (asgNoSubmissionsHint)
  ///
  /// In en, this message translates to:
  /// **'Student work will appear here as it is handed in.'**
  String get asgNoSubmissionsHint;

  /// Mobile UI text (asgSubmittedVersion)
  ///
  /// In en, this message translates to:
  /// **'Submitted {when} · version {version}'**
  String asgSubmittedVersion(String when, int version);

  /// Mobile UI text (asgGrade)
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get asgGrade;

  /// Mobile UI text (asgReview)
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get asgReview;

  /// Mobile UI text (gradeReviewEyebrow)
  ///
  /// In en, this message translates to:
  /// **'Review · {title}'**
  String gradeReviewEyebrow(String title);

  /// Mobile UI text (gradeStudentSubmission)
  ///
  /// In en, this message translates to:
  /// **'Student submission'**
  String get gradeStudentSubmission;

  /// Mobile UI text (gradeReadDesc)
  ///
  /// In en, this message translates to:
  /// **'Read the work, then give a clear next step.'**
  String get gradeReadDesc;

  /// Mobile UI text (gradeStatusTitle)
  ///
  /// In en, this message translates to:
  /// **'Submission status'**
  String get gradeStatusTitle;

  /// Mobile UI text (gradeVersion)
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get gradeVersion;

  /// Mobile UI text (gradeMaxScore)
  ///
  /// In en, this message translates to:
  /// **'Max score'**
  String get gradeMaxScore;

  /// Mobile UI text (gradeSubmittedAt)
  ///
  /// In en, this message translates to:
  /// **'Submitted {when}'**
  String gradeSubmittedAt(String when);

  /// Mobile UI text (gradeStudentAnswer)
  ///
  /// In en, this message translates to:
  /// **'Student answer'**
  String get gradeStudentAnswer;

  /// Mobile UI text (gradeNoText)
  ///
  /// In en, this message translates to:
  /// **'(no text)'**
  String get gradeNoText;

  /// Mobile UI text (gradeReloadLatest)
  ///
  /// In en, this message translates to:
  /// **'Reload latest'**
  String get gradeReloadLatest;

  /// Mobile UI text (gradeWaiting)
  ///
  /// In en, this message translates to:
  /// **'Waiting for the student to revise and resubmit.'**
  String get gradeWaiting;

  /// Mobile UI text (gradeYourFeedback)
  ///
  /// In en, this message translates to:
  /// **'Your feedback: {text}'**
  String gradeYourFeedback(String text);

  /// Mobile UI text (gradeAndFeedback)
  ///
  /// In en, this message translates to:
  /// **'Grade and feedback'**
  String get gradeAndFeedback;

  /// Mobile UI text (gradeHint)
  ///
  /// In en, this message translates to:
  /// **'A score records achievement. Feedback shows what to do next.'**
  String get gradeHint;

  /// Mobile UI text (gradeScore)
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gradeScore;

  /// Mobile UI text (gradeScoreRangeLabel)
  ///
  /// In en, this message translates to:
  /// **'Score (0–{max})'**
  String gradeScoreRangeLabel(int max);

  /// Mobile UI text (gradeFeedbackToStudent)
  ///
  /// In en, this message translates to:
  /// **'Feedback to the student'**
  String get gradeFeedbackToStudent;

  /// Mobile UI text (gradeFeedback)
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get gradeFeedback;

  /// Mobile UI text (gradeSaveNew)
  ///
  /// In en, this message translates to:
  /// **'Save new grade'**
  String get gradeSaveNew;

  /// Mobile UI text (gradeSave)
  ///
  /// In en, this message translates to:
  /// **'Save grade'**
  String get gradeSave;

  /// Mobile UI text (gradeReturn)
  ///
  /// In en, this message translates to:
  /// **'Return for revision'**
  String get gradeReturn;

  /// Mobile UI text (gradeHistory)
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get gradeHistory;

  /// Mobile UI text (gradeNoHistory)
  ///
  /// In en, this message translates to:
  /// **'No grading actions yet.'**
  String get gradeNoHistory;

  /// Mobile UI text (errorNoteTooLong)
  ///
  /// In en, this message translates to:
  /// **'Note is too long (500 characters maximum).'**
  String get errorNoteTooLong;

  /// Mobile UI text (errorRecordChanged)
  ///
  /// In en, this message translates to:
  /// **'This record changed elsewhere. The latest values are shown; try again.'**
  String get errorRecordChanged;

  /// Mobile UI text (errorSessionNotFound)
  ///
  /// In en, this message translates to:
  /// **'Session not found.'**
  String get errorSessionNotFound;

  /// Mobile UI text (errorActivityNotFound)
  ///
  /// In en, this message translates to:
  /// **'Activity not found.'**
  String get errorActivityNotFound;

  /// Mobile UI text (errorAssignmentUnavailable)
  ///
  /// In en, this message translates to:
  /// **'This assignment is no longer available.'**
  String get errorAssignmentUnavailable;

  /// Mobile UI text (errorCourseUnavailable)
  ///
  /// In en, this message translates to:
  /// **'This course is no longer available.'**
  String get errorCourseUnavailable;

  /// Mobile UI text (commonLoadMore)
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get commonLoadMore;

  /// Mobile UI text (commonLoadingEllipsis)
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoadingEllipsis;

  /// Mobile UI text (actPolicyTeacherMarked)
  ///
  /// In en, this message translates to:
  /// **'Teacher marked'**
  String get actPolicyTeacherMarked;

  /// Mobile UI text (actPolicySelfReported)
  ///
  /// In en, this message translates to:
  /// **'Self-reported'**
  String get actPolicySelfReported;

  /// Mobile UI text (actPolicyTeacherVerified)
  ///
  /// In en, this message translates to:
  /// **'Teacher verified'**
  String get actPolicyTeacherVerified;

  /// Mobile UI text (actPolicyHintTeacherMarked)
  ///
  /// In en, this message translates to:
  /// **'Your teacher records completion.'**
  String get actPolicyHintTeacherMarked;

  /// Mobile UI text (actPolicyHintSelfReported)
  ///
  /// In en, this message translates to:
  /// **'You mark it done yourself.'**
  String get actPolicyHintSelfReported;

  /// Mobile UI text (actPolicyHintTeacherVerified)
  ///
  /// In en, this message translates to:
  /// **'You submit it and your teacher confirms.'**
  String get actPolicyHintTeacherVerified;

  /// Mobile UI text (actPolicyDetailTeacherMarked)
  ///
  /// In en, this message translates to:
  /// **'You record who completed it. Students only see their status.'**
  String get actPolicyDetailTeacherMarked;

  /// Mobile UI text (actPolicyDetailSelfReported)
  ///
  /// In en, this message translates to:
  /// **'Students mark their own completion before the deadline.'**
  String get actPolicyDetailSelfReported;

  /// Mobile UI text (actPolicyDetailTeacherVerified)
  ///
  /// In en, this message translates to:
  /// **'Students submit; you approve or reject with a reason.'**
  String get actPolicyDetailTeacherVerified;

  /// Mobile UI text (actStateUpcoming)
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get actStateUpcoming;

  /// Mobile UI text (actStateOpen)
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get actStateOpen;

  /// Mobile UI text (actStatePending)
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get actStatePending;

  /// Mobile UI text (actStateCompleted)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actStateCompleted;

  /// Mobile UI text (actStateRejected)
  ///
  /// In en, this message translates to:
  /// **'Needs another try'**
  String get actStateRejected;

  /// Mobile UI text (actStateNotDone)
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get actStateNotDone;

  /// Mobile UI text (actStateMissed)
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get actStateMissed;

  /// Mobile UI text (actStateNotScheduled)
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get actStateNotScheduled;

  /// Mobile UI text (actPaused)
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get actPaused;

  /// Mobile UI text (actEveryDay)
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get actEveryDay;

  /// Mobile UI text (actWeekdays)
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get actWeekdays;

  /// Mobile UI text (actDeadlineAtTime)
  ///
  /// In en, this message translates to:
  /// **'Due {time} ({tz})'**
  String actDeadlineAtTime(String time, String tz);

  /// Mobile UI text (actDeadlineDayEnd)
  ///
  /// In en, this message translates to:
  /// **'Due at the end of the day ({tz})'**
  String actDeadlineDayEnd(String tz);

  /// Mobile UI text (actNoStreak)
  ///
  /// In en, this message translates to:
  /// **'No streak (no deadline)'**
  String get actNoStreak;

  /// Mobile UI text (actStreak)
  ///
  /// In en, this message translates to:
  /// **'{value} streak'**
  String actStreak(String value);

  /// Mobile UI text (actBest)
  ///
  /// In en, this message translates to:
  /// **'Best {value}'**
  String actBest(String value);

  /// Mobile UI text (actDoneOfResolved)
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String actDoneOfResolved(int done, int total);

  /// Mobile UI text (actEditDetails)
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get actEditDetails;

  /// Mobile UI text (actDescription)
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get actDescription;

  /// Mobile UI text (actDueEndOfDay)
  ///
  /// In en, this message translates to:
  /// **'Due end of day'**
  String get actDueEndOfDay;

  /// Mobile UI text (actSubmitForReview)
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get actSubmitForReview;

  /// Mobile UI text (actNoteForTeacher)
  ///
  /// In en, this message translates to:
  /// **'Note for your teacher (optional)'**
  String get actNoteForTeacher;

  /// Mobile UI text (actSubmit)
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actSubmit;

  /// Mobile UI text (actMarkDone)
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get actMarkDone;

  /// Mobile UI text (actWithdraw)
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get actWithdraw;

  /// Mobile UI text (actTeacherAskedRetry)
  ///
  /// In en, this message translates to:
  /// **'Your teacher asked for another try: {reason}'**
  String actTeacherAskedRetry(String reason);

  /// Mobile UI text (actNothingToday)
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled today'**
  String get actNothingToday;

  /// Mobile UI text (actNothingTodayHint)
  ///
  /// In en, this message translates to:
  /// **'Your teacher has not scheduled an activity for today in this course.'**
  String get actNothingTodayHint;

  /// Mobile UI text (actDaily)
  ///
  /// In en, this message translates to:
  /// **'Daily activities'**
  String get actDaily;

  /// Mobile UI text (actDailyOne)
  ///
  /// In en, this message translates to:
  /// **'Daily activity'**
  String get actDailyOne;

  /// Mobile UI text (actTodaySubtitle)
  ///
  /// In en, this message translates to:
  /// **'What to do today in this course.'**
  String get actTodaySubtitle;

  /// Mobile UI text (actWeekView)
  ///
  /// In en, this message translates to:
  /// **'Week view'**
  String get actWeekView;

  /// Mobile UI text (actMyProgress)
  ///
  /// In en, this message translates to:
  /// **'My progress'**
  String get actMyProgress;

  /// Mobile UI text (actWeekOf)
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String actWeekOf(String date);

  /// Mobile UI text (actThisWeek)
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get actThisWeek;

  /// Mobile UI text (actPrevWeek)
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get actPrevWeek;

  /// Mobile UI text (actNextWeek)
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get actNextWeek;

  /// Mobile UI text (actNoWeekTitle)
  ///
  /// In en, this message translates to:
  /// **'No activities this week'**
  String get actNoWeekTitle;

  /// Mobile UI text (actNoWeekHint)
  ///
  /// In en, this message translates to:
  /// **'Nothing is scheduled for these days. Use the arrows to look at another week.'**
  String get actNoWeekHint;

  /// Mobile UI text (actDaysOfWeek)
  ///
  /// In en, this message translates to:
  /// **'Days of the week'**
  String get actDaysOfWeek;

  /// Mobile UI text (actNoEndDate)
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get actNoEndDate;

  /// Mobile UI text (actEnds)
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String actEnds(String date);

  /// Mobile UI text (actClearEnd)
  ///
  /// In en, this message translates to:
  /// **'Clear end date'**
  String get actClearEnd;

  /// Mobile UI text (actDeadline)
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get actDeadline;

  /// Mobile UI text (actDlDayEnd)
  ///
  /// In en, this message translates to:
  /// **'End of each day'**
  String get actDlDayEnd;

  /// Mobile UI text (actDlDayEndHint)
  ///
  /// In en, this message translates to:
  /// **'Default daily cutoff at midnight in the activity timezone.'**
  String get actDlDayEndHint;

  /// Mobile UI text (actDlTime)
  ///
  /// In en, this message translates to:
  /// **'At a set time each day'**
  String get actDlTime;

  /// Mobile UI text (actDlNoneHint)
  ///
  /// In en, this message translates to:
  /// **'Never counts as missed and has no streak.'**
  String get actDlNoneHint;

  /// Mobile UI text (actDueAtPicker)
  ///
  /// In en, this message translates to:
  /// **'Due at {time}'**
  String actDueAtPicker(String time);

  /// Mobile UI text (actTimezone)
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get actTimezone;

  /// Mobile UI text (actStarts)
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get actStarts;

  /// Mobile UI text (actNewActivity)
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get actNewActivity;

  /// Mobile UI text (actReviewN)
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String actReviewN(int count);

  /// Mobile UI text (actReviewQueue)
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get actReviewQueue;

  /// Mobile UI text (actSectionSubtitle)
  ///
  /// In en, this message translates to:
  /// **'Recurring practice with a completion policy and a deadline.'**
  String get actSectionSubtitle;

  /// Mobile UI text (actTodayDone)
  ///
  /// In en, this message translates to:
  /// **'Today {done}/{expected} done'**
  String actTodayDone(int done, int expected);

  /// Mobile UI text (actNotScheduledToday)
  ///
  /// In en, this message translates to:
  /// **'Not scheduled today'**
  String get actNotScheduledToday;

  /// Mobile UI text (actToReview)
  ///
  /// In en, this message translates to:
  /// **'{count} to review'**
  String actToReview(int count);

  /// Mobile UI text (actEmptyTitle)
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get actEmptyTitle;

  /// Mobile UI text (actEmptyHint)
  ///
  /// In en, this message translates to:
  /// **'Create a daily activity such as Reading Practice, then choose how completion is recorded.'**
  String get actEmptyHint;

  /// Mobile UI text (actProblemTitle)
  ///
  /// In en, this message translates to:
  /// **'Give the activity a title.'**
  String get actProblemTitle;

  /// Mobile UI text (actProblemDays)
  ///
  /// In en, this message translates to:
  /// **'Choose at least one day of the week.'**
  String get actProblemDays;

  /// Mobile UI text (actFormDesc)
  ///
  /// In en, this message translates to:
  /// **'Subject-neutral practice your students repeat on the days you choose.'**
  String get actFormDesc;

  /// Mobile UI text (actDetails)
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get actDetails;

  /// Mobile UI text (actDescriptionOptional)
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get actDescriptionOptional;

  /// Mobile UI text (actHowRecorded)
  ///
  /// In en, this message translates to:
  /// **'How is completion recorded?'**
  String get actHowRecorded;

  /// Mobile UI text (actSchedule)
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get actSchedule;

  /// Mobile UI text (actCreate)
  ///
  /// In en, this message translates to:
  /// **'Create activity'**
  String get actCreate;

  /// Mobile UI text (actChangeSchedule)
  ///
  /// In en, this message translates to:
  /// **'Change schedule'**
  String get actChangeSchedule;

  /// Mobile UI text (actChangeDesc)
  ///
  /// In en, this message translates to:
  /// **'The new schedule starts on the date you choose (tomorrow or later). Days before it keep the rules they had, so nobody\'s history changes.'**
  String get actChangeDesc;

  /// Mobile UI text (actNewSchedule)
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get actNewSchedule;

  /// Mobile UI text (actSaveSchedule)
  ///
  /// In en, this message translates to:
  /// **'Save schedule'**
  String get actSaveSchedule;

  /// Mobile UI text (actScheduleFrom)
  ///
  /// In en, this message translates to:
  /// **'Current schedule from {from} (version {version})'**
  String actScheduleFrom(String from, int version);

  /// Mobile UI text (actScheduleFromTo)
  ///
  /// In en, this message translates to:
  /// **'Current schedule from {from} to {to} (version {version})'**
  String actScheduleFromTo(String from, String to, int version);

  /// Mobile UI text (actPause)
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actPause;

  /// Mobile UI text (actResume)
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actResume;

  /// Mobile UI text (actArchive)
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actArchive;

  /// Mobile UI text (actConfirmPause)
  ///
  /// In en, this message translates to:
  /// **'Pause this activity from tomorrow? Past days keep their records.'**
  String get actConfirmPause;

  /// Mobile UI text (actConfirmArchive)
  ///
  /// In en, this message translates to:
  /// **'Archive this activity? It is hidden from students; history is kept.'**
  String get actConfirmArchive;

  /// Mobile UI text (actConfirmResume)
  ///
  /// In en, this message translates to:
  /// **'Resume this activity from tomorrow?'**
  String get actConfirmResume;

  /// Mobile UI text (actWeeklyRegister)
  ///
  /// In en, this message translates to:
  /// **'Weekly register'**
  String get actWeeklyRegister;

  /// Mobile UI text (actRegisterSubtitle)
  ///
  /// In en, this message translates to:
  /// **'Week of {date}. Tap a cell to record or review.'**
  String actRegisterSubtitle(String date);

  /// Mobile UI text (actCouldNotRefreshWeek)
  ///
  /// In en, this message translates to:
  /// **'Could not refresh: {error} Showing the last loaded week.'**
  String actCouldNotRefreshWeek(String error);

  /// Mobile UI text (actNoStudentsTitle)
  ///
  /// In en, this message translates to:
  /// **'No students enrolled yet'**
  String get actNoStudentsTitle;

  /// Mobile UI text (actNoStudentsHint)
  ///
  /// In en, this message translates to:
  /// **'Students appear here once they join the course.'**
  String get actNoStudentsHint;

  /// Mobile UI text (actNotScheduledWeek)
  ///
  /// In en, this message translates to:
  /// **'Not scheduled this week'**
  String get actNotScheduledWeek;

  /// Mobile UI text (actNotScheduledWeekHint)
  ///
  /// In en, this message translates to:
  /// **'This activity has no scheduled day in this week. Use the arrows to look at another week.'**
  String get actNotScheduledWeekHint;

  /// Mobile UI text (actCellSemantics)
  ///
  /// In en, this message translates to:
  /// **'{name}, {date}: {state}'**
  String actCellSemantics(String name, String date, String state);

  /// Mobile UI text (actStudentNote)
  ///
  /// In en, this message translates to:
  /// **'Student note: {note}'**
  String actStudentNote(String note);

  /// Mobile UI text (actReasonGiven)
  ///
  /// In en, this message translates to:
  /// **'Reason given: {reason}'**
  String actReasonGiven(String reason);

  /// Mobile UI text (actArchivedReadOnly)
  ///
  /// In en, this message translates to:
  /// **'This course is archived, so records are read-only.'**
  String get actArchivedReadOnly;

  /// Mobile UI text (actReasonRequired)
  ///
  /// In en, this message translates to:
  /// **'Reason for the student (required)'**
  String get actReasonRequired;

  /// Mobile UI text (actApprove)
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get actApprove;

  /// Mobile UI text (actReject)
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actReject;

  /// Mobile UI text (actSendRejection)
  ///
  /// In en, this message translates to:
  /// **'Send rejection'**
  String get actSendRejection;

  /// Mobile UI text (actFutureDays)
  ///
  /// In en, this message translates to:
  /// **'Future days cannot be marked yet.'**
  String get actFutureDays;

  /// Mobile UI text (actMarkCompleted)
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get actMarkCompleted;

  /// Mobile UI text (actMarkNotDone)
  ///
  /// In en, this message translates to:
  /// **'Mark not done'**
  String get actMarkNotDone;

  /// Mobile UI text (actVerificationQueue)
  ///
  /// In en, this message translates to:
  /// **'Verification queue'**
  String get actVerificationQueue;

  /// Mobile UI text (actWaitingDecision)
  ///
  /// In en, this message translates to:
  /// **'{count} waiting for your decision.'**
  String actWaitingDecision(int count);

  /// Mobile UI text (actWaitingReview)
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get actWaitingReview;

  /// Mobile UI text (actNothingToReview)
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get actNothingToReview;

  /// Mobile UI text (actNothingToReviewHint)
  ///
  /// In en, this message translates to:
  /// **'Submissions from students appear here for approval or rejection.'**
  String get actNothingToReviewHint;

  /// Mobile UI text (actSubmittedAt)
  ///
  /// In en, this message translates to:
  /// **'submitted {when}'**
  String actSubmittedAt(String when);

  /// Mobile UI text (actNoteLine)
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String actNoteLine(String note);

  /// Mobile UI text (actRejectTitle)
  ///
  /// In en, this message translates to:
  /// **'Reject submission'**
  String get actRejectTitle;

  /// Mobile UI text (atdRateNone)
  ///
  /// In en, this message translates to:
  /// **'No rate yet'**
  String get atdRateNone;

  /// Mobile UI text (atdNewSession)
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get atdNewSession;

  /// Mobile UI text (atdWeeklyGrid)
  ///
  /// In en, this message translates to:
  /// **'Weekly grid'**
  String get atdWeeklyGrid;

  /// Mobile UI text (atdSummary)
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get atdSummary;

  /// Mobile UI text (atdNoSessions)
  ///
  /// In en, this message translates to:
  /// **'No attendance sessions yet'**
  String get atdNoSessions;

  /// Mobile UI text (atdNoSessionsHint)
  ///
  /// In en, this message translates to:
  /// **'Create one for each class meeting.'**
  String get atdNoSessionsHint;

  /// Mobile UI text (atdNewDialogTitle)
  ///
  /// In en, this message translates to:
  /// **'New attendance session'**
  String get atdNewDialogTitle;

  /// Mobile UI text (atdDate)
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get atdDate;

  /// Mobile UI text (atdTime)
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get atdTime;

  /// Mobile UI text (atdNoteFor)
  ///
  /// In en, this message translates to:
  /// **'Note for {name}'**
  String atdNoteFor(String name);

  /// Mobile UI text (atdNote)
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get atdNote;

  /// Mobile UI text (atdSaveNote)
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get atdSaveNote;

  /// Mobile UI text (atdCloseTitle)
  ///
  /// In en, this message translates to:
  /// **'Close this session?'**
  String get atdCloseTitle;

  /// Mobile UI text (atdCloseAllMarked)
  ///
  /// In en, this message translates to:
  /// **'Every student is marked. You can still correct records later.'**
  String get atdCloseAllMarked;

  /// Mobile UI text (atdCloseUnmarked)
  ///
  /// In en, this message translates to:
  /// **'{count} unmarked student(s) will be recorded as Absent. You can still correct records later.'**
  String atdCloseUnmarked(int count);

  /// Mobile UI text (atdCloseSession)
  ///
  /// In en, this message translates to:
  /// **'Close session'**
  String get atdCloseSession;

  /// Mobile UI text (atdEventClosed)
  ///
  /// In en, this message translates to:
  /// **'Session closed · {when}'**
  String atdEventClosed(String when);

  /// Mobile UI text (atdEventCorrected)
  ///
  /// In en, this message translates to:
  /// **'{who}: {from} → {to} · {when}'**
  String atdEventCorrected(String who, String from, String to, String when);

  /// Mobile UI text (atdEventMarked)
  ///
  /// In en, this message translates to:
  /// **'{who}: {status} · {when}'**
  String atdEventMarked(String who, String status, String when);

  /// Mobile UI text (atdEyebrowSession)
  ///
  /// In en, this message translates to:
  /// **'Attendance / Session'**
  String get atdEyebrowSession;

  /// Mobile UI text (atdClassRegister)
  ///
  /// In en, this message translates to:
  /// **'Class register'**
  String get atdClassRegister;

  /// Mobile UI text (atdRegisterHint)
  ///
  /// In en, this message translates to:
  /// **'Choose a status for each student. Changes save immediately.'**
  String get atdRegisterHint;

  /// Mobile UI text (atdArchivedReadOnly)
  ///
  /// In en, this message translates to:
  /// **'This course is archived. Attendance is read-only.'**
  String get atdArchivedReadOnly;

  /// Mobile UI text (atdNoStudents)
  ///
  /// In en, this message translates to:
  /// **'No students are enrolled yet.'**
  String get atdNoStudents;

  /// Mobile UI text (atdCloseSessionN)
  ///
  /// In en, this message translates to:
  /// **'Close session ({count} unmarked)'**
  String atdCloseSessionN(int count);

  /// Mobile UI text (atdSessionClosedNote)
  ///
  /// In en, this message translates to:
  /// **'Session closed. Existing records can still be corrected.'**
  String get atdSessionClosedNote;

  /// Mobile UI text (atdNoChanges)
  ///
  /// In en, this message translates to:
  /// **'No changes yet.'**
  String get atdNoChanges;

  /// Mobile UI text (atdEditNoteFor)
  ///
  /// In en, this message translates to:
  /// **'Edit note for {name}'**
  String atdEditNoteFor(String name);

  /// Mobile UI text (atdNotMarkedYet)
  ///
  /// In en, this message translates to:
  /// **'Not marked yet'**
  String get atdNotMarkedYet;

  /// Mobile UI text (atdEyebrowTeaching)
  ///
  /// In en, this message translates to:
  /// **'Teaching / Attendance'**
  String get atdEyebrowTeaching;

  /// Mobile UI text (atdEyebrowLearning)
  ///
  /// In en, this message translates to:
  /// **'Learning / Attendance'**
  String get atdEyebrowLearning;

  /// Mobile UI text (atdSummaryTitle)
  ///
  /// In en, this message translates to:
  /// **'Attendance summary'**
  String get atdSummaryTitle;

  /// Mobile UI text (atdSummaryDesc)
  ///
  /// In en, this message translates to:
  /// **'A clear record of participation across class sessions.'**
  String get atdSummaryDesc;

  /// Mobile UI text (atdClosedOfTotal)
  ///
  /// In en, this message translates to:
  /// **'{closed} closed of {total} session(s)'**
  String atdClosedOfTotal(int closed, int total);

  /// Mobile UI text (atdRateNote)
  ///
  /// In en, this message translates to:
  /// **'Rate = (Present + Late) ÷ (Present + Late + Absent). Excused is not counted.'**
  String get atdRateNote;

  /// Mobile UI text (atdSummaryEmptyHint)
  ///
  /// In en, this message translates to:
  /// **'Attendance rates appear once students join the course.'**
  String get atdSummaryEmptyHint;

  /// Mobile UI text (atdMyAttendance)
  ///
  /// In en, this message translates to:
  /// **'My attendance'**
  String get atdMyAttendance;

  /// Mobile UI text (atdWeeklyView)
  ///
  /// In en, this message translates to:
  /// **'Weekly view'**
  String get atdWeeklyView;

  /// Mobile UI text (atdNoRecords)
  ///
  /// In en, this message translates to:
  /// **'No attendance recorded yet'**
  String get atdNoRecords;

  /// Mobile UI text (atdNoRecordsHint)
  ///
  /// In en, this message translates to:
  /// **'Your attendance will show here once a class is marked.'**
  String get atdNoRecordsHint;

  /// Mobile UI text (atdRateTitle)
  ///
  /// In en, this message translates to:
  /// **'Attendance rate: {rate}'**
  String atdRateTitle(String rate);

  /// Mobile UI text (atdWeeklyAttendance)
  ///
  /// In en, this message translates to:
  /// **'Weekly attendance'**
  String get atdWeeklyAttendance;

  /// Mobile UI text (atdMyWeek)
  ///
  /// In en, this message translates to:
  /// **'My week'**
  String get atdMyWeek;

  /// Mobile UI text (atdGridDesc)
  ///
  /// In en, this message translates to:
  /// **'Names stay in view. Swipe the days to explore each session.'**
  String get atdGridDesc;

  /// Mobile UI text (atdGlyphPresent)
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get atdGlyphPresent;

  /// Mobile UI text (atdGlyphLate)
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get atdGlyphLate;

  /// Mobile UI text (atdGlyphExcused)
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get atdGlyphExcused;

  /// Mobile UI text (atdGlyphAbsent)
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get atdGlyphAbsent;

  /// Mobile UI text (atdNotMarked)
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get atdNotMarked;

  /// Mobile UI text (atdNoSession)
  ///
  /// In en, this message translates to:
  /// **'· No session'**
  String get atdNoSession;

  /// Mobile UI text (atdTwoSessions)
  ///
  /// In en, this message translates to:
  /// **'×2 = two sessions that day, in time order'**
  String get atdTwoSessions;

  /// Mobile UI text (atdCellNoSession)
  ///
  /// In en, this message translates to:
  /// **'{who}, {date}: no session'**
  String atdCellNoSession(String who, String date);

  /// Mobile UI text (atdMe)
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get atdMe;

  /// Mobile UI text (atdStatusGuide)
  ///
  /// In en, this message translates to:
  /// **'Status guide'**
  String get atdStatusGuide;

  /// Mobile UI text (atdGridNoSessions)
  ///
  /// In en, this message translates to:
  /// **'No attendance sessions this week'**
  String get atdGridNoSessions;

  /// Mobile UI text (atdGridNoSessionsHint)
  ///
  /// In en, this message translates to:
  /// **'Use the arrows to look at another week.'**
  String get atdGridNoSessionsHint;

  /// Mobile UI text (atdGridNoStudentsHint)
  ///
  /// In en, this message translates to:
  /// **'The weekly table appears once students join the course.'**
  String get atdGridNoStudentsHint;

  /// Mobile UI text (atdAllMarked)
  ///
  /// In en, this message translates to:
  /// **'All marked'**
  String get atdAllMarked;

  /// Mobile UI text (atdUnmarkedCount)
  ///
  /// In en, this message translates to:
  /// **'{count} unmarked'**
  String atdUnmarkedCount(int count);

  /// Mobile UI text (progEyebrowTeacher)
  ///
  /// In en, this message translates to:
  /// **'Student progress'**
  String get progEyebrowTeacher;

  /// Mobile UI text (progEnrolledSince)
  ///
  /// In en, this message translates to:
  /// **'Enrolled since {date}'**
  String progEnrolledSince(String date);

  /// Mobile UI text (progPrivateTeacher)
  ///
  /// In en, this message translates to:
  /// **'Private to you and this student. Not shared with the class.'**
  String get progPrivateTeacher;

  /// Mobile UI text (progPrivateStudent)
  ///
  /// In en, this message translates to:
  /// **'Only you and your teacher can see this.'**
  String get progPrivateStudent;

  /// Mobile UI text (progArchived)
  ///
  /// In en, this message translates to:
  /// **'This course is archived (read-only).'**
  String get progArchived;

  /// Mobile UI text (progCouldNotRefresh)
  ///
  /// In en, this message translates to:
  /// **'Could not refresh: {error} Showing the last loaded figures.'**
  String progCouldNotRefresh(String error);

  /// Mobile UI text (progAssignmentsNone)
  ///
  /// In en, this message translates to:
  /// **'No assignment has been published yet.'**
  String get progAssignmentsNone;

  /// Mobile UI text (progAssignmentsSummary)
  ///
  /// In en, this message translates to:
  /// **'{done} of {published} published assignments submitted or graded.'**
  String progAssignmentsSummary(int done, int published);

  /// Mobile UI text (progNoPublishedTitle)
  ///
  /// In en, this message translates to:
  /// **'No published assignments'**
  String get progNoPublishedTitle;

  /// Mobile UI text (progNoPublishedHint)
  ///
  /// In en, this message translates to:
  /// **'Progress appears here once the teacher publishes work.'**
  String get progNoPublishedHint;

  /// Mobile UI text (progOfCount)
  ///
  /// In en, this message translates to:
  /// **'{a} of {b}'**
  String progOfCount(int a, int b);

  /// Mobile UI text (progOverdueHint)
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String progOverdueHint(int count);

  /// Mobile UI text (progAwaitingGrading)
  ///
  /// In en, this message translates to:
  /// **'Awaiting grading'**
  String get progAwaitingGrading;

  /// Mobile UI text (progScore)
  ///
  /// In en, this message translates to:
  /// **'Score {score}/{max}'**
  String progScore(int score, int max);

  /// Mobile UI text (progTruncated)
  ///
  /// In en, this message translates to:
  /// **'Showing the latest {shown} of {total} assignments. The counts above cover all of them.'**
  String progTruncated(int shown, int total);

  /// Mobile UI text (progActivitiesSubtitle)
  ///
  /// In en, this message translates to:
  /// **'Streaks count scheduled days only (last 62 days). Pending review is not counted until approved.'**
  String get progActivitiesSubtitle;

  /// Mobile UI text (progAwaitingVerification)
  ///
  /// In en, this message translates to:
  /// **'{count} awaiting verification'**
  String progAwaitingVerification(int count);

  /// Mobile UI text (progNoActivitiesHint)
  ///
  /// In en, this message translates to:
  /// **'No daily activity has been set up for this course.'**
  String get progNoActivitiesHint;

  /// Mobile UI text (progNoClosedDay)
  ///
  /// In en, this message translates to:
  /// **'No scheduled day has closed yet.'**
  String get progNoClosedDay;

  /// Mobile UI text (progAttNone)
  ///
  /// In en, this message translates to:
  /// **'No attendance session has been created.'**
  String get progAttNone;

  /// Mobile UI text (progAttSummary)
  ///
  /// In en, this message translates to:
  /// **'{total} sessions, {closed} closed.'**
  String progAttSummary(int total, int closed);

  /// Mobile UI text (progNoSessionsTitle)
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get progNoSessionsTitle;

  /// Mobile UI text (progNoSessionsHint)
  ///
  /// In en, this message translates to:
  /// **'Attendance appears once the teacher creates a session.'**
  String get progNoSessionsHint;

  /// Mobile UI text (progRateNone)
  ///
  /// In en, this message translates to:
  /// **'Attendance rate: no data yet (nothing countable)'**
  String get progRateNone;

  /// Mobile UI text (progRate)
  ///
  /// In en, this message translates to:
  /// **'Attendance rate: {rate} ({present} of {counted} counted sessions)'**
  String progRate(String rate, int present, int counted);

  /// Mobile UI text (progNotMarkedCount)
  ///
  /// In en, this message translates to:
  /// **'Not marked: {count}'**
  String progNotMarkedCount(int count);

  /// Mobile UI text (progRecentSessions)
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get progRecentSessions;

  /// Mobile UI text (taskModeMonth)
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get taskModeMonth;

  /// Mobile UI text (taskModeCompleted)
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskModeCompleted;

  /// Mobile UI text (taskOverdue)
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskOverdue;

  /// Mobile UI text (taskNeedsRevision)
  ///
  /// In en, this message translates to:
  /// **'Needs revision'**
  String get taskNeedsRevision;

  /// Mobile UI text (taskGraded)
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get taskGraded;

  /// Mobile UI text (taskHeld)
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get taskHeld;

  /// Mobile UI text (taskScheduled)
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get taskScheduled;

  /// Mobile UI text (taskHeaderTitle)
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get taskHeaderTitle;

  /// Mobile UI text (taskHeaderDesc)
  ///
  /// In en, this message translates to:
  /// **'Assignments and daily activities from all your courses, with one status each.'**
  String get taskHeaderDesc;

  /// Mobile UI text (taskEmptyTodayTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get taskEmptyTodayTitle;

  /// Mobile UI text (taskEmptyTodayHint)
  ///
  /// In en, this message translates to:
  /// **'Enjoy it, or look at the week ahead.'**
  String get taskEmptyTodayHint;

  /// Mobile UI text (taskEmptyWeekTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing this week'**
  String get taskEmptyWeekTitle;

  /// Mobile UI text (taskEmptyWeekHint)
  ///
  /// In en, this message translates to:
  /// **'No assignment deadline or activity falls in this week.'**
  String get taskEmptyWeekHint;

  /// Mobile UI text (taskEmptyMonthTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing this month'**
  String get taskEmptyMonthTitle;

  /// Mobile UI text (taskEmptyDayTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get taskEmptyDayTitle;

  /// Mobile UI text (taskEmptyMonthHint)
  ///
  /// In en, this message translates to:
  /// **'No assignment deadline or activity falls here.'**
  String get taskEmptyMonthHint;

  /// Mobile UI text (taskEmptyUpcomingTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing coming up'**
  String get taskEmptyUpcomingTitle;

  /// Mobile UI text (taskEmptyUpcomingHint)
  ///
  /// In en, this message translates to:
  /// **'New work from your teachers will appear here.'**
  String get taskEmptyUpcomingHint;

  /// Mobile UI text (taskEmptyOverdueTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing overdue'**
  String get taskEmptyOverdueTitle;

  /// Mobile UI text (taskEmptyOverdueHint)
  ///
  /// In en, this message translates to:
  /// **'You are up to date.'**
  String get taskEmptyOverdueHint;

  /// Mobile UI text (taskEmptyCompletedTitle)
  ///
  /// In en, this message translates to:
  /// **'Nothing completed yet'**
  String get taskEmptyCompletedTitle;

  /// Mobile UI text (taskEmptyCompletedHint)
  ///
  /// In en, this message translates to:
  /// **'Finished work appears here.'**
  String get taskEmptyCompletedHint;

  /// Mobile UI text (taskCalendarEyebrow)
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get taskCalendarEyebrow;

  /// Mobile UI text (taskCalendarTitle)
  ///
  /// In en, this message translates to:
  /// **'Teaching calendar'**
  String get taskCalendarTitle;

  /// Mobile UI text (taskCalendarDesc)
  ///
  /// In en, this message translates to:
  /// **'Assignment deadlines, daily activities and attendance sessions across your courses.'**
  String get taskCalendarDesc;

  /// Mobile UI text (taskNoPending)
  ///
  /// In en, this message translates to:
  /// **'No activity submissions waiting for review.'**
  String get taskNoPending;

  /// Mobile UI text (taskPending)
  ///
  /// In en, this message translates to:
  /// **'{count} activity submissions waiting for review.'**
  String taskPending(int count);

  /// Mobile UI text (taskCouldNotRefreshTasks)
  ///
  /// In en, this message translates to:
  /// **'Could not refresh: {error} Showing the last loaded tasks.'**
  String taskCouldNotRefreshTasks(String error);

  /// Mobile UI text (taskCouldNotRefreshCalendar)
  ///
  /// In en, this message translates to:
  /// **'Could not refresh: {error} Showing the last loaded calendar.'**
  String taskCouldNotRefreshCalendar(String error);

  /// Mobile UI text (taskNothingScheduled)
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get taskNothingScheduled;

  /// Mobile UI text (taskNothingScheduledHint)
  ///
  /// In en, this message translates to:
  /// **'No deadline, activity or attendance session falls here.'**
  String get taskNothingScheduledHint;

  /// Mobile UI text (taskPrevious)
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get taskPrevious;

  /// Mobile UI text (taskNext)
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get taskNext;

  /// Mobile UI text (taskDayItems)
  ///
  /// In en, this message translates to:
  /// **'{day} {month}, {count, plural, =0{no items} =1{1 item} other{{count} items}}'**
  String taskDayItems(int day, String month, int count);

  /// Mobile UI text (taskUndated)
  ///
  /// In en, this message translates to:
  /// **'Undated'**
  String get taskUndated;

  /// Mobile UI text (taskDueSubmitted)
  ///
  /// In en, this message translates to:
  /// **'Due {when} · {received} of {expected} submitted'**
  String taskDueSubmitted(String when, int received, int expected);

  /// Mobile UI text (taskDoneOf)
  ///
  /// In en, this message translates to:
  /// **'{received} of {expected} done'**
  String taskDoneOf(int received, int expected);

  /// Mobile UI text (taskAttendanceSession)
  ///
  /// In en, this message translates to:
  /// **'Attendance session {when} · {state}'**
  String taskAttendanceSession(String when, String state);

  /// Mobile UI text (taskClassSession)
  ///
  /// In en, this message translates to:
  /// **'Class session {when}'**
  String taskClassSession(String when);

  /// Mobile UI text (taskNothingDueToday)
  ///
  /// In en, this message translates to:
  /// **'Nothing is due today.'**
  String get taskNothingDueToday;

  /// Mobile UI text (taskTodoDone)
  ///
  /// In en, this message translates to:
  /// **'{todo} to do · {rest} done or waiting'**
  String taskTodoDone(int todo, int rest);

  /// Mobile UI text (taskAllTasks)
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get taskAllTasks;

  /// Mobile UI text (taskAllClear)
  ///
  /// In en, this message translates to:
  /// **'All clear today'**
  String get taskAllClear;

  /// Mobile UI text (taskAllClearHint)
  ///
  /// In en, this message translates to:
  /// **'No assignment deadline or activity is scheduled for today.'**
  String get taskAllClearHint;

  /// Mobile UI text (taskMoreInTasks)
  ///
  /// In en, this message translates to:
  /// **'{count} more in Tasks'**
  String taskMoreInTasks(int count);

  /// Open pending activity reviews
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String taskReview(int count);

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Bangkok (UTC+7)'**
  String get actTzBangkok;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Singapore (UTC+8)'**
  String get actTzSingapore;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Tokyo (UTC+9)'**
  String get actTzTokyo;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'India (UTC+5:30)'**
  String get actTzIndia;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Dubai (UTC+4)'**
  String get actTzDubai;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'London'**
  String get actTzLondon;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Paris / Berlin'**
  String get actTzParisBerlin;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'New York'**
  String get actTzNewYork;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Chicago'**
  String get actTzChicago;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Los Angeles'**
  String get actTzLosAngeles;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Sydney'**
  String get actTzSydney;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Auckland'**
  String get actTzAuckland;

  /// Schedule time zone display name; IANA wire value is unchanged
  ///
  /// In en, this message translates to:
  /// **'Coordinated Universal Time (UTC)'**
  String get actTzUtc;

  /// Native signed-out welcome screen: welcomeTitle
  ///
  /// In en, this message translates to:
  /// **'Your learning day, all in one place.'**
  String get welcomeTitle;

  /// Native signed-out welcome screen: welcomeDescription
  ///
  /// In en, this message translates to:
  /// **'Bring your courses, tasks and learning progress together. Sign in to continue.'**
  String get welcomeDescription;

  /// Native signed-out welcome screen: welcomeFeatures
  ///
  /// In en, this message translates to:
  /// **'Made for everyday learning'**
  String get welcomeFeatures;

  /// Native signed-out welcome screen: welcomeProgress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get welcomeProgress;

  /// Native signed-out welcome screen: welcomeBack
  ///
  /// In en, this message translates to:
  /// **'Back to welcome'**
  String get welcomeBack;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoTitle;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'JPEG or WebP. It is cropped to a square and shrunk to about 256 px. Only you and your course teachers can see it.'**
  String get profilePhotoHint;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profilePhotoAdd;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profilePhotoChange;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get profilePhotoSaved;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get profilePhotoRemoved;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Crop your photo'**
  String get profilePhotoCropTitle;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Drag and pinch the picture to choose what shows in the circle.'**
  String get profilePhotoCropHint;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Save photo'**
  String get profilePhotoSave;

  /// Screen-reader label for a profile photo
  ///
  /// In en, this message translates to:
  /// **'Profile photo of {name}'**
  String profilePhotoSemantics(String name);

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG or WebP picture.'**
  String get errorAvatarType;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'That picture is too large (10 MB maximum).'**
  String get errorAvatarInputTooLarge;

  /// Profile photo (Stage 1 avatars)
  ///
  /// In en, this message translates to:
  /// **'That picture could not be read. Try another one.'**
  String get errorAvatarDecode;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Scan attendance code'**
  String get scanTitle;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get scanButton;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the classroom QR code, or type the code shown under it.'**
  String get scanHint;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Camera preview for scanning the attendance QR code'**
  String get scanCameraLabel;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Attendance code'**
  String get scanManualLabel;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Submit code'**
  String get scanSubmit;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Scan another code'**
  String get scanAgain;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Allow it in Settings, or type the code below.'**
  String get scanCameraDenied;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'This device has no usable camera. Type the code below.'**
  String get scanNoCamera;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'The camera could not start (it may be in use). Type the code below, or try again.'**
  String get scanCameraBusy;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Checked in as {status} at {time}.'**
  String scanOk(String status, String time);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Checked out at {time}.'**
  String scanOutOk(String time);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'You were already recorded as {status}.'**
  String scanAlready(String status);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'You were already checked out.'**
  String get scanOutAlready;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'That code is not valid.'**
  String get scanReasonInvalid;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask for the current code.'**
  String get scanReasonExpired;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'This session is closed.'**
  String get scanReasonClosed;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'You are not an active member of this course.'**
  String get scanReasonNotMember;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Check-in is not open yet.'**
  String get scanReasonTooEarly;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'The check-in window has ended.'**
  String get scanReasonTooLate;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Check in before checking out.'**
  String get scanReasonNoCheckin;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'In {time}'**
  String atdTimeIn(String time);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Out {time}'**
  String atdTimeOut(String time);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get atdViaQr;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Staff attendance'**
  String get staffTitle;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Clock in and out, see your history and ask for leave or a correction.'**
  String get staffSubtitle;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get staffToday;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Clocked in since {time}'**
  String staffStatusIn(String time);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'You are not clocked in.'**
  String get staffStatusOut;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Late by {minutes} min'**
  String staffStatusLate(String minutes);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get staffClockIn;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get staffClockOut;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Clocked in'**
  String get staffClockedIn;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Clocked out'**
  String get staffClockedOut;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Times come from the server clock, not from your device.'**
  String get staffServerTime;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Working schedule'**
  String get staffSchedule;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'No schedule is set for you. You can still clock in; the day is recorded as unscheduled.'**
  String get staffNoSchedule;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'{days} · {start}–{end} ({zone}), {grace} min grace'**
  String staffScheduleLine(
    String days,
    String start,
    String end,
    String zone,
    String grace,
  );

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get staffD1;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get staffD2;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get staffD3;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get staffD4;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get staffD5;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get staffD6;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get staffD7;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Last 14 days'**
  String get staffHistory;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'No records in this period.'**
  String get staffNoRows;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Hours worked: {hours}'**
  String staffWorked(String hours);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get staffOnTime;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get staffLate;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Missing check-out'**
  String get staffMissingCheckout;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get staffInProgress;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get staffAbsent;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get staffLeave;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Unscheduled'**
  String get staffUnscheduled;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get staffUpcoming;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get staffRequests;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Request leave'**
  String get staffNewLeave;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Request a correction'**
  String get staffNewCorrection;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get staffKindLeave;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get staffKindCorrection;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get staffFromDate;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get staffToDate;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Day to correct'**
  String get staffCorrectDate;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Reason (3 to 500 characters)'**
  String get staffReason;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Correct clock-in time (optional)'**
  String get staffCorrectIn;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Correct clock-out time (optional)'**
  String get staffCorrectOut;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get staffPickTime;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get staffSubmit;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get staffSubmitted;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get staffNoRequests;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get staffCancelRequest;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get staffCancelled;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get staffStPending;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get staffStApproved;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get staffStRejected;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get staffStCancelled;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Decision note: {note}'**
  String staffDecisionNote(String note);

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'A supervisor decides your requests. You cannot approve your own.'**
  String get staffSelfNote;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'No supervisor is assigned to you yet, so requests wait until an administrator assigns one.'**
  String get staffNoSupervisor;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Give a reason of at least 3 characters.'**
  String get staffNeedReason;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Choose valid dates.'**
  String get staffFixDates;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Give the correct clock-in or clock-out time.'**
  String get staffNeedTime;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Supervisor tools'**
  String get staffManager;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Team summary'**
  String get staffTeam;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'You do not supervise anyone.'**
  String get staffNoTeam;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Requests to decide'**
  String get staffToDecide;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Nothing to decide.'**
  String get staffNoneToDecide;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get staffApprove;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get staffReject;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get staffNoteOptional;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'Decision saved'**
  String get staffDecided;

  /// Attendance Option E (QR scan and staff attendance)
  ///
  /// In en, this message translates to:
  /// **'{name}: on time {onTime}, late {late}, missing check-out {missing}, absent {absent}'**
  String staffTeamLine(
    String name,
    String onTime,
    String late,
    String missing,
    String absent,
  );

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Try LearnPulse Demo'**
  String get demoTry;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get demoSelectorTitle;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Explore LearnPulse with no personal email and no password to type.'**
  String get demoSelectorSub;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Student Demo'**
  String get demoStudent;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Join a live workshop with a name and a join code. You get a temporary student account.'**
  String get demoStudentText;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Presenter Demo'**
  String get demoPresenter;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'For the presenter: start the workshop, show the QR code and manage the session.'**
  String get demoPresenterText;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Regular sign in'**
  String get demoRegularSignIn;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Sign in once. This device stays signed in, so you will not need to type your details again.'**
  String get demoPresenterSignInSub;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Presenter controls need a Teacher account.'**
  String get demoPresenterNeedsTeacher;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Join the live workshop'**
  String get demoJoinTitle;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Enter your name and the workshop code. It is deleted after the event.'**
  String get demoJoinSub;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Workshop code'**
  String get demoCodeLabel;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Shown on the presenter screen. It changes every minute.'**
  String get demoCodeHint;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get demoNameLabel;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Shown to the presenter. Up to 40 characters.'**
  String get demoNameHint;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Join Demo'**
  String get demoJoinButton;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Getting your seat…'**
  String get demoJoining;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get demoSigningIn;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Many people are joining at once. Trying again in a moment…'**
  String get demoWaiting;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get demoScan;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code on the presenter screen.'**
  String get demoScanHint;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'The camera is not available. Type the code instead.'**
  String get demoCameraProblem;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Enter the 12-character workshop code.'**
  String get demoMsgBadCode;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Use 1–40 characters without < or >.'**
  String get demoMsgBadName;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'This code is not valid, has expired, or the demo has not started yet. Check the presenter\'s screen.'**
  String get demoMsgInvalid;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Joining is closed for this workshop.'**
  String get demoMsgClosed;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'All seats are taken.'**
  String get demoMsgFull;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get demoMsgBusy;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'You are already signed in. Sign out first.'**
  String get demoMsgSignedIn;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'This device already joined. Credentials are shown only once.'**
  String get demoMsgAlready;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Your seat is reserved, but sign-in did not finish. Press Join again to get the same seat.'**
  String get demoMsgAuthFailed;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Sign-in is very busy right now. Press Join again in a few seconds.'**
  String get demoMsgRateBusy;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'This workshop session has ended.'**
  String get demoMsgExpired;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get demoMsgNetwork;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get demoMsgFailed;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Live demo host'**
  String get demoHostTitle;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'No live demo found for this account.'**
  String get demoHostNone;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Live demo'**
  String get demoHostTooltip;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Ready to start'**
  String get demoStatusReady;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get demoStatusOpen;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get demoStatusPaused;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Joining closed'**
  String get demoStatusClosed;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get demoStatusEnded;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'The prepared workshop is ready. Starting it opens joining for {join} minutes and ends the session {life} hours later. This cannot be paused or undone.'**
  String demoReadyText(int join, String life);

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Start Demo'**
  String get demoStart;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Start the live demo now? Joining stays open for {join} minutes and the session ends {life} hours after you start.'**
  String demoStartConfirm(int join, String life);

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'End Demo'**
  String get demoEnd;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'End the demo? Everyone loses access to the workshop immediately.'**
  String get demoEndConfirm;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Pause joining'**
  String get demoPause;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Resume joining'**
  String get demoResume;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Close joining'**
  String get demoCloseJoins;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Joining closes in {time}'**
  String demoJoinsLeft(String time);

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Session ends in {time}'**
  String demoLifeLeft(String time);

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'The joining window has ended.'**
  String get demoJoinWindowOver;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get demoCopyCode;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get demoCopyLink;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get demoCopied;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Show this QR code on the projector. Attendees scan it with the phone camera.'**
  String get demoProjectHint;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'New code in {seconds}s'**
  String demoCodeExpires(int seconds);

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Total seats'**
  String get demoSeatsTotal;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get demoSeatsAvailable;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get demoSeatsClaimed;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get demoSeatsActive;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Last 10 minutes: {claims} joined, {refused} refused'**
  String demoRecent(int claims, int refused);

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'This demo session has ended.'**
  String get demoEndedNotice;

  /// Unified demo experience
  ///
  /// In en, this message translates to:
  /// **'Open the workshop'**
  String get demoOpenWorkshop;

  /// Back button inside the demo screens
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get demoBack;
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
      <String>['en', 'ms', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
