import { Controller } from "@hotwired/stimulus"

// Hamburger toggle for an off-canvas nav drawer (panel + backdrop targets).
export default class extends Controller {
  static targets = ["panel", "backdrop"]

  toggle() {
    this.panelTarget.classList.toggle("is-open")
    this.backdropTarget.classList.toggle("is-open")
  }

  close() {
    this.panelTarget.classList.remove("is-open")
    this.backdropTarget.classList.remove("is-open")
  }
}
