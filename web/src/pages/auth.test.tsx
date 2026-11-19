import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppError } from '../lib/errors';

const signIn = vi.fn();
vi.mock('../auth/AuthProvider', () => ({
  useAuth: () => ({ signIn, signUp: vi.fn(), sessionExpired: false, dismissExpired: () => {}, resendConfirmation: vi.fn(), requestReset: vi.fn() }),
}));
vi.mock('@tanstack/react-router', () => ({
  Link: ({ children, to }: { children: React.ReactNode; to: string }) => <a href={to}>{children}</a>,
  useNavigate: () => vi.fn(),
}));
const settings = vi.fn();
vi.mock('../lib/api/core', () => ({ authSettings: () => settings() }));

import { SignInPage, SignUpPage } from './auth';

const wrap = (ui: React.ReactElement) => render(<QueryClientProvider client={new QueryClient()}>{ui}</QueryClientProvider>);
beforeEach(() => { signIn.mockReset(); settings.mockReset(); settings.mockResolvedValue({ signupDisabled: false }); });

describe('SignInPage', () => {
  it('validates before any request and marks fields invalid', async () => {
    wrap(<SignInPage />);
    await userEvent.click(screen.getByRole('button', { name: 'Sign in' }));
    expect(screen.getByText('Enter your email address')).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toHaveAttribute('aria-invalid', 'true');
    expect(signIn).not.toHaveBeenCalled();
  });

  it('shows a plain error for bad credentials and keeps the form usable', async () => {
    signIn.mockRejectedValueOnce(new AppError('invalidCredentials', 'Email or password is incorrect.'));
    wrap(<SignInPage />);
    await userEvent.type(screen.getByLabelText('Email'), 'a@b.co');
    await userEvent.type(screen.getByLabelText('Password'), 'whatever');
    await userEvent.click(screen.getByRole('button', { name: 'Sign in' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Email or password is incorrect.');
    expect(screen.getByRole('button', { name: 'Sign in' })).toBeEnabled();
  });

  it('offers to resend the confirmation email when the account is unconfirmed', async () => {
    signIn.mockRejectedValueOnce(new AppError('emailNotConfirmed', 'Please confirm your email address first.'));
    wrap(<SignInPage />);
    await userEvent.type(screen.getByLabelText('Email'), 'a@b.co');
    await userEvent.type(screen.getByLabelText('Password'), 'x');
    await userEvent.click(screen.getByRole('button', { name: 'Sign in' }));
    expect(await screen.findByRole('button', { name: 'Resend confirmation email' })).toBeInTheDocument();
  });
});

describe('SignUpPage respects the server configuration', () => {
  it('replaces the form with a notice when registration is closed', async () => {
    settings.mockResolvedValue({ signupDisabled: true });
    wrap(<SignUpPage />);
    expect(await screen.findByText(/Registration is currently closed/)).toBeInTheDocument();
    await waitFor(() => expect(screen.queryByRole('button', { name: 'Create account' })).toBeNull());
  });
  it('validates name, email and password strength when open', async () => {
    wrap(<SignUpPage />);
    await userEvent.click(await screen.findByRole('button', { name: 'Create account' }));
    expect(screen.getByText('Enter your name')).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText('Full name'), 'A');
    await userEvent.type(screen.getByLabelText('Email'), 'a@b.co');
    await userEvent.type(screen.getByLabelText('Password'), 'short');
    await userEvent.click(screen.getByRole('button', { name: 'Create account' }));
    expect(screen.getByText('Use at least 10 characters')).toBeInTheDocument();
  });
});
