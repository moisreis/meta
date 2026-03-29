// nested_normative_articles_controller.js
//
// Author:  Moisés Reis
// Date:    03/26/2026
// Package: Meta
//
// Description:
//   Manages the dynamic nested-form behaviour for PortfolioNormativeArticle entries
//   inside the portfolio form. Handles three responsibilities:
//
//   1. addEntry    — Clones the pre-rendered <template> to append a blank row.
//   2. removeEntry — Soft-deletes persisted rows via the _destroy hidden field, or
//                    removes brand-new rows from the DOM entirely.
//   3. onSelectChange — Reveals the three target inputs once a NormativeArticle is chosen,
//                       and hides them again if the selection is cleared.
//
// Targets:
//   container  — The <div> that holds all rendered entry rows.
//   template   — The <template> element holding a blank pre-rendered entry.
//   entry      — Each individual article row (one per PortfolioNormativeArticle).
//   targets    — The hidden grid of three numeric inputs inside each entry.
//   destroy    — The hidden _destroy field inside each entry.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "template", "entry", "targets", "destroy"];

  // == addEntry
  //
  // Clones the innerHTML of the <template> target, replaces every occurrence of
  // the NEW_RECORD placeholder with a timestamp-based index so Rails generates
  // unique field names, and inserts the resulting HTML at the end of the container.
  //
  addEntry() {
    const template = this.templateTarget.innerHTML;
    const index = new Date().getTime();
    const html = template.replace(/NEW_RECORD/g, index);

    this.containerTarget.insertAdjacentHTML("beforeend", html);
  }

  // == removeEntry
  //
  // Finds the closest entry row relative to the clicked trash button.
  // - If the row has a _destroy hidden field it is a persisted record: set the field
  //   to "1" so Rails destroys it on the next save, then visually hide the row.
  // - If there is no _destroy field the row is brand-new and has no database record:
  //   remove it from the DOM immediately.
  //
  removeEntry(event) {
    const entry = event.currentTarget.closest(
      "[data-nested-normative-articles-target~='entry']",
    );
    if (!entry) return;

    const destroyField = entry.querySelector(
      "[data-nested-normative-articles-target~='destroy']",
    );

    if (destroyField) {
      // Persisted record — mark for destruction and hide.
      destroyField.value = "1";
      entry.classList.add("hidden");
    } else {
      // New record — no database row exists yet, remove outright.
      entry.remove();
    }
  }

  // == onSelectChange
  //
  // Listens for change events bubbling up from any <select> inside an entry div.
  // Guards against unrelated selects by checking that the event originated on a
  // <select> element and that a targets panel exists in the same entry.
  //
  // Tom Select updates the underlying native <select> value and dispatches a native
  // change event, which bubbles normally, so no special tom-select integration is needed.
  //
  onSelectChange(event) {
    // Ignore events not originating from a <select>.
    if (!event.target.matches("select")) return;

    const entry = event.target.closest(
      "[data-nested-normative-articles-target~='entry']",
    );
    if (!entry) return;

    const targets = entry.querySelector(
      "[data-nested-normative-articles-target~='targets']",
    );
    if (!targets) return;

    if (event.target.value) {
      targets.classList.remove("hidden");
    } else {
      targets.classList.add("hidden");
    }
  }
}
