// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get commonCancel => 'ยกเลิก';

  @override
  String get commonSave => 'บันทึก';

  @override
  String get commonClose => 'ปิด';

  @override
  String get commonDelete => 'ลบ';

  @override
  String get commonConfirm => 'ยืนยัน';

  @override
  String get commonBack => 'ย้อนกลับ';

  @override
  String get commonTryAgain => 'ลองอีกครั้ง';

  @override
  String get commonTryingAgain => 'กำลังลองอีกครั้ง…';

  @override
  String get commonLoading => 'กำลังโหลด';

  @override
  String get commonStillWorking => 'ยังทำงานอยู่… ใช้เวลานานกว่าปกติ';

  @override
  String get commonSignOut => 'ออกจากระบบ';

  @override
  String get commonSignInAgain => 'เข้าสู่ระบบอีกครั้ง';

  @override
  String get commonNoDataYet => 'ยังไม่มีข้อมูล';

  @override
  String get commonUnknown => 'ไม่ทราบ';

  @override
  String get configErrorTitle => 'การตั้งค่าผิดพลาด';

  @override
  String get navDashboard => 'แดชบอร์ด';

  @override
  String get navTasks => 'งานของฉัน';

  @override
  String get navCourses => 'รายวิชา';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get navOpenProfile => 'เปิดโปรไฟล์';

  @override
  String get homeNameFallback => 'คุณ';

  @override
  String get relativeToday => 'วันนี้';

  @override
  String get relativeTomorrow => 'พรุ่งนี้';

  @override
  String get relativeYesterday => 'เมื่อวานนี้';

  @override
  String get roleTeacher => 'ครู';

  @override
  String get roleStudent => 'นักเรียน';

  @override
  String get languageTitle => 'ภาษา';

  @override
  String get languageHint =>
      'บันทึกไว้ในอุปกรณ์นี้เท่านั้น ภาษาไม่เปลี่ยนกำหนดส่ง กำหนดการ หรือเขตเวลา';

  @override
  String get languageSelectorLabel => 'เลือกภาษา';

  @override
  String get authPortalEyebrow => 'พอร์ทัลการเรียนการสอน LEARNPULSE';

  @override
  String get authWelcomeTitle => 'ยินดีต้อนรับสู่\nLearnPulse';

  @override
  String get authTagline =>
      'รายวิชา งานที่มอบหมาย และการเข้าเรียน การเรียนรู้ของคุณ ไปด้วยกัน';

  @override
  String get authSignIn => 'เข้าสู่ระบบ';

  @override
  String get authEmail => 'อีเมล';

  @override
  String get authPassword => 'รหัสผ่าน';

  @override
  String get authShowPassword => 'แสดงรหัสผ่าน';

  @override
  String get authHidePassword => 'ซ่อนรหัสผ่าน';

  @override
  String get authForgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get authCreateStudentAccount => 'สร้างบัญชีนักเรียน';

  @override
  String get authCreateYourAccount => 'สร้างบัญชีของคุณ';

  @override
  String get authFullName => 'ชื่อ-นามสกุล';

  @override
  String get authPasswordHelper =>
      'อย่างน้อย 10 ตัวอักษร มีตัวพิมพ์ใหญ่ ตัวพิมพ์เล็ก และตัวเลข';

  @override
  String get authTeacherNote =>
      'สำหรับครู: ใช้ที่อยู่อีเมลที่ได้รับคำเชิญ โรงเรียนจะกำหนดบทบาทของคุณหลังจากที่คุณยืนยันอีเมล';

  @override
  String get authCreateAccount => 'สร้างบัญชี';

  @override
  String get authHaveAccount => 'ฉันมีบัญชีอยู่แล้ว';

  @override
  String get authResetTitle => 'ตั้งรหัสผ่านใหม่';

  @override
  String get authSendResetLink => 'ส่งลิงก์ตั้งรหัสผ่านใหม่';

  @override
  String get authBackToSignIn => 'กลับไปหน้าเข้าสู่ระบบ';

  @override
  String get authCheckEmailTitle => 'ตรวจสอบอีเมลของคุณ';

  @override
  String get authYourEmailAddress => 'อีเมลของคุณ';

  @override
  String authConfirmSent(String email) {
    return 'เราส่งลิงก์ยืนยันไปที่ $email แล้ว เปิดลิงก์บนโทรศัพท์เครื่องนี้เพื่อเข้าสู่ระบบให้เสร็จสมบูรณ์';
  }

  @override
  String get authResendEmail => 'ส่งอีเมลอีกครั้ง';

  @override
  String authResendEmailIn(int seconds) {
    return 'ส่งอีเมลอีกครั้งใน $seconds วินาที';
  }

  @override
  String get authConfirmedSignIn => 'ฉันยืนยันแล้ว - เข้าสู่ระบบ';

  @override
  String get authNewPasswordTitle => 'เลือกรหัสผ่านใหม่';

  @override
  String get authNewPassword => 'รหัสผ่านใหม่';

  @override
  String get authSavePassword => 'บันทึกรหัสผ่าน';

  @override
  String get authSessionExpiredTitle => 'เซสชันหมดอายุ';

  @override
  String get authSignedOutTitle => 'คุณถูกออกจากระบบ';

  @override
  String get authSessionEnded =>
      'เพื่อความปลอดภัย เซสชันของคุณสิ้นสุดลง เข้าสู่ระบบอีกครั้งเพื่อทำต่อจากเดิม';

  @override
  String get authCantReach => 'เชื่อมต่อ LearnPulse ไม่ได้';

  @override
  String get authAccountNotReady => 'บัญชียังไม่พร้อมใช้งาน';

  @override
  String noticeConfirmationSent(String email) {
    return 'ส่งอีเมลยืนยันไปที่ $email แล้ว';
  }

  @override
  String get noticeResetSent =>
      'หากมีบัญชีสำหรับที่อยู่อีเมลนั้น เราได้ส่งลิงก์ตั้งรหัสผ่านใหม่ไปแล้ว';

  @override
  String get noticePasswordUpdated => 'อัปเดตรหัสผ่านแล้ว';

  @override
  String get noticeNameSaved => 'บันทึกชื่อที่แสดงแล้ว';

  @override
  String noticePasswordLinkSent(String email) {
    return 'ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่ $email แล้ว';
  }

  @override
  String get errorNetwork =>
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบเครือข่ายแล้วลองอีกครั้ง';

  @override
  String get errorTimeout =>
      'เซิร์ฟเวอร์ตอบสนองช้าเกินไป โปรดลองอีกครั้งในอีกสักครู่';

  @override
  String get errorInvalidCredentials => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get errorEmailNotConfirmed => 'โปรดยืนยันอีเมลของคุณก่อน';

  @override
  String get errorRateLimited =>
      'พยายามหลายครั้งเกินไป โปรดรอสักครู่แล้วลองอีกครั้ง';

  @override
  String get errorRateLimitedLong =>
      'พยายามหลายครั้งเกินไป โปรดรอสักสองสามนาทีแล้วลองอีกครั้ง';

  @override
  String get errorWeakPassword =>
      'โปรดตั้งรหัสผ่านที่คาดเดายากขึ้น (อย่างน้อย 10 ตัวอักษร มีตัวพิมพ์ใหญ่ ตัวพิมพ์เล็ก และตัวเลข)';

  @override
  String get errorSignupDisabled => 'ขณะนี้ปิดรับการสมัครสมาชิก';

  @override
  String get errorFileForbidden => 'คุณไม่มีสิทธิ์อัปโหลดหรือเปิดไฟล์นี้';

  @override
  String get errorFileTooLarge => 'ไฟล์ใหญ่เกินไป (ไม่เกิน 10 MB)';

  @override
  String get errorFileType => 'ไม่อนุญาตให้ใช้ไฟล์ประเภทนี้';

  @override
  String get errorForbidden => 'คุณไม่มีสิทธิ์ทำรายการนี้';

  @override
  String get errorCourseNotFound =>
      'ไม่พบรายวิชานี้ หรือคุณไม่มีสิทธิ์เข้าถึงอีกต่อไป';

  @override
  String get errorValidation => 'โปรดตรวจสอบข้อมูลแล้วลองอีกครั้ง';

  @override
  String get errorSessionExpired =>
      'เซสชันของคุณหมดอายุ โปรดเข้าสู่ระบบอีกครั้ง';

  @override
  String get errorUnknown => 'เกิดข้อผิดพลาดบางอย่าง โปรดลองอีกครั้ง';

  @override
  String get errorNotSignedIn => 'คุณยังไม่ได้เข้าสู่ระบบ';

  @override
  String get errorNameNotSaved => 'ไม่สามารถบันทึกชื่อของคุณได้';

  @override
  String get errorProfileNotReady =>
      'บัญชีของคุณยังไม่พร้อมใช้งาน โปรดลองอีกครั้งในอีกสักครู่';

  @override
  String get stateOfflineTitle => 'คุณออฟไลน์อยู่';

  @override
  String get stateOfflineMessage =>
      'ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง ข้อมูลที่คุณบันทึกไว้แล้วปลอดภัย';

  @override
  String get stateTimeoutTitle => 'ใช้เวลานานเกินไป';

  @override
  String get stateTimeoutMessage =>
      'การเชื่อมต่อดูเหมือนจะช้า ลองอีกครั้ง หรือย้ายไปที่ที่สัญญาณดีกว่า';

  @override
  String get stateExpiredTitle => 'เซสชันหมดอายุ';

  @override
  String get stateExpiredMessage =>
      'เพื่อความปลอดภัย คุณถูกออกจากระบบ เข้าสู่ระบบอีกครั้งเพื่อทำต่อ';

  @override
  String get stateForbiddenTitle => 'ไม่มีสิทธิ์เข้าถึง';

  @override
  String get stateForbiddenMessage => 'บัญชีของคุณไม่มีสิทธิ์เปิดรายการนี้';

  @override
  String get stateNotFoundTitle => 'ไม่พบรายการ';

  @override
  String get stateNotFoundMessage =>
      'รายการนี้อาจถูกลบไปแล้ว หรือคุณอาจไม่มีสิทธิ์เข้าถึงอีกต่อไป';

  @override
  String get stateConflictTitle => 'ข้อมูลนี้ถูกเปลี่ยนที่อื่น';

  @override
  String get stateConflictMessage =>
      'รีเฟรชเพื่อดูเวอร์ชันล่าสุด แล้วลองอีกครั้ง';

  @override
  String get stateUnknownTitle => 'โหลดข้อมูลนี้ไม่สำเร็จ';

  @override
  String get stateUnknownMessage => 'เกิดเหตุการณ์ที่ไม่คาดคิด โปรดลองอีกครั้ง';

  @override
  String stateCouldNotRefresh(String message) {
    return 'รีเฟรชไม่สำเร็จ: $message กำลังแสดงตัวเลขที่โหลดไว้ล่าสุด';
  }

  @override
  String get validationEmailRequired => 'กรอกที่อยู่อีเมลของคุณ';

  @override
  String get validationEmailInvalid => 'กรอกที่อยู่อีเมลให้ถูกต้อง';

  @override
  String get validationPasswordRequired => 'กรอกรหัสผ่านของคุณ';

  @override
  String get validationPasswordShort => 'ใช้อย่างน้อย 10 ตัวอักษร';

  @override
  String get validationPasswordMix =>
      'ต้องมีตัวพิมพ์ใหญ่ ตัวพิมพ์เล็ก และตัวเลข';

  @override
  String get validationNameRequired => 'กรอกชื่อของคุณ';

  @override
  String get validationNameLong => 'ชื่อยาวเกินไป';

  @override
  String get profileTeachingSummary => 'สรุปการสอน';

  @override
  String get profileLearningSummary => 'สรุปการเรียน';

  @override
  String get profileTeachingSubtitle => 'รายวิชาของคุณ ผลลัพธ์ของคุณ';

  @override
  String get profileLearningSubtitle => 'ภาพรวมที่ชัดเจนว่าคุณเรียนเป็นอย่างไร';

  @override
  String get profileTeachingIdentity => 'ตัวตนผู้สอนของคุณ';

  @override
  String get profileLearningIdentity => 'ตัวตนผู้เรียนของคุณ';

  @override
  String get profileNoName => 'ยังไม่ได้ตั้งชื่อ';

  @override
  String get profileAccountSettings => 'บัญชีและการตั้งค่า';

  @override
  String get profileCoursesRosters => 'รายวิชาและรายชื่อนักเรียนของฉัน';

  @override
  String get profileCoursesAttendance => 'รายวิชาและการเข้าเรียนของฉัน';

  @override
  String get metricCoursesOwned => 'รายวิชาที่ดูแล';

  @override
  String metricArchived(int count) {
    return 'เก็บถาวร $count รายวิชา';
  }

  @override
  String get metricActiveStudents => 'นักเรียนที่ใช้งานอยู่';

  @override
  String get metricAwaitingGrading => 'รอการให้คะแนน';

  @override
  String get metricAttendanceRate => 'อัตราการเข้าเรียน';

  @override
  String metricOpenSessions(int count) {
    return 'เปิดอยู่ $count คาบ';
  }

  @override
  String get metricTeacherNote =>
      'ตัวเลขนับเฉพาะรายวิชาที่คุณดูแลอยู่และนักเรียนที่ใช้งานอยู่ในรายวิชาเหล่านั้น';

  @override
  String get metricEnrolledCourses => 'รายวิชาที่ลงทะเบียน';

  @override
  String get metricAssignmentsDone => 'งานที่ทำเสร็จ';

  @override
  String metricDoneOfPublished(int done, int published) {
    return '$done จาก $published';
  }

  @override
  String get metricSubmittedOrGraded => 'ส่งแล้วหรือตรวจแล้ว';

  @override
  String get metricAwaitingGrade => 'รอคะแนน';

  @override
  String get metricGraded => 'ตรวจแล้ว';

  @override
  String get metricNoGradesYet => 'ยังไม่มีคะแนน';

  @override
  String metricAverage(String value) {
    return 'เฉลี่ย $value';
  }

  @override
  String get metricReturnedRevision => 'ส่งกลับให้แก้ไข';

  @override
  String get metricStudentNote =>
      'ทำเสร็จ = ส่งแล้วหรือตรวจแล้ว จากงานที่เผยแพร่ในรายวิชาที่คุณเรียนอยู่ การเข้าเรียน = (มา + สาย) / (มา + สาย + ขาด) ระบบไม่ติดตามการเรียนบทเรียนจบ';

  @override
  String get accountTitle => 'บัญชี';

  @override
  String get accountRegisteredEmail => 'อีเมลที่ลงทะเบียน';

  @override
  String get accountRole => 'บทบาท';

  @override
  String get accountManagedNote =>
      'อีเมลและบทบาทของคุณจัดการโดยผู้ดูแลระบบของโรงเรียน และเปลี่ยนในแอปไม่ได้';

  @override
  String get accountPassword => 'รหัสผ่าน';

  @override
  String get accountEmailResetLink => 'ส่งลิงก์ตั้งรหัสผ่านใหม่ให้ทางอีเมล';

  @override
  String get accountPrivacy => 'ความเป็นส่วนตัวและความปลอดภัย';

  @override
  String get accountPrivacyText =>
      'ครูเห็นเฉพาะนักเรียนที่ลงทะเบียนในรายวิชาของตนเอง นักเรียนเห็นเฉพาะงานของตนเองและครูผู้สอนในรายวิชา ข้อมูลของคุณไม่เป็นสาธารณะ และไม่มีสมุดรายชื่อสาธารณะ ไฟล์เป็นส่วนตัวและเปิดได้ผ่านลิงก์อายุสั้นเท่านั้น';

  @override
  String get accountAbout => 'เกี่ยวกับ';

  @override
  String accountVersion(String version) {
    return 'เวอร์ชัน $version (เบต้า)';
  }

  @override
  String get accountSignOutTitle => 'ออกจากระบบหรือไม่?';

  @override
  String get accountSignOutBody =>
      'คุณต้องเข้าสู่ระบบอีกครั้งเพื่อใช้ LearnPulse';

  @override
  String get accountEyebrow => 'โปรไฟล์';

  @override
  String get accountDescription =>
      'จัดการตัวตน การเข้าถึงบัญชี และความเป็นส่วนตัวของคุณ';

  @override
  String get accountPersonalDetails => 'ข้อมูลส่วนตัว';

  @override
  String get accountDisplayName => 'ชื่อที่แสดง';

  @override
  String get accountSaveName => 'บันทึกชื่อ';

  @override
  String get commonAll => 'ทั้งหมด';

  @override
  String get commonActive => 'ใช้งานอยู่';

  @override
  String get commonArchived => 'เก็บถาวร';

  @override
  String get commonDraft => 'ฉบับร่าง';

  @override
  String get commonPublished => 'เผยแพร่แล้ว';

  @override
  String get commonPublish => 'เผยแพร่';

  @override
  String get commonCreate => 'สร้าง';

  @override
  String get commonTitle => 'ชื่อเรื่อง';

  @override
  String get commonCopy => 'คัดลอก';

  @override
  String get commonDone => 'เสร็จสิ้น';

  @override
  String get commonJoin => 'เข้าร่วม';

  @override
  String get commonRemove => 'นำออก';

  @override
  String get commonChange => 'เปลี่ยน';

  @override
  String get commonOpen => 'เปิด';

  @override
  String get commonClosed => 'ปิด';

  @override
  String get commonAttendance => 'การเข้าเรียน';

  @override
  String get commonAssignments => 'งาน';

  @override
  String get commonLessons => 'บทเรียน';

  @override
  String get commonFiles => 'ไฟล์';

  @override
  String commonRemoveNamed(String name) {
    return 'นำ $name ออก';
  }

  @override
  String commonOpenNamed(String name) {
    return 'เปิด $name';
  }

  @override
  String get statusSubmitted => 'ส่งงานแล้ว';

  @override
  String get statusReturned => 'ส่งคืนแล้ว';

  @override
  String get statusToGrade => 'รอให้คะแนน';

  @override
  String get attPresent => 'มาเรียน';

  @override
  String get attLate => 'มาสาย';

  @override
  String get attExcused => 'ลา';

  @override
  String get attAbsent => 'ขาดเรียน';

  @override
  String get validationTitleRequired => 'กรอกชื่อเรื่อง';

  @override
  String get validationTitleLong => 'ใช้ได้ไม่เกิน 120 ตัวอักษร';

  @override
  String get validationMaxScoreRange => 'กรอกตัวเลขตั้งแต่ 1 ถึง 1000';

  @override
  String get validationJoinCodeRequired => 'กรอกรหัสรายวิชา';

  @override
  String get validationJoinCodeFormat =>
      'รหัสมี 8 ตัวอักษร/ตัวเลข (ไม่มี I, O, 0 หรือ 1)';

  @override
  String get errorScoreWhole => 'กรอกจำนวนเต็ม';

  @override
  String errorScoreRange(int max) {
    return 'คะแนนต้องอยู่ระหว่าง 0 ถึง $max';
  }

  @override
  String get errorFeedbackLong => 'ข้อเสนอแนะยาวเกินไป (สูงสุด 5000 ตัวอักษร)';

  @override
  String get errorReturnReason => 'อธิบายสิ่งที่นักเรียนต้องแก้ไข';

  @override
  String get errorFileLarger => 'ไฟล์นี้ใหญ่เกิน 10 MB';

  @override
  String get errorFileEmpty => 'ไฟล์นี้ว่างเปล่า';

  @override
  String get errorWriteOrAttach => 'เขียนคำตอบหรือแนบไฟล์';

  @override
  String get errorUploadIncomplete =>
      'อัปโหลดไฟล์ไม่เสร็จสมบูรณ์ แตะส่งงานเพื่อลองอีกครั้ง';

  @override
  String get errorSubmissionChanged =>
      'งานที่ส่งของคุณถูกเปลี่ยนแปลงจากอุปกรณ์อื่น โหลดใหม่เพื่อดำเนินการต่อ ข้อความของคุณยังอยู่';

  @override
  String get errorGradeConflict =>
      'งานที่ส่งนี้ถูกเปลี่ยนแปลง (เช่น นักเรียนส่งใหม่) โหลดใหม่เพื่อดูล่าสุด คะแนนและข้อเสนอแนะที่คุณพิมพ์ไว้ยังอยู่';

  @override
  String get errorFileNoAccess => 'คุณไม่มีสิทธิ์เข้าถึงไฟล์นี้';

  @override
  String get errorFileTypeList =>
      'ไม่อนุญาตไฟล์ประเภทนี้ ใช้ pdf, docx, zip, png, jpg, webp หรือ txt';

  @override
  String get errorOpenFile => 'เปิดไฟล์ไม่สำเร็จ';

  @override
  String noticeJoinedCourse(String title) {
    return 'เข้าร่วม $title แล้ว';
  }

  @override
  String get noticeTheCourse => 'รายวิชา';

  @override
  String get noticeSubmissionSaved => 'บันทึกงานที่ส่งแล้ว';

  @override
  String get noticeGradeSaved => 'บันทึกคะแนนแล้ว';

  @override
  String get noticeReturnedForRevision => 'ส่งคืนให้นักเรียนแก้ไขแล้ว';

  @override
  String dashHello(String name) {
    return 'สวัสดี $name';
  }

  @override
  String dashActiveCourses(int count) {
    return '$count รายวิชาที่ใช้งานอยู่';
  }

  @override
  String dashTeacherHeroDetail(String courses, int grading) {
    return '$courses · รอให้คะแนน $grading';
  }

  @override
  String dashStudentHeroDetail(String courses, int done, int published) {
    return '$courses · ทำงานเสร็จ $done จาก $published';
  }

  @override
  String get dashStatCourses => 'รายวิชา';

  @override
  String get dashStatToGrade => 'รอให้คะแนน';

  @override
  String get dashStatStudents => 'นักเรียน';

  @override
  String get dashStatDone => 'เสร็จแล้ว';

  @override
  String get dashServices => 'บริการด้านการเรียน';

  @override
  String get dashServiceGrading => 'การให้คะแนน';

  @override
  String get dashServiceProfile => 'โปรไฟล์ของฉัน';

  @override
  String get dashServiceProfileDetail => 'ความก้าวหน้าและบัญชี';

  @override
  String dashDetailActive(int count) {
    return '$count ที่ใช้งานอยู่';
  }

  @override
  String dashDetailToReview(int count) {
    return '$count รอตรวจ';
  }

  @override
  String dashDetailOpen(int count) {
    return 'เปิดอยู่ $count';
  }

  @override
  String dashDetailEnrolled(int count) {
    return 'ลงทะเบียน $count';
  }

  @override
  String dashDetailPublished(int count) {
    return 'เผยแพร่แล้ว $count';
  }

  @override
  String get dashEmptyTeacherTitle => 'ยังไม่มีข้อมูลให้แสดง';

  @override
  String get dashEmptyTeacherHint =>
      'สร้างรายวิชาในแท็บรายวิชา หน้านี้จะมีข้อมูลเพิ่มขึ้นเมื่อนักเรียนเข้าร่วม ส่งงาน และเข้าเรียน';

  @override
  String get dashNeedsAttention => 'ต้องดูแล';

  @override
  String get dashAllCaughtUp => 'ไม่มีงานค้าง';

  @override
  String dashSubmissionsAwaiting(int count) {
    return '$count งานที่ส่งรอให้คะแนน';
  }

  @override
  String dashSubmittedLine(int received, int expected, String rate) {
    return 'ส่งแล้ว $received จาก $expected · การเข้าเรียน $rate';
  }

  @override
  String get dashReviewSubmissions => 'ตรวจงานที่ส่ง';

  @override
  String get dashUpcomingDeadlines => 'กำหนดส่งที่ใกล้ถึง';

  @override
  String get dashNoDeadlines => 'ไม่มีกำหนดส่งที่ใกล้ถึง';

  @override
  String get dashNothingDueSoon => 'ไม่มีงานที่ใกล้ครบกำหนด';

  @override
  String get dashRecentSubmissions => 'งานที่ส่งล่าสุด';

  @override
  String get dashNoSubmissions => 'ยังไม่มีงานที่ส่ง';

  @override
  String dashArchivedStudents(String students) {
    return 'เก็บถาวร · $students';
  }

  @override
  String dashCountStudents(int count) {
    return '$count นักเรียน';
  }

  @override
  String dashCountAssignments(int count) {
    return '$count งาน';
  }

  @override
  String dashCountSessions(int count) {
    return '$count คาบเรียน';
  }

  @override
  String dashToGradeCount(int count) {
    return 'รอให้คะแนน $count';
  }

  @override
  String get dashAllFigures => 'ตัวเลขทั้งหมด';

  @override
  String get dashActiveCoursesLabel => 'รายวิชาที่ใช้งานอยู่';

  @override
  String get dashOutstanding => 'งานที่ยังค้าง';

  @override
  String dashSubmittedOf(int received, int expected) {
    return 'ส่งแล้ว $received จาก $expected';
  }

  @override
  String get dashPublishedAssignments => 'งานที่เผยแพร่แล้ว';

  @override
  String dashGradedReturned(int graded, int returned) {
    return 'ให้คะแนนแล้ว $graded · ส่งคืน $returned';
  }

  @override
  String get dashTeacherFootnote =>
      'นับเฉพาะนักเรียนที่ยังใช้งานอยู่ รายวิชาที่เก็บถาวรไม่รวมในตัวเลขงานและการเข้าเรียน อัตราการเข้าเรียน = (มาเรียน + มาสาย) ÷ (มาเรียน + มาสาย + ขาดเรียน) ไม่นับการลา';

  @override
  String get dashEmptyStudentTitle => 'ยังไม่มีรายวิชา';

  @override
  String get dashEmptyStudentHint =>
      'เปิดแท็บรายวิชาแล้วกรอกรหัสเข้าร่วมจากครูของคุณ';

  @override
  String get dashNeedsYourAttention => 'ต้องการความสนใจจากคุณ';

  @override
  String get dashYourNextStep => 'ขั้นตอนถัดไปของคุณ';

  @override
  String dashOverdueCount(int count) {
    return 'งานเลยกำหนด $count รายการ';
  }

  @override
  String get dashReadyToLearn => 'พร้อมเรียนหรือยัง';

  @override
  String get dashExploreCourses => 'ดูรายวิชาของคุณและเรียนต่อจากที่ค้างไว้';

  @override
  String get dashOpenCourses => 'เปิดรายวิชา';

  @override
  String get dashStatusRevise => 'แก้ไข';

  @override
  String get dashStatusTodo => 'ต้องทำ';

  @override
  String get dashLearningProgress => 'ความก้าวหน้าในการเรียน';

  @override
  String dashDoneOfPublished(int done, int published) {
    return 'ทำงานเสร็จ $done จาก $published';
  }

  @override
  String dashAttendanceValue(String value) {
    return 'การเข้าเรียน $value';
  }

  @override
  String get dashMyCourses => 'รายวิชาของฉัน';

  @override
  String get dashArchivedReadOnly => 'เก็บถาวร (อ่านอย่างเดียว)';

  @override
  String dashCourseProgressLine(int done, int total, String rate) {
    return 'ทำงานเสร็จ $done จาก $total · การเข้าเรียน $rate';
  }

  @override
  String get dashRecentResults => 'ผลล่าสุด';

  @override
  String get dashNoGraded => 'ยังไม่มีงานที่ให้คะแนน';

  @override
  String get dashFeedbackAvailable => 'มีข้อเสนอแนะ';

  @override
  String get dashNewLessons => 'บทเรียนใหม่';

  @override
  String get dashNotStarted => 'ยังไม่เริ่ม';

  @override
  String dashOverdueHint(int count) {
    return 'เลยกำหนด $count';
  }

  @override
  String get dashNeedsRevision => 'ต้องแก้ไข';

  @override
  String get dashStudentFootnote =>
      'ความก้าวหน้าของรายวิชา = งานที่ส่งหรือให้คะแนนแล้ว ÷ งานที่เผยแพร่ งานที่ถูกส่งคืนยังไม่ถือว่าเสร็จจนกว่าคุณจะส่งอีกครั้ง ระบบไม่ติดตามว่าบทเรียนเรียนจบแล้ว';

  @override
  String get dashNothingToShow => 'ยังไม่มีข้อมูลให้แสดง';

  @override
  String get courseEyebrowTeaching => 'การสอน';

  @override
  String get courseEyebrowLearning => 'การเรียนของฉัน';

  @override
  String get courseYourCourses => 'รายวิชาของคุณ';

  @override
  String get courseDescTeacher =>
      'จัดการบทเรียน งาน และการเข้าเรียนในแต่ละรายวิชา';

  @override
  String get courseDescStudent => 'เปิดรายวิชาเพื่อเรียนบทเรียนและทำงานต่อ';

  @override
  String get courseNew => 'สร้างรายวิชาใหม่';

  @override
  String get courseJoin => 'เข้าร่วมรายวิชา';

  @override
  String get courseServiceLabel => 'บริการของรายวิชา';

  @override
  String get courseAllContent => 'เนื้อหารายวิชาทั้งหมด';

  @override
  String get courseNoInCategory => 'ไม่มีรายวิชาในหมวดนี้ โปรดเลือกตัวกรองอื่น';

  @override
  String courseCouldNotRefresh(String message) {
    return 'รีเฟรชไม่สำเร็จ: $message';
  }

  @override
  String get courseEmptyTeacherTitle => 'ยังไม่มีรายวิชา';

  @override
  String get courseEmptyTeacherHint =>
      'สร้างรายวิชาแรกของคุณ แล้วแชร์รหัสให้นักเรียน';

  @override
  String get courseEmptyStudentTitle => 'คุณยังไม่ได้เข้าร่วมรายวิชา';

  @override
  String get courseEmptyStudentHint =>
      'ขอรหัสรายวิชาจากครูของคุณ แล้วแตะ \"เข้าร่วมรายวิชา\"';

  @override
  String get courseAreaTeachingAssignments => 'การสอน · งาน';

  @override
  String get courseAreaLearningAssignments => 'การเรียน · งาน';

  @override
  String get courseAreaTeachingAttendance => 'การสอน · การเข้าเรียน';

  @override
  String get courseAreaLearningAttendance => 'การเรียน · การเข้าเรียน';

  @override
  String get courseTapToManage => 'แตะเพื่อจัดการ';

  @override
  String courseTeacherName(String name) {
    return 'ครู: $name';
  }

  @override
  String get courseTeachingCourse => 'รายวิชาที่สอน';

  @override
  String get courseEnrolledCourse => 'รายวิชาที่ลงทะเบียน';

  @override
  String get courseTeachingWorkspace => 'พื้นที่การสอนของคุณ';

  @override
  String get courseLearningWorkspace => 'พื้นที่การเรียนของคุณ';

  @override
  String get courseManage => 'จัดการรายวิชา';

  @override
  String get courseOpen => 'เปิดรายวิชา';

  @override
  String get courseLearningEyebrow => 'พื้นที่การเรียน';

  @override
  String get courseArchivedNote =>
      'รายวิชานี้เก็บถาวรแล้ว ยังมองเห็นได้แต่อ่านได้อย่างเดียว';

  @override
  String get courseEdit => 'แก้ไขรายวิชา';

  @override
  String get courseDescriptionOptional => 'คำอธิบาย (ไม่บังคับ)';

  @override
  String get courseCreated => 'สร้างรายวิชาแล้ว';

  @override
  String get courseShareCode => 'แชร์รหัสนี้ให้นักเรียนของคุณ:';

  @override
  String get courseCodeLabel => 'รหัสรายวิชา';

  @override
  String get courseRemovedMsg =>
      'คุณถูกนำออกจากรายวิชานี้แล้ว โปรดขอให้ครูเพิ่มคุณอีกครั้ง';

  @override
  String get courseCodeInvalid => 'รหัสไม่ถูกต้อง หรือรายวิชาปิดแล้ว';

  @override
  String get courseArchiveTitle => 'เก็บถาวรรายวิชานี้?';

  @override
  String get courseReopenTitle => 'เปิดรายวิชานี้อีกครั้ง?';

  @override
  String get courseArchiveBody =>
      'นักเรียนยังดูได้อย่างเดียว แต่ผู้อื่นจะเข้าร่วมด้วยรหัสไม่ได้';

  @override
  String get courseReopenBody => 'นักเรียนจะเข้าร่วมด้วยรหัสได้อีกครั้ง';

  @override
  String get courseArchiveAction => 'เก็บถาวร';

  @override
  String get courseReopenAction => 'เปิดอีกครั้ง';

  @override
  String get courseRemoveTitle => 'นำนักเรียนออก?';

  @override
  String courseRemoveBody(String name) {
    return '$name จะเข้ารายวิชานี้ไม่ได้และไม่สามารถเข้าร่วมใหม่ด้วยรหัสได้';
  }

  @override
  String get courseThisStudent => 'นักเรียนคนนี้';

  @override
  String get courseInviteTitle => 'เชิญนักเรียนกลุ่มแรกของคุณ';

  @override
  String get courseInviteBody =>
      'แชร์รหัสเข้าร่วมด้านล่าง การเข้าเรียน การให้คะแนน และความก้าวหน้าจะแสดงเมื่อนักเรียนเข้าร่วม';

  @override
  String get courseSvcSubmissions => 'งานที่ส่ง';

  @override
  String get courseSvcReviewWork => 'ตรวจงาน';

  @override
  String get courseSvcRoster => 'รายชื่อ';

  @override
  String get courseSvcContent => 'เนื้อหา';

  @override
  String get courseWeeklyAttendance => 'การเข้าเรียนรายสัปดาห์';

  @override
  String get courseAdmin => 'การจัดการรายวิชา';

  @override
  String get courseJoinCode => 'รหัสเข้าร่วม';

  @override
  String get courseCopyCode => 'คัดลอกรหัส';

  @override
  String get courseCodeCopied => 'คัดลอกรหัสแล้ว';

  @override
  String get courseArchivedNoJoin =>
      'เก็บถาวรแล้ว: นักเรียนเข้าร่วมไม่ได้จนกว่าคุณจะเปิดรายวิชาอีกครั้ง';

  @override
  String get courseReopenCourse => 'เปิดรายวิชาอีกครั้ง';

  @override
  String get courseArchiveCourse => 'เก็บถาวรรายวิชา';

  @override
  String courseStudentsTitle(int count) {
    return 'นักเรียน ($count)';
  }

  @override
  String get courseNoStudents => 'ยังไม่มีนักเรียน แชร์รหัสเข้าร่วมด้านบน';

  @override
  String courseJoinedTap(String date) {
    return 'เข้าร่วมเมื่อ $date · แตะเพื่อดูความก้าวหน้า';
  }

  @override
  String courseRemovedCount(int count) {
    return 'นำนักเรียนออกแล้ว $count คน (ไม่มีสิทธิ์เข้าถึง)';
  }

  @override
  String get classYourClass => 'ชั้นเรียนของคุณ';

  @override
  String get classArchivedReadOnly => 'เก็บถาวร · อ่านอย่างเดียว';

  @override
  String classHeroSemantics(int students, int sessions, String toGrade) {
    return '$students นักเรียน, $sessions คาบเรียนที่เปิดอยู่, งานรอให้คะแนน $toGrade';
  }

  @override
  String get classUnknownNumber => 'ไม่ทราบจำนวน';

  @override
  String get classOpenSessions => 'คาบเรียนที่เปิดอยู่';

  @override
  String get classNoSessions => 'ไม่มีคาบเรียน';

  @override
  String classRateValue(String value) {
    return 'อัตราของชั้น $value';
  }

  @override
  String get classSessions => 'คาบเรียน';

  @override
  String get classNoAttendanceSessions =>
      'ยังไม่มีคาบเรียน สร้างได้ในส่วนการเข้าเรียนเพื่อเริ่มติดตาม';

  @override
  String get classLatestSession => 'คาบเรียนล่าสุด';

  @override
  String get classSessionFallback => 'คาบเรียน';

  @override
  String classNotMarked(int count) {
    return 'ยังไม่บันทึก $count';
  }

  @override
  String get classNothingToGrade => 'ไม่มีงานรอให้คะแนน';

  @override
  String get classPublished => 'เผยแพร่แล้ว';

  @override
  String get classDrafts => 'ฉบับร่าง';

  @override
  String get classNoPublished => 'ยังไม่มีงานที่เผยแพร่';

  @override
  String get classSubmissionsReceived => 'งานที่ได้รับ';

  @override
  String classDueLower(String when) {
    return 'กำหนดส่ง $when';
  }

  @override
  String get classNoRecent => 'ไม่มีความเคลื่อนไหวล่าสุด';

  @override
  String get classNoRecentHint => 'งานที่ส่งจะแสดงที่นี่เมื่อนักเรียนส่งงาน';

  @override
  String get classAttendanceByStudent => 'การเข้าเรียนรายบุคคล';

  @override
  String get classNoStudentsEnrolled => 'ยังไม่มีนักเรียนลงทะเบียน';

  @override
  String get classShareCode => 'แชร์รหัสเข้าร่วมเพื่อให้นักเรียนลงทะเบียน';

  @override
  String lessonFilesCount(int count) {
    return '$count ไฟล์';
  }

  @override
  String get lessonNew => 'สร้างบทเรียนใหม่';

  @override
  String get lessonNoneYet => 'ยังไม่มีบทเรียน';

  @override
  String get lessonEmptyTeacher =>
      'สร้างฉบับร่าง แนบไฟล์ แล้วเผยแพร่ให้นักเรียน';

  @override
  String get lessonEmptyStudent =>
      'ครูของคุณยังไม่ได้เผยแพร่บทเรียนในรายวิชานี้';

  @override
  String get lessonText => 'เนื้อหาบทเรียน';

  @override
  String get lessonCreateDraft => 'สร้างฉบับร่าง';

  @override
  String get lessonDeleteTitle => 'ลบบทเรียน?';

  @override
  String get lessonDeleteBody =>
      'บทเรียนและไฟล์ของบทเรียนจะหายไปสำหรับทุกคน ไม่สามารถย้อนกลับได้';

  @override
  String get lessonTitle => 'บทเรียน';

  @override
  String get lessonGone => 'ไม่มีบทเรียนนี้แล้ว';

  @override
  String get lessonNoFilesAttached => 'ไม่มีไฟล์แนบ';

  @override
  String get lessonAttach => 'แนบไฟล์';

  @override
  String get lessonPublication => 'การเผยแพร่และการเข้าถึง';

  @override
  String get lessonSaveFirst => 'บันทึกเนื้อหาก่อนเปลี่ยนการมองเห็น';

  @override
  String get lessonUnpublish => 'ยกเลิกการเผยแพร่';

  @override
  String get lessonDelete => 'ลบบทเรียน';

  @override
  String get lessonEditEyebrow => 'แก้ไขบทเรียน';

  @override
  String get lessonPublishedDesc => 'เผยแพร่แล้ว · นักเรียนอ่านบทเรียนนี้ได้';

  @override
  String get lessonDraftDesc => 'ฉบับร่าง · มีเพียงคุณที่เห็นบทเรียนนี้';

  @override
  String get lessonContent => 'เนื้อหาการเรียน';

  @override
  String get lessonSaveChanges => 'บันทึกการเปลี่ยนแปลง';

  @override
  String lessonCourseEyebrow(String course) {
    return '$course · บทเรียน';
  }

  @override
  String get lessonReadExplore => 'อ่าน สำรวจ แล้วนำไปใช้จริง';

  @override
  String get lessonNoText => 'ไม่มีเนื้อหาบทเรียน';

  @override
  String get lessonSupporting => 'แหล่งข้อมูลประกอบบทเรียนนี้';

  @override
  String get lessonNoFiles => 'บทเรียนนี้ไม่มีไฟล์';

  @override
  String get asgNotSubmitted => 'ยังไม่ได้ส่ง';

  @override
  String asgGradedScore(int score, int max) {
    return 'ให้คะแนนแล้ว $score/$max';
  }

  @override
  String get asgReturnedForRevision => 'ส่งคืนให้แก้ไข';

  @override
  String get asgNone => 'ยังไม่มีงาน';

  @override
  String get asgStudentEmptyHint => 'งานใหม่จากครูของคุณจะแสดงที่นี่';

  @override
  String get asgNoDeadline => 'ไม่มีกำหนดส่ง';

  @override
  String asgDue(String when) {
    return 'กำหนดส่ง $when';
  }

  @override
  String asgResultGraded(int score, int max) {
    return 'ให้คะแนนแล้ว: $score/$max';
  }

  @override
  String asgFeedbackLine(String text) {
    return 'ข้อเสนอแนะ: $text';
  }

  @override
  String get asgGradedLocked => 'งานที่ส่งนี้ให้คะแนนแล้วและถูกล็อก';

  @override
  String get asgReviseResubmit => 'แก้ไขงานของคุณด้านล่างแล้วส่งอีกครั้ง';

  @override
  String get asgSavedSubmission => 'งานที่คุณส่งไว้';

  @override
  String asgSavedLine(String when, int version) {
    return 'บันทึกเมื่อ $when · เวอร์ชัน $version';
  }

  @override
  String get asgReload => 'โหลดงานที่ส่งของฉันใหม่';

  @override
  String get asgEyebrowWorkspace => 'งาน / พื้นที่ทำงานของคุณ';

  @override
  String asgMaxScore(int score) {
    return 'คะแนนเต็ม $score';
  }

  @override
  String get asgDeadlinePassed => 'เลยกำหนดส่งแล้ว ปิดรับงานที่ส่ง';

  @override
  String get asgBrief => 'คำชี้แจงงาน';

  @override
  String get asgNoInstructions => 'ไม่มีคำชี้แจง';

  @override
  String get asgUploading => 'กำลังอัปโหลดไฟล์…';

  @override
  String get asgSaving => 'กำลังบันทึก…';

  @override
  String get asgSubmit => 'ส่งงาน';

  @override
  String get asgResubmit => 'ส่งอีกครั้ง';

  @override
  String get asgYourResponse => 'คำตอบของคุณ';

  @override
  String get asgFirstHint => 'เขียนคำตอบหรือแนบงานของคุณ แล้วส่งเมื่อพร้อม';

  @override
  String get asgUpdateHint =>
      'แก้ไขคำตอบของคุณด้านล่าง เวอร์ชันที่บันทึกไว้ยังคงอยู่จนกว่าคุณจะส่งอีกครั้ง';

  @override
  String get asgYourAnswer => 'คำตอบของคุณ';

  @override
  String get asgAnswerHint => 'เริ่มจากแนวทางของคุณ แล้วอธิบายสิ่งที่คุณพบ…';

  @override
  String asgUploadPrivately(String size) {
    return '$size · จะอัปโหลดแบบส่วนตัว';
  }

  @override
  String get asgRemoveAttachmentTip => 'นำไฟล์แนบออก';

  @override
  String get asgReplaceFile => 'เปลี่ยนไฟล์แนบ';

  @override
  String get asgAttachFile => 'แนบไฟล์';

  @override
  String get asgRemoveSaved => 'นำไฟล์แนบที่บันทึกไว้ของฉันออก';

  @override
  String get asgSavedOnSubmit => 'งานของคุณจะถูกบันทึกเมื่อคุณส่ง';

  @override
  String get asgNewTitle => 'สร้างงานใหม่';

  @override
  String get asgEditTitle => 'แก้ไขงาน';

  @override
  String get asgInstructions => 'คำชี้แจง';

  @override
  String get asgMaxScoreLabel => 'คะแนนเต็ม';

  @override
  String get asgSetDeadline => 'กำหนดวันส่ง';

  @override
  String get asgRemoveDeadline => 'ลบกำหนดส่ง';

  @override
  String get asgSaveDraft => 'บันทึกฉบับร่าง';

  @override
  String get asgTeacherEmptyHint => 'สร้างฉบับร่าง แล้วเผยแพร่ให้นักเรียน';

  @override
  String get asgPublishTitle => 'เผยแพร่งาน?';

  @override
  String get asgPublishBody =>
      'นักเรียนที่ลงทะเบียนจะเห็นงานนี้และเริ่มส่งงานได้';

  @override
  String get asgGone => 'งานนี้ไม่มีให้ใช้งานแล้ว';

  @override
  String asgSubmissionsCount(int count) {
    return 'งานที่ส่ง ($count)';
  }

  @override
  String get asgTeachingEyebrow => 'การสอน / งาน';

  @override
  String get asgReviewDesc => 'ตรวจงานที่ส่งและผลักดันการเรียนรู้ให้ก้าวหน้า';

  @override
  String get asgPrepareDesc =>
      'เตรียมคำชี้แจงงาน แล้วเผยแพร่ไปยังรายวิชาของคุณ';

  @override
  String get asgBriefTitle => 'คำชี้แจงงาน';

  @override
  String get asgDraftsHidden =>
      'นักเรียนมองไม่เห็นฉบับร่าง เผยแพร่เพื่อรับงานที่ส่ง';

  @override
  String get asgNoSubmissions => 'ยังไม่มีงานที่ส่ง';

  @override
  String get asgNoSubmissionsHint => 'งานของนักเรียนจะแสดงที่นี่เมื่อส่งเข้ามา';

  @override
  String asgSubmittedVersion(String when, int version) {
    return 'ส่งเมื่อ $when · เวอร์ชัน $version';
  }

  @override
  String get asgGrade => 'ให้คะแนน';

  @override
  String get asgReview => 'ตรวจสอบ';

  @override
  String gradeReviewEyebrow(String title) {
    return 'ตรวจ · $title';
  }

  @override
  String get gradeStudentSubmission => 'งานที่นักเรียนส่ง';

  @override
  String get gradeReadDesc => 'อ่านงาน แล้วให้ข้อแนะนำขั้นต่อไปที่ชัดเจน';

  @override
  String get gradeStatusTitle => 'สถานะงานที่ส่ง';

  @override
  String get gradeVersion => 'เวอร์ชัน';

  @override
  String get gradeMaxScore => 'คะแนนเต็ม';

  @override
  String gradeSubmittedAt(String when) {
    return 'ส่งเมื่อ $when';
  }

  @override
  String get gradeStudentAnswer => 'คำตอบของนักเรียน';

  @override
  String get gradeNoText => '(ไม่มีข้อความ)';

  @override
  String get gradeReloadLatest => 'โหลดล่าสุดอีกครั้ง';

  @override
  String get gradeWaiting => 'รอให้นักเรียนแก้ไขและส่งอีกครั้ง';

  @override
  String gradeYourFeedback(String text) {
    return 'ข้อเสนอแนะของคุณ: $text';
  }

  @override
  String get gradeAndFeedback => 'คะแนนและข้อเสนอแนะ';

  @override
  String get gradeHint => 'คะแนนบันทึกผลสัมฤทธิ์ ข้อเสนอแนะบอกว่าควรทำอะไรต่อ';

  @override
  String get gradeScore => 'คะแนน';

  @override
  String gradeScoreRangeLabel(int max) {
    return 'คะแนน (0–$max)';
  }

  @override
  String get gradeFeedbackToStudent => 'ข้อเสนอแนะถึงนักเรียน';

  @override
  String get gradeFeedback => 'ข้อเสนอแนะ';

  @override
  String get gradeSaveNew => 'บันทึกคะแนนใหม่';

  @override
  String get gradeSave => 'บันทึกคะแนน';

  @override
  String get gradeReturn => 'ส่งคืนให้แก้ไข';

  @override
  String get gradeHistory => 'ประวัติ';

  @override
  String get gradeNoHistory => 'ยังไม่มีการให้คะแนน';

  @override
  String get errorNoteTooLong => 'บันทึกยาวเกินไป (สูงสุด 500 ตัวอักษร)';

  @override
  String get errorRecordChanged =>
      'ระเบียนนี้ถูกเปลี่ยนแปลงจากที่อื่น กำลังแสดงค่าล่าสุด โปรดลองอีกครั้ง';

  @override
  String get errorSessionNotFound => 'ไม่พบคาบเรียน';

  @override
  String get errorActivityNotFound => 'ไม่พบกิจกรรม';

  @override
  String get errorAssignmentUnavailable => 'งานนี้ไม่มีให้ใช้งานอีกต่อไป';

  @override
  String get errorCourseUnavailable => 'รายวิชานี้ไม่มีให้ใช้งานอีกต่อไป';

  @override
  String get commonLoadMore => 'โหลดเพิ่ม';

  @override
  String get commonLoadingEllipsis => 'กำลังโหลด…';

  @override
  String get actPolicyTeacherMarked => 'ครูเป็นผู้บันทึก';

  @override
  String get actPolicySelfReported => 'นักเรียนรายงานเอง';

  @override
  String get actPolicyTeacherVerified => 'ครูตรวจสอบ';

  @override
  String get actPolicyHintTeacherMarked => 'ครูของคุณเป็นผู้บันทึกว่าทำเสร็จ';

  @override
  String get actPolicyHintSelfReported => 'คุณทำเครื่องหมายว่าเสร็จด้วยตนเอง';

  @override
  String get actPolicyHintTeacherVerified => 'คุณส่งงานแล้วครูของคุณยืนยัน';

  @override
  String get actPolicyDetailTeacherMarked =>
      'คุณเป็นผู้บันทึกว่าใครทำเสร็จ นักเรียนเห็นเพียงสถานะของตน';

  @override
  String get actPolicyDetailSelfReported =>
      'นักเรียนทำเครื่องหมายว่าเสร็จด้วยตนเองก่อนกำหนดส่ง';

  @override
  String get actPolicyDetailTeacherVerified =>
      'นักเรียนส่งงาน คุณอนุมัติหรือปฏิเสธพร้อมเหตุผล';

  @override
  String get actStateUpcoming => 'กำลังจะถึง';

  @override
  String get actStateOpen => 'ต้องทำ';

  @override
  String get actStatePending => 'รอตรวจสอบ';

  @override
  String get actStateCompleted => 'เสร็จแล้ว';

  @override
  String get actStateRejected => 'ต้องลองอีกครั้ง';

  @override
  String get actStateNotDone => 'ยังไม่ได้ทำ';

  @override
  String get actStateMissed => 'พลาดกำหนด';

  @override
  String get actStateNotScheduled => 'ไม่ได้กำหนดไว้';

  @override
  String get actPaused => 'พักไว้';

  @override
  String get actEveryDay => 'ทุกวัน';

  @override
  String get actWeekdays => 'วันธรรมดา';

  @override
  String actDeadlineAtTime(String time, String tz) {
    return 'กำหนดส่ง $time ($tz)';
  }

  @override
  String actDeadlineDayEnd(String tz) {
    return 'กำหนดส่งภายในสิ้นวัน ($tz)';
  }

  @override
  String get actNoStreak => 'ไม่มีสถิติต่อเนื่อง (ไม่มีกำหนดส่ง)';

  @override
  String actStreak(String value) {
    return 'ต่อเนื่อง $value';
  }

  @override
  String actBest(String value) {
    return 'ดีที่สุด $value';
  }

  @override
  String actDoneOfResolved(int done, int total) {
    return 'เสร็จ $done จาก $total';
  }

  @override
  String get actEditDetails => 'แก้ไขรายละเอียด';

  @override
  String get actDescription => 'คำอธิบาย';

  @override
  String get actDueEndOfDay => 'กำหนดส่งภายในสิ้นวัน';

  @override
  String get actSubmitForReview => 'ส่งเพื่อตรวจสอบ';

  @override
  String get actNoteForTeacher => 'บันทึกถึงครูของคุณ (ไม่บังคับ)';

  @override
  String get actSubmit => 'ส่ง';

  @override
  String get actMarkDone => 'ทำเครื่องหมายว่าเสร็จ';

  @override
  String get actWithdraw => 'ถอนกลับ';

  @override
  String actTeacherAskedRetry(String reason) {
    return 'ครูของคุณขอให้ลองอีกครั้ง: $reason';
  }

  @override
  String get actNothingToday => 'วันนี้ไม่มีกิจกรรมที่กำหนดไว้';

  @override
  String get actNothingTodayHint =>
      'ครูของคุณยังไม่ได้กำหนดกิจกรรมสำหรับวันนี้ในรายวิชานี้';

  @override
  String get actDaily => 'กิจกรรมประจำวัน';

  @override
  String get actDailyOne => 'กิจกรรมประจำวัน';

  @override
  String get actTodaySubtitle => 'สิ่งที่ต้องทำวันนี้ในรายวิชานี้';

  @override
  String get actWeekView => 'มุมมองรายสัปดาห์';

  @override
  String get actMyProgress => 'ความก้าวหน้าของฉัน';

  @override
  String actWeekOf(String date) {
    return 'สัปดาห์ของ $date';
  }

  @override
  String get actThisWeek => 'สัปดาห์นี้';

  @override
  String get actPrevWeek => 'สัปดาห์ก่อนหน้า';

  @override
  String get actNextWeek => 'สัปดาห์ถัดไป';

  @override
  String get actNoWeekTitle => 'สัปดาห์นี้ไม่มีกิจกรรม';

  @override
  String get actNoWeekHint =>
      'ไม่มีกิจกรรมที่กำหนดไว้ในวันเหล่านี้ ใช้ลูกศรเพื่อดูสัปดาห์อื่น';

  @override
  String get actDaysOfWeek => 'วันในสัปดาห์';

  @override
  String get actNoEndDate => 'ไม่มีวันสิ้นสุด';

  @override
  String actEnds(String date) {
    return 'สิ้นสุด $date';
  }

  @override
  String get actClearEnd => 'ล้างวันสิ้นสุด';

  @override
  String get actDeadline => 'กำหนดส่ง';

  @override
  String get actDlDayEnd => 'สิ้นสุดของแต่ละวัน';

  @override
  String get actDlDayEndHint =>
      'เวลาตัดรอบรายวันเริ่มต้นที่เที่ยงคืนตามเขตเวลาของกิจกรรม';

  @override
  String get actDlTime => 'เวลาที่กำหนดในแต่ละวัน';

  @override
  String get actDlNoneHint => 'ไม่ถูกนับว่าพลาดกำหนดและไม่มีสถิติต่อเนื่อง';

  @override
  String actDueAtPicker(String time) {
    return 'กำหนดส่งเวลา $time';
  }

  @override
  String get actTimezone => 'เขตเวลา';

  @override
  String get actStarts => 'เริ่ม';

  @override
  String get actNewActivity => 'กิจกรรมใหม่';

  @override
  String actReviewN(int count) {
    return 'ตรวจสอบ ($count)';
  }

  @override
  String get actReviewQueue => 'คิวตรวจสอบ';

  @override
  String get actSectionSubtitle =>
      'การฝึกซ้ำตามกำหนดการ พร้อมรูปแบบการบันทึกและกำหนดส่ง';

  @override
  String actTodayDone(int done, int expected) {
    return 'วันนี้เสร็จ $done/$expected';
  }

  @override
  String get actNotScheduledToday => 'วันนี้ไม่ได้กำหนดไว้';

  @override
  String actToReview(int count) {
    return 'รอตรวจสอบ $count';
  }

  @override
  String get actEmptyTitle => 'ยังไม่มีกิจกรรม';

  @override
  String get actEmptyHint =>
      'สร้างกิจกรรมประจำวัน เช่น ฝึกอ่าน แล้วเลือกวิธีบันทึกว่าทำเสร็จ';

  @override
  String get actProblemTitle => 'ตั้งชื่อกิจกรรม';

  @override
  String get actProblemDays => 'เลือกอย่างน้อยหนึ่งวันในสัปดาห์';

  @override
  String get actFormDesc =>
      'การฝึกที่ไม่ขึ้นกับวิชา ซึ่งนักเรียนทำซ้ำในวันที่คุณเลือก';

  @override
  String get actDetails => 'รายละเอียด';

  @override
  String get actDescriptionOptional => 'คำอธิบาย (ไม่บังคับ)';

  @override
  String get actHowRecorded => 'บันทึกว่าทำเสร็จอย่างไร?';

  @override
  String get actSchedule => 'กำหนดการ';

  @override
  String get actCreate => 'สร้างกิจกรรม';

  @override
  String get actChangeSchedule => 'เปลี่ยนกำหนดการ';

  @override
  String get actChangeDesc =>
      'กำหนดการใหม่เริ่มตั้งแต่วันที่คุณเลือก (พรุ่งนี้หรือหลังจากนั้น) วันก่อนหน้านั้นยังคงกฎเดิม ประวัติของทุกคนจึงไม่เปลี่ยน';

  @override
  String get actNewSchedule => 'กำหนดการใหม่';

  @override
  String get actSaveSchedule => 'บันทึกกำหนดการ';

  @override
  String actScheduleFrom(String from, int version) {
    return 'กำหนดการปัจจุบันตั้งแต่ $from (เวอร์ชัน $version)';
  }

  @override
  String actScheduleFromTo(String from, String to, int version) {
    return 'กำหนดการปัจจุบันตั้งแต่ $from ถึง $to (เวอร์ชัน $version)';
  }

  @override
  String get actPause => 'พักไว้';

  @override
  String get actResume => 'กลับมาใช้งาน';

  @override
  String get actArchive => 'เก็บถาวร';

  @override
  String get actConfirmPause =>
      'พักกิจกรรมนี้ตั้งแต่พรุ่งนี้? วันที่ผ่านมายังคงมีบันทึกเดิม';

  @override
  String get actConfirmArchive =>
      'เก็บถาวรกิจกรรมนี้? จะไม่แสดงให้นักเรียน ประวัติยังคงอยู่';

  @override
  String get actConfirmResume => 'กลับมาใช้งานกิจกรรมนี้ตั้งแต่พรุ่งนี้?';

  @override
  String get actWeeklyRegister => 'ทะเบียนรายสัปดาห์';

  @override
  String actRegisterSubtitle(String date) {
    return 'สัปดาห์ของ $date แตะช่องเพื่อบันทึกหรือตรวจสอบ';
  }

  @override
  String actCouldNotRefreshWeek(String error) {
    return 'รีเฟรชไม่สำเร็จ: $error กำลังแสดงสัปดาห์ที่โหลดไว้ล่าสุด';
  }

  @override
  String get actNoStudentsTitle => 'ยังไม่มีนักเรียนที่ลงทะเบียน';

  @override
  String get actNoStudentsHint => 'นักเรียนจะแสดงที่นี่เมื่อเข้าร่วมรายวิชา';

  @override
  String get actNotScheduledWeek => 'สัปดาห์นี้ไม่ได้กำหนดไว้';

  @override
  String get actNotScheduledWeekHint =>
      'กิจกรรมนี้ไม่มีวันที่กำหนดไว้ในสัปดาห์นี้ ใช้ลูกศรเพื่อดูสัปดาห์อื่น';

  @override
  String actCellSemantics(String name, String date, String state) {
    return '$name, $date: $state';
  }

  @override
  String actStudentNote(String note) {
    return 'บันทึกของนักเรียน: $note';
  }

  @override
  String actReasonGiven(String reason) {
    return 'เหตุผลที่ให้ไว้: $reason';
  }

  @override
  String get actArchivedReadOnly =>
      'รายวิชานี้ถูกเก็บถาวร บันทึกจึงอ่านได้อย่างเดียว';

  @override
  String get actReasonRequired => 'เหตุผลสำหรับนักเรียน (จำเป็น)';

  @override
  String get actApprove => 'อนุมัติ';

  @override
  String get actReject => 'ปฏิเสธ';

  @override
  String get actSendRejection => 'ส่งการปฏิเสธ';

  @override
  String get actFutureDays => 'ยังบันทึกวันในอนาคตไม่ได้';

  @override
  String get actMarkCompleted => 'บันทึกว่าเสร็จแล้ว';

  @override
  String get actMarkNotDone => 'บันทึกว่ายังไม่ได้ทำ';

  @override
  String get actVerificationQueue => 'คิวตรวจสอบ';

  @override
  String actWaitingDecision(int count) {
    return 'รอการตัดสินใจของคุณ $count รายการ';
  }

  @override
  String get actWaitingReview => 'รอตรวจสอบ';

  @override
  String get actNothingToReview => 'ไม่มีรายการให้ตรวจสอบ';

  @override
  String get actNothingToReviewHint =>
      'งานที่นักเรียนส่งจะแสดงที่นี่เพื่ออนุมัติหรือปฏิเสธ';

  @override
  String actSubmittedAt(String when) {
    return 'ส่งเมื่อ $when';
  }

  @override
  String actNoteLine(String note) {
    return 'บันทึก: $note';
  }

  @override
  String get actRejectTitle => 'ปฏิเสธงานที่ส่ง';

  @override
  String get atdRateNone => 'ยังไม่มีอัตรา';

  @override
  String get atdNewSession => 'สร้างคาบเรียนใหม่';

  @override
  String get atdWeeklyGrid => 'ตารางรายสัปดาห์';

  @override
  String get atdSummary => 'สรุป';

  @override
  String get atdNoSessions => 'ยังไม่มีคาบเรียนสำหรับเช็กชื่อ';

  @override
  String get atdNoSessionsHint => 'สร้างหนึ่งคาบสำหรับการพบกันแต่ละครั้ง';

  @override
  String get atdNewDialogTitle => 'สร้างคาบเรียนสำหรับเช็กชื่อ';

  @override
  String get atdDate => 'วันที่';

  @override
  String get atdTime => 'เวลา';

  @override
  String atdNoteFor(String name) {
    return 'บันทึกสำหรับ $name';
  }

  @override
  String get atdNote => 'บันทึก';

  @override
  String get atdSaveNote => 'บันทึกหมายเหตุ';

  @override
  String get atdCloseTitle => 'ปิดคาบเรียนนี้?';

  @override
  String get atdCloseAllMarked =>
      'บันทึกนักเรียนครบทุกคนแล้ว คุณยังแก้ไขบันทึกได้ภายหลัง';

  @override
  String atdCloseUnmarked(int count) {
    return 'นักเรียนที่ยังไม่บันทึก $count คนจะถูกบันทึกว่าขาดเรียน คุณยังแก้ไขบันทึกได้ภายหลัง';
  }

  @override
  String get atdCloseSession => 'ปิดคาบเรียน';

  @override
  String atdEventClosed(String when) {
    return 'ปิดคาบเรียน · $when';
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
  String get atdEyebrowSession => 'การเข้าเรียน / คาบเรียน';

  @override
  String get atdClassRegister => 'ทะเบียนชั้นเรียน';

  @override
  String get atdRegisterHint =>
      'เลือกสถานะของนักเรียนแต่ละคน การเปลี่ยนแปลงจะบันทึกทันที';

  @override
  String get atdArchivedReadOnly =>
      'รายวิชานี้ถูกเก็บถาวร การเข้าเรียนอ่านได้อย่างเดียว';

  @override
  String get atdNoStudents => 'ยังไม่มีนักเรียนที่ลงทะเบียน';

  @override
  String atdCloseSessionN(int count) {
    return 'ปิดคาบเรียน (ยังไม่บันทึก $count)';
  }

  @override
  String get atdSessionClosedNote =>
      'ปิดคาบเรียนแล้ว ยังแก้ไขบันทึกที่มีอยู่ได้';

  @override
  String get atdNoChanges => 'ยังไม่มีการเปลี่ยนแปลง';

  @override
  String atdEditNoteFor(String name) {
    return 'แก้ไขบันทึกของ $name';
  }

  @override
  String get atdNotMarkedYet => 'ยังไม่ได้บันทึก';

  @override
  String get atdEyebrowTeaching => 'การสอน / การเข้าเรียน';

  @override
  String get atdEyebrowLearning => 'การเรียน / การเข้าเรียน';

  @override
  String get atdSummaryTitle => 'สรุปการเข้าเรียน';

  @override
  String get atdSummaryDesc => 'บันทึกการเข้าร่วมในทุกคาบเรียนอย่างชัดเจน';

  @override
  String atdClosedOfTotal(int closed, int total) {
    return 'ปิดแล้ว $closed จาก $total คาบ';
  }

  @override
  String get atdRateNote =>
      'อัตรา = (มาเรียน + มาสาย) ÷ (มาเรียน + มาสาย + ขาดเรียน) ไม่นับคาบที่ลา';

  @override
  String get atdSummaryEmptyHint =>
      'อัตราการเข้าเรียนจะแสดงเมื่อนักเรียนเข้าร่วมรายวิชา';

  @override
  String get atdMyAttendance => 'การเข้าเรียนของฉัน';

  @override
  String get atdWeeklyView => 'มุมมองรายสัปดาห์';

  @override
  String get atdNoRecords => 'ยังไม่มีการบันทึกการเข้าเรียน';

  @override
  String get atdNoRecordsHint =>
      'การเข้าเรียนของคุณจะแสดงที่นี่เมื่อมีการเช็กชื่อ';

  @override
  String atdRateTitle(String rate) {
    return 'อัตราการเข้าเรียน: $rate';
  }

  @override
  String get atdWeeklyAttendance => 'การเข้าเรียนรายสัปดาห์';

  @override
  String get atdMyWeek => 'สัปดาห์ของฉัน';

  @override
  String get atdGridDesc => 'ชื่อจะแสดงค้างไว้ ปัดวันเพื่อดูแต่ละคาบ';

  @override
  String get atdGlyphPresent => 'ม';

  @override
  String get atdGlyphLate => 'ส';

  @override
  String get atdGlyphExcused => 'ล';

  @override
  String get atdGlyphAbsent => 'ข';

  @override
  String get atdNotMarked => 'ยังไม่ได้บันทึก';

  @override
  String get atdNoSession => '· ไม่มีคาบเรียน';

  @override
  String get atdTwoSessions => '×2 = สองคาบในวันนั้น เรียงตามเวลา';

  @override
  String atdCellNoSession(String who, String date) {
    return '$who, $date: ไม่มีคาบเรียน';
  }

  @override
  String get atdMe => 'ฉัน';

  @override
  String get atdStatusGuide => 'คำอธิบายสถานะ';

  @override
  String get atdGridNoSessions => 'สัปดาห์นี้ไม่มีคาบเรียน';

  @override
  String get atdGridNoSessionsHint => 'ใช้ลูกศรเพื่อดูสัปดาห์อื่น';

  @override
  String get atdGridNoStudentsHint =>
      'ตารางรายสัปดาห์จะแสดงเมื่อนักเรียนเข้าร่วมรายวิชา';

  @override
  String get atdAllMarked => 'บันทึกครบแล้ว';

  @override
  String atdUnmarkedCount(int count) {
    return 'ยังไม่บันทึก $count';
  }

  @override
  String get progEyebrowTeacher => 'ความก้าวหน้าของนักเรียน';

  @override
  String progEnrolledSince(String date) {
    return 'ลงทะเบียนตั้งแต่ $date';
  }

  @override
  String get progPrivateTeacher =>
      'เห็นได้เฉพาะคุณและนักเรียนคนนี้ ไม่แชร์กับทั้งชั้น';

  @override
  String get progPrivateStudent => 'เห็นได้เฉพาะคุณและครูของคุณ';

  @override
  String get progArchived => 'รายวิชานี้ถูกเก็บถาวร (อ่านได้อย่างเดียว)';

  @override
  String progCouldNotRefresh(String error) {
    return 'รีเฟรชไม่สำเร็จ: $error กำลังแสดงตัวเลขที่โหลดไว้ล่าสุด';
  }

  @override
  String get progAssignmentsNone => 'ยังไม่มีการเผยแพร่งาน';

  @override
  String progAssignmentsSummary(int done, int published) {
    return 'ส่งหรือให้คะแนนแล้ว $done จาก $published งานที่เผยแพร่';
  }

  @override
  String get progNoPublishedTitle => 'ไม่มีงานที่เผยแพร่';

  @override
  String get progNoPublishedHint =>
      'ความก้าวหน้าจะแสดงที่นี่เมื่อครูเผยแพร่งาน';

  @override
  String progOfCount(int a, int b) {
    return '$a จาก $b';
  }

  @override
  String progOverdueHint(int count) {
    return 'เลยกำหนด $count';
  }

  @override
  String get progAwaitingGrading => 'รอให้คะแนน';

  @override
  String progScore(int score, int max) {
    return 'คะแนน $score/$max';
  }

  @override
  String progTruncated(int shown, int total) {
    return 'แสดง $shown รายการล่าสุดจากทั้งหมด $total งาน ตัวเลขด้านบนครอบคลุมทั้งหมด';
  }

  @override
  String get progActivitiesSubtitle =>
      'สถิติต่อเนื่องนับเฉพาะวันที่กำหนดไว้ (62 วันล่าสุด) รายการที่รอตรวจสอบจะไม่ถูกนับจนกว่าจะอนุมัติ';

  @override
  String progAwaitingVerification(int count) {
    return 'รอตรวจสอบ $count';
  }

  @override
  String get progNoActivitiesHint =>
      'ยังไม่มีการตั้งกิจกรรมประจำวันสำหรับรายวิชานี้';

  @override
  String get progNoClosedDay => 'ยังไม่มีวันที่กำหนดไว้ที่ปิดแล้ว';

  @override
  String get progAttNone => 'ยังไม่มีการสร้างคาบเรียน';

  @override
  String progAttSummary(int total, int closed) {
    return '$total คาบ ปิดแล้ว $closed';
  }

  @override
  String get progNoSessionsTitle => 'ยังไม่มีคาบเรียน';

  @override
  String get progNoSessionsHint => 'การเข้าเรียนจะแสดงเมื่อครูสร้างคาบเรียน';

  @override
  String get progRateNone =>
      'อัตราการเข้าเรียน: ยังไม่มีข้อมูล (ไม่มีรายการที่นับได้)';

  @override
  String progRate(String rate, int present, int counted) {
    return 'อัตราการเข้าเรียน: $rate ($present จาก $counted คาบที่นับ)';
  }

  @override
  String progNotMarkedCount(int count) {
    return 'ยังไม่บันทึก: $count';
  }

  @override
  String get progRecentSessions => 'คาบเรียนล่าสุด';

  @override
  String get taskModeMonth => 'เดือน';

  @override
  String get taskModeCompleted => 'เสร็จแล้ว';

  @override
  String get taskOverdue => 'เลยกำหนด';

  @override
  String get taskNeedsRevision => 'ต้องแก้ไข';

  @override
  String get taskGraded => 'ให้คะแนนแล้ว';

  @override
  String get taskHeld => 'จัดแล้ว';

  @override
  String get taskScheduled => 'กำหนดไว้แล้ว';

  @override
  String get taskHeaderTitle => 'สิ่งที่ต้องทำ';

  @override
  String get taskHeaderDesc =>
      'งานและกิจกรรมประจำวันจากทุกรายวิชาของคุณ โดยแต่ละรายการมีสถานะเดียว';

  @override
  String get taskEmptyTodayTitle => 'วันนี้ไม่มีงานที่ถึงกำหนด';

  @override
  String get taskEmptyTodayHint => 'พักผ่อนได้เลย หรือดูสัปดาห์ข้างหน้า';

  @override
  String get taskEmptyWeekTitle => 'สัปดาห์นี้ไม่มีรายการ';

  @override
  String get taskEmptyWeekHint => 'ไม่มีกำหนดส่งงานหรือกิจกรรมในสัปดาห์นี้';

  @override
  String get taskEmptyMonthTitle => 'เดือนนี้ไม่มีรายการ';

  @override
  String get taskEmptyDayTitle => 'วันนี้ไม่มีรายการ';

  @override
  String get taskEmptyMonthHint => 'ไม่มีกำหนดส่งงานหรือกิจกรรมในช่วงนี้';

  @override
  String get taskEmptyUpcomingTitle => 'ไม่มีรายการที่กำลังจะถึง';

  @override
  String get taskEmptyUpcomingHint => 'งานใหม่จากครูของคุณจะแสดงที่นี่';

  @override
  String get taskEmptyOverdueTitle => 'ไม่มีงานเลยกำหนด';

  @override
  String get taskEmptyOverdueHint => 'คุณทำครบตามกำหนดแล้ว';

  @override
  String get taskEmptyCompletedTitle => 'ยังไม่มีงานที่เสร็จ';

  @override
  String get taskEmptyCompletedHint => 'งานที่เสร็จแล้วจะแสดงที่นี่';

  @override
  String get taskCalendarEyebrow => 'ปฏิทิน';

  @override
  String get taskCalendarTitle => 'ปฏิทินการสอน';

  @override
  String get taskCalendarDesc =>
      'กำหนดส่งงาน กิจกรรมประจำวัน และคาบเรียนในทุกรายวิชาของคุณ';

  @override
  String get taskNoPending => 'ไม่มีงานกิจกรรมที่รอตรวจสอบ';

  @override
  String taskPending(int count) {
    return 'มีงานกิจกรรม $count รายการรอตรวจสอบ';
  }

  @override
  String taskCouldNotRefreshTasks(String error) {
    return 'รีเฟรชไม่สำเร็จ: $error กำลังแสดงงานที่โหลดไว้ล่าสุด';
  }

  @override
  String taskCouldNotRefreshCalendar(String error) {
    return 'รีเฟรชไม่สำเร็จ: $error กำลังแสดงปฏิทินที่โหลดไว้ล่าสุด';
  }

  @override
  String get taskNothingScheduled => 'ไม่มีรายการที่กำหนดไว้';

  @override
  String get taskNothingScheduledHint =>
      'ไม่มีกำหนดส่ง กิจกรรม หรือคาบเรียนในช่วงนี้';

  @override
  String get taskPrevious => 'ก่อนหน้า';

  @override
  String get taskNext => 'ถัดไป';

  @override
  String taskDayItems(int day, String month, int count) {
    return '$day $month $count รายการ';
  }

  @override
  String get taskUndated => 'ไม่ระบุวันที่';

  @override
  String taskDueSubmitted(String when, int received, int expected) {
    return 'กำหนดส่ง $when · ส่งแล้ว $received จาก $expected';
  }

  @override
  String taskDoneOf(int received, int expected) {
    return 'เสร็จ $received จาก $expected';
  }

  @override
  String taskAttendanceSession(String when, String state) {
    return 'คาบเรียน $when · $state';
  }

  @override
  String taskClassSession(String when) {
    return 'คาบเรียน $when';
  }

  @override
  String get taskNothingDueToday => 'วันนี้ไม่มีงานที่ถึงกำหนด';

  @override
  String taskTodoDone(int todo, int rest) {
    return 'ต้องทำ $todo · เสร็จหรือรอ $rest';
  }

  @override
  String get taskAllTasks => 'งานทั้งหมด';

  @override
  String get taskAllClear => 'วันนี้ไม่มีอะไรค้าง';

  @override
  String get taskAllClearHint => 'วันนี้ไม่มีกำหนดส่งงานหรือกิจกรรม';

  @override
  String taskMoreInTasks(int count) {
    return 'อีก $count รายการในแท็บงาน';
  }

  @override
  String taskReview(int count) {
    return 'ตรวจงาน ($count)';
  }

  @override
  String get actTzBangkok => 'กรุงเทพฯ (UTC+7)';

  @override
  String get actTzSingapore => 'สิงคโปร์ (UTC+8)';

  @override
  String get actTzTokyo => 'โตเกียว (UTC+9)';

  @override
  String get actTzIndia => 'อินเดีย (UTC+5:30)';

  @override
  String get actTzDubai => 'ดูไบ (UTC+4)';

  @override
  String get actTzLondon => 'ลอนดอน';

  @override
  String get actTzParisBerlin => 'ปารีส / เบอร์ลิน';

  @override
  String get actTzNewYork => 'นิวยอร์ก';

  @override
  String get actTzChicago => 'ชิคาโก';

  @override
  String get actTzLosAngeles => 'ลอสแอนเจลิส';

  @override
  String get actTzSydney => 'ซิดนีย์';

  @override
  String get actTzAuckland => 'โอ๊คแลนด์';

  @override
  String get actTzUtc => 'เวลาสากล (UTC)';

  @override
  String get welcomeTitle => 'ทุกเรื่องการเรียนรู้ รวมไว้ในที่เดียว';

  @override
  String get welcomeDescription =>
      'รวมรายวิชา งาน และความก้าวหน้าในการเรียนไว้ด้วยกัน เข้าสู่ระบบเพื่อใช้งานต่อ';

  @override
  String get welcomeFeatures => 'เพื่อการเรียนรู้ในทุกวัน';

  @override
  String get welcomeProgress => 'ความก้าวหน้า';

  @override
  String get welcomeBack => 'กลับหน้าต้อนรับ';

  @override
  String get profilePhotoTitle => 'รูปโปรไฟล์';

  @override
  String get profilePhotoHint =>
      'JPEG หรือ WebP ระบบจะครอบตัดเป็นสี่เหลี่ยมจัตุรัสและย่อเหลือประมาณ 256 พิกเซล เฉพาะคุณและครูประจำรายวิชาของคุณเท่านั้นที่เห็นรูปนี้';

  @override
  String get profilePhotoAdd => 'เพิ่มรูป';

  @override
  String get profilePhotoChange => 'เปลี่ยนรูป';

  @override
  String get profilePhotoRemove => 'ลบรูป';

  @override
  String get profilePhotoSaved => 'บันทึกรูปแล้ว';

  @override
  String get profilePhotoRemoved => 'ลบรูปแล้ว';

  @override
  String get profilePhotoCropTitle => 'ครอบตัดรูปของคุณ';

  @override
  String get profilePhotoCropHint =>
      'ลากและบีบนิ้วเพื่อเลือกส่วนที่จะแสดงในวงกลม';

  @override
  String get profilePhotoSave => 'บันทึกรูป';

  @override
  String profilePhotoSemantics(String name) {
    return 'รูปโปรไฟล์ของ $name';
  }

  @override
  String get errorAvatarType => 'เลือกรูป JPEG หรือ WebP';

  @override
  String get errorAvatarInputTooLarge => 'รูปใหญ่เกินไป (ไม่เกิน 10 MB)';

  @override
  String get errorAvatarDecode => 'อ่านรูปนี้ไม่ได้ ลองรูปอื่น';

  @override
  String get scanTitle => 'สแกนรหัสเช็กชื่อ';

  @override
  String get scanButton => 'สแกนรหัส';

  @override
  String get scanHint =>
      'หันกล้องไปที่คิวอาร์โค้ดของห้องเรียน หรือพิมพ์รหัสที่แสดงใต้คิวอาร์';

  @override
  String get scanCameraLabel => 'ภาพจากกล้องสำหรับสแกนคิวอาร์เช็กชื่อ';

  @override
  String get scanManualLabel => 'รหัสเช็กชื่อ';

  @override
  String get scanSubmit => 'ส่งรหัส';

  @override
  String get scanAgain => 'สแกนรหัสอื่น';

  @override
  String get scanCameraDenied =>
      'การเข้าถึงกล้องถูกปิดอยู่ โปรดอนุญาตในการตั้งค่า หรือพิมพ์รหัสด้านล่าง';

  @override
  String get scanNoCamera =>
      'อุปกรณ์นี้ไม่มีกล้องที่ใช้งานได้ โปรดพิมพ์รหัสด้านล่าง';

  @override
  String get scanCameraBusy =>
      'เปิดกล้องไม่ได้ (อาจมีแอปอื่นใช้อยู่) โปรดพิมพ์รหัสด้านล่างหรือลองอีกครั้ง';

  @override
  String scanOk(String status, String time) {
    return 'เช็กอินเป็น $status เมื่อ $time';
  }

  @override
  String scanOutOk(String time) {
    return 'เช็กเอาต์เมื่อ $time';
  }

  @override
  String scanAlready(String status) {
    return 'คุณถูกบันทึกเป็น $status แล้ว';
  }

  @override
  String get scanOutAlready => 'คุณเช็กเอาต์แล้ว';

  @override
  String get scanReasonInvalid => 'รหัสไม่ถูกต้อง';

  @override
  String get scanReasonExpired => 'รหัสหมดอายุแล้ว โปรดขอรหัสปัจจุบัน';

  @override
  String get scanReasonClosed => 'คาบเรียนนี้ปิดแล้ว';

  @override
  String get scanReasonNotMember => 'คุณไม่ใช่สมาชิกที่ใช้งานอยู่ของรายวิชานี้';

  @override
  String get scanReasonTooEarly => 'ยังไม่เปิดให้เช็กอิน';

  @override
  String get scanReasonTooLate => 'หมดเวลาเช็กอินแล้ว';

  @override
  String get scanReasonNoCheckin => 'โปรดเช็กอินก่อนเช็กเอาต์';

  @override
  String atdTimeIn(String time) {
    return 'เข้า $time';
  }

  @override
  String atdTimeOut(String time) {
    return 'ออก $time';
  }

  @override
  String get atdViaQr => 'คิวอาร์';

  @override
  String get staffTitle => 'การเข้างานของบุคลากร';

  @override
  String get staffSubtitle =>
      'ลงเวลาเข้า-ออกงาน ดูประวัติ และขอลาหรือขอแก้ไขเวลา';

  @override
  String get staffToday => 'วันนี้';

  @override
  String staffStatusIn(String time) {
    return 'ลงเวลาเข้างานตั้งแต่ $time';
  }

  @override
  String get staffStatusOut => 'คุณยังไม่ได้ลงเวลาเข้างาน';

  @override
  String staffStatusLate(String minutes) {
    return 'มาสาย $minutes นาที';
  }

  @override
  String get staffClockIn => 'ลงเวลาเข้า';

  @override
  String get staffClockOut => 'ลงเวลาออก';

  @override
  String get staffClockedIn => 'ลงเวลาเข้าแล้ว';

  @override
  String get staffClockedOut => 'ลงเวลาออกแล้ว';

  @override
  String get staffServerTime =>
      'เวลามาจากนาฬิกาของเซิร์ฟเวอร์ ไม่ใช่จากอุปกรณ์ของคุณ';

  @override
  String get staffSchedule => 'ตารางเวลางาน';

  @override
  String get staffNoSchedule =>
      'ยังไม่มีตารางเวลาของคุณ คุณยังลงเวลาเข้าได้ โดยวันนั้นจะบันทึกเป็นนอกตาราง';

  @override
  String staffScheduleLine(
    String days,
    String start,
    String end,
    String zone,
    String grace,
  ) {
    return '$days · $start–$end ($zone) ผ่อนผัน $grace นาที';
  }

  @override
  String get staffD1 => 'จ.';

  @override
  String get staffD2 => 'อ.';

  @override
  String get staffD3 => 'พ.';

  @override
  String get staffD4 => 'พฤ.';

  @override
  String get staffD5 => 'ศ.';

  @override
  String get staffD6 => 'ส.';

  @override
  String get staffD7 => 'อา.';

  @override
  String get staffHistory => '14 วันที่ผ่านมา';

  @override
  String get staffNoRows => 'ไม่มีบันทึกในช่วงนี้';

  @override
  String staffWorked(String hours) {
    return 'ชั่วโมงทำงาน: $hours';
  }

  @override
  String get staffOnTime => 'ตรงเวลา';

  @override
  String get staffLate => 'มาสาย';

  @override
  String get staffMissingCheckout => 'ไม่ได้ลงเวลาออก';

  @override
  String get staffInProgress => 'กำลังดำเนินอยู่';

  @override
  String get staffAbsent => 'ขาดงาน';

  @override
  String get staffLeave => 'ลา';

  @override
  String get staffUnscheduled => 'นอกตาราง';

  @override
  String get staffUpcoming => 'กำลังจะถึง';

  @override
  String get staffRequests => 'คำขอ';

  @override
  String get staffNewLeave => 'ขอลา';

  @override
  String get staffNewCorrection => 'ขอแก้ไขเวลา';

  @override
  String get staffKindLeave => 'ลา';

  @override
  String get staffKindCorrection => 'แก้ไขเวลา';

  @override
  String get staffFromDate => 'ตั้งแต่วันที่';

  @override
  String get staffToDate => 'ถึงวันที่';

  @override
  String get staffCorrectDate => 'วันที่ต้องการแก้ไข';

  @override
  String get staffReason => 'เหตุผล (3 ถึง 500 ตัวอักษร)';

  @override
  String get staffCorrectIn => 'เวลาเข้าที่ถูกต้อง (ไม่บังคับ)';

  @override
  String get staffCorrectOut => 'เวลาออกที่ถูกต้อง (ไม่บังคับ)';

  @override
  String get staffPickTime => 'เลือกเวลา';

  @override
  String get staffSubmit => 'ส่งคำขอ';

  @override
  String get staffSubmitted => 'ส่งคำขอแล้ว';

  @override
  String get staffNoRequests => 'ยังไม่มีคำขอ';

  @override
  String get staffCancelRequest => 'ยกเลิกคำขอ';

  @override
  String get staffCancelled => 'ยกเลิกคำขอแล้ว';

  @override
  String get staffStPending => 'รอพิจารณา';

  @override
  String get staffStApproved => 'อนุมัติแล้ว';

  @override
  String get staffStRejected => 'ไม่อนุมัติ';

  @override
  String get staffStCancelled => 'ยกเลิกแล้ว';

  @override
  String staffDecisionNote(String note) {
    return 'หมายเหตุการพิจารณา: $note';
  }

  @override
  String get staffSelfNote =>
      'ผู้บังคับบัญชาเป็นผู้พิจารณาคำขอของคุณ คุณอนุมัติคำขอของตนเองไม่ได้';

  @override
  String get staffNoSupervisor =>
      'ยังไม่มีผู้บังคับบัญชาที่ได้รับมอบหมายให้คุณ คำขอจะรอจนกว่าผู้ดูแลระบบจะกำหนดให้';

  @override
  String get staffNeedReason => 'โปรดระบุเหตุผลอย่างน้อย 3 ตัวอักษร';

  @override
  String get staffFixDates => 'เลือกวันที่ให้ถูกต้อง';

  @override
  String get staffNeedTime => 'โปรดระบุเวลาเข้าหรือเวลาออกที่ถูกต้อง';

  @override
  String get staffManager => 'เครื่องมือผู้บังคับบัญชา';

  @override
  String get staffTeam => 'สรุปทีม';

  @override
  String get staffNoTeam => 'คุณไม่ได้เป็นผู้บังคับบัญชาของใคร';

  @override
  String get staffToDecide => 'คำขอที่ต้องพิจารณา';

  @override
  String get staffNoneToDecide => 'ไม่มีรายการที่ต้องพิจารณา';

  @override
  String get staffApprove => 'อนุมัติ';

  @override
  String get staffReject => 'ไม่อนุมัติ';

  @override
  String get staffNoteOptional => 'หมายเหตุ (ไม่บังคับ)';

  @override
  String get staffDecided => 'บันทึกผลการพิจารณาแล้ว';

  @override
  String staffTeamLine(
    String name,
    String onTime,
    String late,
    String missing,
    String absent,
  ) {
    return '$name: ตรงเวลา $onTime, สาย $late, ไม่ลงเวลาออก $missing, ขาดงาน $absent';
  }

  @override
  String get demoTry => 'ลองใช้ LearnPulse เดโม';

  @override
  String get demoSelectorTitle => 'ลองใช้เดโม';

  @override
  String get demoSelectorSub =>
      'สำรวจ LearnPulse โดยไม่ต้องใช้อีเมลส่วนตัวและไม่ต้องพิมพ์รหัสผ่าน';

  @override
  String get demoStudent => 'เดโมสำหรับนักเรียน';

  @override
  String get demoStudentText =>
      'เข้าร่วมเวิร์กช็อปสดด้วยชื่อและรหัสเข้าร่วม คุณจะได้บัญชีนักเรียนชั่วคราว';

  @override
  String get demoPresenter => 'เดโมสำหรับผู้นำเสนอ';

  @override
  String get demoPresenterText =>
      'สำหรับผู้นำเสนอ: เริ่มเวิร์กช็อป แสดงคิวอาร์โค้ด และจัดการเซสชัน';

  @override
  String get demoRegularSignIn => 'เข้าสู่ระบบตามปกติ';

  @override
  String get demoPresenterSignInSub =>
      'เข้าสู่ระบบครั้งเดียว อุปกรณ์นี้จะคงการเข้าสู่ระบบไว้ จึงไม่ต้องพิมพ์ข้อมูลซ้ำ';

  @override
  String get demoPresenterNeedsTeacher =>
      'การควบคุมของผู้นำเสนอต้องใช้บัญชีครู';

  @override
  String get demoJoinTitle => 'เข้าร่วมเวิร์กช็อปสด';

  @override
  String get demoJoinSub => 'ใส่ชื่อและรหัสเวิร์กช็อป บัญชีจะถูกลบหลังจบงาน';

  @override
  String get demoCodeLabel => 'รหัสเวิร์กช็อป';

  @override
  String get demoCodeHint => 'แสดงบนหน้าจอผู้นำเสนอ และเปลี่ยนทุกนาที';

  @override
  String get demoNameLabel => 'ชื่อของคุณ';

  @override
  String get demoNameHint => 'แสดงให้ผู้นำเสนอเห็น ไม่เกิน 40 ตัวอักษร';

  @override
  String get demoJoinButton => 'เข้าร่วมเดโม';

  @override
  String get demoJoining => 'กำลังจองที่นั่ง…';

  @override
  String get demoSigningIn => 'กำลังเข้าสู่ระบบ…';

  @override
  String get demoWaiting =>
      'มีคนเข้าร่วมพร้อมกันจำนวนมาก กำลังลองใหม่อีกครั้ง…';

  @override
  String get demoScan => 'สแกนคิวอาร์โค้ด';

  @override
  String get demoScanHint => 'หันกล้องไปที่คิวอาร์โค้ดบนหน้าจอผู้นำเสนอ';

  @override
  String get demoCameraProblem => 'ไม่สามารถใช้กล้องได้ โปรดพิมพ์รหัสแทน';

  @override
  String get demoMsgBadCode => 'ใส่รหัสเวิร์กช็อป 12 ตัวอักษร';

  @override
  String get demoMsgBadName => 'ใช้ 1–40 ตัวอักษร และไม่ใช้ < หรือ >';

  @override
  String get demoMsgInvalid =>
      'รหัสไม่ถูกต้อง หมดอายุ หรือเดโมยังไม่เริ่ม โปรดตรวจสอบหน้าจอผู้นำเสนอ';

  @override
  String get demoMsgClosed => 'ปิดรับผู้เข้าร่วมเวิร์กช็อปนี้แล้ว';

  @override
  String get demoMsgFull => 'ที่นั่งเต็มแล้ว';

  @override
  String get demoMsgBusy => 'ลองมากเกินไป โปรดรอสักครู่แล้วลองใหม่';

  @override
  String get demoMsgSignedIn => 'คุณเข้าสู่ระบบอยู่แล้ว โปรดออกจากระบบก่อน';

  @override
  String get demoMsgAlready =>
      'อุปกรณ์นี้เข้าร่วมแล้ว ข้อมูลเข้าสู่ระบบแสดงเพียงครั้งเดียว';

  @override
  String get demoMsgAuthFailed =>
      'จองที่นั่งให้แล้ว แต่การเข้าสู่ระบบไม่สำเร็จ กดเข้าร่วมอีกครั้งเพื่อรับที่นั่งเดิม';

  @override
  String get demoMsgRateBusy =>
      'ขณะนี้มีการเข้าสู่ระบบหนาแน่นมาก กดเข้าร่วมอีกครั้งในอีกไม่กี่วินาที';

  @override
  String get demoMsgExpired => 'เซสชันเวิร์กช็อปนี้สิ้นสุดแล้ว';

  @override
  String get demoMsgNetwork =>
      'ไม่มีการเชื่อมต่อ โปรดตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง';

  @override
  String get demoMsgFailed => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String get demoHostTitle => 'โฮสต์การสาธิตสด';

  @override
  String get demoHostNone => 'ไม่พบเดโมสดสำหรับบัญชีนี้';

  @override
  String get demoHostTooltip => 'เดโมสด';

  @override
  String get demoStatusReady => 'พร้อมเริ่ม';

  @override
  String get demoStatusOpen => 'เปิดรับ';

  @override
  String get demoStatusPaused => 'พักอยู่';

  @override
  String get demoStatusClosed => 'ปิดรับแล้ว';

  @override
  String get demoStatusEnded => 'สิ้นสุดแล้ว';

  @override
  String demoReadyText(int join, String life) {
    return 'เวิร์กช็อปที่เตรียมไว้พร้อมแล้ว เมื่อเริ่ม จะเปิดรับเข้าร่วม $join นาที และเซสชันจะสิ้นสุดหลังจากนั้น $life ชั่วโมง ไม่สามารถพักหรือยกเลิกได้';
  }

  @override
  String get demoStart => 'เริ่มเดโม';

  @override
  String demoStartConfirm(int join, String life) {
    return 'เริ่มเดโมสดตอนนี้หรือไม่ เปิดรับเข้าร่วม $join นาที และเซสชันสิ้นสุด $life ชั่วโมงหลังจากเริ่ม';
  }

  @override
  String get demoEnd => 'จบเดโม';

  @override
  String get demoEndConfirm =>
      'จบเดโมหรือไม่ ทุกคนจะเสียสิทธิ์เข้าถึงเวิร์กช็อปทันที';

  @override
  String get demoPause => 'พักการเข้าร่วม';

  @override
  String get demoResume => 'เปิดรับต่อ';

  @override
  String get demoCloseJoins => 'ปิดรับเข้าร่วม';

  @override
  String demoJoinsLeft(String time) {
    return 'ปิดรับเข้าร่วมใน $time';
  }

  @override
  String demoLifeLeft(String time) {
    return 'เซสชันสิ้นสุดใน $time';
  }

  @override
  String get demoJoinWindowOver => 'หมดเวลารับเข้าร่วมแล้ว';

  @override
  String get demoCopyCode => 'คัดลอกรหัส';

  @override
  String get demoCopyLink => 'คัดลอกลิงก์';

  @override
  String get demoCopied => 'คัดลอกแล้ว';

  @override
  String get demoProjectHint =>
      'แสดงคิวอาร์โค้ดนี้บนโปรเจกเตอร์ ผู้เข้าร่วมสแกนด้วยกล้องโทรศัพท์';

  @override
  String demoCodeExpires(int seconds) {
    return 'รหัสใหม่ใน $seconds วินาที';
  }

  @override
  String get demoSeatsTotal => 'จำนวนที่นั่งทั้งหมด';

  @override
  String get demoSeatsAvailable => 'ว่าง';

  @override
  String get demoSeatsClaimed => 'จองแล้ว';

  @override
  String get demoSeatsActive => 'ใช้งานอยู่';

  @override
  String demoRecent(int claims, int refused) {
    return '10 นาทีที่ผ่านมา: เข้าร่วม $claims ถูกปฏิเสธ $refused';
  }

  @override
  String get demoEndedNotice => 'เซสชันสาธิตนี้สิ้นสุดแล้ว';

  @override
  String get demoOpenWorkshop => 'เปิดเวิร์กช็อป';

  @override
  String get demoBack => 'กลับ';
}
