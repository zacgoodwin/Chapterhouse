import { createSignal, createEffect, Show } from 'solid-js';

import { Input, Button, Select } from '../components';
import { Google, Discord } from '../assets';
import { useAppState, useAppAlert, useAppLocale } from '../context';
import { writeToCache, readFromCache, localize, supabase, supabaseConfigured } from '../helpers';

const CHARKEEPER_HOST_CACHE_NAME = 'CharKeeperHost';
const TRANSLATION = {
  en: {
    region: 'Server region',
    euRegion: 'EU region',
    ruRegion: 'RU region',
    regionHelp: 'The servers operate independently of each other.',
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
  ru: {
    region: 'Регион сервера',
    euRegion: 'Евро регион',
    ruRegion: 'РУ регион',
    regionHelp: 'Серверы работают независимо от друг друга.',
    signin: 'Вход',
    signup: 'Регистрация',
    email: 'Электронная почта',
    password: 'Пароль',
    haveAccount: 'Уже есть аккаунт?',
    noAccount: 'Еще нет аккаунта?',
    orContinueWith: 'Или войти через',
    confirmEmail: 'Проверьте почту, чтобы подтвердить адрес.',
    notConfigured: 'Supabase не настроен: заполните supabaseConfig.js.'
  },
  es: {
    region: 'Región del servidor',
    euRegion: 'Región EU',
    ruRegion: 'Región RU',
    regionHelp: 'Los servidores funcionan de forma independiente entre sí.',
    signin: 'Iniciar sesión',
    signup: 'Registrarse',
    email: 'Correo electrónico',
    password: 'Contraseña',
    haveAccount: '¿Ya tienes una cuenta?',
    noAccount: '¿No tienes una cuenta?',
    orContinueWith: 'O continuar con',
    confirmEmail: 'Revisa tu correo para confirmar la dirección.',
    notConfigured: 'Supabase no está configurado: completa supabaseConfig.js.'
  }
}

export const LoginPage = () => {
  const [page, setPage] = createSignal('signin');
  const [email, setEmail] = createSignal('');
  const [password, setPassword] = createSignal('');
  const [region, setRegion] = createSignal('charkeeper.org');

  const [, { setAccessToken }] = useAppState();
  const [{ renderAlerts, renderNotice }] = useAppAlert();
  const [locale] = useAppLocale();

  const readRegion = async () => {
    const cacheValue = await readFromCache(CHARKEEPER_HOST_CACHE_NAME);
    if (cacheValue) setRegion(cacheValue);
  }

  createEffect(() => {
    readRegion();
  });

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
        <Show when={window.__TAURI_INTERNALS__}>
          <Select
            containerClassList="mb-1"
            labelText={localize(TRANSLATION, locale()).region}
            items={{
              'charkeeper.org': localize(TRANSLATION, locale()).euRegion,
              'charkeeper.ru': localize(TRANSLATION, locale()).ruRegion,
            }}
            selectedValue={region()}
            onSelect={setRegion}
          />
          <p class="text-sm mb-2">{localize(TRANSLATION, locale()).regionHelp}</p>
        </Show>
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
