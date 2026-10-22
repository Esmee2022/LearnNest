import { randomUUID } from 'node:crypto';
import { db } from './db.js';
type Event = { eventType:string; actorId?:string|null; targetId?:string|null; outcome:'success'|'failure'|'denied'; reason?:string; metadata?:Record<string,unknown>; requestId?:string };
export async function audit(event: Event) {
  const row = { id:randomUUID(), event_type:event.eventType, actor_user_id:event.actorId ?? null, target_resource_id:event.targetId ?? null, outcome:event.outcome, reason:event.reason ?? null, metadata:event.metadata ?? {}, request_id:event.requestId ?? null, created_at:new Date().toISOString() };
  const {error}=await db().from('audit_logs').insert({...row,previous_hash:'PENDING',entry_hash:'PENDING'});
  if(error) throw new Error(`Audit append failed: ${error.message}`);
}
