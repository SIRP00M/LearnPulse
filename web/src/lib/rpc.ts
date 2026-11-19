import type { z } from 'zod';
import { supabase } from './supabase';
import { AppError, toAppError } from './errors';

const TIMEOUT_MS = 25_000;

function clean(p?: Record<string, unknown>) {
  if (!p) return undefined;
  return Object.fromEntries(Object.entries(p).filter(([, v]) => v !== undefined));
}

/**
 * Calls a PostgREST RPC with the user's JWT, validates the response and maps PT4xx errors.
 * Network/timeout failures retry with the SAME params, so a mutation's `p_request_id` is preserved
 * and the server replays instead of repeating.
 */
export async function rpc<S extends z.ZodType>(
  name: string,
  params: Record<string, unknown> | undefined,
  schema: S,
  opts: { retries?: number } = {},
): Promise<z.infer<S>> {
  const retries = opts.retries ?? 1;
  let last: AppError | null = null;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const { data, error } = await supabase
        .rpc(name, clean(params))
        .abortSignal(AbortSignal.timeout(TIMEOUT_MS));
      if (error) throw toAppError(error);
      const parsed = schema.safeParse(data);
      if (!parsed.success) throw new AppError('contract', 'The server answered in an unexpected format.');
      return parsed.data;
    } catch (e) {
      last = toAppError(e);
      if (!last.retryable || attempt === retries) throw last;
      await new Promise((r) => setTimeout(r, 400 * (attempt + 1)));
    }
  }
  throw last ?? new AppError('unknown', 'Something went wrong. Please try again.');
}

/** Table/Storage reads that go through RLS. Rows are validated by the caller's zod schema. */
export async function read<S extends z.ZodType>(
  q: PromiseLike<{ data: unknown; error: unknown }>,
  schema: S,
): Promise<z.infer<S>> {
  let res;
  try {
    res = await q;
  } catch (e) {
    throw toAppError(e);
  }
  if (res.error) throw toAppError(res.error);
  const parsed = schema.safeParse(res.data);
  if (!parsed.success) throw new AppError('contract', 'The server answered in an unexpected format.');
  return parsed.data;
}
