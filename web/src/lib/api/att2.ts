import { z } from 'zod';
import { rpc } from '../rpc';
import { supabase } from '../supabase';
import {
  qrIssue, scanResult, rulesResult, staffContext, staffReport, teamSummary, punchResult, staffRequest, idResult,
} from '../schemas';

/** Option E: QR attendance (V13) and staff attendance (V14). Every mutation is an RPC; the server clock decides every time. */
export const att2 = {
  setRules: (sessionId: string, requestId: string, version: number, r: { requiresCheckout: boolean; lateAfter: number; opens: number; window: number | null }) =>
    rpc('set_attendance_rules', {
      p_session_id: sessionId, p_request_id: requestId, p_expected_version: version, p_requires_checkout: r.requiresCheckout,
      p_late_after_minutes: r.lateAfter, p_checkin_opens_minutes: r.opens, p_checkin_window_minutes: r.window,
    }, rulesResult),
  issueQr: (sessionId: string, action: 'in' | 'out') => rpc('issue_attendance_qr', { p_session_id: sessionId, p_action: action }, qrIssue, { retries: 0 }),
  scan: (token: string) => rpc('scan_attendance', { p_token: token.trim() }, scanResult, { retries: 0 }),

  staffContext: () => rpc('get_my_staff_context', undefined, staffContext),
  clockIn: (requestId: string) => rpc('staff_clock_in', { p_request_id: requestId }, punchResult),
  clockOut: (requestId: string) => rpc('staff_clock_out', { p_request_id: requestId }, punchResult),
  staffReport: (from: string, to: string, staffId?: string) => rpc('get_staff_attendance', { p_from: from, p_to: to, p_staff_id: staffId }, staffReport),
  team: (from: string, to: string) => rpc('get_staff_team_summary', { p_from: from, p_to: to }, teamSummary),
  listRequests: (scope: 'mine' | 'decide', status?: string) => rpc('list_staff_requests', { p_scope: scope, p_status: status }, z.array(staffRequest)),
  submitRequest: (requestId: string, r: { kind: 'leave' | 'correction'; from: string; to: string; reason: string; clockIn?: string; clockOut?: string }) =>
    rpc('submit_staff_request', {
      p_request_id: requestId, p_kind: r.kind, p_from: r.from, p_to: r.to, p_reason: r.reason, p_clock_in: r.clockIn, p_clock_out: r.clockOut,
    }, idResult),
  cancelRequest: (id: string) => rpc('cancel_staff_request', { p_id: id }, idResult),
  decide: (id: string, requestId: string, decision: 'approve' | 'reject', note: string) =>
    rpc('decide_staff_request', { p_id: id, p_request_id: requestId, p_decision: decision, p_note: note }, idResult),
  saveSchedule: (staffId: string, requestId: string, s: { label: string; weekdays: number[]; start: string; end: string; timezone: string; grace: number; from: string; to?: string }) =>
    rpc('save_staff_schedule', {
      p_staff_id: staffId, p_request_id: requestId, p_label: s.label, p_weekdays: s.weekdays, p_start: s.start, p_end: s.end, p_timezone: s.timezone,
      p_grace: s.grace, p_effective_from: s.from, p_effective_to: s.to,
    }, idResult),
  /** RLS lets a supervisor read the schedules of the staff they supervise (and nobody else's). */
  async schedulesOf(staffId: string) {
    const { data, error } = await supabase.from('staff_schedules').select('id, label, weekdays, start_time, end_time, timezone, late_grace_minutes, effective_from, effective_to')
      .eq('staff_id', staffId).order('start_time');
    if (error) throw error;
    return data ?? [];
  },
  endSchedule: (id: string, to: string) => rpc('end_staff_schedule', { p_schedule_id: id, p_effective_to: to }, idResult),
};
