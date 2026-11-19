// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonBack => 'Go back';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonTryingAgain => 'Trying again…';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonStillWorking =>
      'Still working… this is taking longer than usual.';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonSignInAgain => 'Sign in again';

  @override
  String get commonNoDataYet => 'No data yet';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get configErrorTitle => 'Configuration error';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navCourses => 'Courses';

  @override
  String get navProfile => 'Profile';

  @override
  String get navOpenProfile => 'Open profile';

  @override
  String get homeNameFallback => 'there';

  @override
  String get relativeToday => 'Today';

  @override
  String get relativeTomorrow => 'Tomorrow';

  @override
  String get relativeYesterday => 'Yesterday';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleStudent => 'Student';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageHint =>
      'Saved on this device only. The language never changes deadlines, schedules or time zones.';

  @override
  String get languageSelectorLabel => 'Choose language';

  @override
  String get authPortalEyebrow => 'LEARNPULSE ACADEMIC PORTAL';

  @override
  String get authWelcomeTitle => 'Welcome to\nLearnPulse.';

  @override
  String get authTagline =>
      'Courses, assignments and attendance. Your learning, together.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authCreateStudentAccount => 'Create a student account';

  @override
  String get authCreateYourAccount => 'Create your account';

  @override
  String get authFullName => 'Full name';

  @override
  String get authPasswordHelper =>
      '10+ characters with upper case, lower case and a digit';

  @override
  String get authTeacherNote =>
      'Teachers: use the email address your invitation was sent to. Your role is assigned by the school after you confirm your email.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authHaveAccount => 'I already have an account';

  @override
  String get authResetTitle => 'Reset your password';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authCheckEmailTitle => 'Check your email';

  @override
  String get authYourEmailAddress => 'your email address';

  @override
  String authConfirmSent(String email) {
    return 'We sent a confirmation link to $email. Open it on this phone to finish signing in.';
  }

  @override
  String get authResendEmail => 'Resend email';

  @override
  String authResendEmailIn(int seconds) {
    return 'Resend email in ${seconds}s';
  }

  @override
  String get authConfirmedSignIn => 'I\'ve confirmed - sign in';

  @override
  String get authNewPasswordTitle => 'Choose a new password';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authSavePassword => 'Save password';

  @override
  String get authSessionExpiredTitle => 'Session expired';

  @override
  String get authSignedOutTitle => 'You were signed out';

  @override
  String get authSessionEnded =>
      'For your security your session ended. Sign in again to pick up where you left off.';

  @override
  String get authCantReach => 'Can\'t reach LearnPulse';

  @override
  String get authAccountNotReady => 'Account not ready';

  @override
  String noticeConfirmationSent(String email) {
    return 'Confirmation email sent to $email.';
  }

  @override
  String get noticeResetSent =>
      'If an account exists for that address, a reset link is on its way.';

  @override
  String get noticePasswordUpdated => 'Password updated.';

  @override
  String get noticeNameSaved => 'Display name saved.';

  @override
  String noticePasswordLinkSent(String email) {
    return 'A password reset link is on its way to $email.';
  }

  @override
  String get errorNetwork =>
      'No connection to the server. Check your network and try again.';

  @override
  String get errorTimeout =>
      'The server took too long to answer. Try again in a moment.';

  @override
  String get errorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get errorEmailNotConfirmed =>
      'Please confirm your email address first.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorRateLimitedLong =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get errorWeakPassword =>
      'Choose a stronger password (10+ characters with upper, lower case and a digit).';

  @override
  String get errorSignupDisabled => 'Registration is currently closed.';

  @override
  String get errorFileForbidden =>
      'You are not allowed to upload or open that file.';

  @override
  String get errorFileTooLarge => 'That file is too large (10 MB maximum).';

  @override
  String get errorFileType => 'That file type is not allowed.';

  @override
  String get errorForbidden => 'You do not have permission to do that.';

  @override
  String get errorCourseNotFound =>
      'That course was not found, or you no longer have access to it.';

  @override
  String get errorValidation => 'Please check the details and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorNotSignedIn => 'You are not signed in.';

  @override
  String get errorNameNotSaved => 'Your name could not be saved.';

  @override
  String get errorProfileNotReady =>
      'Your account is not ready yet. Please try again in a moment.';

  @override
  String get stateOfflineTitle => 'You are offline';

  @override
  String get stateOfflineMessage =>
      'Check your connection, then try again. Anything you have already saved is safe.';

  @override
  String get stateTimeoutTitle => 'This is taking too long';

  @override
  String get stateTimeoutMessage =>
      'The connection looks slow. Try again, or move somewhere with a better signal.';

  @override
  String get stateExpiredTitle => 'Session expired';

  @override
  String get stateExpiredMessage =>
      'For your security you were signed out. Sign in again to carry on.';

  @override
  String get stateForbiddenTitle => 'Access denied';

  @override
  String get stateForbiddenMessage =>
      'Your account does not have permission to open this.';

  @override
  String get stateNotFoundTitle => 'Not found';

  @override
  String get stateNotFoundMessage =>
      'This may have been removed, or you may no longer have access to it.';

  @override
  String get stateConflictTitle => 'This changed elsewhere';

  @override
  String get stateConflictMessage =>
      'Refresh to see the latest version, then try again.';

  @override
  String get stateUnknownTitle => 'Could not load this';

  @override
  String get stateUnknownMessage =>
      'Something unexpected happened. Please try again.';

  @override
  String stateCouldNotRefresh(String message) {
    return 'Could not refresh: $message Showing the last loaded figures.';
  }

  @override
  String get validationEmailRequired => 'Enter your email address';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String get validationPasswordShort => 'Use at least 10 characters';

  @override
  String get validationPasswordMix =>
      'Include upper case, lower case and a digit';

  @override
  String get validationNameRequired => 'Enter your name';

  @override
  String get validationNameLong => 'Name is too long';

  @override
  String get profileTeachingSummary => 'Teaching summary';

  @override
  String get profileLearningSummary => 'Learning summary';

  @override
  String get profileTeachingSubtitle => 'Your courses. Your impact.';

  @override
  String get profileLearningSubtitle => 'A clear view of how you are doing.';

  @override
  String get profileTeachingIdentity => 'YOUR TEACHING IDENTITY';

  @override
  String get profileLearningIdentity => 'YOUR LEARNING IDENTITY';

  @override
  String get profileNoName => 'No name set';

  @override
  String get profileAccountSettings => 'Account & settings';

  @override
  String get profileCoursesRosters => 'My courses and rosters';

  @override
  String get profileCoursesAttendance => 'My courses and attendance';

  @override
  String get metricCoursesOwned => 'Courses owned';

  @override
  String metricArchived(int count) {
    return '$count archived';
  }

  @override
  String get metricActiveStudents => 'Active students';

  @override
  String get metricAwaitingGrading => 'Awaiting grading';

  @override
  String get metricAttendanceRate => 'Attendance rate';

  @override
  String metricOpenSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open sessions',
      one: '1 open session',
    );
    return '$_temp0';
  }

  @override
  String get metricTeacherNote =>
      'Figures cover only your own active courses and their active students.';

  @override
  String get metricEnrolledCourses => 'Enrolled courses';

  @override
  String get metricAssignmentsDone => 'Assignments done';

  @override
  String metricDoneOfPublished(int done, int published) {
    return '$done of $published';
  }

  @override
  String get metricSubmittedOrGraded => 'Submitted or graded';

  @override
  String get metricAwaitingGrade => 'Awaiting grade';

  @override
  String get metricGraded => 'Graded';

  @override
  String get metricNoGradesYet => 'No grades yet';

  @override
  String metricAverage(String value) {
    return 'Average $value';
  }

  @override
  String get metricReturnedRevision => 'Returned for revision';

  @override
  String get metricStudentNote =>
      'Done = submitted or graded, out of published assignments in your active courses. Attendance = (present + late) / (present + late + absent). Lesson completion is not tracked.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountRegisteredEmail => 'Registered email';

  @override
  String get accountRole => 'Role';

  @override
  String get accountManagedNote =>
      'Your email and role are managed by the school administrator and cannot be changed in the app.';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountEmailResetLink => 'Email me a password reset link';

  @override
  String get accountPrivacy => 'Privacy & security';

  @override
  String get accountPrivacyText =>
      'Teachers see only students enrolled in their own courses; students see only their own work and their course teachers. Your data is not public and there is no public directory. Files are private and open only through short-lived links.';

  @override
  String get accountAbout => 'About';

  @override
  String accountVersion(String version) {
    return 'Version $version (beta)';
  }

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutBody =>
      'You will need to sign in again to use LearnPulse.';

  @override
  String get accountEyebrow => 'Profile';

  @override
  String get accountDescription =>
      'Manage your identity, account access and privacy.';

  @override
  String get accountPersonalDetails => 'Personal details';

  @override
  String get accountDisplayName => 'Display name';

  @override
  String get accountSaveName => 'Save name';

  @override
  String get commonAll => 'All';

  @override
  String get commonActive => 'Active';

  @override
  String get commonArchived => 'Archived';

  @override
  String get commonDraft => 'Draft';

  @override
  String get commonPublished => 'Published';

  @override
  String get commonPublish => 'Publish';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDone => 'Done';

  @override
  String get commonJoin => 'Join';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonChange => 'Change';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonClosed => 'Closed';

  @override
  String get commonAttendance => 'Attendance';

  @override
  String get commonAssignments => 'Assignments';

  @override
  String get commonLessons => 'Lessons';

  @override
  String get commonFiles => 'Files';

  @override
  String commonRemoveNamed(String name) {
    return 'Remove $name';
  }

  @override
  String commonOpenNamed(String name) {
    return 'Open $name';
  }

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusReturned => 'Returned';

  @override
  String get statusToGrade => 'To grade';

  @override
  String get attPresent => 'Present';

  @override
  String get attLate => 'Late';

  @override
  String get attExcused => 'Excused';

  @override
  String get attAbsent => 'Absent';

  @override
  String get validationTitleRequired => 'Enter a title';

  @override
  String get validationTitleLong => 'Use at most 120 characters';

  @override
  String get validationMaxScoreRange => 'Enter a number from 1 to 1000';

  @override
  String get validationJoinCodeRequired => 'Enter the course code';

  @override
  String get validationJoinCodeFormat =>
      'Codes are 8 letters/digits (no I, O, 0 or 1)';

  @override
  String get errorScoreWhole => 'Enter a whole number';

  @override
  String errorScoreRange(int max) {
    return 'Score must be between 0 and $max';
  }

  @override
  String get errorFeedbackLong =>
      'Feedback is too long (5000 characters maximum).';

  @override
  String get errorReturnReason => 'Explain what the student should revise.';

  @override
  String get errorFileLarger => 'That file is larger than 10 MB.';

  @override
  String get errorFileEmpty => 'That file is empty.';

  @override
  String get errorWriteOrAttach => 'Write an answer or attach a file.';

  @override
  String get errorUploadIncomplete =>
      'The file didn\'t finish uploading. Tap Submit to try again.';

  @override
  String get errorSubmissionChanged =>
      'Your submission was changed on another device. Reload to continue; your text is kept.';

  @override
  String get errorGradeConflict =>
      'This submission changed (for example the student resubmitted). Reload to see the latest; your typed score and feedback are kept.';

  @override
  String get errorFileNoAccess => 'You do not have access to this file.';

  @override
  String get errorFileTypeList =>
      'That file type is not allowed. Use pdf, docx, zip, png, jpg, webp or txt.';

  @override
  String get errorOpenFile => 'Could not open the file.';

  @override
  String noticeJoinedCourse(String title) {
    return 'Joined $title.';
  }

  @override
  String get noticeTheCourse => 'the course';

  @override
  String get noticeSubmissionSaved => 'Submission saved.';

  @override
  String get noticeGradeSaved => 'Grade saved.';

  @override
  String get noticeReturnedForRevision =>
      'Returned to the student for revision.';

  @override
  String dashHello(String name) {
    return 'Hello, $name';
  }

  @override
  String dashActiveCourses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active courses',
      one: '1 active course',
    );
    return '$_temp0';
  }

  @override
  String dashTeacherHeroDetail(String courses, int grading) {
    return '$courses · $grading awaiting grading';
  }

  @override
  String dashStudentHeroDetail(String courses, int done, int published) {
    return '$courses · $done of $published assignments done';
  }

  @override
  String get dashStatCourses => 'Courses';

  @override
  String get dashStatToGrade => 'To grade';

  @override
  String get dashStatStudents => 'Students';

  @override
  String get dashStatDone => 'Done';

  @override
  String get dashServices => 'Academic services';

  @override
  String get dashServiceGrading => 'Grading';

  @override
  String get dashServiceProfile => 'My profile';

  @override
  String get dashServiceProfileDetail => 'Progress & account';

  @override
  String dashDetailActive(int count) {
    return '$count active';
  }

  @override
  String dashDetailToReview(int count) {
    return '$count to review';
  }

  @override
  String dashDetailOpen(int count) {
    return '$count open';
  }

  @override
  String dashDetailEnrolled(int count) {
    return '$count enrolled';
  }

  @override
  String dashDetailPublished(int count) {
    return '$count published';
  }

  @override
  String get dashEmptyTeacherTitle => 'Nothing to show yet';

  @override
  String get dashEmptyTeacherHint =>
      'Create a course in the Courses tab. This page fills in as students join, submit work and attend.';

  @override
  String get dashNeedsAttention => 'Needs attention';

  @override
  String get dashAllCaughtUp => 'All caught up';

  @override
  String dashSubmissionsAwaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count submissions awaiting grading',
      one: '1 submission awaiting grading',
    );
    return '$_temp0';
  }

  @override
  String dashSubmittedLine(int received, int expected, String rate) {
    return 'Submitted: $received of $expected · attendance $rate';
  }

  @override
  String get dashReviewSubmissions => 'Review submissions';

  @override
  String get dashUpcomingDeadlines => 'Upcoming deadlines';

  @override
  String get dashNoDeadlines => 'No upcoming deadlines.';

  @override
  String get dashNothingDueSoon => 'Nothing due soon.';

  @override
  String get dashRecentSubmissions => 'Recent submissions';

  @override
  String get dashNoSubmissions => 'No submissions yet.';

  @override
  String dashArchivedStudents(String students) {
    return 'Archived · $students';
  }

  @override
  String dashCountStudents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String dashCountAssignments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assignments',
      one: '1 assignment',
    );
    return '$_temp0';
  }

  @override
  String dashCountSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String dashToGradeCount(int count) {
    return '$count to grade';
  }

  @override
  String get dashAllFigures => 'All figures';

  @override
  String get dashActiveCoursesLabel => 'Active courses';

  @override
  String get dashOutstanding => 'Outstanding work';

  @override
  String dashSubmittedOf(int received, int expected) {
    return '$received of $expected submitted';
  }

  @override
  String get dashPublishedAssignments => 'Published assignments';

  @override
  String dashGradedReturned(int graded, int returned) {
    return '$graded graded · $returned returned';
  }

  @override
  String get dashTeacherFootnote =>
      'Only active students count. Archived courses are excluded from work and attendance figures. Attendance rate = (Present + Late) ÷ (Present + Late + Absent); Excused is not counted.';

  @override
  String get dashEmptyStudentTitle => 'No courses yet';

  @override
  String get dashEmptyStudentHint =>
      'Open the Courses tab and enter the join code from your teacher.';

  @override
  String get dashNeedsYourAttention => 'Needs your attention';

  @override
  String get dashYourNextStep => 'Your next step';

  @override
  String dashOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assignments overdue',
      one: '1 assignment overdue',
    );
    return '$_temp0';
  }

  @override
  String get dashReadyToLearn => 'Ready to learn?';

  @override
  String get dashExploreCourses =>
      'Explore your courses and pick up where you left off.';

  @override
  String get dashOpenCourses => 'Open courses';

  @override
  String get dashStatusRevise => 'Revise';

  @override
  String get dashStatusTodo => 'To do';

  @override
  String get dashLearningProgress => 'Learning progress';

  @override
  String dashDoneOfPublished(int done, int published) {
    return '$done of $published assignments done';
  }

  @override
  String dashAttendanceValue(String value) {
    return 'Attendance $value';
  }

  @override
  String get dashMyCourses => 'My courses';

  @override
  String get dashArchivedReadOnly => 'Archived (read-only)';

  @override
  String dashCourseProgressLine(int done, int total, String rate) {
    return '$done of $total assignments done · attendance $rate';
  }

  @override
  String get dashRecentResults => 'Recent results';

  @override
  String get dashNoGraded => 'No graded work yet.';

  @override
  String get dashFeedbackAvailable => 'feedback available';

  @override
  String get dashNewLessons => 'New lessons';

  @override
  String get dashNotStarted => 'Not started';

  @override
  String dashOverdueHint(int count) {
    return '$count overdue';
  }

  @override
  String get dashNeedsRevision => 'Needs revision';

  @override
  String get dashStudentFootnote =>
      'Course progress = assignments submitted or graded ÷ assignments published. Returned work is not done until you resubmit. Lessons are not tracked as completed.';

  @override
  String get dashNothingToShow => 'Nothing to show yet.';

  @override
  String get courseEyebrowTeaching => 'Teaching';

  @override
  String get courseEyebrowLearning => 'My learning';

  @override
  String get courseYourCourses => 'Your courses';

  @override
  String get courseDescTeacher =>
      'Manage lessons, assignments and attendance in each course.';

  @override
  String get courseDescStudent =>
      'Open a course to continue with lessons and assignments.';

  @override
  String get courseNew => 'New course';

  @override
  String get courseJoin => 'Join a course';

  @override
  String get courseServiceLabel => 'Course service';

  @override
  String get courseAllContent => 'All course content';

  @override
  String get courseNoInCategory =>
      'No courses in this category. Choose another filter.';

  @override
  String courseCouldNotRefresh(String message) {
    return 'Could not refresh: $message';
  }

  @override
  String get courseEmptyTeacherTitle => 'No courses yet';

  @override
  String get courseEmptyTeacherHint =>
      'Create your first course, then share its code with students.';

  @override
  String get courseEmptyStudentTitle => 'You have not joined a course';

  @override
  String get courseEmptyStudentHint =>
      'Ask your teacher for a course code and tap \"Join a course\".';

  @override
  String get courseAreaTeachingAssignments => 'Teaching · Assignments';

  @override
  String get courseAreaLearningAssignments => 'Learning · Assignments';

  @override
  String get courseAreaTeachingAttendance => 'Teaching · Attendance';

  @override
  String get courseAreaLearningAttendance => 'Learning · Attendance';

  @override
  String get courseTapToManage => 'Tap to manage';

  @override
  String courseTeacherName(String name) {
    return 'Teacher: $name';
  }

  @override
  String get courseTeachingCourse => 'Teaching course';

  @override
  String get courseEnrolledCourse => 'Enrolled course';

  @override
  String get courseTeachingWorkspace => 'Your teaching workspace';

  @override
  String get courseLearningWorkspace => 'Your learning workspace';

  @override
  String get courseManage => 'Manage course';

  @override
  String get courseOpen => 'Open course';

  @override
  String get courseLearningEyebrow => 'Learning workspace';

  @override
  String get courseArchivedNote =>
      'This course is archived. It stays visible but is read-only.';

  @override
  String get courseEdit => 'Edit course';

  @override
  String get courseDescriptionOptional => 'Description (optional)';

  @override
  String get courseCreated => 'Course created';

  @override
  String get courseShareCode => 'Share this code with your students:';

  @override
  String get courseCodeLabel => 'Course code';

  @override
  String get courseRemovedMsg =>
      'You were removed from this course. Ask your teacher to add you back.';

  @override
  String get courseCodeInvalid =>
      'That code is not valid, or the course is closed.';

  @override
  String get courseArchiveTitle => 'Archive this course?';

  @override
  String get courseReopenTitle => 'Reopen this course?';

  @override
  String get courseArchiveBody =>
      'Students keep read-only access, but nobody new can join with the code.';

  @override
  String get courseReopenBody =>
      'Students will be able to join with the code again.';

  @override
  String get courseArchiveAction => 'Archive';

  @override
  String get courseReopenAction => 'Reopen';

  @override
  String get courseRemoveTitle => 'Remove student?';

  @override
  String courseRemoveBody(String name) {
    return '$name will lose access to the course and cannot rejoin with the code.';
  }

  @override
  String get courseThisStudent => 'This student';

  @override
  String get courseInviteTitle => 'Invite your first students';

  @override
  String get courseInviteBody =>
      'Share the join code below. Attendance, grading and progress fill in once students join.';

  @override
  String get courseSvcSubmissions => 'Submissions';

  @override
  String get courseSvcReviewWork => 'Review work';

  @override
  String get courseSvcRoster => 'Roster';

  @override
  String get courseSvcContent => 'Content';

  @override
  String get courseWeeklyAttendance => 'Weekly attendance';

  @override
  String get courseAdmin => 'Course administration';

  @override
  String get courseJoinCode => 'Join code';

  @override
  String get courseCopyCode => 'Copy code';

  @override
  String get courseCodeCopied => 'Code copied';

  @override
  String get courseArchivedNoJoin =>
      'Archived: students cannot join until you reopen the course.';

  @override
  String get courseReopenCourse => 'Reopen course';

  @override
  String get courseArchiveCourse => 'Archive course';

  @override
  String courseStudentsTitle(int count) {
    return 'Students ($count)';
  }

  @override
  String get courseNoStudents => 'No students yet. Share the join code above.';

  @override
  String courseJoinedTap(String date) {
    return 'Joined $date · tap for progress';
  }

  @override
  String courseRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count removed students (no access)',
      one: '1 removed student (no access)',
    );
    return '$_temp0';
  }

  @override
  String get classYourClass => 'Your class';

  @override
  String get classArchivedReadOnly => 'Archived · read-only';

  @override
  String classHeroSemantics(int students, int sessions, String toGrade) {
    return '$students students, $sessions open attendance sessions, $toGrade submissions to grade';
  }

  @override
  String get classUnknownNumber => 'unknown number of';

  @override
  String get classOpenSessions => 'Open sessions';

  @override
  String get classNoSessions => 'No sessions';

  @override
  String classRateValue(String value) {
    return 'Class rate $value';
  }

  @override
  String get classSessions => 'Sessions';

  @override
  String get classNoAttendanceSessions =>
      'No attendance sessions yet. Create one in the Attendance section to start tracking.';

  @override
  String get classLatestSession => 'Latest session';

  @override
  String get classSessionFallback => 'Session';

  @override
  String classNotMarked(int count) {
    return 'Not marked $count';
  }

  @override
  String get classNothingToGrade => 'Nothing to grade';

  @override
  String get classPublished => 'Published';

  @override
  String get classDrafts => 'Drafts';

  @override
  String get classNoPublished => 'No published assignments yet.';

  @override
  String get classSubmissionsReceived => 'Submissions received';

  @override
  String classDueLower(String when) {
    return 'due $when';
  }

  @override
  String get classNoRecent => 'No recent activity';

  @override
  String get classNoRecentHint =>
      'Submitted work will show here as students hand it in.';

  @override
  String get classAttendanceByStudent => 'Attendance by student';

  @override
  String get classNoStudentsEnrolled => 'No students enrolled yet';

  @override
  String get classShareCode => 'Share the join code so students can enrol.';

  @override
  String lessonFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get lessonNew => 'New lesson';

  @override
  String get lessonNoneYet => 'No lessons yet';

  @override
  String get lessonEmptyTeacher =>
      'Create a draft, add files, then publish it for students.';

  @override
  String get lessonEmptyStudent =>
      'Your teacher has not published any lessons for this course.';

  @override
  String get lessonText => 'Lesson text';

  @override
  String get lessonCreateDraft => 'Create draft';

  @override
  String get lessonDeleteTitle => 'Delete lesson?';

  @override
  String get lessonDeleteBody =>
      'The lesson and its files disappear for everyone. This cannot be undone.';

  @override
  String get lessonTitle => 'Lesson';

  @override
  String get lessonGone => 'This lesson no longer exists.';

  @override
  String get lessonNoFilesAttached => 'No files attached.';

  @override
  String get lessonAttach => 'Attach file';

  @override
  String get lessonPublication => 'Publication & access';

  @override
  String get lessonSaveFirst =>
      'Save your content before changing its visibility.';

  @override
  String get lessonUnpublish => 'Unpublish';

  @override
  String get lessonDelete => 'Delete lesson';

  @override
  String get lessonEditEyebrow => 'Edit lesson';

  @override
  String get lessonPublishedDesc =>
      'Published · Students can read this lesson.';

  @override
  String get lessonDraftDesc => 'Draft · Only you can see this lesson.';

  @override
  String get lessonContent => 'Learning content';

  @override
  String get lessonSaveChanges => 'Save changes';

  @override
  String lessonCourseEyebrow(String course) {
    return '$course · Lesson';
  }

  @override
  String get lessonReadExplore => 'Read, explore, then put it into practice.';

  @override
  String get lessonNoText => 'No lesson text.';

  @override
  String get lessonSupporting => 'Supporting resources for this lesson.';

  @override
  String get lessonNoFiles => 'No files for this lesson.';

  @override
  String get asgNotSubmitted => 'Not submitted';

  @override
  String asgGradedScore(int score, int max) {
    return 'Graded $score/$max';
  }

  @override
  String get asgReturnedForRevision => 'Returned for revision';

  @override
  String get asgNone => 'No assignments yet';

  @override
  String get asgStudentEmptyHint =>
      'New work from your teacher will appear here.';

  @override
  String get asgNoDeadline => 'No deadline';

  @override
  String asgDue(String when) {
    return 'Due $when';
  }

  @override
  String asgResultGraded(int score, int max) {
    return 'Graded: $score/$max';
  }

  @override
  String asgFeedbackLine(String text) {
    return 'Feedback: $text';
  }

  @override
  String get asgGradedLocked => 'This submission is graded and locked.';

  @override
  String get asgReviseResubmit => 'Revise your work below and resubmit.';

  @override
  String get asgSavedSubmission => 'Your saved submission';

  @override
  String asgSavedLine(String when, int version) {
    return 'Saved $when · version $version';
  }

  @override
  String get asgReload => 'Reload my submission';

  @override
  String get asgEyebrowWorkspace => 'Assignment / Your workspace';

  @override
  String asgMaxScore(int score) {
    return 'Max score $score';
  }

  @override
  String get asgDeadlinePassed =>
      'The deadline has passed. Submissions are closed.';

  @override
  String get asgBrief => 'The brief';

  @override
  String get asgNoInstructions => 'No instructions.';

  @override
  String get asgUploading => 'Uploading file…';

  @override
  String get asgSaving => 'Saving…';

  @override
  String get asgSubmit => 'Submit';

  @override
  String get asgResubmit => 'Resubmit';

  @override
  String get asgYourResponse => 'Your response';

  @override
  String get asgFirstHint =>
      'Write your answer or attach your work. Submit when you are ready.';

  @override
  String get asgUpdateHint =>
      'Update your answer below. Your saved version stays available until you resubmit.';

  @override
  String get asgYourAnswer => 'Your answer';

  @override
  String get asgAnswerHint =>
      'Start with your approach, then explain what you found…';

  @override
  String asgUploadPrivately(String size) {
    return '$size · will be uploaded privately';
  }

  @override
  String get asgRemoveAttachmentTip => 'Remove attachment';

  @override
  String get asgReplaceFile => 'Replace attached file';

  @override
  String get asgAttachFile => 'Attach a file';

  @override
  String get asgRemoveSaved => 'Remove my saved attachment';

  @override
  String get asgSavedOnSubmit => 'Your work is saved when you submit.';

  @override
  String get asgNewTitle => 'New assignment';

  @override
  String get asgEditTitle => 'Edit assignment';

  @override
  String get asgInstructions => 'Instructions';

  @override
  String get asgMaxScoreLabel => 'Maximum score';

  @override
  String get asgSetDeadline => 'Set deadline';

  @override
  String get asgRemoveDeadline => 'Remove deadline';

  @override
  String get asgSaveDraft => 'Save draft';

  @override
  String get asgTeacherEmptyHint =>
      'Create a draft, then publish it for students.';

  @override
  String get asgPublishTitle => 'Publish assignment?';

  @override
  String get asgPublishBody =>
      'Enrolled students will see it and can start submitting work.';

  @override
  String get asgGone => 'This assignment is no longer available.';

  @override
  String asgSubmissionsCount(int count) {
    return 'Submissions ($count)';
  }

  @override
  String get asgTeachingEyebrow => 'Teaching / Assignment';

  @override
  String get asgReviewDesc => 'Review submissions and move learning forward.';

  @override
  String get asgPrepareDesc =>
      'Prepare your brief, then publish it to your course.';

  @override
  String get asgBriefTitle => 'Assignment brief';

  @override
  String get asgDraftsHidden =>
      'Students cannot see drafts. Publish to receive submissions.';

  @override
  String get asgNoSubmissions => 'No submissions yet';

  @override
  String get asgNoSubmissionsHint =>
      'Student work will appear here as it is handed in.';

  @override
  String asgSubmittedVersion(String when, int version) {
    return 'Submitted $when · version $version';
  }

  @override
  String get asgGrade => 'Grade';

  @override
  String get asgReview => 'Review';

  @override
  String gradeReviewEyebrow(String title) {
    return 'Review · $title';
  }

  @override
  String get gradeStudentSubmission => 'Student submission';

  @override
  String get gradeReadDesc => 'Read the work, then give a clear next step.';

  @override
  String get gradeStatusTitle => 'Submission status';

  @override
  String get gradeVersion => 'Version';

  @override
  String get gradeMaxScore => 'Max score';

  @override
  String gradeSubmittedAt(String when) {
    return 'Submitted $when';
  }

  @override
  String get gradeStudentAnswer => 'Student answer';

  @override
  String get gradeNoText => '(no text)';

  @override
  String get gradeReloadLatest => 'Reload latest';

  @override
  String get gradeWaiting => 'Waiting for the student to revise and resubmit.';

  @override
  String gradeYourFeedback(String text) {
    return 'Your feedback: $text';
  }

  @override
  String get gradeAndFeedback => 'Grade and feedback';

  @override
  String get gradeHint =>
      'A score records achievement. Feedback shows what to do next.';

  @override
  String get gradeScore => 'Score';

  @override
  String gradeScoreRangeLabel(int max) {
    return 'Score (0–$max)';
  }

  @override
  String get gradeFeedbackToStudent => 'Feedback to the student';

  @override
  String get gradeFeedback => 'Feedback';

  @override
  String get gradeSaveNew => 'Save new grade';

  @override
  String get gradeSave => 'Save grade';

  @override
  String get gradeReturn => 'Return for revision';

  @override
  String get gradeHistory => 'History';

  @override
  String get gradeNoHistory => 'No grading actions yet.';

  @override
  String get errorNoteTooLong => 'Note is too long (500 characters maximum).';

  @override
  String get errorRecordChanged =>
      'This record changed elsewhere. The latest values are shown; try again.';

  @override
  String get errorSessionNotFound => 'Session not found.';

  @override
  String get errorActivityNotFound => 'Activity not found.';

  @override
  String get errorAssignmentUnavailable =>
      'This assignment is no longer available.';

  @override
  String get errorCourseUnavailable => 'This course is no longer available.';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get commonLoadingEllipsis => 'Loading…';

  @override
  String get actPolicyTeacherMarked => 'Teacher marked';

  @override
  String get actPolicySelfReported => 'Self-reported';

  @override
  String get actPolicyTeacherVerified => 'Teacher verified';

  @override
  String get actPolicyHintTeacherMarked => 'Your teacher records completion.';

  @override
  String get actPolicyHintSelfReported => 'You mark it done yourself.';

  @override
  String get actPolicyHintTeacherVerified =>
      'You submit it and your teacher confirms.';

  @override
  String get actPolicyDetailTeacherMarked =>
      'You record who completed it. Students only see their status.';

  @override
  String get actPolicyDetailSelfReported =>
      'Students mark their own completion before the deadline.';

  @override
  String get actPolicyDetailTeacherVerified =>
      'Students submit; you approve or reject with a reason.';

  @override
  String get actStateUpcoming => 'Upcoming';

  @override
  String get actStateOpen => 'To do';

  @override
  String get actStatePending => 'Awaiting review';

  @override
  String get actStateCompleted => 'Done';

  @override
  String get actStateRejected => 'Needs another try';

  @override
  String get actStateNotDone => 'Not done';

  @override
  String get actStateMissed => 'Missed';

  @override
  String get actStateNotScheduled => 'Not scheduled';

  @override
  String get actPaused => 'Paused';

  @override
  String get actEveryDay => 'Every day';

  @override
  String get actWeekdays => 'Weekdays';

  @override
  String actDeadlineAtTime(String time, String tz) {
    return 'Due $time ($tz)';
  }

  @override
  String actDeadlineDayEnd(String tz) {
    return 'Due at the end of the day ($tz)';
  }

  @override
  String get actNoStreak => 'No streak (no deadline)';

  @override
  String actStreak(String value) {
    return '$value streak';
  }

  @override
  String actBest(String value) {
    return 'Best $value';
  }

  @override
  String actDoneOfResolved(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get actEditDetails => 'Edit details';

  @override
  String get actDescription => 'Description';

  @override
  String get actDueEndOfDay => 'Due end of day';

  @override
  String get actSubmitForReview => 'Submit for review';

  @override
  String get actNoteForTeacher => 'Note for your teacher (optional)';

  @override
  String get actSubmit => 'Submit';

  @override
  String get actMarkDone => 'Mark as done';

  @override
  String get actWithdraw => 'Withdraw';

  @override
  String actTeacherAskedRetry(String reason) {
    return 'Your teacher asked for another try: $reason';
  }

  @override
  String get actNothingToday => 'Nothing scheduled today';

  @override
  String get actNothingTodayHint =>
      'Your teacher has not scheduled an activity for today in this course.';

  @override
  String get actDaily => 'Daily activities';

  @override
  String get actDailyOne => 'Daily activity';

  @override
  String get actTodaySubtitle => 'What to do today in this course.';

  @override
  String get actWeekView => 'Week view';

  @override
  String get actMyProgress => 'My progress';

  @override
  String actWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get actThisWeek => 'This week';

  @override
  String get actPrevWeek => 'Previous week';

  @override
  String get actNextWeek => 'Next week';

  @override
  String get actNoWeekTitle => 'No activities this week';

  @override
  String get actNoWeekHint =>
      'Nothing is scheduled for these days. Use the arrows to look at another week.';

  @override
  String get actDaysOfWeek => 'Days of the week';

  @override
  String get actNoEndDate => 'No end date';

  @override
  String actEnds(String date) {
    return 'Ends $date';
  }

  @override
  String get actClearEnd => 'Clear end date';

  @override
  String get actDeadline => 'Deadline';

  @override
  String get actDlDayEnd => 'End of each day';

  @override
  String get actDlDayEndHint =>
      'Default daily cutoff at midnight in the activity timezone.';

  @override
  String get actDlTime => 'At a set time each day';

  @override
  String get actDlNoneHint => 'Never counts as missed and has no streak.';

  @override
  String actDueAtPicker(String time) {
    return 'Due at $time';
  }

  @override
  String get actTimezone => 'Timezone';

  @override
  String get actStarts => 'Starts';

  @override
  String get actNewActivity => 'New activity';

  @override
  String actReviewN(int count) {
    return 'Review ($count)';
  }

  @override
  String get actReviewQueue => 'Review queue';

  @override
  String get actSectionSubtitle =>
      'Recurring practice with a completion policy and a deadline.';

  @override
  String actTodayDone(int done, int expected) {
    return 'Today $done/$expected done';
  }

  @override
  String get actNotScheduledToday => 'Not scheduled today';

  @override
  String actToReview(int count) {
    return '$count to review';
  }

  @override
  String get actEmptyTitle => 'No activities yet';

  @override
  String get actEmptyHint =>
      'Create a daily activity such as Reading Practice, then choose how completion is recorded.';

  @override
  String get actProblemTitle => 'Give the activity a title.';

  @override
  String get actProblemDays => 'Choose at least one day of the week.';

  @override
  String get actFormDesc =>
      'Subject-neutral practice your students repeat on the days you choose.';

  @override
  String get actDetails => 'Details';

  @override
  String get actDescriptionOptional => 'Description (optional)';

  @override
  String get actHowRecorded => 'How is completion recorded?';

  @override
  String get actSchedule => 'Schedule';

  @override
  String get actCreate => 'Create activity';

  @override
  String get actChangeSchedule => 'Change schedule';

  @override
  String get actChangeDesc =>
      'The new schedule starts on the date you choose (tomorrow or later). Days before it keep the rules they had, so nobody\'s history changes.';

  @override
  String get actNewSchedule => 'New schedule';

  @override
  String get actSaveSchedule => 'Save schedule';

  @override
  String actScheduleFrom(String from, int version) {
    return 'Current schedule from $from (version $version)';
  }

  @override
  String actScheduleFromTo(String from, String to, int version) {
    return 'Current schedule from $from to $to (version $version)';
  }

  @override
  String get actPause => 'Pause';

  @override
  String get actResume => 'Resume';

  @override
  String get actArchive => 'Archive';

  @override
  String get actConfirmPause =>
      'Pause this activity from tomorrow? Past days keep their records.';

  @override
  String get actConfirmArchive =>
      'Archive this activity? It is hidden from students; history is kept.';

  @override
  String get actConfirmResume => 'Resume this activity from tomorrow?';

  @override
  String get actWeeklyRegister => 'Weekly register';

  @override
  String actRegisterSubtitle(String date) {
    return 'Week of $date. Tap a cell to record or review.';
  }

  @override
  String actCouldNotRefreshWeek(String error) {
    return 'Could not refresh: $error Showing the last loaded week.';
  }

  @override
  String get actNoStudentsTitle => 'No students enrolled yet';

  @override
  String get actNoStudentsHint =>
      'Students appear here once they join the course.';

  @override
  String get actNotScheduledWeek => 'Not scheduled this week';

  @override
  String get actNotScheduledWeekHint =>
      'This activity has no scheduled day in this week. Use the arrows to look at another week.';

  @override
  String actCellSemantics(String name, String date, String state) {
    return '$name, $date: $state';
  }

  @override
  String actStudentNote(String note) {
    return 'Student note: $note';
  }

  @override
  String actReasonGiven(String reason) {
    return 'Reason given: $reason';
  }

  @override
  String get actArchivedReadOnly =>
      'This course is archived, so records are read-only.';

  @override
  String get actReasonRequired => 'Reason for the student (required)';

  @override
  String get actApprove => 'Approve';

  @override
  String get actReject => 'Reject';

  @override
  String get actSendRejection => 'Send rejection';

  @override
  String get actFutureDays => 'Future days cannot be marked yet.';

  @override
  String get actMarkCompleted => 'Mark completed';

  @override
  String get actMarkNotDone => 'Mark not done';

  @override
  String get actVerificationQueue => 'Verification queue';

  @override
  String actWaitingDecision(int count) {
    return '$count waiting for your decision.';
  }

  @override
  String get actWaitingReview => 'Waiting for review';

  @override
  String get actNothingToReview => 'Nothing to review';

  @override
  String get actNothingToReviewHint =>
      'Submissions from students appear here for approval or rejection.';

  @override
  String actSubmittedAt(String when) {
    return 'submitted $when';
  }

  @override
  String actNoteLine(String note) {
    return 'Note: $note';
  }

  @override
  String get actRejectTitle => 'Reject submission';

  @override
  String get atdRateNone => 'No rate yet';

  @override
  String get atdNewSession => 'New session';

  @override
  String get atdWeeklyGrid => 'Weekly grid';

  @override
  String get atdSummary => 'Summary';

  @override
  String get atdNoSessions => 'No attendance sessions yet';

  @override
  String get atdNoSessionsHint => 'Create one for each class meeting.';

  @override
  String get atdNewDialogTitle => 'New attendance session';

  @override
  String get atdDate => 'Date';

  @override
  String get atdTime => 'Time';

  @override
  String atdNoteFor(String name) {
    return 'Note for $name';
  }

  @override
  String get atdNote => 'Note';

  @override
  String get atdSaveNote => 'Save note';

  @override
  String get atdCloseTitle => 'Close this session?';

  @override
  String get atdCloseAllMarked =>
      'Every student is marked. You can still correct records later.';

  @override
  String atdCloseUnmarked(int count) {
    return '$count unmarked student(s) will be recorded as Absent. You can still correct records later.';
  }

  @override
  String get atdCloseSession => 'Close session';

  @override
  String atdEventClosed(String when) {
    return 'Session closed · $when';
  }

  @override
  String atdEventCorrected(String who, String from, String to, String when) {
    return '$who: $from → $to · $when';
  }

  @override
  String atdEventMarked(String who, String status, String when) {
    return '$who: $status · $when';
  }

  @override
  String get atdEyebrowSession => 'Attendance / Session';

  @override
  String get atdClassRegister => 'Class register';

  @override
  String get atdRegisterHint =>
      'Choose a status for each student. Changes save immediately.';

  @override
  String get atdArchivedReadOnly =>
      'This course is archived. Attendance is read-only.';

  @override
  String get atdNoStudents => 'No students are enrolled yet.';

  @override
  String atdCloseSessionN(int count) {
    return 'Close session ($count unmarked)';
  }

  @override
  String get atdSessionClosedNote =>
      'Session closed. Existing records can still be corrected.';

  @override
  String get atdNoChanges => 'No changes yet.';

  @override
  String atdEditNoteFor(String name) {
    return 'Edit note for $name';
  }

  @override
  String get atdNotMarkedYet => 'Not marked yet';

  @override
  String get atdEyebrowTeaching => 'Teaching / Attendance';

  @override
  String get atdEyebrowLearning => 'Learning / Attendance';

  @override
  String get atdSummaryTitle => 'Attendance summary';

  @override
  String get atdSummaryDesc =>
      'A clear record of participation across class sessions.';

  @override
  String atdClosedOfTotal(int closed, int total) {
    return '$closed closed of $total session(s)';
  }

  @override
  String get atdRateNote =>
      'Rate = (Present + Late) ÷ (Present + Late + Absent). Excused is not counted.';

  @override
  String get atdSummaryEmptyHint =>
      'Attendance rates appear once students join the course.';

  @override
  String get atdMyAttendance => 'My attendance';

  @override
  String get atdWeeklyView => 'Weekly view';

  @override
  String get atdNoRecords => 'No attendance recorded yet';

  @override
  String get atdNoRecordsHint =>
      'Your attendance will show here once a class is marked.';

  @override
  String atdRateTitle(String rate) {
    return 'Attendance rate: $rate';
  }

  @override
  String get atdWeeklyAttendance => 'Weekly attendance';

  @override
  String get atdMyWeek => 'My week';

  @override
  String get atdGridDesc =>
      'Names stay in view. Swipe the days to explore each session.';

  @override
  String get atdGlyphPresent => 'P';

  @override
  String get atdGlyphLate => 'L';

  @override
  String get atdGlyphExcused => 'E';

  @override
  String get atdGlyphAbsent => 'A';

  @override
  String get atdNotMarked => 'Not marked';

  @override
  String get atdNoSession => '· No session';

  @override
  String get atdTwoSessions => '×2 = two sessions that day, in time order';

  @override
  String atdCellNoSession(String who, String date) {
    return '$who, $date: no session';
  }

  @override
  String get atdMe => 'Me';

  @override
  String get atdStatusGuide => 'Status guide';

  @override
  String get atdGridNoSessions => 'No attendance sessions this week';

  @override
  String get atdGridNoSessionsHint => 'Use the arrows to look at another week.';

  @override
  String get atdGridNoStudentsHint =>
      'The weekly table appears once students join the course.';

  @override
  String get atdAllMarked => 'All marked';

  @override
  String atdUnmarkedCount(int count) {
    return '$count unmarked';
  }

  @override
  String get progEyebrowTeacher => 'Student progress';

  @override
  String progEnrolledSince(String date) {
    return 'Enrolled since $date';
  }

  @override
  String get progPrivateTeacher =>
      'Private to you and this student. Not shared with the class.';

  @override
  String get progPrivateStudent => 'Only you and your teacher can see this.';

  @override
  String get progArchived => 'This course is archived (read-only).';

  @override
  String progCouldNotRefresh(String error) {
    return 'Could not refresh: $error Showing the last loaded figures.';
  }

  @override
  String get progAssignmentsNone => 'No assignment has been published yet.';

  @override
  String progAssignmentsSummary(int done, int published) {
    return '$done of $published published assignments submitted or graded.';
  }

  @override
  String get progNoPublishedTitle => 'No published assignments';

  @override
  String get progNoPublishedHint =>
      'Progress appears here once the teacher publishes work.';

  @override
  String progOfCount(int a, int b) {
    return '$a of $b';
  }

  @override
  String progOverdueHint(int count) {
    return '$count overdue';
  }

  @override
  String get progAwaitingGrading => 'Awaiting grading';

  @override
  String progScore(int score, int max) {
    return 'Score $score/$max';
  }

  @override
  String progTruncated(int shown, int total) {
    return 'Showing the latest $shown of $total assignments. The counts above cover all of them.';
  }

  @override
  String get progActivitiesSubtitle =>
      'Streaks count scheduled days only (last 62 days). Pending review is not counted until approved.';

  @override
  String progAwaitingVerification(int count) {
    return '$count awaiting verification';
  }

  @override
  String get progNoActivitiesHint =>
      'No daily activity has been set up for this course.';

  @override
  String get progNoClosedDay => 'No scheduled day has closed yet.';

  @override
  String get progAttNone => 'No attendance session has been created.';

  @override
  String progAttSummary(int total, int closed) {
    return '$total sessions, $closed closed.';
  }

  @override
  String get progNoSessionsTitle => 'No sessions yet';

  @override
  String get progNoSessionsHint =>
      'Attendance appears once the teacher creates a session.';

  @override
  String get progRateNone => 'Attendance rate: no data yet (nothing countable)';

  @override
  String progRate(String rate, int present, int counted) {
    return 'Attendance rate: $rate ($present of $counted counted sessions)';
  }

  @override
  String progNotMarkedCount(int count) {
    return 'Not marked: $count';
  }

  @override
  String get progRecentSessions => 'Recent sessions';

  @override
  String get taskModeMonth => 'Month';

  @override
  String get taskModeCompleted => 'Completed';

  @override
  String get taskOverdue => 'Overdue';

  @override
  String get taskNeedsRevision => 'Needs revision';

  @override
  String get taskGraded => 'Graded';

  @override
  String get taskHeld => 'Held';

  @override
  String get taskScheduled => 'Scheduled';

  @override
  String get taskHeaderTitle => 'What to do';

  @override
  String get taskHeaderDesc =>
      'Assignments and daily activities from all your courses, with one status each.';

  @override
  String get taskEmptyTodayTitle => 'Nothing due today';

  @override
  String get taskEmptyTodayHint => 'Enjoy it, or look at the week ahead.';

  @override
  String get taskEmptyWeekTitle => 'Nothing this week';

  @override
  String get taskEmptyWeekHint =>
      'No assignment deadline or activity falls in this week.';

  @override
  String get taskEmptyMonthTitle => 'Nothing this month';

  @override
  String get taskEmptyDayTitle => 'Nothing on this day';

  @override
  String get taskEmptyMonthHint =>
      'No assignment deadline or activity falls here.';

  @override
  String get taskEmptyUpcomingTitle => 'Nothing coming up';

  @override
  String get taskEmptyUpcomingHint =>
      'New work from your teachers will appear here.';

  @override
  String get taskEmptyOverdueTitle => 'Nothing overdue';

  @override
  String get taskEmptyOverdueHint => 'You are up to date.';

  @override
  String get taskEmptyCompletedTitle => 'Nothing completed yet';

  @override
  String get taskEmptyCompletedHint => 'Finished work appears here.';

  @override
  String get taskCalendarEyebrow => 'Calendar';

  @override
  String get taskCalendarTitle => 'Teaching calendar';

  @override
  String get taskCalendarDesc =>
      'Assignment deadlines, daily activities and attendance sessions across your courses.';

  @override
  String get taskNoPending => 'No activity submissions waiting for review.';

  @override
  String taskPending(int count) {
    return '$count activity submissions waiting for review.';
  }

  @override
  String taskCouldNotRefreshTasks(String error) {
    return 'Could not refresh: $error Showing the last loaded tasks.';
  }

  @override
  String taskCouldNotRefreshCalendar(String error) {
    return 'Could not refresh: $error Showing the last loaded calendar.';
  }

  @override
  String get taskNothingScheduled => 'Nothing scheduled';

  @override
  String get taskNothingScheduledHint =>
      'No deadline, activity or attendance session falls here.';

  @override
  String get taskPrevious => 'Previous';

  @override
  String get taskNext => 'Next';

  @override
  String taskDayItems(int day, String month, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'no items',
    );
    return '$day $month, $_temp0';
  }

  @override
  String get taskUndated => 'Undated';

  @override
  String taskDueSubmitted(String when, int received, int expected) {
    return 'Due $when · $received of $expected submitted';
  }

  @override
  String taskDoneOf(int received, int expected) {
    return '$received of $expected done';
  }

  @override
  String taskAttendanceSession(String when, String state) {
    return 'Attendance session $when · $state';
  }

  @override
  String taskClassSession(String when) {
    return 'Class session $when';
  }

  @override
  String get taskNothingDueToday => 'Nothing is due today.';

  @override
  String taskTodoDone(int todo, int rest) {
    return '$todo to do · $rest done or waiting';
  }

  @override
  String get taskAllTasks => 'All tasks';

  @override
  String get taskAllClear => 'All clear today';

  @override
  String get taskAllClearHint =>
      'No assignment deadline or activity is scheduled for today.';

  @override
  String taskMoreInTasks(int count) {
    return '$count more in Tasks';
  }

  @override
  String taskReview(int count) {
    return 'Review ($count)';
  }

  @override
  String get actTzBangkok => 'Bangkok (UTC+7)';

  @override
  String get actTzSingapore => 'Singapore (UTC+8)';

  @override
  String get actTzTokyo => 'Tokyo (UTC+9)';

  @override
  String get actTzIndia => 'India (UTC+5:30)';

  @override
  String get actTzDubai => 'Dubai (UTC+4)';

  @override
  String get actTzLondon => 'London';

  @override
  String get actTzParisBerlin => 'Paris / Berlin';

  @override
  String get actTzNewYork => 'New York';

  @override
  String get actTzChicago => 'Chicago';

  @override
  String get actTzLosAngeles => 'Los Angeles';

  @override
  String get actTzSydney => 'Sydney';

  @override
  String get actTzAuckland => 'Auckland';

  @override
  String get actTzUtc => 'Coordinated Universal Time (UTC)';

  @override
  String get welcomeTitle => 'Your learning day, all in one place.';

  @override
  String get welcomeDescription =>
      'Bring your courses, tasks and learning progress together. Sign in to continue.';

  @override
  String get welcomeFeatures => 'Made for everyday learning';

  @override
  String get welcomeProgress => 'Progress';

  @override
  String get welcomeBack => 'Back to welcome';

  @override
  String get profilePhotoTitle => 'Profile photo';

  @override
  String get profilePhotoHint =>
      'JPEG or WebP. It is cropped to a square and shrunk to about 256 px. Only you and your course teachers can see it.';

  @override
  String get profilePhotoAdd => 'Add photo';

  @override
  String get profilePhotoChange => 'Change photo';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoSaved => 'Photo saved';

  @override
  String get profilePhotoRemoved => 'Photo removed';

  @override
  String get profilePhotoCropTitle => 'Crop your photo';

  @override
  String get profilePhotoCropHint =>
      'Drag and pinch the picture to choose what shows in the circle.';

  @override
  String get profilePhotoSave => 'Save photo';

  @override
  String profilePhotoSemantics(String name) {
    return 'Profile photo of $name';
  }

  @override
  String get errorAvatarType => 'Choose a JPEG or WebP picture.';

  @override
  String get errorAvatarInputTooLarge =>
      'That picture is too large (10 MB maximum).';

  @override
  String get errorAvatarDecode =>
      'That picture could not be read. Try another one.';

  @override
  String get scanTitle => 'Scan attendance code';

  @override
  String get scanButton => 'Scan code';

  @override
  String get scanHint =>
      'Point the camera at the classroom QR code, or type the code shown under it.';

  @override
  String get scanCameraLabel =>
      'Camera preview for scanning the attendance QR code';

  @override
  String get scanManualLabel => 'Attendance code';

  @override
  String get scanSubmit => 'Submit code';

  @override
  String get scanAgain => 'Scan another code';

  @override
  String get scanCameraDenied =>
      'Camera access is off. Allow it in Settings, or type the code below.';

  @override
  String get scanNoCamera =>
      'This device has no usable camera. Type the code below.';

  @override
  String get scanCameraBusy =>
      'The camera could not start (it may be in use). Type the code below, or try again.';

  @override
  String scanOk(String status, String time) {
    return 'Checked in as $status at $time.';
  }

  @override
  String scanOutOk(String time) {
    return 'Checked out at $time.';
  }

  @override
  String scanAlready(String status) {
    return 'You were already recorded as $status.';
  }

  @override
  String get scanOutAlready => 'You were already checked out.';

  @override
  String get scanReasonInvalid => 'That code is not valid.';

  @override
  String get scanReasonExpired =>
      'That code has expired. Ask for the current code.';

  @override
  String get scanReasonClosed => 'This session is closed.';

  @override
  String get scanReasonNotMember =>
      'You are not an active member of this course.';

  @override
  String get scanReasonTooEarly => 'Check-in is not open yet.';

  @override
  String get scanReasonTooLate => 'The check-in window has ended.';

  @override
  String get scanReasonNoCheckin => 'Check in before checking out.';

  @override
  String atdTimeIn(String time) {
    return 'In $time';
  }

  @override
  String atdTimeOut(String time) {
    return 'Out $time';
  }

  @override
  String get atdViaQr => 'QR';

  @override
  String get staffTitle => 'Staff attendance';

  @override
  String get staffSubtitle =>
      'Clock in and out, see your history and ask for leave or a correction.';

  @override
  String get staffToday => 'Today';

  @override
  String staffStatusIn(String time) {
    return 'Clocked in since $time';
  }

  @override
  String get staffStatusOut => 'You are not clocked in.';

  @override
  String staffStatusLate(String minutes) {
    return 'Late by $minutes min';
  }

  @override
  String get staffClockIn => 'Clock in';

  @override
  String get staffClockOut => 'Clock out';

  @override
  String get staffClockedIn => 'Clocked in';

  @override
  String get staffClockedOut => 'Clocked out';

  @override
  String get staffServerTime =>
      'Times come from the server clock, not from your device.';

  @override
  String get staffSchedule => 'Working schedule';

  @override
  String get staffNoSchedule =>
      'No schedule is set for you. You can still clock in; the day is recorded as unscheduled.';

  @override
  String staffScheduleLine(
    String days,
    String start,
    String end,
    String zone,
    String grace,
  ) {
    return '$days · $start–$end ($zone), $grace min grace';
  }

  @override
  String get staffD1 => 'Mon';

  @override
  String get staffD2 => 'Tue';

  @override
  String get staffD3 => 'Wed';

  @override
  String get staffD4 => 'Thu';

  @override
  String get staffD5 => 'Fri';

  @override
  String get staffD6 => 'Sat';

  @override
  String get staffD7 => 'Sun';

  @override
  String get staffHistory => 'Last 14 days';

  @override
  String get staffNoRows => 'No records in this period.';

  @override
  String staffWorked(String hours) {
    return 'Hours worked: $hours';
  }

  @override
  String get staffOnTime => 'On time';

  @override
  String get staffLate => 'Late';

  @override
  String get staffMissingCheckout => 'Missing check-out';

  @override
  String get staffInProgress => 'In progress';

  @override
  String get staffAbsent => 'Absent';

  @override
  String get staffLeave => 'On leave';

  @override
  String get staffUnscheduled => 'Unscheduled';

  @override
  String get staffUpcoming => 'Upcoming';

  @override
  String get staffRequests => 'Requests';

  @override
  String get staffNewLeave => 'Request leave';

  @override
  String get staffNewCorrection => 'Request a correction';

  @override
  String get staffKindLeave => 'Leave';

  @override
  String get staffKindCorrection => 'Correction';

  @override
  String get staffFromDate => 'From date';

  @override
  String get staffToDate => 'To date';

  @override
  String get staffCorrectDate => 'Day to correct';

  @override
  String get staffReason => 'Reason (3 to 500 characters)';

  @override
  String get staffCorrectIn => 'Correct clock-in time (optional)';

  @override
  String get staffCorrectOut => 'Correct clock-out time (optional)';

  @override
  String get staffPickTime => 'Pick time';

  @override
  String get staffSubmit => 'Submit request';

  @override
  String get staffSubmitted => 'Request submitted';

  @override
  String get staffNoRequests => 'No requests yet.';

  @override
  String get staffCancelRequest => 'Cancel request';

  @override
  String get staffCancelled => 'Request cancelled';

  @override
  String get staffStPending => 'Pending';

  @override
  String get staffStApproved => 'Approved';

  @override
  String get staffStRejected => 'Rejected';

  @override
  String get staffStCancelled => 'Cancelled';

  @override
  String staffDecisionNote(String note) {
    return 'Decision note: $note';
  }

  @override
  String get staffSelfNote =>
      'A supervisor decides your requests. You cannot approve your own.';

  @override
  String get staffNoSupervisor =>
      'No supervisor is assigned to you yet, so requests wait until an administrator assigns one.';

  @override
  String get staffNeedReason => 'Give a reason of at least 3 characters.';

  @override
  String get staffFixDates => 'Choose valid dates.';

  @override
  String get staffNeedTime => 'Give the correct clock-in or clock-out time.';

  @override
  String get staffManager => 'Supervisor tools';

  @override
  String get staffTeam => 'Team summary';

  @override
  String get staffNoTeam => 'You do not supervise anyone.';

  @override
  String get staffToDecide => 'Requests to decide';

  @override
  String get staffNoneToDecide => 'Nothing to decide.';

  @override
  String get staffApprove => 'Approve';

  @override
  String get staffReject => 'Reject';

  @override
  String get staffNoteOptional => 'Note (optional)';

  @override
  String get staffDecided => 'Decision saved';

  @override
  String staffTeamLine(
    String name,
    String onTime,
    String late,
    String missing,
    String absent,
  ) {
    return '$name: on time $onTime, late $late, missing check-out $missing, absent $absent';
  }

  @override
  String get demoTry => 'Try LearnPulse Demo';

  @override
  String get demoSelectorTitle => 'Try the demo';

  @override
  String get demoSelectorSub =>
      'Explore LearnPulse with no personal email and no password to type.';

  @override
  String get demoStudent => 'Student Demo';

  @override
  String get demoStudentText =>
      'Join a live workshop with a name and a join code. You get a temporary student account.';

  @override
  String get demoPresenter => 'Presenter Demo';

  @override
  String get demoPresenterText =>
      'For the presenter: start the workshop, show the QR code and manage the session.';

  @override
  String get demoRegularSignIn => 'Regular sign in';

  @override
  String get demoPresenterSignInSub =>
      'Sign in once. This device stays signed in, so you will not need to type your details again.';

  @override
  String get demoPresenterNeedsTeacher =>
      'Presenter controls need a Teacher account.';

  @override
  String get demoJoinTitle => 'Join the live workshop';

  @override
  String get demoJoinSub =>
      'Enter your name and the workshop code. It is deleted after the event.';

  @override
  String get demoCodeLabel => 'Workshop code';

  @override
  String get demoCodeHint =>
      'Shown on the presenter screen. It changes every minute.';

  @override
  String get demoNameLabel => 'Your name';

  @override
  String get demoNameHint => 'Shown to the presenter. Up to 40 characters.';

  @override
  String get demoJoinButton => 'Join Demo';

  @override
  String get demoJoining => 'Getting your seat…';

  @override
  String get demoSigningIn => 'Signing you in…';

  @override
  String get demoWaiting =>
      'Many people are joining at once. Trying again in a moment…';

  @override
  String get demoScan => 'Scan QR code';

  @override
  String get demoScanHint =>
      'Point the camera at the QR code on the presenter screen.';

  @override
  String get demoCameraProblem =>
      'The camera is not available. Type the code instead.';

  @override
  String get demoMsgBadCode => 'Enter the 12-character workshop code.';

  @override
  String get demoMsgBadName => 'Use 1–40 characters without < or >.';

  @override
  String get demoMsgInvalid =>
      'This code is not valid, has expired, or the demo has not started yet. Check the presenter\'s screen.';

  @override
  String get demoMsgClosed => 'Joining is closed for this workshop.';

  @override
  String get demoMsgFull => 'All seats are taken.';

  @override
  String get demoMsgBusy => 'Too many attempts. Wait a minute and try again.';

  @override
  String get demoMsgSignedIn => 'You are already signed in. Sign out first.';

  @override
  String get demoMsgAlready =>
      'This device already joined. Credentials are shown only once.';

  @override
  String get demoMsgAuthFailed =>
      'Your seat is reserved, but sign-in did not finish. Press Join again to get the same seat.';

  @override
  String get demoMsgRateBusy =>
      'Sign-in is very busy right now. Press Join again in a few seconds.';

  @override
  String get demoMsgExpired => 'This workshop session has ended.';

  @override
  String get demoMsgNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get demoMsgFailed => 'Something went wrong. Please try again.';

  @override
  String get demoHostTitle => 'Live demo host';

  @override
  String get demoHostNone => 'No live demo found for this account.';

  @override
  String get demoHostTooltip => 'Live demo';

  @override
  String get demoStatusReady => 'Ready to start';

  @override
  String get demoStatusOpen => 'Open';

  @override
  String get demoStatusPaused => 'Paused';

  @override
  String get demoStatusClosed => 'Joining closed';

  @override
  String get demoStatusEnded => 'Ended';

  @override
  String demoReadyText(int join, String life) {
    return 'The prepared workshop is ready. Starting it opens joining for $join minutes and ends the session $life hours later. This cannot be paused or undone.';
  }

  @override
  String get demoStart => 'Start Demo';

  @override
  String demoStartConfirm(int join, String life) {
    return 'Start the live demo now? Joining stays open for $join minutes and the session ends $life hours after you start.';
  }

  @override
  String get demoEnd => 'End Demo';

  @override
  String get demoEndConfirm =>
      'End the demo? Everyone loses access to the workshop immediately.';

  @override
  String get demoPause => 'Pause joining';

  @override
  String get demoResume => 'Resume joining';

  @override
  String get demoCloseJoins => 'Close joining';

  @override
  String demoJoinsLeft(String time) {
    return 'Joining closes in $time';
  }

  @override
  String demoLifeLeft(String time) {
    return 'Session ends in $time';
  }

  @override
  String get demoJoinWindowOver => 'The joining window has ended.';

  @override
  String get demoCopyCode => 'Copy code';

  @override
  String get demoCopyLink => 'Copy link';

  @override
  String get demoCopied => 'Copied';

  @override
  String get demoProjectHint =>
      'Show this QR code on the projector. Attendees scan it with the phone camera.';

  @override
  String demoCodeExpires(int seconds) {
    return 'New code in ${seconds}s';
  }

  @override
  String get demoSeatsTotal => 'Total seats';

  @override
  String get demoSeatsAvailable => 'Available';

  @override
  String get demoSeatsClaimed => 'Claimed';

  @override
  String get demoSeatsActive => 'Active';

  @override
  String demoRecent(int claims, int refused) {
    return 'Last 10 minutes: $claims joined, $refused refused';
  }

  @override
  String get demoEndedNotice => 'This demo session has ended.';

  @override
  String get demoOpenWorkshop => 'Open the workshop';

  @override
  String get demoBack => 'Back';
}
