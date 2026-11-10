import test from "node:test";
import assert from "node:assert/strict";
import { absoluteVoteUrl, copyVoteLink } from "../../../../lib/holodeck_web/pages/poll/clipboard.mjs";

test("clipboard handles success, native rejection, and unavailable API", async () => {
  const original = Object.getOwnPropertyDescriptor(globalThis, "navigator");
  const originalLocation = Object.getOwnPropertyDescriptor(globalThis, "location");
  try {
    Object.defineProperty(globalThis, "location", {
      configurable: true,
      value: { origin: "http://localhost:4043" },
    });
    assert.equal(absoluteVoteUrl("/poll/1/vote"), "http://localhost:4043/poll/1/vote");
    let copied;
    Object.defineProperty(globalThis, "navigator", {
      configurable: true,
      value: { clipboard: { writeText: async (url) => { copied = url; } } },
    });
    assert.equal(await copyVoteLink("/poll/1/vote"), true);
    assert.equal(copied, "http://localhost:4043/poll/1/vote");
    assert.equal(await copyVoteLink("https://example.test/poll/1/vote"), true);
    assert.equal(copied, "https://example.test/poll/1/vote");
    globalThis.location.origin = "http://192.168.1.25:4043";
    assert.equal(await copyVoteLink("/poll/1/vote"), true);
    assert.equal(copied, "http://192.168.1.25:4043/poll/1/vote");

    navigator.clipboard.writeText = () => Promise.reject(new DOMException("Denied", "NotAllowedError"));
    assert.equal(await copyVoteLink("https://example.test/poll/1/vote"), false);

    delete navigator.clipboard;
    assert.equal(await copyVoteLink("https://example.test/poll/1/vote"), false);
  } finally {
    if (originalLocation) Object.defineProperty(globalThis, "location", originalLocation);
    else delete globalThis.location;
    if (original) Object.defineProperty(globalThis, "navigator", original);
    else delete globalThis.navigator;
  }
});
