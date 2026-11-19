import { Navigate, Outlet, createRootRoute, createRoute, createRouter, useRouterState } from '@tanstack/react-router';
import { useTranslation } from 'react-i18next';
import { useAuth } from './auth/AuthProvider';
import { configProblem } from './config';
import { Button, Banner, EmptyState, ErrorState, SkeletonBlock } from './ui/kit';
import { Center, Shell } from './layout/Shell';
import { CallbackPage, ConfirmEmailPage, ForgotPage, SetPasswordPage, SignInPage, SignUpPage } from './pages/auth';
import { Suspense, lazy, type ComponentType, type ReactNode } from 'react';

// Route-level code splitting keeps the first load small; every page is its own chunk.
const L = <T,>(load: () => Promise<T>, name: keyof T & string) =>
  lazy(() => load().then((m) => ({ default: m[name] as unknown as ComponentType })));
const LandingPage = L(() => import('./pages/landing'), 'LandingPage');
const DashboardPage = L(() => import('./pages/dashboard'), 'DashboardPage');
const CourseLayout = L(() => import('./pages/courses'), 'CourseLayout');
const CourseOverview = L(() => import('./pages/courses'), 'CourseOverview');
const CoursesPage = L(() => import('./pages/courses'), 'CoursesPage');
const PeoplePage = L(() => import('./pages/courses'), 'PeoplePage');
const LessonsPage = L(() => import('./pages/lessons'), 'LessonsPage');
const AssignmentDetailPage = L(() => import('./pages/assignments'), 'AssignmentDetailPage');
const AssignmentsPage = L(() => import('./pages/assignments'), 'AssignmentsPage');
const GradingWorkspace = L(() => import('./pages/assignments'), 'GradingWorkspace');
const StaffPage = L(() => import('./pages/staff'), 'StaffPage');
const AttendancePage = L(() => import('./pages/attendance'), 'AttendancePage');
const AttendanceSessionPage = L(() => import('./pages/attendance'), 'AttendanceSessionPage');
const ActivitiesPage = L(() => import('./pages/activities'), 'ActivitiesPage');
const ActivityDetailPage = L(() => import('./pages/activities'), 'ActivityDetailPage');
const MyProgressPage = L(() => import('./pages/progress'), 'MyProgressPage');
const StudentProgressPage = L(() => import('./pages/progress'), 'StudentProgressPage');
const TasksPage = L(() => import('./pages/tasks'), 'TasksPage');
const VerificationPage = L(() => import('./pages/verification'), 'VerificationPage');
const ProfilePage = L(() => import('./pages/profile'), 'ProfilePage');
const DemoJoinPage = L(() => import('./pages/demo'), 'DemoJoinPage');
const DemoSelectorPage = L(() => import('./pages/demo'), 'DemoSelectorPage');
const PresenterAccessPage = L(() => import('./pages/demo'), 'PresenterAccessPage');
const DemoHostPage = L(() => import('./pages/demo'), 'DemoHostPage');
import { TeacherOnly } from './pages/teacher-only';

const PUBLIC = ['/', '/demo', '/try', '/demo-presenter', '/login', '/signup', '/forgot', '/confirm-email', '/auth/callback'];

function Splash() {
  const { t } = useTranslation('common');
  return <Center><div role="status" aria-label={t('loading')} style={{ width: 260 }}><SkeletonBlock rows={3} /></div></Center>;
}

function NotFound() {
  const { t } = useTranslation('common');
  return <Center><div className="frame auth-card"><EmptyState icon="travel_explore" title={t('pageNotFoundTitle')} action={<a className="btn" href="/">{t('goHome')}</a>}>{t('pageNotFoundText')}</EmptyState></div></Center>;
}

function RootLayout() {
  const { t } = useTranslation(['common', 'nav']);
  const { stage, profile, profileError, retryProfile, signOut } = useAuth();
  const path = useRouterState({ select: (s) => s.location.pathname });
  if (configProblem) {
    return <Center><div className="frame auth-card"><div className="body stack"><Banner tone="err" icon="settings">{t('common:notConfiguredTitle', { problem: configProblem })}</Banner><p className="muted small">{t('common:notConfiguredHint')}</p></div></div></Center>;
  }
  if (stage === 'starting' || stage === 'loadingProfile') return <Splash />;
  if (stage === 'recovery') return <SetPasswordPage />;
  if (stage === 'profileError') {
    return <Center><div className="frame auth-card"><ErrorState error={profileError} onRetry={retryProfile} /><div className="body"><Button variant="text" icon="logout" onClick={() => void signOut()}>{t('nav:signOut')}</Button></div></div></Center>;
  }
  const isPublic = PUBLIC.includes(path);
  if (stage === 'signedOut') return isPublic ? <Suspense fallback={<Splash />}><Outlet /></Suspense> : <Navigate to="/login" replace />;
  if (isPublic) return <Navigate to={path === '/demo-presenter' && profile?.role === 'teacher' ? '/demo-host' : '/dashboard'} replace />;
  return <Shell />;
}

