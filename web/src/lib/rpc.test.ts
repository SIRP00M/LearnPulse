import { beforeEach, describe, expect, it, vi } from 'vitest';
import { z } from 'zod';

const calls: { name: string; params: unknown }[] = [];
let queue: { data?: unknown; error?: unknown; throwNet?: boolean }[] = [];

vi.mock('./supabase', () => ({
  supabase: {
    rpc: (name: string, params: unknown) => {
      calls.push({ name, params });
      return { abortSignal: async () => {
        const next = queue.shift() ?? { data: null };
        if (next.throwNet) throw new TypeError('Failed to fetch');
        return { data: next.data ?? null, error: next.error ?? null };
      } };
    },
  },
}));

import { rpc } from './rpc';

beforeEach(() => { calls.length = 0; queue = []; });
const schema = z.object({ id: z.string() });

describe('rpc wrapper', () => {
  it('validates the response and drops undefined params', async () => {
    queue = [{ data: { id: 'x', extra: 1 } }];
    const r = await rpc('f', { a: 1, b: undefined }, schema);
    expect(r).toEqual({ id: 'x' });
    expect(calls[0]!.params).toEqual({ a: 1 });
  });

  it('retries a network failure with the SAME params (so the request id is preserved)', async () => {
    queue = [{ throwNet: true }, { data: { id: 'ok' } }];
    const r = await rpc('create_thing', { p_request_id: 'req-1', p_title: 't' }, schema);
    expect(r.id).toBe('ok');
    expect(calls).toHaveLength(2);
    expect(calls[1]!.params).toEqual(calls[0]!.params);
  });

  it('gives up after the retry budget with a retryable network error', async () => {
    queue = [{ throwNet: true }, { throwNet: true }];
    await expect(rpc('f', {}, schema)).rejects.toMatchObject({ kind: 'network', retryable: true });
    expect(calls).toHaveLength(2);
  });

  it('does not retry server rejections and maps PT409 to a conflict', async () => {
    queue = [{ error: { code: 'PT409', message: 'stale' } }, { data: { id: 'never' } }];
    await expect(rpc('f', {}, schema)).rejects.toMatchObject({ kind: 'conflict' });
    expect(calls).toHaveLength(1);
  });

  it('turns a malformed answer into a contract error instead of data', async () => {
    queue = [{ data: { id: 42 } }];
    await expect(rpc('f', {}, schema)).rejects.toMatchObject({ kind: 'contract' });
  });
});
