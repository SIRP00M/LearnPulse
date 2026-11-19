import type { Role } from './schemas';

export interface Target { to: string; params?: Record<string, string>; search?: Record<string, string> }

/** Deep link to the real resource behind a task/calendar row. */
export function taskTarget(kind: string, courseId: string, id: string, role: Role, date?: string | null): Target {
  const params = { courseId, id };
  switch (kind) {
    case 'assignment':
    case 'assignment_due':
      return { to: '/courses/$courseId/assignments/$id', params };
    case 'activity':
    case 'activity_day':
      return { to: '/courses/$courseId/activities/$id', params, search: date ? { week: date } : undefined };
    default:
      return role === 'teacher'
        ? { to: '/courses/$courseId/attendance/$id', params }
        : { to: '/courses/$courseId/attendance', params: { courseId } };
  }
}
