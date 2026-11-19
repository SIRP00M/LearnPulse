import { describe, expect, it, vi } from 'vitest';
import { act, renderHook } from '@testing-library/react';
import { QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import { AppError } from './errors';
import { makeQueryClient, useAction } from './hooks';
import { ToastProvider } from '../ui/kit';

const wrapper = ({ children }: { children: ReactNode }) => (
  <QueryClientProvider client={makeQueryClient()}><ToastProvider>{children}</ToastProvider></QueryClientProvider>
);

describe('useAction (idempotency and duplicate prevention)', () => {
  it('reuses the request id when the same input is retried after a failure, and issues a new one for new input', async () => {
    const ids: string[] = [];
    const fn = vi.fn(async (id: string, _x: string) => { ids.push(id); if (ids.length < 3) throw new AppError('network', 'offline'); return 'ok'; });
    const { result } = renderHook(() => useAction(fn), { wrapper });
    await act(async () => { await result.current.run('same'); });
    await act(async () => { await result.current.run('same'); });
    expect(ids[0]).toBe(ids[1]); // retry of identical content: same id (server replays)
    await act(async () => { await result.current.run('same'); }); // succeeds
    await act(async () => { await result.current.run('same'); });
    expect(ids[3]).not.toBe(ids[2]); // after success a new action gets a new id
    await act(async () => { await result.current.run('edited'); });
    expect(ids[4]).not.toBe(ids[3]);
  });

  it('a different input after a failure gets a new id (same id + different content would be a server conflict)', async () => {
    const ids: string[] = [];
    const fn = async (id: string, _x: string) => { ids.push(id); throw new AppError('network', 'offline'); };
    const { result } = renderHook(() => useAction(fn), { wrapper });
    await act(async () => { await result.current.run('a'); });
    await act(async () => { await result.current.run('b'); });
    expect(ids[0]).not.toBe(ids[1]);
  });

  it('ignores a second call while one is in flight', async () => {
    let release: () => void = () => {};
    const fn = vi.fn((_id: string) => new Promise<string>((r) => { release = () => r('done'); }));
    const { result } = renderHook(() => useAction(fn), { wrapper });
    let first: Promise<unknown>;
    act(() => { first = result.current.run(); });
    await act(async () => { await result.current.run(); });
    expect(fn).toHaveBeenCalledTimes(1);
    await act(async () => { release(); await first; });
    expect(result.current.busy).toBe(false);
  });

  it('a conflict drops the old id and surfaces the error', async () => {
    const ids: string[] = [];
    const fn = async (id: string) => { ids.push(id); throw new AppError('conflict', 'stale'); };
    const { result } = renderHook(() => useAction(fn), { wrapper });
    await act(async () => { await result.current.run(); });
    expect(result.current.error?.kind).toBe('conflict');
    await act(async () => { await result.current.run(); });
    expect(ids[0]).not.toBe(ids[1]);
  });
});
