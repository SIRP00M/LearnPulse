import { useState } from 'react';
import { Link } from '@tanstack/react-router';
import { useTranslation } from 'react-i18next';
import { getThemePref, setThemePref, type ThemePref } from '../lib/theme';
import { Icon } from '../ui/kit';
import { LanguageSelector } from '../ui/LanguageSelector';
import './landing.css';

export function LandingPage() {
  const { t } = useTranslation('landing');
  const [theme, setTheme] = useState(getThemePref);
  const features = [
    ['menu_book', 'courses', 'coursesText'], ['assignment', 'assignments', 'assignmentsText'],
    ['how_to_reg', 'attendance', 'attendanceText'], ['local_fire_department', 'activities', 'activitiesText'],
    ['insights', 'progress', 'progressText'], ['event_note', 'tasks', 'tasksText'], ['fact_check', 'grading', 'gradingText'],
  ] as const;
  return <div className="landing">
    <a tabIndex={0} className="skip" href="#main">{t('skip')}</a>
    <header className="landing-header"><div className="landing-wrap landing-nav">
      <a tabIndex={0} className="landing-brand" href="/" aria-label="LearnPulse"><Icon name="auto_stories" /><span>Learn<b>Pulse</b></span></a>
      <nav aria-label={t('features')}><a tabIndex={0} href="#features">{t('features')}</a><a tabIndex={0} href="#teachers">{t('teachers')}</a><a tabIndex={0} href="#students">{t('students')}</a></nav>
      <div className="landing-controls"><LanguageSelector compact /><label className="landing-theme"><span className="sr-only">{t('theme')}</span><select className="input" value={theme} onChange={(e) => { const value = e.target.value as ThemePref; setTheme(value); setThemePref(value); }}><option value="system">{t('system')}</option><option value="light">{t('light')}</option><option value="dark">{t('dark')}</option></select></label><Link tabIndex={0} className="btn outline" to="/try">{t('tryDemo')}</Link><Link tabIndex={0} className="btn" to="/login">{t('signIn')}</Link></div>
    </div></header>
    <main id="main" tabIndex={-1}><section className="landing-wrap landing-hero"><div><p className="landing-eyebrow"><Icon name="school" /> LearnPulse</p><h1>{t('heroTitle')}</h1><p className="landing-intro">{t('heroText')}</p><div className="landing-actions"><Link tabIndex={0} className="btn" to="/login">{t('getStarted')} <Icon name="arrow_forward" /></Link><Link tabIndex={0} className="btn tonal" to="/try">{t('tryDemo')}</Link><a tabIndex={0} className="btn outline" href="#features">{t('explore')}</a></div></div>
      <div className="landing-preview" aria-label={t('preview')}><div className="preview-top"><span><Icon name="auto_stories" /> LearnPulse</span><span>{t('preview')}</span></div><div className="preview-body"><div className="preview-side" aria-hidden="true"><Icon name="dashboard" /><Icon name="menu_book" /><Icon name="event_note" /><Icon name="insights" /></div><div className="preview-content"><p className="preview-note">{t('previewNote')}</p><h2>{t('overview')}</h2><div className="preview-course"><Icon name="menu_book" /><div><strong>{t('course')}</strong><p>{t('lessonReady')}</p></div></div><div className="preview-row"><Icon name="check_circle" /><span>{t('lessonReady')}</span></div><div className="preview-row"><Icon name="assignment" /><span>{t('assignmentReady')}</span></div></div></div></div>
    </section><section id="features" className="landing-section"><div className="landing-wrap"><p className="landing-eyebrow">{t('features')}</p><h2>{t('featuresTitle')}</h2><p className="landing-section-intro">{t('featuresText')}</p><div className="landing-grid">{features.map(([icon, title, description]) => <article className="landing-feature" key={title}><span className="landing-icon"><Icon name={icon} /></span><h3>{t(title)}</h3><p>{t(description)}</p></article>)}</div></div></section>
    <section className="landing-wrap landing-audiences"><article id="teachers"><span className="landing-icon"><Icon name="co_present" /></span><p className="landing-eyebrow">{t('teachers')}</p><h2>{t('teacherTitle')}</h2><p>{t('teacherText')}</p></article><article id="students"><span className="landing-icon"><Icon name="school" /></span><p className="landing-eyebrow">{t('students')}</p><h2>{t('studentTitle')}</h2><p>{t('studentText')}</p></article></section>
    <section className="landing-wrap landing-cta"><div><h2>{t('ctaTitle')}</h2><p>{t('ctaText')}</p></div><Link tabIndex={0} className="btn" to="/login">{t('signIn')} <Icon name="arrow_forward" /></Link></section></main>
    <footer className="landing-footer"><div className="landing-wrap"><span>Learn<b>Pulse</b></span><nav aria-label={t('footer')}><a tabIndex={0} href="#features">{t('features')}</a><a tabIndex={0} href="#teachers">{t('teachers')}</a><a tabIndex={0} href="#students">{t('students')}</a><Link tabIndex={0} to="/login">{t('signIn')}</Link></nav></div></footer>
  </div>;
}
