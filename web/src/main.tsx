import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider } from '@tanstack/react-router';
import '@fontsource/roboto/latin-400.css';
import '@fontsource/roboto/latin-500.css';
import '@fontsource/roboto/latin-700.css';
import '@fontsource/noto-sans-thai/thai-400.css';
import '@fontsource/noto-sans-thai/thai-500.css';
import '@fontsource/noto-sans-thai/thai-700.css';
import '@fontsource/material-icons-outlined/latin-400.css';
import './styles.css';
import './i18n';
import { applyTheme, getThemePref } from './lib/theme';
import { makeQueryClient } from './lib/hooks';
import { AuthProvider } from './auth/AuthProvider';
import { ToastProvider } from './ui/kit';
import { router } from './router';

applyTheme(getThemePref());
window.matchMedia?.('(prefers-color-scheme: dark)').addEventListener('change', () => applyTheme(getThemePref()));

const queryClient = makeQueryClient();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <ToastProvider>
        <AuthProvider>
          <RouterProvider router={router} />
        </AuthProvider>
      </ToastProvider>
    </QueryClientProvider>
  </StrictMode>,
);
