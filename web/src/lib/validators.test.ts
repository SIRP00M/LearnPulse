import { describe, expect, it } from 'vitest';
import { validateEmail, validateName, validatePassword, validateTitle } from './validators';

describe('validators', () => {
  it('email', () => {
    expect(validateEmail('')).toBe('validation:emailRequired');
    expect(validateEmail('a@b')).toBe('validation:emailInvalid');
    expect(validateEmail(' a@b.co ')).toBeNull();
  });
  it('password policy matches the server (10+, upper, lower, digit)', () => {
    expect(validatePassword('Short1')).toBe('validation:passwordShort');
    expect(validatePassword('alllowercase1')).toBe('validation:passwordMix');
    expect(validatePassword('NoDigitsHereAtAll')).toBe('validation:passwordMix');
    expect(validatePassword('GoodPassw0rd!')).toBeNull();
  });
  it('name and title limits', () => {
    expect(validateName('  ')).toBe('validation:nameRequired');
    expect(validateName('x'.repeat(121))).toBe('validation:nameLong');
    expect(validateTitle('x'.repeat(121), 120)).toBe('validation:titleLong');
    expect(validateTitle('Quiz', 120)).toBeNull();
  });
});
