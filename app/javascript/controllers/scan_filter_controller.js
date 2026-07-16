import { Controller } from "@hotwired/stimulus"

// Client-side search + tone filter for the scan history table.
export default class extends Controller {
  static targets = ["search", "row", "toneButton", "empty"]

  apply() {
    const query = this.searchTarget.value.trim().toLowerCase()
    const activeTones = this.toneButtonTargets
      .filter((button) => button.classList.contains("is-active"))
      .map((button) => button.dataset.tone)

    let visibleCount = 0

    this.rowTargets.forEach((row) => {
      const matchesQuery = row.dataset.site.includes(query)
      const matchesTone = activeTones.includes(row.dataset.tone)
      const visible = matchesQuery && matchesTone
      row.hidden = !visible
      if (visible) visibleCount += 1
    })

    this.emptyTarget.hidden = visibleCount > 0
  }

  toggleTone(event) {
    event.currentTarget.classList.toggle("is-active")
    this.apply()
  }
}
