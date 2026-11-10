const installed = new WeakSet();
const cardType = "application/x-holodeck-card";
const columns = new Set(["todo", "doing", "done"]);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function install(rootId, boardCid) {
  const root = document.getElementById(rootId);
  if (!root || installed.has(root)) return;
  installed.add(root);

  const busy = () => root.getAttribute("aria-busy") === "true";
  const dispatch = (name, params = {}) => {
    if (root.isConnected) globalThis.Hologram.dispatchAction(name, boardCid, params);
  };

  root.addEventListener("dragstart", (event) => {
    const card = event.target.closest("[data-card-id]");
    if (!card || busy() || card.getAttribute("draggable") !== "true") {
      event.preventDefault();
      return;
    }
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData(cardType, JSON.stringify({
      card_id: card.dataset.cardId,
      expected_version: Number(card.dataset.version),
    }));
  });

  root.addEventListener("dragover", (event) => {
    const column = event.target.closest("[data-column]");
    if (!busy() && column && columns.has(column.dataset.column) &&
        Array.from(event.dataTransfer.types).includes(cardType)) {
      event.preventDefault();
      event.dataTransfer.dropEffect = "move";
    }
  });

  root.addEventListener("drop", (event) => {
    const column = event.target.closest("[data-column]");
    if (busy() || !column || !columns.has(column.dataset.column)) return;
    event.preventDefault();
    try {
      const data = JSON.parse(event.dataTransfer.getData(cardType));
      if (!uuid.test(data.card_id) || !Number.isSafeInteger(data.expected_version) ||
          data.expected_version < 1) return;
      dispatch("request_move", {
        card_id: data.card_id,
        expected_version: data.expected_version,
        destination: column.dataset.column,
      });
    } catch {
      // Ignore unrelated or malformed external drags. The server validates again.
    }
  });

  // The old button can disappear when the card changes columns. Wait for Hologram's
  // render, then focus the card by its stable id, without moving any DOM nodes.
  let focusCard = null;
  let focusColumn = null;
  root.addEventListener("click", (event) => {
    const button = event.target.closest("[data-move-card]");
    if (event.detail === 0 && button && !button.disabled) {
      focusCard = button.dataset.moveCard;
      focusColumn = button.closest("[data-column]").dataset.column;
    }
  }, true);
  const observer = new MutationObserver(() => {
    if (!focusCard) return;
    const card = document.getElementById(`kanban-card-${focusCard}`);
    if (!card) {
      focusCard = null;
      document.getElementById("kanban-sync")?.focus();
    } else if (card.closest("[data-column]").dataset.column !== focusColumn) {
      focusCard = null;
      card.focus({ preventScroll: true });
    } else if (!busy()) {
      focusCard = null;
    }
  });
  observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["aria-busy"] });

  // Abort the window listener and observer on navigation, so revisiting the page
  // never retains old board roots or dispatches twice.
  const controller = new AbortController();
  window.addEventListener("focus", () => dispatch("sync"), { signal: controller.signal });
  const cleanup = new MutationObserver(() => {
    if (!root.isConnected) {
      controller.abort();
      observer.disconnect();
      cleanup.disconnect();
    }
  });
  cleanup.observe(document.body, { childList: true, subtree: true });
}
