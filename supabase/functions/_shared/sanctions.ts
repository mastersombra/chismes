/**
 * Sanciones al usuario (015_sanctions.sql): consulta del estado y bloqueo.
 *
 * Lo usan moderate-gossip y report-gossip (bloquean si hay restricción o
 * suspensión) y account-status (muestra el estado). Antes de leer el estado
 * revisa si el usuario es reincidente (claim_inherited_strikes): la huella
 * del email se calcula aquí porque la base no tiene ACCOUNT_HASH_SECRET.
 *
 * Tests: sanctions.test.ts
 */
import { emailHash } from './email_hash.ts'

export type SanctionState = 'ok' | 'restricted' | 'suspended'

export interface SanctionStatus {
  state: SanctionState
  restricted_until: string | null
  active_points: number
  strike_count: number
  expiry_days: number
  thresholds: { restriction_short: number; restriction_long: number; suspension: number }
}

/** Lo mínimo del cliente admin que se usa (permite probar sin red) */
export interface RpcClient {
  // deno-lint-ignore no-explicit-any
  rpc: (fn: string, args: Record<string, unknown>) => PromiseLike<{ data: any; error: any }>
}

export const RESTRICTED_ERROR_CODE = 'account_restricted'

/**
 * Revisa faltas heredadas (si hay secret y email) y devuelve el estado.
 * null si no se pudo leer el estado: quien llama decide (fail-closed).
 * Un fallo al revisar las heredadas NO bloquea: se reintenta en la próxima
 * llamada (claim_inherited_strikes es idempotente).
 */
export async function loadSanctionStatus(
  supabaseAdmin: RpcClient,
  user: { id: string; email?: string | null },
  hashSecret: string | null | undefined,
): Promise<SanctionStatus | null> {
  if (hashSecret) {
    try {
      const hash = await emailHash(user.email, hashSecret)
      if (hash) {
        const { error } = await supabaseAdmin.rpc('claim_inherited_strikes', {
          p_user_id: user.id,
          p_email_hash: hash,
        })
        if (error) console.error('⚠️ claim_inherited_strikes failed:', error.message ?? error)
      }
    } catch (claimError) {
      console.error('⚠️ claim_inherited_strikes failed:', claimError)
    }
  } else {
    console.warn('⚠️ ACCOUNT_HASH_SECRET not configured: inherited strikes not checked')
  }

  const { data, error } = await supabaseAdmin.rpc('get_user_sanction_status', { p_user_id: user.id })
  if (error || !isSanctionStatus(data)) {
    console.error('❌ get_user_sanction_status failed:', error?.message ?? 'invalid response')
    return null
  }
  return data
}

export function isBlocked(status: SanctionStatus): boolean {
  return status.state === 'restricted' || status.state === 'suspended'
}

/** Cuerpo del 403 cuando la cuenta no puede publicar ni reportar */
export function restrictedResponseBody(status: SanctionStatus) {
  return {
    error: 'Account restricted',
    code: RESTRICTED_ERROR_CODE,
    state: status.state,
    restricted_until: status.restricted_until,
  }
}

function isSanctionStatus(value: unknown): value is SanctionStatus {
  if (typeof value !== 'object' || value === null) return false
  const v = value as Record<string, unknown>
  return (v.state === 'ok' || v.state === 'restricted' || v.state === 'suspended') &&
    typeof v.active_points === 'number'
}
