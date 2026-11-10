import test from "node:test";
import assert from "node:assert/strict";
import { copyVoteLink } from "../../../../lib/holodeck_web/pages/poll/clipboard.mjs";

test("clipboard handles success, native rejection, and unavailable API", async () => {
  const original = Object.getOwnPropertyDescriptor(globalThis, "navigator");
  try {
    let copied;
    Object.defineProperty(globalThis, "navigator", {
      configurable: true,
      value: { clipboard: { writeText: async (url) => { copied = url; } } },
    });
    assert.equal(await copyVoteLink("https://example.test/poll/1/vote"), true);
    assert.equal(copied, "https://example.test/poll/1/vote");

    navigator.clipboard.writeText = () => Promise.reject(new DOMException("Denied", "NotAllowedError"));
    assert.equal(await copyVoteLink("https://example.test/poll/1/vote"), false);

    delete navigator.clipboard;
    assert.equal(await copyVoteLink("https://example.test/poll/1/vote"), false);
  } finally {
    if (original) Object.defineProperty(globalThis, "navigator", original);
    else delete globalThis.navigator;
  }
});
