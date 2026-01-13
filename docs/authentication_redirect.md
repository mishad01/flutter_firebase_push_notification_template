# Authentication Redirect Implementation

This implementation provides an authentication guard system that automatically redirects unauthenticated users to the login page and then redirects them to their originally intended destination after successful authentication.

## How It Works

### 1. AuthGuard Class (`auth_guard.dart`)
- `requiresAuth(String path)`: Determines if a route requires authentication
- `loginWithRedirect(String intendedDestination)`: Creates a login URL with redirect parameters
- `getRedirectDestination(GoRouterState state)`: Extracts redirect destination from login page state

### 2. Router Configuration (`router.dart`)
The main router includes an authentication guard in its redirect function:
- Checks if the requested route requires authentication
- If user is not logged in, redirects to login with the intended destination as a query parameter
- Public routes (splash, onboarding, login, registration, etc.) are accessible without authentication

### 3. Login Page Enhancement (`login_page.dart`)
After successful login:
- Checks for redirect destination from query parameters
- Redirects user to their originally intended destination
- Falls back to home page if no redirect destination is specified

## Usage Example

1. **User tries to access `/settings` while logged out**
2. **Router redirect function detects:**
   - `/settings` requires authentication
   - User is not logged in
3. **User is redirected to:** `/login?redirectTo=/settings`
4. **User logs in successfully**
5. **Login success handler:**
   - Extracts `redirectTo=/settings` from URL
   - Redirects user to `/settings`

## Protected Routes

By default, all routes require authentication except:
- `/` (initial)
- `/splash`
- `/onboarding` 
- `/login` and all its child routes (registration, reset password, etc.)

## Testing the Implementation

1. **Start the app and log in**
2. **Navigate to Home page and click "Go to Settings (Protected)"**
3. **Log out from the settings or home page**
4. **Try to access `/settings` directly in the browser/URL**
5. **You should be redirected to login**
6. **After logging in, you should be automatically redirected to `/settings`**

## Configuration

To make a route public (not require authentication), add it to the `publicRoutes` list in `AuthGuard.requiresAuth()` method.

To add new protected routes, simply add them to the router - they will automatically be protected by the authentication guard.
