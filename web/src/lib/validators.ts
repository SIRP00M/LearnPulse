const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

// Validators return a translation KEY (namespace:key). Components keep the key in state and translate it when rendering,
// so a visible message changes language the moment the interface language changes.
export const validateEmail = (v: string): string | null => {
  const t = v.trim();
  if (!t) return 'validation:emailRequired';
  return EMAIL.test(t) ? null : 'validation:emailInvalid';
};
export const validatePassword = (v: string): string | null => {
  if (v.length < 10) return 'validation:passwordShort';
  if (!/[a-z]/.test(v) || !/[A-Z]/.test(v) || !/[0-9]/.test(v)) return 'validation:passwordMix';
  return null;
};
export const validatePasswordPresent = (v: string): string | null => (v ? null : 'validation:passwordRequired');
export const validateName = (v: string): string | null => {
  const t = v.trim();
  if (!t) return 'validation:nameRequired';
  return t.length > 120 ? 'validation:nameLong' : null;
};
export const validateTitle = (v: string, max = 120): string | null => {
  const t = v.trim();
  if (!t) return 'validation:titleRequired';
  return t.length > max ? 'validation:titleLong' : null;
};
