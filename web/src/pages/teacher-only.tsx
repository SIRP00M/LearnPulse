import type { ReactNode } from 'react';
import { useAuth } from '../auth/AuthProvider';
import { ErrorState } from '../ui/kit';

export function TeacherOnly({ children }: { children: ReactNode }) {
  const { profile } = useAuth();
  if (profile?.role !== 'teacher') return <ErrorState error={{ code: 'PT403' }} />;
  return <>{children}</>;
}
