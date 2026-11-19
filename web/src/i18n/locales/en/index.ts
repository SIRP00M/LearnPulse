// Translation resources for 'en'. One file per namespace; the key set must equal English (enforced by src/i18n/i18n.test.ts and the type below).
import common from './common';
import errors from './errors';
import validation from './validation';
import status from './status';
import nav from './nav';
import table from './table';
import auth from './auth';
import dashboard from './dashboard';
import courses from './courses';
import lessons from './lessons';
import assignments from './assignments';
import attendance from './attendance';
import activities from './activities';
import progress from './progress';
import tasks from './tasks';
import verification from './verification';
import profile from './profile';
import landing from './landing';
import staff from './staff';
import demo from './demo';

const en = { common, errors, validation, status, nav, table, auth, dashboard, courses, lessons, assignments, attendance, activities, progress, tasks, verification, profile, landing, staff, demo };
export default en;
/** The canonical shape: every other language must provide exactly these keys. */
export type Resources = typeof en;
