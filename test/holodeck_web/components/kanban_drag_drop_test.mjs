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
  const old = Object.fromEntries(["document", "window", "MutationObserver", "Hologram", "Element"].map(k => [k, globalThis[k]]));
  let windowFocus;
  let signal;
  globalThis.Element = class Element {};
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
      target: Object.assign(new Element(), { closest: selector => selector === "[data-card-id]" ? card : column }),
      preventDefault: () => { prevented++; },
      dataTransfer: {
        types: ["application/x-holodeck-card"],
        setData: (type, value) => { assert.equal(type, "application/x-holodeck-card"); payload = value; },
        getData: () => payload,
      },
    };
    handlers.dragstart(event);
    assert.deepEqual(JSON.parse(payload), { card_id: id, expected_version: 1 });
    assert.equal(card.dataset.dragging, "");
    handlers.dragover(event);
    assert.equal(prevented, 1);
    assert.equal(column.dataset.dropTarget, "");
    // Moving onto a child of the highlighted column keeps the highlight; leaving clears it.
    column.contains = node => node === "child";
    handlers.dragleave({ relatedTarget: "child" });
    assert.equal(column.dataset.dropTarget, "");
    handlers.dragleave({ relatedTarget: null });
    assert.equal("dropTarget" in column.dataset, false);
    handlers.dragover(event);
    assert.equal(column.dataset.dropTarget, "");
    column.dataset.column = "done";
    handlers.drop(event);
    assert.equal("dropTarget" in column.dataset, false);
    assert.equal("dragging" in card.dataset, false);
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
    handlers.click({ detail: 0, target: Object.assign(new Element(), { closest: () => ({ dataset: { moveCard: id }, closest: () => column }) }) });
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

test("dragging hands the browser a tilted copy of the card, grabbed at the same point", async () => {
  const handlers = {};
  const appended = [];
  let dragImage;
  const strippedIds = [];
  const makeElement = () => ({
    style: {},
    children: [],
    attributes: {},
    setAttribute(name, value) { this.attributes[name] = value; },
    appendChild(child) { this.children.push(child); },
    remove() { this.removed = true; },
  });
  const clone = {
    style: {},
    removeAttribute: name => strippedIds.push(["clone", name]),
    querySelectorAll: () => [{ removeAttribute: name => strippedIds.push(["child", name]) }],
  };
  const card = {
    dataset: { cardId: "00000000-0000-4000-8000-000000000001", version: "1" },
    getAttribute: () => "true",
    getBoundingClientRect: () => ({ left: 100, top: 50, width: 240 }),
    cloneNode: deep => { assert.equal(deep, true); return clone; },
  };
  const root = {
    isConnected: true,
    getAttribute: () => "false",
    addEventListener: (name, fn) => { handlers[name] = fn; },
  };
  const old = Object.fromEntries(["document", "window", "MutationObserver", "Hologram", "Element"].map(k => [k, globalThis[k]]));
  globalThis.Element = class Element {};
  globalThis.document = {
    body: { appendChild: node => appended.push(node) },
    getElementById: () => root,
    createElement: tag => { assert.equal(tag, "div"); return makeElement(); },
  };
  globalThis.window = { addEventListener() {} };
  globalThis.MutationObserver = class { observe() {} disconnect() {} };
  globalThis.Hologram = { dispatchAction() {} };
  try {
    install("tilt-root", "kanban-board");
    handlers.dragstart({
      target: Object.assign(new Element(), { closest: () => card }),
      clientX: 130,
      clientY: 70,
      preventDefault: () => assert.fail("a valid drag must not be cancelled"),
      dataTransfer: {
        setData() {},
        setDragImage: (element, x, y) => { dragImage = { element, x, y }; },
      },
    });

    const [wrapper] = appended;
    assert.equal(wrapper.className, "hd-kanban-drag-image");
    assert.equal(wrapper.attributes["aria-hidden"], "true");
    assert.deepEqual(wrapper.children, [clone]);
    assert.equal(clone.style.width, "240px");
    // Copied ids would duplicate the live card's, so they are all stripped.
    assert.deepEqual(strippedIds, [["clone", "id"], ["child", "id"]]);
    // 30px/20px into the card, plus the wrapper's 24px padding.
    assert.deepEqual(dragImage, { element: wrapper, x: 54, y: 44 });
    assert.equal(card.dataset.dragging, "");

    await new Promise(resolve => setTimeout(resolve, 0));
    assert.equal(wrapper.removed, true);
  } finally {
    for (const [key, value] of Object.entries(old)) {
      if (value === undefined) delete globalThis[key];
      else globalThis[key] = value;
    }
  }
});
