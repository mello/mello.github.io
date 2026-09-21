# mello.github.io

Personal academic website for Steve Mello, Assistant Professor of Economics at Dartmouth College.

**Live at <https://mello.github.io>**

## How it works

The site is written in [Quarto](https://quarto.org). This repository holds the **source** — Markdown files, a stylesheet and a few templates. The published HTML is built by GitHub Actions and lives on the `gh-pages` branch, which is what GitHub Pages serves.

That means editing the site is just editing text here:

```
edit a .qmd  →  commit  →  push  →  ~1 min  →  live
```

Nothing is built or published from a laptop. A failed render leaves the previous version of the site up.

## Layout

| File | Page |
|---|---|
| `index.qmd` | home — short bio, then working papers and publications |
| `teaching.qmd` | courses |
| `resources.qmd` | guides for students and research assistants |
| `cv.qmd` | CV, viewable inline and downloadable |
| `contact.qmd` | contact details and a campus map |

Content that appears as a list — papers, courses, resources — lives one file per item in `papers/`, `courses/` and `resources/`. Each carries its metadata in front matter (title, coauthors, venue, abstract, links) and is rendered through a small template in `_paper.ejs`, `_course.ejs` or `_resource.ejs`. Adding a paper means adding a file, not editing a page.

`_profile-sidebar.qmd` is the identity block that appears on every page — one copy, included everywhere.

## Design

A single content column beside a sidebar that stays in place while you scroll, so the page never feels empty even where a section is short. Petrona over Red Hat Text; Dartmouth green in the navigation; links that stay quiet in running text and only announce themselves on hover. Abstracts and citations expand in place using native HTML disclosure elements — the only JavaScript on the site is a copy-to-clipboard button for BibTeX.

The campus map is generated from OpenStreetMap data by `tools/office_map.R` and committed as an image, so building the site needs neither R nor network access.

## Credits

Built on [Marvin Schmitt's Quarto website template](https://github.com/marvinschmitt/quarto-website-template), which in turn draws on [Andrew Heiss's](https://github.com/andrewheiss/ath-quarto). The sticky sidebar idea comes from [luost26/academic-homepage](https://github.com/luost26/academic-homepage).
