'use client'

import { useCallback, useRef, useState } from 'react'

/**
 * One submit at a time, and the same idempotency key for retries of the same operation.
 *
 * Why each piece (reference/QA-PREVENTION.md §2, the most common and most expensive QA
 * finding): a `disabled` button alone is not enough, because a double click lands both
 * events before React re-renders the button; the ref blocks the second one synchronously.
 * And the client guard is not enough either: the key travels to the server, which refuses a
 * key it already processed (unique column or idempotency key on the payment). The key is
 * kept after a failure, so "it failed, retry" cannot create the record twice if the first
 * request did reach the server; it is renewed only after a success.
 *
 *   const guard = useSubmitGuard((key, data: Values) => createOrder({ ...data, key }))
 *   <form onSubmit={form.handleSubmit(guard.run)}>
 *   <Button type="submit" {...guard.buttonProps}>{guard.pending ? 'Enviando…' : 'Enviar'}</Button>
 */
export function useSubmitGuard<A extends unknown[], R>(
  action: (idempotencyKey: string, ...args: A) => Promise<R>,
) {
  const inFlight = useRef(false)
  const key = useRef<string | null>(null)
  const [pending, setPending] = useState(false)

  const run = useCallback(
    async (...args: A): Promise<R | undefined> => {
      if (inFlight.current) return undefined
      inFlight.current = true
      setPending(true)
      key.current ??= crypto.randomUUID()
      try {
        const result = await action(key.current, ...args)
        key.current = null
        return result
      } finally {
        inFlight.current = false
        setPending(false)
      }
    },
    [action],
  )

  return { run, pending, buttonProps: { disabled: pending, 'aria-busy': pending } as const }
}
