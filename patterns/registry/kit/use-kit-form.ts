'use client'

import { zodResolver } from '@hookform/resolvers/zod'
import { type FieldValues, type Resolver, type UseFormProps, useForm } from 'react-hook-form'
import type { z } from 'zod'

/**
 * The two validation modes every site uses, so no form decides it again:
 *
 * - `submit` (default): nothing is red until the first submit; from then on each field
 *   re-checks as it changes, so a fixed error disappears at once. Short forms (contact,
 *   login), where errors while typing feel like scolding.
 * - `live`: checks while typing, but an error waits `delay` ms after the last keystroke
 *   before it shows (a correction clears it immediately). Long forms or fields with a
 *   format (sign-up, password with rules, checkout), where finding out at the end costs.
 */
export type ValidationMode = 'submit' | 'live'

type Options<S extends z.ZodType<FieldValues, FieldValues>> = Omit<
  UseFormProps<z.input<S>, unknown, z.output<S>>,
  'resolver' | 'mode' | 'reValidateMode' | 'delayError'
> & { validation?: ValidationMode; delay?: number }

export function useKitForm<S extends z.ZodType<FieldValues, FieldValues>>(
  schema: S,
  { validation = 'submit', delay = 600, ...options }: Options<S> = {},
) {
  return useForm<z.input<S>, unknown, z.output<S>>({
    // The cast only narrows zodResolver's generic return to this schema's input/output: with a
    // generic S, TypeScript cannot infer it (react-hook-form/resolvers, zod 4 overloads).
    resolver: zodResolver(schema) as unknown as Resolver<z.input<S>, unknown, z.output<S>>,
    ...(validation === 'live'
      ? { mode: 'onChange', reValidateMode: 'onChange', delayError: delay }
      : { mode: 'onSubmit', reValidateMode: 'onChange' }),
    shouldFocusError: true, // the first invalid field gets focus: keyboard and screen readers land on it
    ...options,
  })
}
