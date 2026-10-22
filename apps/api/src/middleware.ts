import type {Request,Response,NextFunction} from 'express';
import {db} from './db.js';
import {digestToken} from './security.js';
import type {Role} from '@learnnest/shared';
declare global { namespace Express { interface Request { user?:{id:string;email:string;name:string;role:Role;schoolScope:string|null;twoFactorEnabled:boolean;sessionId:string;reauthenticatedAt:string|null}; requestId?:string } } }
export async function requireAuth(req:Request,res:Response,next:NextFunction){
 try {
  const token=req.cookies?.ln_session ?? req.get('authorization')?.replace(/^Bearer\s+/i,'');
  if(!token) return res.status(401).json({error:'Sign in required'});
  const {data:session}=await db().from('sessions').select('id,user_id,expires_at,revoked_at,reauthenticated_at').eq('token_hash',digestToken(token)).maybeSingle();
  if(!session || session.revoked_at || new Date(session.expires_at)<new Date()) return res.status(401).json({error:'Session expired'});
  const {data:user}=await db().from('users').select('id,email,full_name,status,school_scope,deleted_at').eq('id',session.user_id).maybeSingle();
  if(!user || user.status!=='active' || user.deleted_at) return res.status(401).json({error:'Account unavailable'});
  const {data:roles}=await db().from('user_roles').select('roles(code)').eq('user_id',user.id).limit(1);
  const role=(roles?.[0] as any)?.roles?.code as Role|undefined;
  if(!role) return res.status(403).json({error:'No role assigned'});
  const {data:security}=await db().from('user_security').select('two_factor_enabled').eq('user_id',user.id).maybeSingle();
  req.user={id:user.id,email:user.email,name:user.full_name,role,schoolScope:user.school_scope??null,twoFactorEnabled:!!security?.two_factor_enabled,sessionId:session.id,reauthenticatedAt:session.reauthenticated_at};
  next();
 }catch(error){next(error)}
}
export const allowRoles=(...roles:Role[]) => (req:Request,res:Response,next:NextFunction) => { if(!req.user || !roles.includes(req.user.role)) return res.status(403).json({error:'You do not have permission for this action'}); next(); };
export function requireRecentMfa(req:Request,res:Response,next:NextFunction){ const stamp=req.user?.reauthenticatedAt; if(!req.user?.twoFactorEnabled || !stamp || Date.now()-new Date(stamp).getTime()>10*60_000) return res.status(403).json({error:'Recent two-factor verification is required'}); next(); }
