const installed = new WeakSet();
const cardType = "application/x-holodeck-card";
const columns = new Set(["todo", "doing", "done"]);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
// Room around the tilted card so its rotated corners and shadow stay in the image.
const dragImagePadding = 24;

// Browsers snapshot the drag image once, at dragstart. A transform on the card
// itself is not reliably captured and would also tilt the card left in place,
// so hand the browser a tilted copy instead. The copy sits in an unrotated,
// off-screen wrapper (styled by .hd-kanban-drag-image) and is removed right after.
function setTiltedDragImage(event, card) {
  if (typeof event.dataTransfer.setDragImage !== "function") return;

  const rect = card.getBoundingClientRect();
  const clone = card.cloneNode(true);
  clone.removeAttribute("id");
  clone.querySelectorAll("[id]").forEach((element) => element.removeAttribute("id"));
  clone.style.width = `${rect.width}px`;

  const wrapper = document.createElement("div");
  wrapper.className = "hd-kanban-drag-image";
  wrapper.setAttribute("aria-hidden", "true");
  wrapper.style.padding = `${dragImagePadding}px`;
  wrapper.appendChild(clone);
  document.body.appendChild(wrapper);

  // Keep the card under the pointer exactly where it was grabbed.
  event.dataTransfer.setDragImage(
    wrapper,
    event.clientX - rect.left + dragImagePadding,
    event.clientY - rect.top + dragImagePadding,
  );
  setTimeout(() => wrapper.remove(), 0);
}

export function install(rootId, boardCid) {
  const root = document.getElementById(rootId);
  if (!root || installed.has(root)) return;
  installed.add(root);

  const busy = () => root.getAttribute("aria-busy") === "true";
  const dispatch = (name, params = {}) => {
    if (root.isConnected) globalThis.Hologram.dispatchAction(name, boardCid, params);
  };

  // Drag feedback lives in data attributes Hologram's templates never set, so
  // re-renders leave them alone. Only one column and one card are marked at a time.
  let dropColumn = null;
  let draggedCard = null;
  const highlight = (column) => {
    if (column === dropColumn) return;
    if (dropColumn) delete dropColumn.dataset.dropTarget;
    dropColumn = column;
    if (column) column.dataset.dropTarget = "";
  };
  const endDrag = () => {
    highlight(null);
    if (draggedCard) delete draggedCard.dataset.dragging;
    draggedCard = null;
  };

  root.addEventListener("dragstart", (event) => {
    if (!(event.target instanceof Element)) {
      event.preventDefault();
      return;
    }
    const card = event.target.closest("[data-card-id]");
    if (!card || busy() || card.getAttribute("draggable") !== "true") {
      event.preventDefault();
      return;
    }
    event.dataTransfer.effectAllowed = "move";
    // Clone before marking the card, so the drag image isn't the faded version.
    setTiltedDragImage(event, card);
    draggedCard = card;
    card.dataset.dragging = "";
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
      highlight(column);
    } else {
      highlight(null);
    }
  });

  // dragleave also fires when moving between a column's children; only clear
  // the highlight once the pointer has really left the highlighted column.
  root.addEventListener("dragleave", (event) => {
    if (dropColumn && !(event.relatedTarget && dropColumn.contains(event.relatedTarget))) {
      highlight(null);
    }
  });
  root.addEventListener("dragend", endDrag);

  root.addEventListener("drop", (event) => {
    endDrag();
    const column = event.target.closest("[data-column]");
    if (busy() || !column || !columns.has(column.dataset.column)) return;
    event.preventDefault();
    let data;
    try {
      data = JSON.parse(event.dataTransfer.getData(cardType));
    } catch {
      // Ignore unrelated or malformed external drags. The server validates again.
      return;
    }

    if (!data || !uuid.test(data.card_id) || !Number.isSafeInteger(data.expected_version) ||
        data.expected_version < 1) return;

    dispatch("request_move", {
      card_id: data.card_id,
      expected_version: data.expected_version,
      destination: column.dataset.column,
    });
  });

  // The old button can disappear when the card changes columns. Wait for Hologram's
  // render, then focus the card by its stable id, without moving any DOM nodes.
  let focusCard = null;
  let focusColumn = null;
  root.addEventListener("click", (event) => {
    if (!(event.target instanceof Element)) return;
    const button = event.target.closest("[data-move-card], [data-delete-card]");
    if (event.detail === 0 && button && !button.disabled) {
      focusCard = button.dataset.moveCard || button.dataset.deleteCard;
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
