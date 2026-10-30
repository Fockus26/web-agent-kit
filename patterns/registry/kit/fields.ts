import { z } from 'zod'

// Field schemas for forms, shared by client and server. Every rule here is a defect QA kept
// finding (reference/QA-PREVENTION.md §1): "only spaces" passing as filled, " ana@x.com"
// duplicating an account, a two-digit year saved as 1926, strings longer than the column.
// Messages in Spanish: the kit's sites are. Change the copy, not the rules.

/** Required text: trimmed BEFORE it is checked, and the trimmed value is the one saved. */
export const text = (max: number, required = 'Este campo es obligatorio') =>
  z.string().trim().min(1, required).max(max, `Máximo ${max} caracteres`)

/** Optional text: '' and spaces become undefined, so the database gets NULL, not ''. */
export const optionalText = (max: number) =>
  z
    .string()
    .trim()
    .max(max, `Máximo ${max} caracteres`)
    .optional()
    .transform((v) => (v ? v : undefined))

/** Email: trimmed and lowercased before the format check and the uniqueness check. */
export const email = (invalid = 'Escribe un correo válido') =>
  z.string().trim().toLowerCase().max(254, 'Correo demasiado largo').pipe(z.email(invalid))

/**
 * Password: NEVER trimmed (a space is a valid character the user typed on purpose).
 * 8 minimum and a high maximum: length protects more than composition rules (NIST 800-63B).
 */
export const password = (min = 8) =>
  z
    .string()
    .min(min, `Mínimo ${min} caracteres`)
    .max(128, 'Máximo 128 caracteres')

/** Four-digit year within a real range. Never `new Date(<free text>)`. */
export const year = (from = 1900, aheadYears = 0) =>
  z.coerce
    .number<string | number>()
    .int('Escribe un año válido')
    .min(from, `Escribe el año con 4 cifras (desde ${from})`)
    .max(new Date().getFullYear() + aheadYears, 'Ese año aún no llegó')

/** Whole positive quantity with a real ceiling (no 0, no -1, no 1e10). */
export const quantity = (max: number) =>
  z.coerce
    .number<string | number>()
    .int('Solo números enteros')
    .positive('Debe ser mayor que 0')
    .max(max, `Máximo ${max}`)
