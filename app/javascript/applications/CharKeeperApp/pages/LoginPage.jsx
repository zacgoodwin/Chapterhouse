import { createSignal, Show } from 'solid-js';

import { Input, Button } from '../components';
import { Google, Discord } from '../assets';
import { useAppState, useAppAlert, useAppLocale } from '../context';
import { writeToCache, localize, supabase, supabaseConfigured } from '../helpers';

const CHARKEEPER_HOST_CACHE_NAME = 'CharKeeperHost';
const TRANSLATION = {
  en: {
    signin: 'Sign in',
    signup: 'Sign up',
    email: 'Email',
    password: 'Password',
    haveAccount: 'Already have account?',
    noAccount: "Don't have account?",
    orContinueWith: 'Or continue with',
    confirmEmail: 'Check your inbox to confirm the email address.',
    notConfigured: 'Supabase is not configured: fill supabaseConfig.js.'
  },
}

export const LoginPage = () => {
  const [page, setPage] = createSignal('signin');
  const [email, setEmail] = createSignal('');
  const [password, setPassword] = createSignal('');
  // Tauri desktop builds cache the API host; the RU/EU region picker is gone,
  // so the host is fixed to the single remaining server.
  const [region] = createSignal('charkeeper.org');

  const [, { setAccessToken }] = useAppState();
  const [{ renderAlerts, renderNotice }] = useAppAlert();
  const [locale] = useAppLocale();

  const guardConfigured = () => {
    if (supabaseConfigured()) return true;

    renderAlerts([localize(TRANSLATION, locale()).notConfigured]);
    return false;
  }

  const rememberRegion = () => {
    if (window.__TAURI_INTERNALS__) writeToCache(CHARKEEPER_HOST_CACHE_NAME, region());
  }

  const signIn = async () => {
    if (!guardConfigured()) return;
    rememberRegion();

    const { data, error } = await supabase().auth.signInWithPassword({ email: email(), password: password() });
    if (error) return renderAlerts([error.message]);

    // onAuthStateChange updates appState; set directly for immediate render
    setAccessToken(data.session.access_token);
  }

  const signUp = async () => {
    if (!guardConfigured()) return;
    rememberRegion();

    const { data, error } = await supabase().auth.signUp({ email: email(), password: password() });
    if (error) return renderAlerts([error.message]);

    // session is null when email confirmations are enabled in the project
    if (data.session) setAccessToken(data.session.access_token);
    else renderNotice(localize(TRANSLATION, locale()).confirmEmail);
  }

  const signInWithProvider = async (provider) => {
    if (!guardConfigured()) return;

    const { error } = await supabase().auth.signInWithOAuth({
      provider: provider,
      options: { redirectTo: `${window.location.origin}/dashboard` }
    });
    if (error) renderAlerts([error.message]);
  }

  return (
    <div class="min-h-screen flex flex-col justify-center items-center">
      <div class="max-w-sm w-full p-4">
        <h2 class="text-2xl mb-4">{localize(TRANSLATION, locale())[page()]}</h2>
        <Input
          containerClassList="form-field mb-2"
          labelText={localize(TRANSLATION, locale()).email}
          value={email()}
          onInput={setEmail}
        />
        <Input
          password
          containerClassList="form-field mb-2"
          labelText={localize(TRANSLATION, locale()).password}
          value={password()}
          onInput={setPassword}
        />
        <Show
          when={page() === 'signin'}
          fallback={
            <p>
              {localize(TRANSLATION, locale()).haveAccount}
              <span class="ml-4 underline text-blue-600 cursor-pointer" onClick={() => setPage('signin')}>
                {localize(TRANSLATION, locale()).signin}
              </span>
            </p>
          }
        >
          <p>
            {localize(TRANSLATION, locale()).noAccount}
            <span class="ml-4 underline text-blue-600 cursor-pointer" onClick={() => setPage('signup')}>
              {localize(TRANSLATION, locale()).signup}
            </span>
          </p>
        </Show>
        <Button default textable classList="mt-2" onClick={page() === 'signin' ? signIn : signUp}>
          {localize(TRANSLATION, locale())[page()]}
        </Button>
        <Show when={!window.__TAURI_INTERNALS__}>
          <p class="mt-4 mb-2 text-sm">{localize(TRANSLATION, locale()).orContinueWith}</p>
          <div class="flex gap-4">
            <span class="cursor-pointer opacity-75 hover:opacity-100" onClick={() => signInWithProvider('google')}>
              <Google />
            </span>
            <span class="cursor-pointer opacity-75 hover:opacity-100" onClick={() => signInWithProvider('discord')}>
              <Discord />
            </span>
          </div>
        </Show>
      </div>
    </div>
  );
}
