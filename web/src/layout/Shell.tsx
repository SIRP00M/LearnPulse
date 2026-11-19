import { Suspense, useEffect, useState, type ReactNode } from 'react';
import { Link, Outlet, useRouterState } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/AuthProvider';
import { LanguageSelector } from '../ui/LanguageSelector';
import { Icon, Button, Banner, SkeletonBlock } from '../ui/kit';
import { v9 } from '../lib/api/v9';
import { APP_VERSION, config } from '../config';
import { Avatar } from '../ui/Avatar';

const PAGES = [() => import('../pages/dashboard'), () => import('../pages/courses'), () => import('../pages/lessons'), () => import('../pages/assignments'), () => import('../pages/attendance'), () => import('../pages/activities'), () => import('../pages/progress'), () => import('../pages/tasks'), () => import('../pages/verification'), () => import('../pages/staff'), () => import('../pages/profile')];

interface Item { to: string; label: string; icon: string; badge?: number }

function Nav({ items, onNavigate }: { items: Item[]; onNavigate?: () => void }) {
  const { t } = useTranslation('nav');
  const path = useRouterState({ select: (s) => s.location.pathname });
  return (
    <nav className="nav" aria-label={t('main')}>
      {items.map((i) => {
        const active = path === i.to || path.startsWith(i.to + '/');
        return (
          <Link key={i.to} to={i.to} aria-current={active ? 'page' : undefined} onClick={onNavigate} title={i.label} tabIndex={0}>
            <Icon name={i.icon} /><span className="label">{i.label}</span>
            {!!i.badge && <span className="badge" title={t('waiting', { count: i.badge })}>{i.badge > 99 ? '99+' : i.badge}</span>}
          </Link>
        );
      })}
    </nav>
  );
}

function useOnline() {
  const [on, setOn] = useState(() => navigator.onLine);
  useEffect(() => {
    const u = () => setOn(true), d = () => setOn(false);
    window.addEventListener('online', u); window.addEventListener('offline', d);
    return () => { window.removeEventListener('online', u); window.removeEventListener('offline', d); };
  }, []);
  return on;
}

export function Shell() {
  const { t } = useTranslation(['nav', 'common']);
  const online = useOnline();
  const { profile, userId, signOut, sessionExpired } = useAuth();
  const [drawer, setDrawer] = useState(false);
  const teacher = profile?.role === 'teacher';
  const pending = useQuery({
    queryKey: ['activities', 'pending-total'],
    queryFn: async () => (await v9.pending()).total,
    enabled: teacher,
  });
  const path = useRouterState({ select: (s) => s.location.pathname });
  useEffect(() => setDrawer(false), [path]);
  // After sign-in, warm every page chunk in idle time: navigation is instant and survives going offline.
  useEffect(() => {
    const warm = () => { for (const m of PAGES) void m().catch(() => undefined); };
    const t = window.setTimeout(warm, 600);
    return () => clearTimeout(t);
  }, []);

  const items: Item[] = teacher
    ? [
        { to: '/dashboard', label: t('dashboard'), icon: 'dashboard' },
        { to: '/tasks', label: t('calendar'), icon: 'calendar_month' },
        { to: '/courses', label: t('courses'), icon: 'school' },
        { to: '/verification', label: t('verification'), icon: 'fact_check', badge: pending.data },
        { to: '/staff', label: t('staff'), icon: 'badge' },
        { to: '/profile', label: t('profile'), icon: 'person' },
      ]
    : [
        { to: '/dashboard', label: t('dashboard'), icon: 'dashboard' },
        { to: '/tasks', label: t('tasks'), icon: 'checklist' },
        { to: '/courses', label: t('courses'), icon: 'school' },
        { to: '/profile', label: t('profile'), icon: 'person' },
      ];

  const brand = <div className="wordmark" aria-label="LearnPulse"><span className="full">Learn<b>Pulse</b></span></div>;
  const foot = (
    <div className="side-foot">
      <div className="row" style={{ flexWrap: 'nowrap' }}><Avatar userId={userId} name={profile?.fullName ?? ''} size={28} /><div className="small muted label">{t('signedInAs', { name: profile?.fullName || t('signedIn'), role: teacher ? t('common:teacher') : t('common:student') })}</div></div>
      <LanguageSelector compact />
      <Button variant="outline" size="sm" icon="logout" onClick={() => void signOut()} aria-label={t('signOut')}><span className="label">{t('signOut')}</span></Button>
      <div className="small muted label">{t('version', { version: APP_VERSION, env: config.env })}</div>
    </div>
  );
  return (
    <>
      <a href="#main" className="skip" tabIndex={0}>{t('skip')}</a>
      <div className="shell">
        <aside className="sidebar" aria-label={t('sidebar')}>{brand}<Nav items={items} />{foot}</aside>
        <div>
          <div className="topbar">
            <Button variant="text" className="icon" icon="menu" aria-label={t('openMenu')} onClick={() => setDrawer(true)} />
            {brand}
          </div>
          {drawer && (
            <>
              <div className="scrim" onClick={() => setDrawer(false)} aria-hidden />
              <div className="drawer" role="dialog" aria-modal="true" aria-label={t('menu')}>
                <div className="row between">{brand}<Button variant="text" className="icon" icon="close" aria-label={t('closeMenu')} onClick={() => setDrawer(false)} /></div>
                <Nav items={items} onNavigate={() => setDrawer(false)} />{foot}
              </div>
            </>
          )}
          <main id="main" className="main" tabIndex={-1}>
            {!online && <div style={{ marginBottom: 16 }}><Banner tone="warn" icon="cloud_off">{t('offline')}</Banner></div>}
            {sessionExpired && <div style={{ marginBottom: 16 }}><Banner tone="warn">{t('sessionExpired')}</Banner></div>}
            <Suspense fallback={<SkeletonBlock rows={4} />}><Outlet /></Suspense>
          </main>
        </div>
      </div>
    </>
  );
}

export const Center = ({ children }: { children: ReactNode }) => <div className="auth-wrap">{children}</div>;
