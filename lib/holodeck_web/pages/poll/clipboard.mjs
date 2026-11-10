// Resolve native rejections before Hologram converts the promise to an Elixir Task.
export async function copyVoteLink(url) {
  try {
    if (!globalThis.navigator?.clipboard?.writeText) return false;
    await navigator.clipboard.writeText(url);
    return true;
  } catch {
    return false;
  }
}
