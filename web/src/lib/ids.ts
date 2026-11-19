/** One id per user action; reuse it on retry so the server replays instead of repeating. */
export const newRequestId = (): string => crypto.randomUUID();
