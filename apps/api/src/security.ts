import { createCipheriv, createDecipheriv, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import argon2 from 'argon2';
import { authenticator } from 'otplib';

const pepper = (version=process.env.PEPPER_VERSION??'v1') => { const current=process.env.PEPPER_VERSION??'v1';const value=version===current?process.env.PASSWORD_PEPPER:version===process.env.PREVIOUS_PEPPER_VERSION?process.env.PREVIOUS_PASSWORD_PEPPER:undefined;if(!value||Buffer.byteLength(value)<32)throw new Error(`Password pepper version ${version} is not configured`);return value; };
const peppered = (password: string,version?:string) => createHmac('sha256', pepper(version)).update('learnnest-password-v1\0').update(password, 'utf8').digest();
export async function hashPassword(password: string) {
  const salt = randomBytes(16);
  const hash = await argon2.hash(peppered(password), { type: argon2.argon2id, salt, memoryCost: 19456, timeCost: 2, parallelism: 1, hashLength: 32 });
  return { hash, salt: salt.toString('base64'), algorithm: 'argon2id', parameters: { memoryCost: 19456, timeCost: 2, parallelism: 1, hashLength: 32 }, schemeVersion: 1, pepperVersion: process.env.PEPPER_VERSION ?? 'v1' };
}
export async function verifyPassword(password: string, hash: string,pepperVersion?:string) { try { return await argon2.verify(hash, peppered(password,pepperVersion)); } catch { return false; } }
export const needsPasswordRehash=(hash:string)=>argon2.needsRehash(hash,{memoryCost:19456,timeCost:2,parallelism:1});
export const randomToken = (bytes = 32) => randomBytes(bytes).toString('base64url');
export const digestToken = (token: string) => createHmac('sha256', pepper()).update('learnnest-token-v1\0').update(token).digest('hex');
export const constantTimeTextEqual = (left: string, right: string) => { const a = Buffer.from(left); const b = Buffer.from(right); return a.length === b.length && timingSafeEqual(a,b); };
export const newTotpSecret = () => authenticator.generateSecret();
export const totpUri = (secret: string, email: string) => authenticator.keyuri(email, 'LearnNest', secret);
export const verifyTotp = (token: string, secret: string) => { authenticator.options = { window: 1 }; return authenticator.checkDelta(token, secret); };
export const recoveryCodeHash = (code: string,version?:string) => createHmac('sha256', pepper(version)).update('learnnest-recovery-v1\0').update(code.toUpperCase()).digest('hex');
function encryptionKey(){const value=process.env.TOTP_ENCRYPTION_KEY;if(!value||Buffer.from(value,'base64').length!==32)throw new Error('TOTP_ENCRYPTION_KEY must be a base64 encoded 32 byte key');return Buffer.from(value,'base64')}
export function encryptSecret(value:string){const iv=randomBytes(12);const cipher=createCipheriv('aes-256-gcm',encryptionKey(),iv);const ciphertext=Buffer.concat([cipher.update(value,'utf8'),cipher.final()]);return [iv.toString('base64'),cipher.getAuthTag().toString('base64'),ciphertext.toString('base64')].join('.')}
export function decryptSecret(value:string){const [iv,tag,ciphertext]=value.split('.');const decipher=createDecipheriv('aes-256-gcm',encryptionKey(),Buffer.from(iv!,'base64'));decipher.setAuthTag(Buffer.from(tag!,'base64'));return Buffer.concat([decipher.update(Buffer.from(ciphertext!,'base64')),decipher.final()]).toString('utf8')}
