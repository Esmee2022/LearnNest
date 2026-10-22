declare module 'cookie-parser' {
  import type { RequestHandler } from 'express';
  const cookieParser: () => RequestHandler;
  export default cookieParser;
}
