# Claude context: mello.github.io

Steve Mello's academic website. Quarto source; GitHub Actions renders it and publishes to `gh-pages`, which GitHub Pages serves at <https://mello.github.io>.

Longer design history, sources of inspiration and rejected options are in Steve's Obsidian vault at `💾 Computing/Website — Current build.md`. This file is the operational context.

**Where things live:**

- `~/repos/mello.github.io/` — this repo, the only live source. Outside Dropbox deliberately: Dropbox syncing `.git/` corrupts repositories.
- `~/Dropbox (Personal)/reference/academic_website/` — archive. Holds the `website_revamp/` working directory used before deployment (a dozen design experiments, plus `scratchpad-rewind/` snapshots), a zip of the hand-written site this replaced, and older iterations. Reference only; never the source.

---

## Deployment — read this before anything else

**Never run `quarto publish`, and never commit `_site/`.** The deployment model is:

```
edit a .qmd on main  →  commit  →  push  →  Action renders  →  gh-pages  →  live
```

`.github/workflows/publish.yml` does the rendering on GitHub. Local `quarto render` and `quarto preview` are for *looking at* work, never for publishing. If a render fails, the Action fails and the previous site stays up.

`gh-pages` is machine-generated. Never edit or commit to it by hand.

### If a deploy breaks

Setting this up hit four things, any of which can recur:

- The personal access token needs **both `repo` and `workflow` scopes**; pushing anything under `.github/workflows/` fails without the second.
- Repository **Settings > Actions > General > Workflow permissions** must be "Read and write". The repo setting caps what the workflow's `permissions:` block can request.
- Quarto's publish action **will not create `gh-pages`** — it must already exist. One local `quarto publish gh-pages` initialises it. This is the only time that command is ever run.
- Pages source must be set to `gh-pages` **by hand** for user sites; GitHub only auto-detects it for project repos.

Action logs need auth, so ask Steve to paste the error rather than trying to fetch them.

## Running it locally

```bash
quarto preview --port 8816
```

Quarto hits an EPERM error writing to `~/Library/Caches` in this environment. If that happens, run it with `HOME` pointed at a scratch directory.

Two things that have wasted real time:

- **The preview server serves its own stale copy** after edits, disagreeing with `_site/` on disk. Verify against both.
- **Quarto's render-error page is returned with HTTP 200**, so a status-code check passes on a broken page. Check for `Quarto Render Error` in the body, not the status.

When either misbehaves: kill the server, `rm -rf .quarto _site`, re-render, restart. Never delete the directory while the preview server is running inside it — the server's working directory becomes a deleted inode and every request 500s.

## Structure

Five top-level pages, each a two-column grid: `_profile-sidebar.qmd` (included, one copy) plus a `.stack-main` content column.

| File | Page |
|---|---|
| `index.qmd` | bio, then `_research.qmd` (working papers + publications) |
| `teaching.qmd` | courses listing |
| `resources.qmd` | resources listing |
| `cv.qmd` | download link above an inline PDF embed |
| `contact.qmd` | contact details, campus map |

`resources/*.qmd` are real sub-pages. `courses/*.qmd` and `papers/**/*.qmd` are listing **data** that Quarto also renders as standalone pages nothing links to — this is deliberate, see gotchas.

Listings are rendered by `_paper.ejs`, `_course.ejs`, `_resource.ejs`, sorted by a `weight` field. Every field is optional except `title`; a missing field produces no element rather than an empty one.

## Adding content

- **A paper** — new `.qmd` in `papers/working/` or `papers/publications/`. Copy an existing one for the field list. Set `weight` to control order.
- **A course** — new `.qmd` in `courses/`.
- **A resource** — new `.qmd` in `resources/`; it becomes both a listing entry and its own page.
- **The sidebar** — `_profile-sidebar.qmd`, once, applies to all five pages.

## Gotchas, all of which have bitten at least once

**The root font size is 17.6px, not 16px.** `fontsize: 1.1em` in `_quarto.yml` sets it. Every `rem` is therefore 10% larger than the usual assumption — `1.5rem` is 26.4px. Several wrong diagnoses came from forgetting this.

**`.profile-sidebar { top: 135.17px }` is measured, not derived.** Two attempts to calculate it were both wrong. If the sidebar drifts on scroll, re-measure rather than adjust by eye:

```js
window.scrollTo(0,0);
document.querySelector('.profile-sidebar').getBoundingClientRect().top
```

Do not raise it for breathing room — sticky pushes an element *down* when `top` exceeds its natural offset.

**Quarto overrides heading weights after the theme variables resolve.** `h1`/`h2` render at 600 regardless of `$headings-font-weight`. Restate weights in `scss:rules`.

**Quarto already underlines every `h2`** with a `border-bottom`. Adding a border above sandwiches the heading between two rules.

**A listing item *is* a page.** Excluding `courses/*.qmd` from `render:` was tested; it removes them from the Teaching listing as well. The unlinked course pages are the accepted cost.

**Unreferenced files are not published.** Quarto only copies resources a page links to. `files/fines_supplementary.pdf` exists solely to keep an old cited URL alive and is listed explicitly under `project: resources:` — without that entry it silently never ships.

**A `render:` list containing only a negation matches nothing** and empties `_site`. The positive glob must come first.

**`website`, `journal`, `project` and `format` are reserved Quarto keys.** A `website:` field in a listing item silently resolves to the whole site config. The paper template uses `journal_name` for this reason.

**Fenced divs wrap content in a `<p>`,** and Bootstrap's `p { margin-bottom: 1rem }` collapses through the div — so a div margin under 1rem does nothing. Zero the inner paragraph to regain control.

**Gaps in a CSS grid do not shrink, and `.grid` has eleven of them.** Quarto's `.grid` is `repeat(12, 1fr)` with a gap between every pair, whatever the children span. A `column-gap` of 2.5rem is therefore 11 x 44px = 484px of irreducible width — wider than a phone viewport, so every page scrolled sideways. Fixed by zeroing `column-gap` below 768px, where both children are full width anyway. Watch for this with any grid gap: multiply by eleven before assuming it fits.

**Grep patterns miss grouped selectors.** The rule setting `h3` spacing is `h3, .h3, h4, .h4 { margin-top: 1.5rem }`, invisible to a search for `h3,.h3{`.

## Design tokens

| | |
|---|---|
| Headings | Petrona (serif) |
| Body | Red Hat Text (sans) |
| Navbar, footer | Dartmouth green `#00693E` |
| Links | `#267ABA`, hover `#003C73` |
| Link behaviour | hover-reveal — prose links look like body text until hovered |
| Pills | grey outline, fills grey on hover |

## Open questions

- **Pill styling** is unresolved. The current outline pill won by default, not on merit. Plain dot-separated links were tried and rejected. The strongest untried candidates are a borderless grey fill and an uppercase micro-label. Do not treat the present styling as settled.
- **Typography and link colour** were never tested against alternatives.
- **Content owed:** office hours on Contact, real course descriptions, remaining abstracts, NBER numbers, working-paper PDF links.
- Course sub-pages are deliberately unlinked; that content may end up on GitHub project pages or the Dartmouth web server instead.

## Working preferences

- Measure in the browser rather than inferring from minified CSS. Every spacing problem that took more than one attempt was prolonged by reasoning and ended by a one-line measurement.
- Snapshot a file before a visual change; Steve reverses visual decisions often and cheap rewinds matter more than being right first time.
- Ask before hard-to-reverse or outward-facing actions. Pushing to `main` changes the live site.
