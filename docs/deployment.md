# Deployment and mobile builds

## Web (Vercel)

Create a Vercel project with root directory `apps/web`, framework preset Vite, build command `npm run build --workspace @learnnest/shared && npm run build --workspace @learnnest/web`, and output directory `apps/web/dist`. The monorepo root must be used for dependency installation. Set `VITE_API_URL` to the public API URL. Configure SPA fallback to `index.html`, exact production `WEB_ORIGIN` on the API, and HTTPS.

## Render (web + API)

The root `render.yaml` is a Blueprint for both services. Push the repository to GitHub, then in Render choose **New → Blueprint**, connect the repository, and let Render read `render.yaml`. The API service builds and starts the Express workspace and checks `/api/health`; the static site builds the Vite workspace and publishes `apps/web/dist`.

Before the first deploy, apply the Supabase migration and set the API secrets in Render. The Blueprint asks for `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `PASSWORD_PEPPER`, `TOTP_ENCRYPTION_KEY`, `BACKUP_ENCRYPTION_KEY`, `WEB_ORIGIN`, and SMTP settings. Set `WEB_ORIGIN` to the static site's exact `https://<site>.onrender.com` origin. Set the static site's `VITE_API_URL` to the API's exact `https://<service>.onrender.com/api` URL. If Render assigns different service URLs than expected during Blueprint creation, update both values in each service's Environment page and redeploy the static site after changing `VITE_API_URL`. The two origins must match exactly for browser cookies and CORS.

Keep the Supabase service-role key and encryption keys only in Render's secret environment settings; never commit them. SMTP is required for production invitations and password-reset email. Review the selected Render plan and its current cost before creating paid resources.

## Supabase

Create a managed project, apply the SQL migration, configure a private backup bucket and review RLS. Store the service-role key only in the API host. Enable managed backups/PITR and set a retention window. The project migration must be applied before the API starts. Generate 1,000 activity rows with `npm run seed:activities`, then upload from a trusted environment with `npm run seed:cloud-activities`.

## Expo native app

Install Expo tooling, configure `EXPO_PUBLIC_API_URL` to the HTTPS API origin, then from `apps/mobile` run `npx expo start`. For a real build, create an EAS project (`npx eas-cli@latest init`), replace `SET_AFTER_EAS_PROJECT_CREATE` in `app.json` with the returned project ID, then run `npx eas-cli@latest build --platform android` and `npx eas-cli@latest build --platform ios`. EAS manages signing credentials when configured. Android emulator API host is typically `http://10.0.2.2:4000/api`; a physical device needs a reachable LAN HTTPS/dev-tunnel URL. Production must use HTTPS. This is a native React Native application, not a WebView.

## Not deployed

No Supabase project, hosting account, domain, SMTP service, EAS project, or signing credentials were supplied or configured. This repository includes deployment configuration guidance, not a claimed deployment.
