import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import type { Session } from '@supabase/supabase-js';
import { supabase, recoveryUserId } from '../lib/supabase';
import { api } from '../lib/api/core';
import { AppError, toAppError } from '../lib/errors';
import type { Profile } from '../lib/schemas';
import { clearAvatarCaches, dropAvatar, saveAvatar } from '../lib/api/avatar';

export type Stage = 'starting' | 'signedOut' | 'loadingProfile' | 'signedIn' | 'recovery' | 'profileError';

interface AuthState {
  stage: Stage;
  profile: Profile | null;
  userId: string | null;
  email: string | null;
  /** True when the session ended without the user asking for it. */
  sessionExpired: boolean;
  profileError: AppError | null;
  signIn(email: string, password: string): Promise<void>;
  signUp(email: string, password: string, fullName: string): Promise<{ needsConfirmation: boolean }>;
  resendConfirmation(email: string): Promise<void>;
  requestReset(email: string): Promise<void>;
  setNewPassword(password: string): Promise<void>;
  signOut(): Promise<void>;
  updateName(name: string): Promise<void>;
  setAvatar(blob: Blob, ext: 'webp' | 'jpg'): Promise<void>;
  removeAvatar(): Promise<void>;
  retryProfile(): void;
  dismissExpired(): void;
}

const Ctx = createContext<AuthState | null>(null);
export const useAuth = () => {
  const v = useContext(Ctx);
  if (!v) throw new Error('useAuth outside AuthProvider');
  return v;
};

const callback = () => `${window.location.origin}/auth/callback`;

export function AuthProvider({ children }: { children: ReactNode }) {
  const qc = useQueryClient();
  const [stage, setStage] = useState<Stage>('starting');
  const [profile, setProfile] = useState<Profile | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [expired, setExpired] = useState(false);
  const [profileError, setProfileError] = useState<AppError | null>(null);
  const signingOut = useRef(false);
  const userRef = useRef<string | null>(null);
  const stageRef = useRef<Stage>('starting');
  stageRef.current = stage;

  const loadProfile = useCallback(async (uid: string) => {
    stageRef.current = 'loadingProfile';
    setStage('loadingProfile');
    try {
      const p = await api.loadProfile(uid);
      if (userRef.current !== uid || recoveryUserId === uid) return;
      setProfile(p);
      setProfileError(null);
      setStage('signedIn');
    } catch (e) {
      if (userRef.current !== uid || recoveryUserId === uid) return;
      setProfileError(toAppError(e));
      setStage('profileError');
    }
  }, []);

  useEffect(() => {
    const { data: sub } = supabase.auth.onAuthStateChange((event, s) => {
      // Never await Supabase calls inside this callback (it would deadlock the auth lock); defer them.
      setTimeout(() => {
        if (event === 'PASSWORD_RECOVERY' || (event === 'INITIAL_SESSION' && s?.user.id === recoveryUserId)) {
          stageRef.current = 'recovery';
          userRef.current = s?.user.id ?? null;
          setSession(s);
          setStage('recovery');
          return;
        }
        if (event === 'SIGNED_OUT' || !s) {
          const wasIn = stageRef.current === 'signedIn' || stageRef.current === 'loadingProfile';
          if (wasIn && !signingOut.current) setExpired(true);
          signingOut.current = false;
          userRef.current = null;
          qc.clear(); // account-scoped caches never survive a sign-out
          clearAvatarCaches();
          setProfile(null);
          setSession(null);
          setStage('signedOut');
          return;
        }
        const changed = userRef.current !== s.user.id;
        setSession(s);
        if (changed) {
          // A different account: drop every cached row before anything renders for it.
          qc.clear();
          clearAvatarCaches();
          userRef.current = s.user.id;
          setProfile(null);
          if (stageRef.current !== 'recovery') void loadProfile(s.user.id);
        } else if (event === 'USER_UPDATED' && stageRef.current === 'recovery') {
          void loadProfile(s.user.id);
        }
      }, 0);
    });
    return () => sub.subscription.unsubscribe();
  }, [qc, loadProfile]);

  const value = useMemo<AuthState>(
    () => ({
      stage,
      profile,
      userId: session?.user.id ?? null,
      email: session?.user.email ?? null,
      sessionExpired: expired,
      profileError,
      async signIn(email, password) {
        setExpired(false);
        const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
        if (error) throw toAppError(error);
      },
      async signUp(email, password, fullName) {
        setExpired(false);
        const { data, error } = await supabase.auth.signUp({
          email: email.trim(), password, options: { data: { full_name: fullName.trim() }, emailRedirectTo: callback() },
        });
        if (error) throw toAppError(error);
        // A registered address answers like a new one (no enumeration); either way the user acts on an email,
        // unless the project auto-confirms (then a session exists and onAuthStateChange signs in).
        return { needsConfirmation: data.session == null };
      },
      async resendConfirmation(email) {
        const { error } = await supabase.auth.resend({ type: 'signup', email: email.trim(), options: { emailRedirectTo: callback() } });
        if (error) throw toAppError(error);
      },
      async requestReset(email) {
        const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo: callback() });
        if (error) throw toAppError(error);
      },
      async setNewPassword(password) {
        const { error } = await supabase.auth.updateUser({ password });
        if (error) throw toAppError(error);
        if (userRef.current && stageRef.current === 'recovery') void loadProfile(userRef.current);
      },
      async signOut() {
        signingOut.current = true;
        const { error } = await supabase.auth.signOut();
        if (error) {
          // Local sign-out still happens; make sure nothing of this account remains.
          await supabase.auth.signOut({ scope: 'local' });
        }
        // The deferred SIGNED_OUT handler resets the flag; this is only a safety net if no event arrives.
        setTimeout(() => { signingOut.current = false; }, 2000);
        qc.clear();
        clearAvatarCaches();
        userRef.current = null;
        setProfile(null);
        setSession(null);
        setStage('signedOut');
      },
      async updateName(name) {
        if (!session) throw new AppError('unauthenticated', 'You are not signed in.', undefined, 'errors:noSession');
        await api.updateName(session.user.id, name.trim());
        setProfile((p) => (p ? { ...p, fullName: name.trim() } : p));
      },
      async setAvatar(blob, ext) {
        if (!session) throw new AppError('unauthenticated', 'You are not signed in.', undefined, 'errors:noSession');
        const path = await saveAvatar(session.user.id, blob, ext);
        setProfile((p) => (p ? { ...p, avatarPath: path } : p));
      },
      async removeAvatar() {
        if (!session) throw new AppError('unauthenticated', 'You are not signed in.', undefined, 'errors:noSession');
        await dropAvatar(session.user.id);
        setProfile((p) => (p ? { ...p, avatarPath: null } : p));
      },
      retryProfile() {
        if (userRef.current) void loadProfile(userRef.current);
      },
      dismissExpired: () => setExpired(false),
    }),
    [stage, profile, session, expired, profileError, qc, loadProfile],
  );
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}
