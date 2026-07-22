// tlc is a dnd2024 derivative (tlc.json declares `"base": "dnd2024"`), so every
// dnd2024 branch in the sheet applies to it unless the branch is genuinely
// 2024-only. Exact `provider === 'dnd2024'` checks silently drop tlc to the
// dnd5 side, which is why they route through here instead.
export const isDnd2024Family = (provider) => ['dnd2024', 'tlc'].includes(provider);
