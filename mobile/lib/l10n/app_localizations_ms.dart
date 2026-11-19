// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonDelete => 'Padam';

  @override
  String get commonConfirm => 'Sahkan';

  @override
  String get commonBack => 'Kembali';

  @override
  String get commonTryAgain => 'Cuba lagi';

  @override
  String get commonTryingAgain => 'Mencuba semula…';

  @override
  String get commonLoading => 'Memuatkan';

  @override
  String get commonStillWorking =>
      'Masih diproses… ini mengambil masa lebih lama daripada biasa.';

  @override
  String get commonSignOut => 'Log keluar';

  @override
  String get commonSignInAgain => 'Log masuk semula';

  @override
  String get commonNoDataYet => 'Belum ada data';

  @override
  String get commonUnknown => 'Tidak diketahui';

  @override
  String get configErrorTitle => 'Ralat konfigurasi';

  @override
  String get navDashboard => 'Papan pemuka';

  @override
  String get navTasks => 'Tugasan';

  @override
  String get navCourses => 'Kursus';

  @override
  String get navProfile => 'Profil';

  @override
  String get navOpenProfile => 'Buka profil';

  @override
  String get homeNameFallback => 'anda';

  @override
  String get relativeToday => 'Hari ini';

  @override
  String get relativeTomorrow => 'Esok';

  @override
  String get relativeYesterday => 'Semalam';

  @override
  String get roleTeacher => 'Guru';

  @override
  String get roleStudent => 'Pelajar';

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get languageHint =>
      'Disimpan pada peranti ini sahaja. Bahasa tidak pernah mengubah tarikh akhir, jadual atau zon waktu.';

  @override
  String get languageSelectorLabel => 'Pilih bahasa';

  @override
  String get authPortalEyebrow => 'PORTAL AKADEMIK LEARNPULSE';

  @override
  String get authWelcomeTitle => 'Selamat datang ke\nLearnPulse.';

  @override
  String get authTagline =>
      'Kursus, tugasan dan kehadiran. Pembelajaran anda, bersama-sama.';

  @override
  String get authSignIn => 'Log masuk';

  @override
  String get authEmail => 'E-mel';

  @override
  String get authPassword => 'Kata laluan';

  @override
  String get authShowPassword => 'Tunjukkan kata laluan';

  @override
  String get authHidePassword => 'Sembunyikan kata laluan';

  @override
  String get authForgotPassword => 'Lupa kata laluan?';

  @override
  String get authCreateStudentAccount => 'Cipta akaun pelajar';

  @override
  String get authCreateYourAccount => 'Cipta akaun anda';

  @override
  String get authFullName => 'Nama penuh';

  @override
  String get authPasswordHelper =>
      'Sekurang-kurangnya 10 aksara dengan huruf besar, huruf kecil dan satu digit';

  @override
  String get authTeacherNote =>
      'Guru: gunakan alamat e-mel yang menerima jemputan anda. Peranan anda ditetapkan oleh sekolah selepas anda mengesahkan e-mel.';

  @override
  String get authCreateAccount => 'Cipta akaun';

  @override
  String get authHaveAccount => 'Saya sudah mempunyai akaun';

  @override
  String get authResetTitle => 'Tetapkan semula kata laluan anda';

  @override
  String get authSendResetLink => 'Hantar pautan penetapan semula';

  @override
  String get authBackToSignIn => 'Kembali ke log masuk';

  @override
  String get authCheckEmailTitle => 'Semak e-mel anda';

  @override
  String get authYourEmailAddress => 'alamat e-mel anda';

  @override
  String authConfirmSent(String email) {
    return 'Kami telah menghantar pautan pengesahan ke $email. Buka pautan itu pada telefon ini untuk melengkapkan log masuk.';
  }

  @override
  String get authResendEmail => 'Hantar semula e-mel';

  @override
  String authResendEmailIn(int seconds) {
    return 'Hantar semula e-mel dalam ${seconds}s';
  }

  @override
  String get authConfirmedSignIn => 'Saya sudah mengesahkan - log masuk';

  @override
  String get authNewPasswordTitle => 'Pilih kata laluan baharu';

  @override
  String get authNewPassword => 'Kata laluan baharu';

  @override
  String get authSavePassword => 'Simpan kata laluan';

  @override
  String get authSessionExpiredTitle => 'Sesi tamat tempoh';

  @override
  String get authSignedOutTitle => 'Anda telah dilog keluar';

  @override
  String get authSessionEnded =>
      'Demi keselamatan anda, sesi anda telah tamat. Log masuk semula untuk menyambung dari tempat anda berhenti.';

  @override
  String get authCantReach => 'Tidak dapat menghubungi LearnPulse';

  @override
  String get authAccountNotReady => 'Akaun belum sedia';

  @override
  String noticeConfirmationSent(String email) {
    return 'E-mel pengesahan telah dihantar ke $email.';
  }

  @override
  String get noticeResetSent =>
      'Jika akaun wujud untuk alamat itu, pautan penetapan semula sedang dihantar.';

  @override
  String get noticePasswordUpdated => 'Kata laluan telah dikemas kini.';

  @override
  String get noticeNameSaved => 'Nama paparan telah disimpan.';

  @override
  String noticePasswordLinkSent(String email) {
    return 'Pautan penetapan semula kata laluan sedang dihantar ke $email.';
  }

  @override
  String get errorNetwork =>
      'Tiada sambungan ke pelayan. Semak rangkaian anda dan cuba lagi.';

  @override
  String get errorTimeout =>
      'Pelayan mengambil masa terlalu lama untuk menjawab. Cuba lagi sebentar nanti.';

  @override
  String get errorInvalidCredentials => 'E-mel atau kata laluan tidak betul.';

  @override
  String get errorEmailNotConfirmed => 'Sila sahkan alamat e-mel anda dahulu.';

  @override
  String get errorRateLimited =>
      'Terlalu banyak percubaan. Sila tunggu sebentar dan cuba lagi.';

  @override
  String get errorRateLimitedLong =>
      'Terlalu banyak percubaan. Sila tunggu beberapa minit dan cuba lagi.';

  @override
  String get errorWeakPassword =>
      'Pilih kata laluan yang lebih kukuh (sekurang-kurangnya 10 aksara dengan huruf besar, huruf kecil dan satu digit).';

  @override
  String get errorSignupDisabled => 'Pendaftaran ditutup buat masa ini.';

  @override
  String get errorFileForbidden =>
      'Anda tidak dibenarkan memuat naik atau membuka fail itu.';

  @override
  String get errorFileTooLarge => 'Fail itu terlalu besar (maksimum 10 MB).';

  @override
  String get errorFileType => 'Jenis fail itu tidak dibenarkan.';

  @override
  String get errorForbidden =>
      'Anda tidak mempunyai kebenaran untuk melakukannya.';

  @override
  String get errorCourseNotFound =>
      'Kursus itu tidak ditemui, atau anda tidak lagi mempunyai akses kepadanya.';

  @override
  String get errorValidation => 'Sila semak butiran dan cuba lagi.';

  @override
  String get errorSessionExpired =>
      'Sesi anda telah tamat. Sila log masuk semula.';

  @override
  String get errorUnknown => 'Sesuatu telah berlaku. Sila cuba lagi.';

  @override
  String get errorNotSignedIn => 'Anda belum log masuk.';

  @override
  String get errorNameNotSaved => 'Nama anda tidak dapat disimpan.';

  @override
  String get errorProfileNotReady =>
      'Akaun anda belum sedia. Sila cuba lagi sebentar nanti.';

  @override
  String get stateOfflineTitle => 'Anda di luar talian';

  @override
  String get stateOfflineMessage =>
      'Semak sambungan anda, kemudian cuba lagi. Apa-apa yang telah anda simpan adalah selamat.';

  @override
  String get stateTimeoutTitle => 'Ini mengambil masa terlalu lama';

  @override
  String get stateTimeoutMessage =>
      'Sambungan kelihatan perlahan. Cuba lagi, atau pindah ke tempat yang mempunyai isyarat lebih baik.';

  @override
  String get stateExpiredTitle => 'Sesi tamat tempoh';

  @override
  String get stateExpiredMessage =>
      'Demi keselamatan anda, anda telah dilog keluar. Log masuk semula untuk meneruskan.';

  @override
  String get stateForbiddenTitle => 'Akses dinafikan';

  @override
  String get stateForbiddenMessage =>
      'Akaun anda tidak mempunyai kebenaran untuk membuka ini.';

  @override
  String get stateNotFoundTitle => 'Tidak ditemui';

  @override
  String get stateNotFoundMessage =>
      'Ini mungkin telah dialih keluar, atau anda mungkin tidak lagi mempunyai akses kepadanya.';

  @override
  String get stateConflictTitle => 'Ini telah diubah di tempat lain';

  @override
  String get stateConflictMessage =>
      'Muat semula untuk melihat versi terkini, kemudian cuba lagi.';

  @override
  String get stateUnknownTitle => 'Tidak dapat memuatkan ini';

  @override
  String get stateUnknownMessage =>
      'Sesuatu yang tidak dijangka berlaku. Sila cuba lagi.';

  @override
  String stateCouldNotRefresh(String message) {
    return 'Tidak dapat memuat semula: $message Memaparkan angka yang dimuatkan kali terakhir.';
  }

  @override
  String get validationEmailRequired => 'Masukkan alamat e-mel anda';

  @override
  String get validationEmailInvalid => 'Masukkan alamat e-mel yang sah';

  @override
  String get validationPasswordRequired => 'Masukkan kata laluan anda';

  @override
  String get validationPasswordShort => 'Gunakan sekurang-kurangnya 10 aksara';

  @override
  String get validationPasswordMix =>
      'Sertakan huruf besar, huruf kecil dan satu digit';

  @override
  String get validationNameRequired => 'Masukkan nama anda';

  @override
  String get validationNameLong => 'Nama terlalu panjang';

  @override
  String get profileTeachingSummary => 'Ringkasan pengajaran';

  @override
  String get profileLearningSummary => 'Ringkasan pembelajaran';

  @override
  String get profileTeachingSubtitle => 'Kursus anda. Impak anda.';

  @override
  String get profileLearningSubtitle =>
      'Pandangan jelas tentang prestasi anda.';

  @override
  String get profileTeachingIdentity => 'IDENTITI PENGAJARAN ANDA';

  @override
  String get profileLearningIdentity => 'IDENTITI PEMBELAJARAN ANDA';

  @override
  String get profileNoName => 'Nama belum ditetapkan';

  @override
  String get profileAccountSettings => 'Akaun & tetapan';

  @override
  String get profileCoursesRosters => 'Kursus dan senarai pelajar saya';

  @override
  String get profileCoursesAttendance => 'Kursus dan kehadiran saya';

  @override
  String get metricCoursesOwned => 'Kursus dimiliki';

  @override
  String metricArchived(int count) {
    return '$count diarkibkan';
  }

  @override
  String get metricActiveStudents => 'Pelajar aktif';

  @override
  String get metricAwaitingGrading => 'Menunggu penggredan';

  @override
  String get metricAttendanceRate => 'Kadar kehadiran';

  @override
  String metricOpenSessions(int count) {
    return '$count sesi dibuka';
  }

  @override
  String get metricTeacherNote =>
      'Angka hanya merangkumi kursus aktif anda sendiri dan pelajar aktifnya.';

  @override
  String get metricEnrolledCourses => 'Kursus yang didaftarkan';

  @override
  String get metricAssignmentsDone => 'Tugasan selesai';

  @override
  String metricDoneOfPublished(int done, int published) {
    return '$done daripada $published';
  }

  @override
  String get metricSubmittedOrGraded => 'Dihantar atau digred';

  @override
  String get metricAwaitingGrade => 'Menunggu gred';

  @override
  String get metricGraded => 'Digred';

  @override
  String get metricNoGradesYet => 'Belum ada gred';

  @override
  String metricAverage(String value) {
    return 'Purata $value';
  }

  @override
  String get metricReturnedRevision => 'Dipulangkan untuk semakan semula';

  @override
  String get metricStudentNote =>
      'Selesai = dihantar atau digred, daripada tugasan yang diterbitkan dalam kursus aktif anda. Kehadiran = (hadir + lewat) / (hadir + lewat + tidak hadir). Penyiapan pelajaran tidak dijejaki.';

  @override
  String get accountTitle => 'Akaun';

  @override
  String get accountRegisteredEmail => 'E-mel berdaftar';

  @override
  String get accountRole => 'Peranan';

  @override
  String get accountManagedNote =>
      'E-mel dan peranan anda diurus oleh pentadbir sekolah dan tidak boleh diubah dalam aplikasi.';

  @override
  String get accountPassword => 'Kata laluan';

  @override
  String get accountEmailResetLink =>
      'E-melkan saya pautan penetapan semula kata laluan';

  @override
  String get accountPrivacy => 'Privasi & keselamatan';

  @override
  String get accountPrivacyText =>
      'Guru hanya melihat pelajar yang mendaftar dalam kursus mereka sendiri; pelajar hanya melihat hasil kerja mereka sendiri dan guru kursus mereka. Data anda tidak terbuka kepada umum dan tiada direktori awam. Fail adalah peribadi dan hanya boleh dibuka melalui pautan jangka pendek.';

  @override
  String get accountAbout => 'Tentang';

  @override
  String accountVersion(String version) {
    return 'Versi $version (beta)';
  }

  @override
  String get accountSignOutTitle => 'Log keluar?';

  @override
  String get accountSignOutBody =>
      'Anda perlu log masuk semula untuk menggunakan LearnPulse.';

  @override
  String get accountEyebrow => 'Profil';

  @override
  String get accountDescription =>
      'Urus identiti, akses akaun dan privasi anda.';

  @override
  String get accountPersonalDetails => 'Butiran peribadi';

  @override
  String get accountDisplayName => 'Nama paparan';

  @override
  String get accountSaveName => 'Simpan nama';

  @override
  String get commonAll => 'Semua';

  @override
  String get commonActive => 'Aktif';

  @override
  String get commonArchived => 'Diarkibkan';

  @override
  String get commonDraft => 'Draf';

  @override
  String get commonPublished => 'Diterbitkan';

  @override
  String get commonPublish => 'Terbitkan';

  @override
  String get commonCreate => 'Cipta';

  @override
  String get commonTitle => 'Tajuk';

  @override
  String get commonCopy => 'Salin';

  @override
  String get commonDone => 'Selesai';

  @override
  String get commonJoin => 'Sertai';

  @override
  String get commonRemove => 'Keluarkan';

  @override
  String get commonChange => 'Ubah';

  @override
  String get commonOpen => 'Dibuka';

  @override
  String get commonClosed => 'Ditutup';

  @override
  String get commonAttendance => 'Kehadiran';

  @override
  String get commonAssignments => 'Tugasan';

  @override
  String get commonLessons => 'Pelajaran';

  @override
  String get commonFiles => 'Fail';

  @override
  String commonRemoveNamed(String name) {
    return 'Keluarkan $name';
  }

  @override
  String commonOpenNamed(String name) {
    return 'Buka $name';
  }

  @override
  String get statusSubmitted => 'Dihantar';

  @override
  String get statusReturned => 'Dipulangkan';

  @override
  String get statusToGrade => 'Untuk dinilai';

  @override
  String get attPresent => 'Hadir';

  @override
  String get attLate => 'Lewat';

  @override
  String get attExcused => 'Dibenarkan tidak hadir';

  @override
  String get attAbsent => 'Tidak hadir';

  @override
  String get validationTitleRequired => 'Masukkan tajuk';

  @override
  String get validationTitleLong => 'Gunakan paling banyak 120 aksara';

  @override
  String get validationMaxScoreRange => 'Masukkan nombor dari 1 hingga 1000';

  @override
  String get validationJoinCodeRequired => 'Masukkan kod kursus';

  @override
  String get validationJoinCodeFormat =>
      'Kod mempunyai 8 huruf/digit (tanpa I, O, 0 atau 1)';

  @override
  String get errorScoreWhole => 'Masukkan nombor bulat';

  @override
  String errorScoreRange(int max) {
    return 'Skor mesti antara 0 dan $max';
  }

  @override
  String get errorFeedbackLong =>
      'Maklum balas terlalu panjang (maksimum 5000 aksara).';

  @override
  String get errorReturnReason =>
      'Terangkan apa yang perlu disemak semula oleh pelajar.';

  @override
  String get errorFileLarger => 'Fail ini lebih besar daripada 10 MB.';

  @override
  String get errorFileEmpty => 'Fail ini kosong.';

  @override
  String get errorWriteOrAttach => 'Tulis jawapan atau lampirkan fail.';

  @override
  String get errorUploadIncomplete =>
      'Fail tidak selesai dimuat naik. Ketik Hantar untuk cuba lagi.';

  @override
  String get errorSubmissionChanged =>
      'Hantaran anda telah diubah pada peranti lain. Muat semula untuk meneruskan; teks anda disimpan.';

  @override
  String get errorGradeConflict =>
      'Hantaran ini telah berubah (contohnya pelajar menghantar semula). Muat semula untuk melihat yang terkini; skor dan maklum balas yang anda taip disimpan.';

  @override
  String get errorFileNoAccess => 'Anda tidak mempunyai akses kepada fail ini.';

  @override
  String get errorFileTypeList =>
      'Jenis fail itu tidak dibenarkan. Gunakan pdf, docx, zip, png, jpg, webp atau txt.';

  @override
  String get errorOpenFile => 'Tidak dapat membuka fail.';

  @override
  String noticeJoinedCourse(String title) {
    return 'Telah menyertai $title.';
  }

  @override
  String get noticeTheCourse => 'kursus itu';

  @override
  String get noticeSubmissionSaved => 'Hantaran telah disimpan.';

  @override
  String get noticeGradeSaved => 'Penilaian telah disimpan.';

  @override
  String get noticeReturnedForRevision =>
      'Dipulangkan kepada pelajar untuk pembetulan.';

  @override
  String dashHello(String name) {
    return 'Helo, $name';
  }

  @override
  String dashActiveCourses(int count) {
    return '$count kursus aktif';
  }

  @override
  String dashTeacherHeroDetail(String courses, int grading) {
    return '$courses · $grading menunggu penilaian';
  }

  @override
  String dashStudentHeroDetail(String courses, int done, int published) {
    return '$courses · $done daripada $published tugasan selesai';
  }

  @override
  String get dashStatCourses => 'Kursus';

  @override
  String get dashStatToGrade => 'Untuk dinilai';

  @override
  String get dashStatStudents => 'Pelajar';

  @override
  String get dashStatDone => 'Selesai';

  @override
  String get dashServices => 'Perkhidmatan akademik';

  @override
  String get dashServiceGrading => 'Penilaian';

  @override
  String get dashServiceProfile => 'Profil saya';

  @override
  String get dashServiceProfileDetail => 'Kemajuan & akaun';

  @override
  String dashDetailActive(int count) {
    return '$count aktif';
  }

  @override
  String dashDetailToReview(int count) {
    return '$count untuk disemak';
  }

  @override
  String dashDetailOpen(int count) {
    return '$count dibuka';
  }

  @override
  String dashDetailEnrolled(int count) {
    return '$count berdaftar';
  }

  @override
  String dashDetailPublished(int count) {
    return '$count diterbitkan';
  }

  @override
  String get dashEmptyTeacherTitle => 'Belum ada apa-apa untuk dipaparkan';

  @override
  String get dashEmptyTeacherHint =>
      'Cipta kursus dalam tab Kursus. Halaman ini akan terisi apabila pelajar menyertai, menghantar tugasan dan hadir.';

  @override
  String get dashNeedsAttention => 'Perlu perhatian';

  @override
  String get dashAllCaughtUp => 'Semua sudah selesai';

  @override
  String dashSubmissionsAwaiting(int count) {
    return '$count hantaran menunggu penilaian';
  }

  @override
  String dashSubmittedLine(int received, int expected, String rate) {
    return 'Dihantar: $received daripada $expected · kehadiran $rate';
  }

  @override
  String get dashReviewSubmissions => 'Semak hantaran';

  @override
  String get dashUpcomingDeadlines => 'Tarikh akhir yang akan datang';

  @override
  String get dashNoDeadlines => 'Tiada tarikh akhir yang akan datang.';

  @override
  String get dashNothingDueSoon =>
      'Tiada yang perlu diserahkan tidak lama lagi.';

  @override
  String get dashRecentSubmissions => 'Hantaran terkini';

  @override
  String get dashNoSubmissions => 'Belum ada hantaran.';

  @override
  String dashArchivedStudents(String students) {
    return 'Diarkibkan · $students';
  }

  @override
  String dashCountStudents(int count) {
    return '$count pelajar';
  }

  @override
  String dashCountAssignments(int count) {
    return '$count tugasan';
  }

  @override
  String dashCountSessions(int count) {
    return '$count sesi';
  }

  @override
  String dashToGradeCount(int count) {
    return '$count untuk dinilai';
  }

  @override
  String get dashAllFigures => 'Semua angka';

  @override
  String get dashActiveCoursesLabel => 'Kursus aktif';

  @override
  String get dashOutstanding => 'Kerja tertunggak';

  @override
  String dashSubmittedOf(int received, int expected) {
    return '$received daripada $expected dihantar';
  }

  @override
  String get dashPublishedAssignments => 'Tugasan diterbitkan';

  @override
  String dashGradedReturned(int graded, int returned) {
    return '$graded dinilai · $returned dipulangkan';
  }

  @override
  String get dashTeacherFootnote =>
      'Hanya pelajar aktif dikira. Kursus yang diarkibkan tidak termasuk dalam angka tugasan dan kehadiran. Kadar kehadiran = (Hadir + Lewat) ÷ (Hadir + Lewat + Tidak hadir); Dibenarkan tidak hadir tidak dikira.';

  @override
  String get dashEmptyStudentTitle => 'Belum ada kursus';

  @override
  String get dashEmptyStudentHint =>
      'Buka tab Kursus dan masukkan kod sertai daripada guru anda.';

  @override
  String get dashNeedsYourAttention => 'Perlu perhatian anda';

  @override
  String get dashYourNextStep => 'Langkah seterusnya';

  @override
  String dashOverdueCount(int count) {
    return '$count tugasan lewat';
  }

  @override
  String get dashReadyToLearn => 'Bersedia untuk belajar?';

  @override
  String get dashExploreCourses =>
      'Terokai kursus anda dan sambung dari tempat anda berhenti.';

  @override
  String get dashOpenCourses => 'Buka kursus';

  @override
  String get dashStatusRevise => 'Semak semula';

  @override
  String get dashStatusTodo => 'Perlu dibuat';

  @override
  String get dashLearningProgress => 'Kemajuan pembelajaran';

  @override
  String dashDoneOfPublished(int done, int published) {
    return '$done daripada $published tugasan selesai';
  }

  @override
  String dashAttendanceValue(String value) {
    return 'Kehadiran $value';
  }

  @override
  String get dashMyCourses => 'Kursus saya';

  @override
  String get dashArchivedReadOnly => 'Diarkibkan (baca sahaja)';

  @override
  String dashCourseProgressLine(int done, int total, String rate) {
    return '$done daripada $total tugasan selesai · kehadiran $rate';
  }

  @override
  String get dashRecentResults => 'Keputusan terkini';

  @override
  String get dashNoGraded => 'Belum ada tugasan yang dinilai.';

  @override
  String get dashFeedbackAvailable => 'maklum balas tersedia';

  @override
  String get dashNewLessons => 'Pelajaran baharu';

  @override
  String get dashNotStarted => 'Belum bermula';

  @override
  String dashOverdueHint(int count) {
    return '$count lewat';
  }

  @override
  String get dashNeedsRevision => 'Perlu disemak semula';

  @override
  String get dashStudentFootnote =>
      'Kemajuan kursus = tugasan yang dihantar atau dinilai ÷ tugasan yang diterbitkan. Kerja yang dipulangkan belum dikira selesai sehingga anda menghantar semula. Pelajaran tidak dijejaki sebagai selesai.';

  @override
  String get dashNothingToShow => 'Belum ada apa-apa untuk dipaparkan.';

  @override
  String get courseEyebrowTeaching => 'Mengajar';

  @override
  String get courseEyebrowLearning => 'Pembelajaran saya';

  @override
  String get courseYourCourses => 'Kursus anda';

  @override
  String get courseDescTeacher =>
      'Urus pelajaran, tugasan dan kehadiran dalam setiap kursus.';

  @override
  String get courseDescStudent =>
      'Buka kursus untuk meneruskan pelajaran dan tugasan.';

  @override
  String get courseNew => 'Kursus baharu';

  @override
  String get courseJoin => 'Sertai kursus';

  @override
  String get courseServiceLabel => 'Perkhidmatan kursus';

  @override
  String get courseAllContent => 'Semua kandungan kursus';

  @override
  String get courseNoInCategory =>
      'Tiada kursus dalam kategori ini. Pilih penapis lain.';

  @override
  String courseCouldNotRefresh(String message) {
    return 'Tidak dapat menyegarkan: $message';
  }

  @override
  String get courseEmptyTeacherTitle => 'Belum ada kursus';

  @override
  String get courseEmptyTeacherHint =>
      'Cipta kursus pertama anda, kemudian kongsikan kodnya dengan pelajar.';

  @override
  String get courseEmptyStudentTitle => 'Anda belum menyertai sebarang kursus';

  @override
  String get courseEmptyStudentHint =>
      'Minta kod kursus daripada guru anda dan ketik \"Sertai kursus\".';

  @override
  String get courseAreaTeachingAssignments => 'Mengajar · Tugasan';

  @override
  String get courseAreaLearningAssignments => 'Pembelajaran · Tugasan';

  @override
  String get courseAreaTeachingAttendance => 'Mengajar · Kehadiran';

  @override
  String get courseAreaLearningAttendance => 'Pembelajaran · Kehadiran';

  @override
  String get courseTapToManage => 'Ketik untuk mengurus';

  @override
  String courseTeacherName(String name) {
    return 'Guru: $name';
  }

  @override
  String get courseTeachingCourse => 'Kursus yang diajar';

  @override
  String get courseEnrolledCourse => 'Kursus yang didaftar';

  @override
  String get courseTeachingWorkspace => 'Ruang mengajar anda';

  @override
  String get courseLearningWorkspace => 'Ruang pembelajaran anda';

  @override
  String get courseManage => 'Urus kursus';

  @override
  String get courseOpen => 'Buka kursus';

  @override
  String get courseLearningEyebrow => 'Ruang pembelajaran';

  @override
  String get courseArchivedNote =>
      'Kursus ini diarkibkan. Ia kekal kelihatan tetapi baca sahaja.';

  @override
  String get courseEdit => 'Sunting kursus';

  @override
  String get courseDescriptionOptional => 'Penerangan (pilihan)';

  @override
  String get courseCreated => 'Kursus telah dicipta';

  @override
  String get courseShareCode => 'Kongsikan kod ini dengan pelajar anda:';

  @override
  String get courseCodeLabel => 'Kod kursus';

  @override
  String get courseRemovedMsg =>
      'Anda telah dikeluarkan daripada kursus ini. Minta guru anda menambah anda semula.';

  @override
  String get courseCodeInvalid =>
      'Kod itu tidak sah, atau kursus telah ditutup.';

  @override
  String get courseArchiveTitle => 'Arkibkan kursus ini?';

  @override
  String get courseReopenTitle => 'Buka semula kursus ini?';

  @override
  String get courseArchiveBody =>
      'Pelajar kekal dengan akses baca sahaja, tetapi tiada pelajar baharu boleh menyertai dengan kod.';

  @override
  String get courseReopenBody =>
      'Pelajar akan dapat menyertai dengan kod itu semula.';

  @override
  String get courseArchiveAction => 'Arkibkan';

  @override
  String get courseReopenAction => 'Buka semula';

  @override
  String get courseRemoveTitle => 'Keluarkan pelajar?';

  @override
  String courseRemoveBody(String name) {
    return '$name akan kehilangan akses kepada kursus ini dan tidak boleh menyertai semula dengan kod.';
  }

  @override
  String get courseThisStudent => 'Pelajar ini';

  @override
  String get courseInviteTitle => 'Jemput pelajar pertama anda';

  @override
  String get courseInviteBody =>
      'Kongsikan kod sertai di bawah. Kehadiran, penilaian dan kemajuan akan terisi apabila pelajar menyertai.';

  @override
  String get courseSvcSubmissions => 'Hantaran';

  @override
  String get courseSvcReviewWork => 'Semak kerja';

  @override
  String get courseSvcRoster => 'Senarai nama';

  @override
  String get courseSvcContent => 'Kandungan';

  @override
  String get courseWeeklyAttendance => 'Kehadiran mingguan';

  @override
  String get courseAdmin => 'Pentadbiran kursus';

  @override
  String get courseJoinCode => 'Kod sertai';

  @override
  String get courseCopyCode => 'Salin kod';

  @override
  String get courseCodeCopied => 'Kod telah disalin';

  @override
  String get courseArchivedNoJoin =>
      'Diarkibkan: pelajar tidak boleh menyertai sehingga anda membuka semula kursus.';

  @override
  String get courseReopenCourse => 'Buka semula kursus';

  @override
  String get courseArchiveCourse => 'Arkibkan kursus';

  @override
  String courseStudentsTitle(int count) {
    return 'Pelajar ($count)';
  }

  @override
  String get courseNoStudents =>
      'Belum ada pelajar. Kongsikan kod sertai di atas.';

  @override
  String courseJoinedTap(String date) {
    return 'Menyertai pada $date · ketik untuk kemajuan';
  }

  @override
  String courseRemovedCount(int count) {
    return '$count pelajar dikeluarkan (tiada akses)';
  }

  @override
  String get classYourClass => 'Kelas anda';

  @override
  String get classArchivedReadOnly => 'Diarkibkan · baca sahaja';

  @override
  String classHeroSemantics(int students, int sessions, String toGrade) {
    return '$students pelajar, $sessions sesi kehadiran dibuka, $toGrade hantaran untuk dinilai';
  }

  @override
  String get classUnknownNumber => 'bilangan tidak diketahui';

  @override
  String get classOpenSessions => 'Sesi dibuka';

  @override
  String get classNoSessions => 'Tiada sesi';

  @override
  String classRateValue(String value) {
    return 'Kadar kelas $value';
  }

  @override
  String get classSessions => 'Sesi';

  @override
  String get classNoAttendanceSessions =>
      'Belum ada sesi kehadiran. Cipta satu dalam bahagian Kehadiran untuk mula menjejak.';

  @override
  String get classLatestSession => 'Sesi terkini';

  @override
  String get classSessionFallback => 'Sesi';

  @override
  String classNotMarked(int count) {
    return 'Belum direkodkan $count';
  }

  @override
  String get classNothingToGrade => 'Tiada untuk dinilai';

  @override
  String get classPublished => 'Diterbitkan';

  @override
  String get classDrafts => 'Draf';

  @override
  String get classNoPublished => 'Belum ada tugasan yang diterbitkan.';

  @override
  String get classSubmissionsReceived => 'Hantaran diterima';

  @override
  String classDueLower(String when) {
    return 'tarikh akhir $when';
  }

  @override
  String get classNoRecent => 'Tiada aktiviti terkini';

  @override
  String get classNoRecentHint =>
      'Kerja yang dihantar akan dipaparkan di sini apabila pelajar menyerahkannya.';

  @override
  String get classAttendanceByStudent => 'Kehadiran mengikut pelajar';

  @override
  String get classNoStudentsEnrolled => 'Belum ada pelajar berdaftar';

  @override
  String get classShareCode =>
      'Kongsikan kod sertai supaya pelajar boleh mendaftar.';

  @override
  String lessonFilesCount(int count) {
    return '$count fail';
  }

  @override
  String get lessonNew => 'Pelajaran baharu';

  @override
  String get lessonNoneYet => 'Belum ada pelajaran';

  @override
  String get lessonEmptyTeacher =>
      'Cipta draf, tambah fail, kemudian terbitkan untuk pelajar.';

  @override
  String get lessonEmptyStudent =>
      'Guru anda belum menerbitkan sebarang pelajaran untuk kursus ini.';

  @override
  String get lessonText => 'Teks pelajaran';

  @override
  String get lessonCreateDraft => 'Cipta draf';

  @override
  String get lessonDeleteTitle => 'Padam pelajaran?';

  @override
  String get lessonDeleteBody =>
      'Pelajaran dan failnya akan hilang untuk semua orang. Tindakan ini tidak boleh dibatalkan.';

  @override
  String get lessonTitle => 'Pelajaran';

  @override
  String get lessonGone => 'Pelajaran ini sudah tidak wujud.';

  @override
  String get lessonNoFilesAttached => 'Tiada fail dilampirkan.';

  @override
  String get lessonAttach => 'Lampirkan fail';

  @override
  String get lessonPublication => 'Penerbitan & akses';

  @override
  String get lessonSaveFirst =>
      'Simpan kandungan anda sebelum menukar keterlihatannya.';

  @override
  String get lessonUnpublish => 'Batalkan penerbitan';

  @override
  String get lessonDelete => 'Padam pelajaran';

  @override
  String get lessonEditEyebrow => 'Sunting pelajaran';

  @override
  String get lessonPublishedDesc =>
      'Diterbitkan · Pelajar boleh membaca pelajaran ini.';

  @override
  String get lessonDraftDesc =>
      'Draf · Hanya anda yang boleh melihat pelajaran ini.';

  @override
  String get lessonContent => 'Kandungan pembelajaran';

  @override
  String get lessonSaveChanges => 'Simpan perubahan';

  @override
  String lessonCourseEyebrow(String course) {
    return '$course · Pelajaran';
  }

  @override
  String get lessonReadExplore => 'Baca, teroka, kemudian praktikkan.';

  @override
  String get lessonNoText => 'Tiada teks pelajaran.';

  @override
  String get lessonSupporting => 'Sumber sokongan untuk pelajaran ini.';

  @override
  String get lessonNoFiles => 'Tiada fail untuk pelajaran ini.';

  @override
  String get asgNotSubmitted => 'Belum dihantar';

  @override
  String asgGradedScore(int score, int max) {
    return 'Dinilai $score/$max';
  }

  @override
  String get asgReturnedForRevision => 'Dipulangkan untuk pembetulan';

  @override
  String get asgNone => 'Belum ada tugasan';

  @override
  String get asgStudentEmptyHint =>
      'Kerja baharu daripada guru anda akan dipaparkan di sini.';

  @override
  String get asgNoDeadline => 'Tiada tarikh akhir';

  @override
  String asgDue(String when) {
    return 'Tarikh akhir $when';
  }

  @override
  String asgResultGraded(int score, int max) {
    return 'Dinilai: $score/$max';
  }

  @override
  String asgFeedbackLine(String text) {
    return 'Maklum balas: $text';
  }

  @override
  String get asgGradedLocked => 'Hantaran ini telah dinilai dan dikunci.';

  @override
  String get asgReviseResubmit =>
      'Semak semula kerja anda di bawah dan hantar semula.';

  @override
  String get asgSavedSubmission => 'Hantaran anda yang disimpan';

  @override
  String asgSavedLine(String when, int version) {
    return 'Disimpan pada $when · versi $version';
  }

  @override
  String get asgReload => 'Muat semula hantaran saya';

  @override
  String get asgEyebrowWorkspace => 'Tugasan / Ruang kerja anda';

  @override
  String asgMaxScore(int score) {
    return 'Skor maksimum $score';
  }

  @override
  String get asgDeadlinePassed =>
      'Tarikh akhir telah berlalu. Hantaran ditutup.';

  @override
  String get asgBrief => 'Ringkasan tugasan';

  @override
  String get asgNoInstructions => 'Tiada arahan.';

  @override
  String get asgUploading => 'Memuat naik fail…';

  @override
  String get asgSaving => 'Menyimpan…';

  @override
  String get asgSubmit => 'Hantar';

  @override
  String get asgResubmit => 'Hantar semula';

  @override
  String get asgYourResponse => 'Respons anda';

  @override
  String get asgFirstHint =>
      'Tulis jawapan anda atau lampirkan kerja anda. Hantar apabila anda bersedia.';

  @override
  String get asgUpdateHint =>
      'Kemas kini jawapan anda di bawah. Versi yang disimpan kekal tersedia sehingga anda menghantar semula.';

  @override
  String get asgYourAnswer => 'Jawapan anda';

  @override
  String get asgAnswerHint =>
      'Mulakan dengan pendekatan anda, kemudian terangkan apa yang anda temui…';

  @override
  String asgUploadPrivately(String size) {
    return '$size · akan dimuat naik secara peribadi';
  }

  @override
  String get asgRemoveAttachmentTip => 'Keluarkan lampiran';

  @override
  String get asgReplaceFile => 'Gantikan fail yang dilampirkan';

  @override
  String get asgAttachFile => 'Lampirkan fail';

  @override
  String get asgRemoveSaved => 'Keluarkan lampiran saya yang disimpan';

  @override
  String get asgSavedOnSubmit => 'Kerja anda disimpan apabila anda menghantar.';

  @override
  String get asgNewTitle => 'Tugasan baharu';

  @override
  String get asgEditTitle => 'Sunting tugasan';

  @override
  String get asgInstructions => 'Arahan';

  @override
  String get asgMaxScoreLabel => 'Skor maksimum';

  @override
  String get asgSetDeadline => 'Tetapkan tarikh akhir';

  @override
  String get asgRemoveDeadline => 'Buang tarikh akhir';

  @override
  String get asgSaveDraft => 'Simpan draf';

  @override
  String get asgTeacherEmptyHint =>
      'Cipta draf, kemudian terbitkan untuk pelajar.';

  @override
  String get asgPublishTitle => 'Terbitkan tugasan?';

  @override
  String get asgPublishBody =>
      'Pelajar berdaftar akan melihatnya dan boleh mula menghantar kerja.';

  @override
  String get asgGone => 'Tugasan ini tidak lagi tersedia.';

  @override
  String asgSubmissionsCount(int count) {
    return 'Hantaran ($count)';
  }

  @override
  String get asgTeachingEyebrow => 'Mengajar / Tugasan';

  @override
  String get asgReviewDesc => 'Semak hantaran dan majukan pembelajaran.';

  @override
  String get asgPrepareDesc =>
      'Sediakan ringkasan anda, kemudian terbitkan ke kursus anda.';

  @override
  String get asgBriefTitle => 'Ringkasan tugasan';

  @override
  String get asgDraftsHidden =>
      'Pelajar tidak dapat melihat draf. Terbitkan untuk menerima hantaran.';

  @override
  String get asgNoSubmissions => 'Belum ada hantaran';

  @override
  String get asgNoSubmissionsHint =>
      'Kerja pelajar akan dipaparkan di sini apabila dihantar.';

  @override
  String asgSubmittedVersion(String when, int version) {
    return 'Dihantar pada $when · versi $version';
  }

  @override
  String get asgGrade => 'Nilai';

  @override
  String get asgReview => 'Semak';

  @override
  String gradeReviewEyebrow(String title) {
    return 'Semak · $title';
  }

  @override
  String get gradeStudentSubmission => 'Hantaran pelajar';

  @override
  String get gradeReadDesc =>
      'Baca kerja itu, kemudian berikan langkah seterusnya yang jelas.';

  @override
  String get gradeStatusTitle => 'Status hantaran';

  @override
  String get gradeVersion => 'Versi';

  @override
  String get gradeMaxScore => 'Skor maksimum';

  @override
  String gradeSubmittedAt(String when) {
    return 'Dihantar pada $when';
  }

  @override
  String get gradeStudentAnswer => 'Jawapan pelajar';

  @override
  String get gradeNoText => '(tiada teks)';

  @override
  String get gradeReloadLatest => 'Muat semula yang terkini';

  @override
  String get gradeWaiting =>
      'Menunggu pelajar menyemak semula dan menghantar semula.';

  @override
  String gradeYourFeedback(String text) {
    return 'Maklum balas anda: $text';
  }

  @override
  String get gradeAndFeedback => 'Penilaian dan maklum balas';

  @override
  String get gradeHint =>
      'Skor merekodkan pencapaian. Maklum balas menunjukkan apa yang perlu dibuat seterusnya.';

  @override
  String get gradeScore => 'Skor';

  @override
  String gradeScoreRangeLabel(int max) {
    return 'Skor (0–$max)';
  }

  @override
  String get gradeFeedbackToStudent => 'Maklum balas kepada pelajar';

  @override
  String get gradeFeedback => 'Maklum balas';

  @override
  String get gradeSaveNew => 'Simpan penilaian baharu';

  @override
  String get gradeSave => 'Simpan penilaian';

  @override
  String get gradeReturn => 'Pulangkan untuk pembetulan';

  @override
  String get gradeHistory => 'Sejarah';

  @override
  String get gradeNoHistory => 'Belum ada tindakan penilaian.';

  @override
  String get errorNoteTooLong =>
      'Catatan terlalu panjang (maksimum 500 aksara).';

  @override
  String get errorRecordChanged =>
      'Rekod ini telah berubah di tempat lain. Nilai terkini dipaparkan; sila cuba lagi.';

  @override
  String get errorSessionNotFound => 'Sesi tidak ditemui.';

  @override
  String get errorActivityNotFound => 'Aktiviti tidak ditemui.';

  @override
  String get errorAssignmentUnavailable => 'Tugasan ini tidak lagi tersedia.';

  @override
  String get errorCourseUnavailable => 'Kursus ini tidak lagi tersedia.';

  @override
  String get commonLoadMore => 'Muat lagi';

  @override
  String get commonLoadingEllipsis => 'Memuatkan…';

  @override
  String get actPolicyTeacherMarked => 'Guru merekod';

  @override
  String get actPolicySelfReported => 'Pelajar melapor';

  @override
  String get actPolicyTeacherVerified => 'Guru mengesahkan';

  @override
  String get actPolicyHintTeacherMarked => 'Guru anda merekod penyempurnaan.';

  @override
  String get actPolicyHintSelfReported =>
      'Anda menandakan sendiri bahawa ia selesai.';

  @override
  String get actPolicyHintTeacherVerified =>
      'Anda menghantar dan guru anda mengesahkan.';

  @override
  String get actPolicyDetailTeacherMarked =>
      'Anda merekod siapa yang selesai. Pelajar hanya melihat status mereka.';

  @override
  String get actPolicyDetailSelfReported =>
      'Pelajar menandakan sendiri penyempurnaan sebelum tarikh akhir.';

  @override
  String get actPolicyDetailTeacherVerified =>
      'Pelajar menghantar; anda meluluskan atau menolak dengan sebab.';

  @override
  String get actStateUpcoming => 'Akan datang';

  @override
  String get actStateOpen => 'Perlu dibuat';

  @override
  String get actStatePending => 'Menunggu semakan';

  @override
  String get actStateCompleted => 'Selesai';

  @override
  String get actStateRejected => 'Perlu cuba lagi';

  @override
  String get actStateNotDone => 'Belum dibuat';

  @override
  String get actStateMissed => 'Terlepas';

  @override
  String get actStateNotScheduled => 'Tidak dijadualkan';

  @override
  String get actPaused => 'Dijeda';

  @override
  String get actEveryDay => 'Setiap hari';

  @override
  String get actWeekdays => 'Hari bekerja';

  @override
  String actDeadlineAtTime(String time, String tz) {
    return 'Tarikh akhir $time ($tz)';
  }

  @override
  String actDeadlineDayEnd(String tz) {
    return 'Tarikh akhir penghujung hari ($tz)';
  }

  @override
  String get actNoStreak => 'Tiada rentetan (tiada tarikh akhir)';

  @override
  String actStreak(String value) {
    return 'Rentetan $value';
  }

  @override
  String actBest(String value) {
    return 'Terbaik $value';
  }

  @override
  String actDoneOfResolved(int done, int total) {
    return '$done daripada $total selesai';
  }

  @override
  String get actEditDetails => 'Sunting butiran';

  @override
  String get actDescription => 'Penerangan';

  @override
  String get actDueEndOfDay => 'Tarikh akhir penghujung hari';

  @override
  String get actSubmitForReview => 'Hantar untuk semakan';

  @override
  String get actNoteForTeacher => 'Catatan untuk guru anda (pilihan)';

  @override
  String get actSubmit => 'Hantar';

  @override
  String get actMarkDone => 'Tandakan selesai';

  @override
  String get actWithdraw => 'Tarik balik';

  @override
  String actTeacherAskedRetry(String reason) {
    return 'Guru anda meminta anda mencuba lagi: $reason';
  }

  @override
  String get actNothingToday => 'Tiada yang dijadualkan hari ini';

  @override
  String get actNothingTodayHint =>
      'Guru anda belum menjadualkan aktiviti untuk hari ini dalam kursus ini.';

  @override
  String get actDaily => 'Aktiviti harian';

  @override
  String get actDailyOne => 'Aktiviti harian';

  @override
  String get actTodaySubtitle =>
      'Apa yang perlu dibuat hari ini dalam kursus ini.';

  @override
  String get actWeekView => 'Paparan mingguan';

  @override
  String get actMyProgress => 'Kemajuan saya';

  @override
  String actWeekOf(String date) {
    return 'Minggu $date';
  }

  @override
  String get actThisWeek => 'Minggu ini';

  @override
  String get actPrevWeek => 'Minggu sebelumnya';

  @override
  String get actNextWeek => 'Minggu seterusnya';

  @override
  String get actNoWeekTitle => 'Tiada aktiviti minggu ini';

  @override
  String get actNoWeekHint =>
      'Tiada yang dijadualkan pada hari-hari ini. Gunakan anak panah untuk melihat minggu lain.';

  @override
  String get actDaysOfWeek => 'Hari dalam minggu';

  @override
  String get actNoEndDate => 'Tiada tarikh tamat';

  @override
  String actEnds(String date) {
    return 'Tamat $date';
  }

  @override
  String get actClearEnd => 'Kosongkan tarikh tamat';

  @override
  String get actDeadline => 'Tarikh akhir';

  @override
  String get actDlDayEnd => 'Penghujung setiap hari';

  @override
  String get actDlDayEndHint =>
      'Had harian lalai pada tengah malam dalam zon waktu aktiviti.';

  @override
  String get actDlTime => 'Pada masa tetap setiap hari';

  @override
  String get actDlNoneHint =>
      'Tidak pernah dikira terlepas dan tiada rentetan.';

  @override
  String actDueAtPicker(String time) {
    return 'Tarikh akhir pada $time';
  }

  @override
  String get actTimezone => 'Zon waktu';

  @override
  String get actStarts => 'Bermula';

  @override
  String get actNewActivity => 'Aktiviti baharu';

  @override
  String actReviewN(int count) {
    return 'Semak ($count)';
  }

  @override
  String get actReviewQueue => 'Baris gilir semakan';

  @override
  String get actSectionSubtitle =>
      'Latihan berulang dengan dasar penyempurnaan dan tarikh akhir.';

  @override
  String actTodayDone(int done, int expected) {
    return 'Hari ini $done/$expected selesai';
  }

  @override
  String get actNotScheduledToday => 'Tidak dijadualkan hari ini';

  @override
  String actToReview(int count) {
    return '$count untuk disemak';
  }

  @override
  String get actEmptyTitle => 'Belum ada aktiviti';

  @override
  String get actEmptyHint =>
      'Cipta aktiviti harian seperti Latihan Membaca, kemudian pilih cara penyempurnaan direkodkan.';

  @override
  String get actProblemTitle => 'Beri tajuk kepada aktiviti.';

  @override
  String get actProblemDays =>
      'Pilih sekurang-kurangnya satu hari dalam minggu.';

  @override
  String get actFormDesc =>
      'Latihan tanpa mengira mata pelajaran yang pelajar ulang pada hari yang anda pilih.';

  @override
  String get actDetails => 'Butiran';

  @override
  String get actDescriptionOptional => 'Penerangan (pilihan)';

  @override
  String get actHowRecorded => 'Bagaimana penyempurnaan direkodkan?';

  @override
  String get actSchedule => 'Jadual';

  @override
  String get actCreate => 'Cipta aktiviti';

  @override
  String get actChangeSchedule => 'Tukar jadual';

  @override
  String get actChangeDesc =>
      'Jadual baharu bermula pada tarikh yang anda pilih (esok atau selepasnya). Hari sebelumnya mengekalkan peraturan asal, jadi sejarah sesiapa pun tidak berubah.';

  @override
  String get actNewSchedule => 'Jadual baharu';

  @override
  String get actSaveSchedule => 'Simpan jadual';

  @override
  String actScheduleFrom(String from, int version) {
    return 'Jadual semasa dari $from (versi $version)';
  }

  @override
  String actScheduleFromTo(String from, String to, int version) {
    return 'Jadual semasa dari $from hingga $to (versi $version)';
  }

  @override
  String get actPause => 'Jeda';

  @override
  String get actResume => 'Sambung semula';

  @override
  String get actArchive => 'Arkibkan';

  @override
  String get actConfirmPause =>
      'Jeda aktiviti ini mulai esok? Hari yang lalu mengekalkan rekod mereka.';

  @override
  String get actConfirmArchive =>
      'Arkibkan aktiviti ini? Ia disembunyikan daripada pelajar; sejarah disimpan.';

  @override
  String get actConfirmResume => 'Sambung semula aktiviti ini mulai esok?';

  @override
  String get actWeeklyRegister => 'Daftar mingguan';

  @override
  String actRegisterSubtitle(String date) {
    return 'Minggu $date. Ketik sel untuk merekod atau menyemak.';
  }

  @override
  String actCouldNotRefreshWeek(String error) {
    return 'Tidak dapat menyegarkan: $error Memaparkan minggu yang dimuatkan kali terakhir.';
  }

  @override
  String get actNoStudentsTitle => 'Belum ada pelajar didaftarkan';

  @override
  String get actNoStudentsHint =>
      'Pelajar dipaparkan di sini selepas mereka menyertai kursus.';

  @override
  String get actNotScheduledWeek => 'Tidak dijadualkan minggu ini';

  @override
  String get actNotScheduledWeekHint =>
      'Aktiviti ini tiada hari berjadual dalam minggu ini. Gunakan anak panah untuk melihat minggu lain.';

  @override
  String actCellSemantics(String name, String date, String state) {
    return '$name, $date: $state';
  }

  @override
  String actStudentNote(String note) {
    return 'Catatan pelajar: $note';
  }

  @override
  String actReasonGiven(String reason) {
    return 'Sebab diberikan: $reason';
  }

  @override
  String get actArchivedReadOnly =>
      'Kursus ini diarkibkan, jadi rekod hanya boleh dibaca.';

  @override
  String get actReasonRequired => 'Sebab untuk pelajar (diperlukan)';

  @override
  String get actApprove => 'Luluskan';

  @override
  String get actReject => 'Tolak';

  @override
  String get actSendRejection => 'Hantar penolakan';

  @override
  String get actFutureDays => 'Hari akan datang belum boleh direkodkan.';

  @override
  String get actMarkCompleted => 'Tandakan siap';

  @override
  String get actMarkNotDone => 'Tandakan belum dibuat';

  @override
  String get actVerificationQueue => 'Baris gilir pengesahan';

  @override
  String actWaitingDecision(int count) {
    return '$count menunggu keputusan anda.';
  }

  @override
  String get actWaitingReview => 'Menunggu semakan';

  @override
  String get actNothingToReview => 'Tiada apa untuk disemak';

  @override
  String get actNothingToReviewHint =>
      'Penghantaran pelajar dipaparkan di sini untuk diluluskan atau ditolak.';

  @override
  String actSubmittedAt(String when) {
    return 'dihantar $when';
  }

  @override
  String actNoteLine(String note) {
    return 'Catatan: $note';
  }

  @override
  String get actRejectTitle => 'Tolak penghantaran';

  @override
  String get atdRateNone => 'Belum ada kadar';

  @override
  String get atdNewSession => 'Sesi baharu';

  @override
  String get atdWeeklyGrid => 'Grid mingguan';

  @override
  String get atdSummary => 'Ringkasan';

  @override
  String get atdNoSessions => 'Belum ada sesi kehadiran';

  @override
  String get atdNoSessionsHint => 'Cipta satu untuk setiap pertemuan kelas.';

  @override
  String get atdNewDialogTitle => 'Sesi kehadiran baharu';

  @override
  String get atdDate => 'Tarikh';

  @override
  String get atdTime => 'Masa';

  @override
  String atdNoteFor(String name) {
    return 'Catatan untuk $name';
  }

  @override
  String get atdNote => 'Catatan';

  @override
  String get atdSaveNote => 'Simpan catatan';

  @override
  String get atdCloseTitle => 'Tutup sesi ini?';

  @override
  String get atdCloseAllMarked =>
      'Setiap pelajar telah direkodkan. Anda masih boleh membetulkan rekod kemudian.';

  @override
  String atdCloseUnmarked(int count) {
    return '$count pelajar yang belum direkodkan akan direkodkan sebagai Tidak hadir. Anda masih boleh membetulkan rekod kemudian.';
  }

  @override
  String get atdCloseSession => 'Tutup sesi';

  @override
  String atdEventClosed(String when) {
    return 'Sesi ditutup · $when';
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
  String get atdEyebrowSession => 'Kehadiran / Sesi';

  @override
  String get atdClassRegister => 'Daftar kelas';

  @override
  String get atdRegisterHint =>
      'Pilih status bagi setiap pelajar. Perubahan disimpan serta-merta.';

  @override
  String get atdArchivedReadOnly =>
      'Kursus ini diarkibkan. Kehadiran hanya boleh dibaca.';

  @override
  String get atdNoStudents => 'Belum ada pelajar didaftarkan.';

  @override
  String atdCloseSessionN(int count) {
    return 'Tutup sesi ($count belum direkodkan)';
  }

  @override
  String get atdSessionClosedNote =>
      'Sesi ditutup. Rekod sedia ada masih boleh dibetulkan.';

  @override
  String get atdNoChanges => 'Belum ada perubahan.';

  @override
  String atdEditNoteFor(String name) {
    return 'Sunting catatan untuk $name';
  }

  @override
  String get atdNotMarkedYet => 'Belum direkodkan';

  @override
  String get atdEyebrowTeaching => 'Pengajaran / Kehadiran';

  @override
  String get atdEyebrowLearning => 'Pembelajaran / Kehadiran';

  @override
  String get atdSummaryTitle => 'Ringkasan kehadiran';

  @override
  String get atdSummaryDesc =>
      'Rekod penyertaan yang jelas merentas sesi kelas.';

  @override
  String atdClosedOfTotal(int closed, int total) {
    return '$closed ditutup daripada $total sesi';
  }

  @override
  String get atdRateNote =>
      'Kadar = (Hadir + Lewat) ÷ (Hadir + Lewat + Tidak hadir). Dibenarkan tidak hadir tidak dikira.';

  @override
  String get atdSummaryEmptyHint =>
      'Kadar kehadiran dipaparkan selepas pelajar menyertai kursus.';

  @override
  String get atdMyAttendance => 'Kehadiran saya';

  @override
  String get atdWeeklyView => 'Paparan mingguan';

  @override
  String get atdNoRecords => 'Belum ada kehadiran direkodkan';

  @override
  String get atdNoRecordsHint =>
      'Kehadiran anda akan dipaparkan di sini selepas kelas direkodkan.';

  @override
  String atdRateTitle(String rate) {
    return 'Kadar kehadiran: $rate';
  }

  @override
  String get atdWeeklyAttendance => 'Kehadiran mingguan';

  @override
  String get atdMyWeek => 'Minggu saya';

  @override
  String get atdGridDesc =>
      'Nama kekal kelihatan. Leret hari untuk meneroka setiap sesi.';

  @override
  String get atdGlyphPresent => 'H';

  @override
  String get atdGlyphLate => 'L';

  @override
  String get atdGlyphExcused => 'D';

  @override
  String get atdGlyphAbsent => 'T';

  @override
  String get atdNotMarked => 'Belum direkodkan';

  @override
  String get atdNoSession => '· Tiada sesi';

  @override
  String get atdTwoSessions =>
      '×2 = dua sesi pada hari itu, mengikut urutan masa';

  @override
  String atdCellNoSession(String who, String date) {
    return '$who, $date: tiada sesi';
  }

  @override
  String get atdMe => 'Saya';

  @override
  String get atdStatusGuide => 'Panduan status';

  @override
  String get atdGridNoSessions => 'Tiada sesi kehadiran minggu ini';

  @override
  String get atdGridNoSessionsHint =>
      'Gunakan anak panah untuk melihat minggu lain.';

  @override
  String get atdGridNoStudentsHint =>
      'Jadual mingguan dipaparkan selepas pelajar menyertai kursus.';

  @override
  String get atdAllMarked => 'Semua direkodkan';

  @override
  String atdUnmarkedCount(int count) {
    return '$count belum direkodkan';
  }

  @override
  String get progEyebrowTeacher => 'Kemajuan pelajar';

  @override
  String progEnrolledSince(String date) {
    return 'Mendaftar sejak $date';
  }

  @override
  String get progPrivateTeacher =>
      'Peribadi kepada anda dan pelajar ini. Tidak dikongsi dengan kelas.';

  @override
  String get progPrivateStudent =>
      'Hanya anda dan guru anda yang boleh melihat ini.';

  @override
  String get progArchived => 'Kursus ini diarkibkan (baca sahaja).';

  @override
  String progCouldNotRefresh(String error) {
    return 'Tidak dapat menyegarkan: $error Memaparkan angka yang dimuatkan kali terakhir.';
  }

  @override
  String get progAssignmentsNone => 'Belum ada tugasan diterbitkan.';

  @override
  String progAssignmentsSummary(int done, int published) {
    return '$done daripada $published tugasan diterbitkan telah dihantar atau dinilai.';
  }

  @override
  String get progNoPublishedTitle => 'Tiada tugasan diterbitkan';

  @override
  String get progNoPublishedHint =>
      'Kemajuan dipaparkan di sini selepas guru menerbitkan tugasan.';

  @override
  String progOfCount(int a, int b) {
    return '$a daripada $b';
  }

  @override
  String progOverdueHint(int count) {
    return '$count lewat';
  }

  @override
  String get progAwaitingGrading => 'Menunggu penilaian';

  @override
  String progScore(int score, int max) {
    return 'Skor $score/$max';
  }

  @override
  String progTruncated(int shown, int total) {
    return 'Memaparkan $shown terkini daripada $total tugasan. Kiraan di atas meliputi kesemuanya.';
  }

  @override
  String get progActivitiesSubtitle =>
      'Rentetan hanya mengira hari berjadual (62 hari terakhir). Yang menunggu semakan tidak dikira sehingga diluluskan.';

  @override
  String progAwaitingVerification(int count) {
    return '$count menunggu pengesahan';
  }

  @override
  String get progNoActivitiesHint =>
      'Tiada aktiviti harian disediakan untuk kursus ini.';

  @override
  String get progNoClosedDay => 'Belum ada hari berjadual yang telah ditutup.';

  @override
  String get progAttNone => 'Tiada sesi kehadiran dicipta.';

  @override
  String progAttSummary(int total, int closed) {
    return '$total sesi, $closed ditutup.';
  }

  @override
  String get progNoSessionsTitle => 'Belum ada sesi';

  @override
  String get progNoSessionsHint =>
      'Kehadiran dipaparkan selepas guru mencipta sesi.';

  @override
  String get progRateNone =>
      'Kadar kehadiran: belum ada data (tiada yang boleh dikira)';

  @override
  String progRate(String rate, int present, int counted) {
    return 'Kadar kehadiran: $rate ($present daripada $counted sesi dikira)';
  }

  @override
  String progNotMarkedCount(int count) {
    return 'Belum direkodkan: $count';
  }

  @override
  String get progRecentSessions => 'Sesi terkini';

  @override
  String get taskModeMonth => 'Bulan';

  @override
  String get taskModeCompleted => 'Selesai';

  @override
  String get taskOverdue => 'Lewat';

  @override
  String get taskNeedsRevision => 'Perlu disemak semula';

  @override
  String get taskGraded => 'Telah dinilai';

  @override
  String get taskHeld => 'Telah berlangsung';

  @override
  String get taskScheduled => 'Dijadualkan';

  @override
  String get taskHeaderTitle => 'Apa yang perlu dibuat';

  @override
  String get taskHeaderDesc =>
      'Tugasan dan aktiviti harian daripada semua kursus anda, setiap satu dengan satu status.';

  @override
  String get taskEmptyTodayTitle => 'Tiada yang perlu disiapkan hari ini';

  @override
  String get taskEmptyTodayHint => 'Nikmatilah, atau lihat minggu hadapan.';

  @override
  String get taskEmptyWeekTitle => 'Tiada apa-apa minggu ini';

  @override
  String get taskEmptyWeekHint =>
      'Tiada tarikh akhir tugasan atau aktiviti pada minggu ini.';

  @override
  String get taskEmptyMonthTitle => 'Tiada apa-apa bulan ini';

  @override
  String get taskEmptyDayTitle => 'Tiada apa-apa pada hari ini';

  @override
  String get taskEmptyMonthHint =>
      'Tiada tarikh akhir tugasan atau aktiviti di sini.';

  @override
  String get taskEmptyUpcomingTitle => 'Tiada yang akan datang';

  @override
  String get taskEmptyUpcomingHint =>
      'Tugasan baharu daripada guru anda akan dipaparkan di sini.';

  @override
  String get taskEmptyOverdueTitle => 'Tiada yang lewat';

  @override
  String get taskEmptyOverdueHint => 'Anda sudah terkini.';

  @override
  String get taskEmptyCompletedTitle => 'Belum ada yang selesai';

  @override
  String get taskEmptyCompletedHint =>
      'Tugasan yang selesai dipaparkan di sini.';

  @override
  String get taskCalendarEyebrow => 'Kalendar';

  @override
  String get taskCalendarTitle => 'Kalendar pengajaran';

  @override
  String get taskCalendarDesc =>
      'Tarikh akhir tugasan, aktiviti harian dan sesi kehadiran merentas kursus anda.';

  @override
  String get taskNoPending => 'Tiada penghantaran aktiviti menunggu semakan.';

  @override
  String taskPending(int count) {
    return '$count penghantaran aktiviti menunggu semakan.';
  }

  @override
  String taskCouldNotRefreshTasks(String error) {
    return 'Tidak dapat menyegarkan: $error Memaparkan tugas yang dimuatkan kali terakhir.';
  }

  @override
  String taskCouldNotRefreshCalendar(String error) {
    return 'Tidak dapat menyegarkan: $error Memaparkan kalendar yang dimuatkan kali terakhir.';
  }

  @override
  String get taskNothingScheduled => 'Tiada yang dijadualkan';

  @override
  String get taskNothingScheduledHint =>
      'Tiada tarikh akhir, aktiviti atau sesi kehadiran di sini.';

  @override
  String get taskPrevious => 'Sebelumnya';

  @override
  String get taskNext => 'Seterusnya';

  @override
  String taskDayItems(int day, String month, int count) {
    return '$day $month, $count item';
  }

  @override
  String get taskUndated => 'Tiada tarikh';

  @override
  String taskDueSubmitted(String when, int received, int expected) {
    return 'Tarikh akhir $when · $received daripada $expected dihantar';
  }

  @override
  String taskDoneOf(int received, int expected) {
    return '$received daripada $expected selesai';
  }

  @override
  String taskAttendanceSession(String when, String state) {
    return 'Sesi kehadiran $when · $state';
  }

  @override
  String taskClassSession(String when) {
    return 'Sesi kelas $when';
  }

  @override
  String get taskNothingDueToday => 'Tiada yang perlu disiapkan hari ini.';

  @override
  String taskTodoDone(int todo, int rest) {
    return '$todo perlu dibuat · $rest selesai atau menunggu';
  }

  @override
  String get taskAllTasks => 'Semua tugas';

  @override
  String get taskAllClear => 'Hari ini semuanya selesai';

  @override
  String get taskAllClearHint =>
      'Tiada tarikh akhir tugasan atau aktiviti dijadualkan untuk hari ini.';

  @override
  String taskMoreInTasks(int count) {
    return '$count lagi dalam Tugas';
  }

  @override
  String taskReview(int count) {
    return 'Semak ($count)';
  }

  @override
  String get actTzBangkok => 'Bangkok (UTC+7)';

  @override
  String get actTzSingapore => 'Singapura (UTC+8)';

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
  String get actTzUtc => 'Waktu sejagat (UTC)';

  @override
  String get welcomeTitle => 'Hari pembelajaran anda, dalam satu tempat.';

  @override
  String get welcomeDescription =>
      'Satukan kursus, tugasan dan kemajuan pembelajaran anda. Log masuk untuk meneruskan.';

  @override
  String get welcomeFeatures => 'Untuk pembelajaran harian';

  @override
  String get welcomeProgress => 'Kemajuan';

  @override
  String get welcomeBack => 'Kembali ke halaman alu-aluan';

  @override
  String get profilePhotoTitle => 'Gambar profil';

  @override
  String get profilePhotoHint =>
      'JPEG atau WebP. Ia dipotong menjadi segi empat sama dan dikecilkan kepada kira-kira 256 px. Hanya anda dan guru kursus anda boleh melihatnya.';

  @override
  String get profilePhotoAdd => 'Tambah gambar';

  @override
  String get profilePhotoChange => 'Tukar gambar';

  @override
  String get profilePhotoRemove => 'Buang gambar';

  @override
  String get profilePhotoSaved => 'Gambar telah disimpan';

  @override
  String get profilePhotoRemoved => 'Gambar telah dibuang';

  @override
  String get profilePhotoCropTitle => 'Potong gambar anda';

  @override
  String get profilePhotoCropHint =>
      'Seret dan cubit gambar untuk memilih bahagian yang dipaparkan dalam bulatan.';

  @override
  String get profilePhotoSave => 'Simpan gambar';

  @override
  String profilePhotoSemantics(String name) {
    return 'Gambar profil $name';
  }

  @override
  String get errorAvatarType => 'Pilih gambar JPEG atau WebP.';

  @override
  String get errorAvatarInputTooLarge =>
      'Gambar itu terlalu besar (maksimum 10 MB).';

  @override
  String get errorAvatarDecode =>
      'Gambar itu tidak dapat dibaca. Cuba gambar lain.';

  @override
  String get scanTitle => 'Imbas kod kehadiran';

  @override
  String get scanButton => 'Imbas kod';

  @override
  String get scanHint =>
      'Halakan kamera ke kod QR bilik darjah, atau taip kod yang dipaparkan di bawahnya.';

  @override
  String get scanCameraLabel =>
      'Pratonton kamera untuk mengimbas kod QR kehadiran';

  @override
  String get scanManualLabel => 'Kod kehadiran';

  @override
  String get scanSubmit => 'Hantar kod';

  @override
  String get scanAgain => 'Imbas kod lain';

  @override
  String get scanCameraDenied =>
      'Akses kamera dimatikan. Benarkannya dalam Tetapan, atau taip kod di bawah.';

  @override
  String get scanNoCamera =>
      'Peranti ini tiada kamera yang boleh digunakan. Taip kod di bawah.';

  @override
  String get scanCameraBusy =>
      'Kamera tidak dapat dimulakan (mungkin sedang digunakan). Taip kod di bawah, atau cuba lagi.';

  @override
  String scanOk(String status, String time) {
    return 'Didaftarkan sebagai $status pada $time.';
  }

  @override
  String scanOutOk(String time) {
    return 'Daftar keluar pada $time.';
  }

  @override
  String scanAlready(String status) {
    return 'Anda telah direkodkan sebagai $status.';
  }

  @override
  String get scanOutAlready => 'Anda telah pun mendaftar keluar.';

  @override
  String get scanReasonInvalid => 'Kod itu tidak sah.';

  @override
  String get scanReasonExpired =>
      'Kod itu telah tamat tempoh. Minta kod semasa.';

  @override
  String get scanReasonClosed => 'Sesi ini telah ditutup.';

  @override
  String get scanReasonNotMember => 'Anda bukan ahli aktif kursus ini.';

  @override
  String get scanReasonTooEarly => 'Daftar masuk belum dibuka.';

  @override
  String get scanReasonTooLate => 'Tempoh daftar masuk telah berakhir.';

  @override
  String get scanReasonNoCheckin =>
      'Daftar masuk dahulu sebelum daftar keluar.';

  @override
  String atdTimeIn(String time) {
    return 'Masuk $time';
  }

  @override
  String atdTimeOut(String time) {
    return 'Keluar $time';
  }

  @override
  String get atdViaQr => 'QR';

  @override
  String get staffTitle => 'Kehadiran kakitangan';

  @override
  String get staffSubtitle =>
      'Daftar masuk dan keluar, lihat sejarah dan mohon cuti atau pembetulan.';

  @override
  String get staffToday => 'Hari ini';

  @override
  String staffStatusIn(String time) {
    return 'Daftar masuk sejak $time';
  }

  @override
  String get staffStatusOut => 'Anda belum mendaftar masuk.';

  @override
  String staffStatusLate(String minutes) {
    return 'Lewat $minutes min';
  }

  @override
  String get staffClockIn => 'Daftar masuk';

  @override
  String get staffClockOut => 'Daftar keluar';

  @override
  String get staffClockedIn => 'Telah mendaftar masuk';

  @override
  String get staffClockedOut => 'Telah mendaftar keluar';

  @override
  String get staffServerTime =>
      'Masa diambil daripada jam pelayan, bukan peranti anda.';

  @override
  String get staffSchedule => 'Jadual kerja';

  @override
  String get staffNoSchedule =>
      'Tiada jadual ditetapkan untuk anda. Anda masih boleh mendaftar masuk; hari itu direkodkan sebagai tanpa jadual.';

  @override
  String staffScheduleLine(
    String days,
    String start,
    String end,
    String zone,
    String grace,
  ) {
    return '$days · $start–$end ($zone), tempoh bertolak ansur $grace min';
  }

  @override
  String get staffD1 => 'Isn';

  @override
  String get staffD2 => 'Sel';

  @override
  String get staffD3 => 'Rab';

  @override
  String get staffD4 => 'Kha';

  @override
  String get staffD5 => 'Jum';

  @override
  String get staffD6 => 'Sab';

  @override
  String get staffD7 => 'Ahd';

  @override
  String get staffHistory => '14 hari lepas';

  @override
  String get staffNoRows => 'Tiada rekod dalam tempoh ini.';

  @override
  String staffWorked(String hours) {
    return 'Jam bekerja: $hours';
  }

  @override
  String get staffOnTime => 'Tepat masa';

  @override
  String get staffLate => 'Lewat';

  @override
  String get staffMissingCheckout => 'Tiada daftar keluar';

  @override
  String get staffInProgress => 'Sedang berjalan';

  @override
  String get staffAbsent => 'Tidak hadir';

  @override
  String get staffLeave => 'Bercuti';

  @override
  String get staffUnscheduled => 'Tanpa jadual';

  @override
  String get staffUpcoming => 'Akan datang';

  @override
  String get staffRequests => 'Permohonan';

  @override
  String get staffNewLeave => 'Mohon cuti';

  @override
  String get staffNewCorrection => 'Mohon pembetulan';

  @override
  String get staffKindLeave => 'Cuti';

  @override
  String get staffKindCorrection => 'Pembetulan';

  @override
  String get staffFromDate => 'Dari tarikh';

  @override
  String get staffToDate => 'Hingga tarikh';

  @override
  String get staffCorrectDate => 'Hari untuk dibetulkan';

  @override
  String get staffReason => 'Sebab (3 hingga 500 aksara)';

  @override
  String get staffCorrectIn => 'Masa daftar masuk yang betul (pilihan)';

  @override
  String get staffCorrectOut => 'Masa daftar keluar yang betul (pilihan)';

  @override
  String get staffPickTime => 'Pilih masa';

  @override
  String get staffSubmit => 'Hantar permohonan';

  @override
  String get staffSubmitted => 'Permohonan dihantar';

  @override
  String get staffNoRequests => 'Belum ada permohonan.';

  @override
  String get staffCancelRequest => 'Batalkan permohonan';

  @override
  String get staffCancelled => 'Permohonan dibatalkan';

  @override
  String get staffStPending => 'Menunggu';

  @override
  String get staffStApproved => 'Diluluskan';

  @override
  String get staffStRejected => 'Ditolak';

  @override
  String get staffStCancelled => 'Dibatalkan';

  @override
  String staffDecisionNote(String note) {
    return 'Nota keputusan: $note';
  }

  @override
  String get staffSelfNote =>
      'Penyelia memutuskan permohonan anda. Anda tidak boleh meluluskan permohonan sendiri.';

  @override
  String get staffNoSupervisor =>
      'Belum ada penyelia ditetapkan untuk anda, jadi permohonan menunggu sehingga pentadbir menetapkannya.';

  @override
  String get staffNeedReason => 'Berikan sebab sekurang-kurangnya 3 aksara.';

  @override
  String get staffFixDates => 'Pilih tarikh yang sah.';

  @override
  String get staffNeedTime =>
      'Berikan masa daftar masuk atau keluar yang betul.';

  @override
  String get staffManager => 'Alat penyelia';

  @override
  String get staffTeam => 'Ringkasan pasukan';

  @override
  String get staffNoTeam => 'Anda tidak menyelia sesiapa.';

  @override
  String get staffToDecide => 'Permohonan untuk diputuskan';

  @override
  String get staffNoneToDecide => 'Tiada yang perlu diputuskan.';

  @override
  String get staffApprove => 'Luluskan';

  @override
  String get staffReject => 'Tolak';

  @override
  String get staffNoteOptional => 'Nota (pilihan)';

  @override
  String get staffDecided => 'Keputusan disimpan';

  @override
  String staffTeamLine(
    String name,
    String onTime,
    String late,
    String missing,
    String absent,
  ) {
    return '$name: tepat masa $onTime, lewat $late, tiada daftar keluar $missing, tidak hadir $absent';
  }

  @override
  String get demoTry => 'Cuba Demo LearnPulse';

  @override
  String get demoSelectorTitle => 'Cuba demo';

  @override
  String get demoSelectorSub =>
      'Terokai LearnPulse tanpa e-mel peribadi dan tanpa menaip kata laluan.';

  @override
  String get demoStudent => 'Demo Pelajar';

  @override
  String get demoStudentText =>
      'Sertai bengkel langsung dengan nama dan kod sertai. Anda mendapat akaun pelajar sementara.';

  @override
  String get demoPresenter => 'Demo Pembentang';

  @override
  String get demoPresenterText =>
      'Untuk pembentang: mulakan bengkel, paparkan kod QR dan urus sesi.';

  @override
  String get demoRegularSignIn => 'Log masuk biasa';

  @override
  String get demoPresenterSignInSub =>
      'Log masuk sekali sahaja. Peranti ini kekal log masuk, jadi anda tidak perlu menaip semula.';

  @override
  String get demoPresenterNeedsTeacher =>
      'Kawalan pembentang memerlukan akaun Guru.';

  @override
  String get demoJoinTitle => 'Sertai bengkel langsung';

  @override
  String get demoJoinSub =>
      'Masukkan nama anda dan kod bengkel. Akaun dipadam selepas acara.';

  @override
  String get demoCodeLabel => 'Kod bengkel';

  @override
  String get demoCodeHint =>
      'Dipaparkan pada skrin pembentang. Ia berubah setiap minit.';

  @override
  String get demoNameLabel => 'Nama anda';

  @override
  String get demoNameHint =>
      'Dipaparkan kepada pembentang. Sehingga 40 aksara.';

  @override
  String get demoJoinButton => 'Sertai Demo';

  @override
  String get demoJoining => 'Mendapatkan tempat anda…';

  @override
  String get demoSigningIn => 'Sedang melog masuk…';

  @override
  String get demoWaiting =>
      'Ramai yang menyertai serentak. Mencuba semula sebentar lagi…';

  @override
  String get demoScan => 'Imbas kod QR';

  @override
  String get demoScanHint => 'Halakan kamera ke kod QR pada skrin pembentang.';

  @override
  String get demoCameraProblem => 'Kamera tidak tersedia. Taip kod sebaliknya.';

  @override
  String get demoMsgBadCode => 'Masukkan kod bengkel 12 aksara.';

  @override
  String get demoMsgBadName => 'Gunakan 1–40 aksara tanpa < atau >.';

  @override
  String get demoMsgInvalid =>
      'Kod ini tidak sah, telah tamat tempoh, atau demo belum dimulakan. Semak skrin pembentang.';

  @override
  String get demoMsgClosed => 'Penyertaan telah ditutup untuk bengkel ini.';

  @override
  String get demoMsgFull => 'Semua tempat telah diambil.';

  @override
  String get demoMsgBusy =>
      'Terlalu banyak percubaan. Tunggu seminit dan cuba lagi.';

  @override
  String get demoMsgSignedIn => 'Anda sudah log masuk. Log keluar dahulu.';

  @override
  String get demoMsgAlready =>
      'Peranti ini sudah menyertai. Kelayakan hanya dipaparkan sekali.';

  @override
  String get demoMsgAuthFailed =>
      'Tempat anda sudah ditempah, tetapi log masuk tidak selesai. Tekan Sertai sekali lagi untuk mendapat tempat yang sama.';

  @override
  String get demoMsgRateBusy =>
      'Log masuk sangat sibuk sekarang. Tekan Sertai semula dalam beberapa saat.';

  @override
  String get demoMsgExpired => 'Sesi bengkel ini telah tamat.';

  @override
  String get demoMsgNetwork =>
      'Tiada sambungan. Semak internet anda dan cuba lagi.';

  @override
  String get demoMsgFailed => 'Sesuatu tidak kena. Sila cuba lagi.';

  @override
  String get demoHostTitle => 'Hos demo langsung';

  @override
  String get demoHostNone => 'Tiada demo langsung ditemui untuk akaun ini.';

  @override
  String get demoHostTooltip => 'Demo langsung';

  @override
  String get demoStatusReady => 'Sedia untuk dimulakan';

  @override
  String get demoStatusOpen => 'Dibuka';

  @override
  String get demoStatusPaused => 'Dijeda';

  @override
  String get demoStatusClosed => 'Penyertaan ditutup';

  @override
  String get demoStatusEnded => 'Tamat';

  @override
  String demoReadyText(int join, String life) {
    return 'Bengkel yang disediakan sudah sedia. Apabila dimulakan, penyertaan dibuka selama $join minit dan sesi tamat $life jam kemudian. Ia tidak boleh dijeda atau dibatalkan.';
  }

  @override
  String get demoStart => 'Mulakan Demo';

  @override
  String demoStartConfirm(int join, String life) {
    return 'Mulakan demo langsung sekarang? Penyertaan kekal dibuka selama $join minit dan sesi tamat $life jam selepas anda memulakannya.';
  }

  @override
  String get demoEnd => 'Tamatkan Demo';

  @override
  String get demoEndConfirm =>
      'Tamatkan demo? Semua orang kehilangan akses ke bengkel serta-merta.';

  @override
  String get demoPause => 'Jeda penyertaan';

  @override
  String get demoResume => 'Sambung penyertaan';

  @override
  String get demoCloseJoins => 'Tutup penyertaan';

  @override
  String demoJoinsLeft(String time) {
    return 'Penyertaan ditutup dalam $time';
  }

  @override
  String demoLifeLeft(String time) {
    return 'Sesi tamat dalam $time';
  }

  @override
  String get demoJoinWindowOver => 'Tempoh penyertaan telah tamat.';

  @override
  String get demoCopyCode => 'Salin kod';

  @override
  String get demoCopyLink => 'Salin pautan';

  @override
  String get demoCopied => 'Disalin';

  @override
  String get demoProjectHint =>
      'Paparkan kod QR ini pada projektor. Peserta mengimbasnya dengan kamera telefon.';

  @override
  String demoCodeExpires(int seconds) {
    return 'Kod baharu dalam ${seconds}s';
  }

  @override
  String get demoSeatsTotal => 'Jumlah tempat';

  @override
  String get demoSeatsAvailable => 'Tersedia';

  @override
  String get demoSeatsClaimed => 'Dituntut';

  @override
  String get demoSeatsActive => 'Aktif';

  @override
  String demoRecent(int claims, int refused) {
    return '10 minit lepas: $claims menyertai, $refused ditolak';
  }

  @override
  String get demoEndedNotice => 'Sesi demo ini telah tamat.';

  @override
  String get demoOpenWorkshop => 'Buka bengkel';

  @override
  String get demoBack => 'Kembali';
}
