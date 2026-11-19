import { z } from 'zod';
import { rpc } from '../rpc';
import { supabase } from '../supabase';

/** Live Demo (Option B). The two ANONYMOUS calls bypass `rpc()` because there is no session yet and a claim must never be auto-retried. */
const claimResult = z.object({
  ok: z.boolean(), reason: z.string().optional(), email: z.string().optional(), password: z.string().optional(),
  retry: z.boolean().optional(), already_active: z.boolean().optional(), workshop_course_id: z.string().nullish(),
});
export type ClaimResult = z.infer<typeof claimResult>;

const overview = z.object({
  id: z.string(), label: z.string(), status: z.string(), capacity: z.number(), seats: z.number(), workshop_course_id: z.string().nullish(), workshop_title: z.string().nullish(),
  joins_close_at: z.string(), expires_at: z.string(), server_now: z.string(), join_window_seconds: z.number(), lifetime_seconds: z.number(),
  counts: z.record(z.string(), z.number()),
  recent: z.object({ claims: z.number(), refused: z.number() }),
  seats_list: z.array(z.object({ seat_no: z.number(), state: z.string(), name: z.string().nullish(), reserve: z.boolean() })),
});
const mySessions = z.array(z.object({ id: z.string(), label: z.string(), status: z.string(), workshop_course_id: z.string().nullish(), joins_close_at: z.string(), expires_at: z.string() }));
const joinToken = z.object({ token: z.string(), display: z.string(), expires_at: z.string(), refresh_seconds: z.number(), status: z.string() });
const any = z.unknown();

export const demo = {
  async claim(token: string, name: string, nonce: string): Promise<ClaimResult> {
    const { data, error } = await supabase.rpc('demo_claim_seat', { p_join_token: token, p_name: name, p_client_nonce: nonce });
    if (error) return { ok: false, reason: 'failed' };
    const p = claimResult.safeParse(data);
    return p.success ? p.data : { ok: false, reason: 'failed' };
  },
  activate: () => rpc('demo_activate_seat', undefined, z.object({ ok: z.boolean(), workshop_course_id: z.string().nullish() }), { retries: 0 }),
  mySessions: () => rpc('demo_my_sessions', undefined, mySessions),
  token: (session: string) => rpc('demo_join_token', { p_session: session }, joinToken, { retries: 0 }),
  overview: (session: string) => rpc('demo_session_overview', { p_session: session }, overview),
  start: (session: string) => rpc('demo_start_session', { p_session: session }, z.object({ status: z.string(), already: z.boolean() }), { retries: 0 }),
  setJoins: (session: string, mode: 'open' | 'paused' | 'closed') => rpc('demo_set_joins', { p_session: session, p_mode: mode }, any),
  end: (session: string) => rpc('demo_end_session', { p_session: session }, any),
  disable: (session: string, seat: number) => rpc('demo_disable_seat', { p_session: session, p_seat_no: seat }, any),
};
