import { keepPreviousData, queryOptions, useQuery } from '@tanstack/react-query';
import { api } from './api/core';
import { v9 } from './api/v9';
import { att2 } from './api/att2';

/** Every key starts with its invalidation topic (see lib/hooks.ts). */
export const q = {
  courses: () => queryOptions({ queryKey: ['courses', 'list'], queryFn: api.listCourses }),
  roster: (courseId: string) => queryOptions({ queryKey: ['roster', courseId], queryFn: () => api.roster(courseId) }),
  joinCode: (courseId: string) => queryOptions({ queryKey: ['courses', 'join-code', courseId], queryFn: () => api.joinCode(courseId), staleTime: 5 * 60_000 }),
  lessons: (courseId: string) => queryOptions({ queryKey: ['lessons', 'list', courseId], queryFn: () => api.listLessons(courseId) }),
  resources: (courseId: string) => queryOptions({ queryKey: ['lessons', 'resources', courseId], queryFn: () => api.listResources(courseId) }),
  assignments: (courseId: string) => queryOptions({ queryKey: ['assignments', 'list', courseId], queryFn: () => api.listAssignments(courseId) }),
  mySubmissions: () => queryOptions({ queryKey: ['submissions', 'mine'], queryFn: api.mySubmissions }),
  submissions: (assignmentId: string) => queryOptions({ queryKey: ['submissions', 'of', assignmentId], queryFn: () => api.listSubmissions(assignmentId) }),
  submissionEvents: (submissionId: string) => queryOptions({ queryKey: ['submissions', 'events', submissionId], queryFn: () => api.submissionEvents(submissionId) }),
  sessions: (courseId: string) => queryOptions({ queryKey: ['attendance', 'sessions', courseId], queryFn: () => api.listSessions(courseId) }),
  session: (id: string) => queryOptions({ queryKey: ['attendance', 'session', id], queryFn: () => api.getSession(id) }),
  sessionRecords: (id: string) => queryOptions({ queryKey: ['attendance', 'records', id], queryFn: () => api.listRecordsFor([id]) }),
  courseRecords: (sessionIds: string[]) => queryOptions({ queryKey: ['attendance', 'course-records', ...sessionIds], queryFn: () => api.listRecordsFor(sessionIds), enabled: sessionIds.length > 0 }),
  myRecords: (courseId: string) => queryOptions({ queryKey: ['attendance', 'mine', courseId], queryFn: () => api.myRecords(courseId) }),
  sessionEvents: (id: string) => queryOptions({ queryKey: ['attendance', 'events', id], queryFn: () => api.sessionEvents(id) }),
  attendanceSummary: (courseId: string) => queryOptions({ queryKey: ['attendance', 'summary', courseId], queryFn: () => api.attendanceSummary(courseId) }),
  staffContext: () => queryOptions({ queryKey: ['staff', 'context'], queryFn: att2.staffContext }),
  staffReport: (from: string, to: string, staffId?: string) => queryOptions({ queryKey: ['staff', 'report', staffId ?? 'me', from, to], queryFn: () => att2.staffReport(from, to, staffId), placeholderData: keepPreviousData }),
  staffTeam: (from: string, to: string) => queryOptions({ queryKey: ['staff', 'team', from, to], queryFn: () => att2.team(from, to) }),
  staffRequests: (scope: 'mine' | 'decide', status?: string) => queryOptions({ queryKey: ['staff', 'requests', scope, status ?? 'all'], queryFn: () => att2.listRequests(scope, status) }),
  staffSchedules: (staffId: string) => queryOptions({ queryKey: ['staff', 'schedules', staffId], queryFn: () => att2.schedulesOf(staffId) }),
  teacherDashboard: () => queryOptions({ queryKey: ['dashboard', 'teacher'], queryFn: api.teacherDashboard }),
  studentDashboard: () => queryOptions({ queryKey: ['dashboard', 'student'], queryFn: api.studentDashboard }),
  overview: (courseId: string) => queryOptions({ queryKey: ['activities', 'overview', courseId], queryFn: () => v9.overview(courseId) }),
  register: (activityId: string, week: string) => queryOptions({ queryKey: ['activities', 'register', activityId, week], queryFn: () => v9.register(activityId, week), placeholderData: keepPreviousData }),
  pending: (courseId?: string) => queryOptions({ queryKey: ['activities', 'pending', courseId ?? 'all'], queryFn: () => v9.allPending(courseId) }),
  streaks: (courseId: string, studentId?: string) => queryOptions({ queryKey: ['progress', 'streaks', courseId, studentId ?? 'me'], queryFn: () => v9.streaks(courseId, studentId) }),
  studentProgress: (courseId: string, studentId: string) => queryOptions({ queryKey: ['progress', 'student', courseId, studentId], queryFn: () => v9.studentProgress(courseId, studentId) }),
  myProgress: (courseId: string) => queryOptions({ queryKey: ['progress', 'mine', courseId], queryFn: () => v9.myProgress(courseId) }),
  myActivities: (from: string, to: string, courseId?: string) => queryOptions({ queryKey: ['activities', 'mine', from, to, courseId ?? 'all'], queryFn: () => v9.myActivitiesWindow(from, to, courseId), placeholderData: keepPreviousData }),
};

export const useCourses = () => useQuery(q.courses());
export function useCourse(courseId: string) {
  const r = useCourses();
  return { ...r, course: r.data?.find((c) => c.id === courseId) };
}
