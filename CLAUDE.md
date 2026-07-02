# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`iata` is a Ruby gem that exposes the IATA (International Air Transport Association) airport code list as a queryable in-memory registry.

The dataset is sourced from Wikidata (property P238, "IATA airport code") and ships inside the gem as a JSON file so the registry works offline. The upstream Wikidata URL is the **source of truth for data refresh**, not a runtime dependency.

## Commands

```bash
bundle install                       # Install dev dependencies
bundle exec rake                     # Run full RSpec suite + RuboCop
bundle exec rake spec                # Run RSpec only
bundle exec rake rubocop             # Lint only
bundle exec rspec spec/iata/entry_spec.rb   # Run a single spec file
bundle exec rspec spec/iata/entry_spec.rb:42  # Run one example by line
bundle exec rake iata:fetch          # Refresh bundled dataset from Wikidata
bundle exec rake build               # Build .gem into pkg/
bundle exec rake release             # Build, tag, push to git + RubyGems
```

## Architecture

### Data flow

```
lib/iata/data/airports.json  ──▶  Loader  ──▶  [Iata::Entry, …]  ──▶  Registry  ──▶  Query API
```

- **Loader** (`lib/iata/loader.rb`) parses the bundled JSON file once into `Iata::Entry` instances. The JSON is a flat object keyed by IATA code with a `_meta` sibling for source metadata.
- **Entry** (`lib/iata/entry.rb`) is a `lutaml-model` class — every attribute is typed; never a hash bag.
- **Registry** (`lib/iata/registry.rb`) holds all loaded entries and lazily builds the `by_code` index on first lookup.
- **Coordinates** (`lib/iata/coordinates.rb`) is a value type wrapping lat/lon, with haversine `#distance_to`.

### Wire format (bundled JSON)

The bundled `airports.json` is shaped like:

```json
{
  "_meta": {
    "fetched_at": "2026-07-02T12:00:00Z",
    "source": "Wikidata (property P238)",
    "result_count": 12345,
    "entry_count": 12345
  },
  "PVG": {
    "code": "PVG",
    "name": "Shanghai Pudong International Airport",
    "wikidata_id": "Q86792",
    "country_iso2": "CN",
    "country_name": "Q148",
    "latitude": 31.1434,
    "longitude": 121.8052
  },
  ...
}
```

The `_meta` block is read by the `check-upstream` workflow to detect drift. `country_name` is the Wikidata Q-number (not a human-readable name — for human country names use a separate `iso3166` lookup).

### Upstream source

Wikidata SPARQL endpoint: `https://query.wikidata.org/sparql`. The query is in `lib/iata/data/fetcher.rb`. Property P238 is "IATA airport code". P17 is "country". P625 is "coordinate location". P297 is "ISO 3166-1 alpha-2 code" (on the country entity).

### Query API

`Iata::Registry` is the public query surface:
- `find(code)` / `[code]` — exact lookup (case-insensitive)
- `where(code:, country:, name:, ...)` — filtered query (single value or any-of array; `name:` accepts String or Regexp)
- `countries` — sorted distinct country codes
- `counts_by_country` — per-country counts
- `each`, `size`, `count`

Top-level shortcuts on `Iata` (a `SingleForwardable` delegator to `Iata.registry`): `find`, `where`, `each`, `size`, `count`, `countries`.

### Dataset size & loading

~12,000 entries, ~2.5 MB bundled JSON. Loading parses once (~1–2 seconds wall clock) and holds the entries array in memory.

## Conventions

These rules are load-bearing for this project; broader rules live in the global `~/.claude/CLAUDE.md`.

- **`lutaml-model` for every model.** No hand-rolled `to_h` / `from_h` / `to_json` / `from_json` on model classes. Wire-name translation lives in the Loader, not on the model.
- **`autoload`, not `require_relative`.** All internal library code uses `autoload` declared in the immediate parent namespace file (`lib/iata.rb`).
- **No `double()` in specs.** Use real `Iata::Entry` instances built from sample data, or lightweight `Struct`s for plain data.
- **Vendor the dataset inside the gem.** The gem must work offline. `lib/iata/data/airports.json` ships in the gem package via the gemspec's `Dir.glob('{lib}/**/*')`.
- **Data refresh is an upstream-sync task.** Run `bundle exec rake iata:fetch` → commit the new `lib/iata/data/airports.json` as one clearly-described update. Gem version bumps follow SemVer independently.

### Workflow safety (do not violate)

- All changes go through PRs. Never commit to `main`, never push to `main`, never merge to `main`, never push git tags. Releases are the user's call.
- Never add `Co-authored-by` / `Generated with` / `Signed-off-by` AI trailers to commits or PR descriptions.
- Never delete files I did not create. If cleanup is needed, flag it — never `rm` source files.