const root = createRootRoute({ component: RootLayout, notFoundComponent: NotFound });
const r = (path: string, component: () => ReactNode) => createRoute({ getParentRoute: () => root, path, component });

const index = r('/', () => <LandingPage />);
const login = r('/login', () => <SignInPage />);
const demoJoin = r('/demo', () => <DemoJoinPage />);
const demoTry = r('/try', () => <DemoSelectorPage />);
const demoPresenter = r('/demo-presenter', () => <PresenterAccessPage />);
const demoHost = r('/demo-host', () => <TeacherOnly><DemoHostPage /></TeacherOnly>);
const signup = r('/signup', () => <SignUpPage />);
const forgot = r('/forgot', () => <ForgotPage />);
const callback = r('/auth/callback', () => <CallbackPage />);
const confirm = createRoute({
  getParentRoute: () => root, path: '/confirm-email',
  validateSearch: (s: Record<string, unknown>) => ({ email: typeof s.email === 'string' ? s.email : undefined }),
  component: function Confirm() { const { email } = confirm.useSearch(); return <ConfirmEmailPage email={email} />; },
});
const dashboard = r('/dashboard', () => <DashboardPage />);
const tasks = r('/tasks', () => <TasksPage />);
const verification = r('/verification', () => <TeacherOnly><VerificationPage /></TeacherOnly>);
const profile = r('/profile', () => <ProfilePage />);
const staff = r('/staff', () => <TeacherOnly><StaffPage /></TeacherOnly>);
const courses = r('/courses', () => <CoursesPage />);

const course = createRoute({ getParentRoute: () => root, path: '/courses/$courseId', component: () => <CourseLayout /> });
const c = (path: string, component: () => ReactNode) => createRoute({ getParentRoute: () => course, path, component });
const overview = c('/', () => <CourseOverview />);
const lessons = c('/lessons', () => <LessonsPage />);
const assignments = c('/assignments', () => <AssignmentsPage />);
const assignment = c('/assignments/$id', () => <AssignmentDetailPage />);
const grade = c('/assignments/$id/grade', () => <TeacherOnly><GradingWorkspace /></TeacherOnly>);
const attendance = c('/attendance', () => <AttendancePage />);
const session = c('/attendance/$id', () => <TeacherOnly><AttendanceSessionPage /></TeacherOnly>);
const activities = c('/activities', () => <ActivitiesPage />);
const activity = c('/activities/$id', () => <ActivityDetailPage />);
const people = c('/people', () => <TeacherOnly><PeoplePage /></TeacherOnly>);
const student = c('/people/$studentId', () => <TeacherOnly><StudentProgressPage /></TeacherOnly>);
const myProgress = c('/progress', () => <MyProgressPage />);

const tree = root.addChildren([
  index, login, demoJoin, demoTry, demoPresenter, demoHost, signup, forgot, callback, confirm, dashboard, tasks, verification, profile, staff, courses,
  course.addChildren([overview, lessons, assignments, assignment, grade, attendance, session, activities, activity, people, student, myProgress]),
]);

/** Last-resort boundary: a failed page chunk (offline, or a stale deployment) or a render error never shows a blank/raw error. */
function RouteError({ error, reset }: { error: unknown; reset: () => void }) {
  const { t } = useTranslation('common');
  const chunk = /dynamically imported module|Importing a module script|Failed to fetch|Load failed|ChunkLoadError/i.test((error as Error | undefined)?.message ?? '');
  return (
    <div className="state" role="alert">
      <h3>{chunk ? t('pageLoadFailedTitle') : t('renderErrorTitle')}</h3>
      <p>{chunk ? t('pageLoadFailedText') : t('renderErrorText')}</p>
      <Button variant="tonal" icon="refresh" onClick={() => (chunk ? window.location.reload() : reset())}>{chunk ? t('reload') : t('tryAgain')}</Button>
    </div>
  );
}

export const router = createRouter({ routeTree: tree, defaultPreload: false, scrollRestoration: true, defaultErrorComponent: RouteError });
