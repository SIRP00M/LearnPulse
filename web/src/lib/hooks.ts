import { useCallback, useRef, useState } from 'react';
import { QueryClient, useQueryClient } from '@tanstack/react-query';
import i18n from '../i18n';
import { errorText, toAppError, type AppError } from './errors';
import { newRequestId } from './ids';
import { useToast } from '../ui/kit';

/** Query-key topics, mirroring the mobile SummaryBus. Every key starts with its topic so prefix invalidation works. */
export type Topic = 'dashboard' | 'progress' | 'tasks' | 'activities' | 'courses' | 'lessons' | 'assignments' | 'submissions' | 'attendance' | 'roster' | 'staff';

export function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        gcTime: 10 * 60_000,
        networkMode: 'always', // attempt the request and show a real error, instead of pausing on a spinner while offline
        refetchOnWindowFocus: true, // the only "live" behaviour by design: no Realtime, no polling
        retry: (n, e) => n < 1 && toAppError(e).retryable,
      },
    },
  });
}

export function invalidate(qc: QueryClient, ...topics: Topic[]) {
  return Promise.all(topics.map((t) => qc.invalidateQueries({ queryKey: [t] })));
}

export interface ActionOptions<R> {
  topics?: Topic[];
  success?: string;
  onDone?: (r: R) => void;
}

/**
 * Runs one user action at a time. The request id is generated per distinct input and REUSED when the same
 * input is retried after a failure, so the server replays instead of repeating. A conflict (PT409) or a
 * not-found refreshes the affected topics so the next attempt uses the current version.
 */
export function useAction<A extends unknown[], R>(fn: (requestId: string, ...args: A) => Promise<R>, opts: ActionOptions<R> = {}) {
  const qc = useQueryClient();
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  const flight = useRef(false);
  const last = useRef<{ key: string; id: string } | null>(null);

  const run = useCallback(async (...args: A): Promise<R | undefined> => {
    if (flight.current) return undefined; // no duplicate submission
    flight.current = true;
    setBusy(true);
    setError(null);
    const key = JSON.stringify(args, (_, v) => (v instanceof File ? `${v.name}:${v.size}:${v.lastModified}` : v));
    if (!last.current || last.current.key !== key) last.current = { key, id: newRequestId() };
    try {
      const r = await fn(last.current.id, ...args);
      last.current = null;
      if (opts.topics?.length) await invalidate(qc, ...opts.topics);
      if (opts.success) toast(opts.success);
      opts.onDone?.(r);
      return r;
    } catch (e) {
      const err = toAppError(e);
      setError(err);
      if (err.kind === 'conflict' || err.kind === 'notFound') {
        // The refresh below can remount the form that showed the error, so say it where it survives a remount.
        toast(`${errorText(err)} ${i18n.t('errors:conflictReloaded')}`, true);
        last.current = null; // the content is no longer valid as-is
        if (opts.topics?.length) void invalidate(qc, ...opts.topics);
      }
      return undefined;
    } finally {
      flight.current = false;
      setBusy(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fn, qc, toast, opts.topics?.join(','), opts.success]);

  return { run, busy, error, clearError: () => setError(null) };
}

/** Fixed Task-based topics to refresh after activity/assignment/attendance mutations (matches the mobile rules). */
export const AFTER_ACTIVITY: Topic[] = ['activities', 'progress', 'tasks', 'dashboard'];
export const AFTER_ASSIGNMENT: Topic[] = ['assignments', 'submissions', 'progress', 'tasks', 'dashboard'];
export const AFTER_ATTENDANCE: Topic[] = ['attendance', 'progress', 'tasks', 'dashboard'];
export const AFTER_STAFF: Topic[] = ['staff'];
