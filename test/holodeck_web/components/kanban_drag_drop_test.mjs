import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

// The colocated .js is bundled as ESM by Hologram (the repo has no Node package type).
const source = await readFile(new URL("../../../lib/holodeck_web/components/kanban/drag_drop.js", import.meta.url), "utf8");
const { install } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);

test("delegated DnD dispatches validated moves, focus syncs, installation and cleanup are idempotent", () => {
  const handlers = {};
  const calls = [];
  const observers = [];
  let busy = false;
  let focused = false;
  const column = { dataset: { column: "todo" } };
  const id = "00000000-0000-4000-8000-000000000001";
  const card = {
    dataset: { cardId: id, version: "1" },
    getAttribute: () => "true",
    closest: () => column,
    focus: () => { focused = true; },
  };
  const root = {
    isConnected: true,
    getAttribute: () => String(busy),
    addEventListener: (name, fn) => { assert.equal(handlers[name], undefined); handlers[name] = fn; },
  };
  const old = Object.fromEntries(["document", "window", "MutationObserver", "Hologram"].map(k => [k, globalThis[k]]));
  let windowFocus;
  let signal;
  globalThis.document = { body: {}, getElementById: key => key === "root" ? root : card };
  globalThis.window = { addEventListener: (_, fn, options) => { windowFocus = fn; signal = options.signal; } };
  globalThis.MutationObserver = class {
    constructor(fn) { this.fn = fn; observers.push(this); }
    observe() {}
    disconnect() { this.disconnected = true; }
  };
  globalThis.Hologram = { dispatchAction: (...args) => calls.push(args) };
  try {
    install("root", "kanban-board");
    install("root", "kanban-board");
    assert.equal(observers.length, 2);
    let payload;
    let prevented = 0;
    const event = {
      target: { closest: selector => selector === "[data-card-id]" ? card : column },
      preventDefault: () => { prevented++; },
      dataTransfer: {
        types: ["application/x-holodeck-card"],
        setData: (type, value) => { assert.equal(type, "application/x-holodeck-card"); payload = value; },
        getData: () => payload,
      },
    };
    handlers.dragstart(event);
    assert.deepEqual(JSON.parse(payload), { card_id: id, expected_version: 1 });
    handlers.dragover(event);
    assert.equal(prevented, 1);
    column.dataset.column = "done";
    handlers.drop(event);
    assert.deepEqual(calls.pop(), ["request_move", "kanban-board", { card_id: id, expected_version: 1, destination: "done" }]);
    for (const invalid of ["{", "null", "{}", JSON.stringify({ card_id: id, expected_version: -1 })]) {
      payload = invalid;
      handlers.drop(event);
    }
    assert.equal(calls.length, 0);
    busy = true;
    handlers.dragstart(event);
    handlers.drop(event);
    assert.equal(calls.length, 0);
    busy = false;
    windowFocus();
    assert.deepEqual(calls.pop(), ["sync", "kanban-board", {}]);

    column.dataset.column = "todo";
    handlers.click({ detail: 0, target: { closest: () => ({ dataset: { moveCard: id }, closest: () => column }) } });
    column.dataset.column = "done";
    observers[0].fn();
    assert.equal(focused, true);
    root.isConnected = false;
    observers[1].fn();
    assert.equal(signal.aborted, true);
    assert.ok(observers.every(observer => observer.disconnected));
    windowFocus();
    assert.equal(calls.length, 0);
  } finally {
    for (const [key, value] of Object.entries(old)) {
      if (value === undefined) delete globalThis[key];
      else globalThis[key] = value;
    }
  }
});
