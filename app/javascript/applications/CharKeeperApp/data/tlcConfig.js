import dnd2024Config from './dnd2024.json' with { type: 'json' };
import tlcDelta from './tlc.json' with { type: 'json' };

// Client-side mirror of PlatformConfig#load_data (app/lib/platform_config.rb).
// The SPA imports provider JSON statically, so the server's merge never reaches
// it: anything that renders a tlc character has to merge here instead.
//
// Same semantics as the server: the delta's values win, nested plain objects
// combine key-by-key, arrays and scalars replace wholesale, `base` is dropped.
// Unlike the server it cannot follow a `base` chain -- esbuild resolves imports
// statically -- so the base is asserted below instead of read.
const isPlainObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);

const deepMerge = (base, delta) => {
  const result = { ...base };
  for (const [key, value] of Object.entries(delta)) {
    result[key] = isPlainObject(value) && isPlainObject(base[key]) ? deepMerge(base[key], value) : value;
  }
  return result;
};

const { base, ...delta } = tlcDelta;
if (base !== 'dnd2024') {
  throw new Error(`tlc.json declares base "${base}"; tlcConfig.js only imports dnd2024.json`);
}

// ponytail: merge can add and override but never remove, so tlcConfig.species
// still carries the dnd2024-only species (halfling, dragonborn, tiefling,
// aasimar, goliath) that TLC does not use. Fine while nothing lists species
// from config; A5b's creation form needs an explicit TLC species list.
export const tlcConfig = deepMerge(dnd2024Config, delta);

// The dnd-family config object for a provider. tlc characters must read the
// merged config; dnd5/dnd2024 keep their own JSON.
export const dndConfigFor = (provider) => (provider === 'tlc' ? tlcConfig : dnd2024Config);

// Species a character can be rendered from: the provider's own config first,
// user homebrew races on top. Callers must pass homebrew races ALONE -- pass a
// dnd2024-config-plus-homebrew blob for a tlc character and dnd2024's base
// species clobber every slug tlc redefines.
export const speciesFor = (provider, homebrewRaces = {}) => ({ ...dndConfigFor(provider).species, ...homebrewRaces });
