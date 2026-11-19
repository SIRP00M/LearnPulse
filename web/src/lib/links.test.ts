import { describe, expect, it } from 'vitest';
import { taskTarget } from './links';

describe('taskTarget (deep links to the real resource)', () => {
  it('assignments and activities open their own pages', () => {
    expect(taskTarget('assignment', 'c1', 'a1', 'student').to).toBe('/courses/$courseId/assignments/$id');
    const t = taskTarget('activity', 'c1', 'x1', 'student', '2026-11-16');
    expect(t.to).toBe('/courses/$courseId/activities/$id');
    expect(t.search).toEqual({ week: '2026-11-16' });
    expect(taskTarget('activity_day', 'c1', 'x1', 'teacher', '2026-11-16').to).toBe('/courses/$courseId/activities/$id');
  });
  it('attendance goes to the session for teachers and the course attendance tab for students', () => {
    expect(taskTarget('attendance_session', 'c1', 's1', 'teacher').to).toBe('/courses/$courseId/attendance/$id');
    expect(taskTarget('attendance_session', 'c1', 's1', 'student').to).toBe('/courses/$courseId/attendance');
  });
});
