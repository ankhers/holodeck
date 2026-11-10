export function absoluteVoteUrl(url) {
  return new URL(url, globalThis.location.origin).href;
}

// Resolve native rejections before Hologram converts the promise to an Elixir Task.
export async function copyVoteLink(url) {
  try {
    if (!globalThis.navigator?.clipboard?.writeText) return false;
    await navigator.clipboard.writeText(absoluteVoteUrl(url));
    return true;
  } catch {
    return false;
  }
}
