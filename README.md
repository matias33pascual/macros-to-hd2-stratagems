# macros-to-hd2-stratagems

Helldivers 2 stratagems catalog used by Macros to HD2 Game, plus the script that refreshes it.

## Format

`stratagems.json`:

```json
{
  "version": 2,
  "gameVersion": "1.007.200",
  "nextId": 107,
  "stratagems": [
    {
      "id": "030",
      "wikiPage": "Orbital Gatling Barrage",
      "wikiName": "Orbital Gatling Barrage",
      "type": "orbital",
      "keysCode": ["right", "down", "left", "up", "up"],
      "icon": "icons/orbital-gatling-barrage.svg",
      "cooldown": "70",
      "names": { "en": "...", "es": "...", "pt": "...", "ru": "..." },
      "deprecated": true
    }
  ]
}
```

- `version`: integer, bumped by the script only when the content changes.
- `gameVersion`: highest `Last Updated` game version found on the wiki stratagem pages (`0.000.000` until the first live run).
- `id`: stable string; never reused or renumbered. New entries continue the sequence.
- `nextId`: next id to hand out. Persisted so the id of a removed entry (retired, e.g. `106`) is never reused; the script raises it as it adds entries and never lowers it.
- `wikiPage`: helldivers.wiki.gg page title, the merge key between runs. Absent when the entry has no confident wiki match.
- `type`: `eagle`, `orbital`, `weapons`, `backpacks`, `defenses` or `mission`.
- `keysCode`: `up`, `down`, `left`, `right`.
- `icon`: path relative to the repo (`icons/<slug>.svg`). Entries not matched yet keep the app asset name (`assets/icons/*.webp`) they were seeded with; those are not files of this repo.
- `cooldown`: seconds, as a string.
- `wikiName`: English name exactly as the wiki shows it (the page title). Kept in sync on every run; absent when there is no `wikiPage`.
- `names`: display names for `en`, `es`, `pt`, `ru`, in natural case (English in Title Case like the wiki; Spanish, Portuguese and Russian in sentence case; codes, acronyms and proper names keep their case). The script never overwrites them; a new entry gets `en` from `wikiName` and the other languages are reported as missing, to be written by hand.
- `deprecated`: `true` on legacy duplicates the app keeps for saved missions but hides; omitted otherwise. The script preserves it.

## Update

```
dart pub get
dart run tool/update_catalog.dart
dart analyze && dart test
```

The script (one request at a time, 1 s apart):

- lists the pages that use `Template:Stratagem_code` on helldivers.wiki.gg and reads the `stratagem_code` field of each one;
- maps entries without `wikiPage` by normalized English name, then by a key code only one page has (listed for review);
- keeps ids and translations, updates changed key codes, adds new stratagems (Support Weapon, Backpack, Emplacement, Sentry, Vehicle, Orbital, Eagle) with `wikiName` as `en` name and the wiki name kept in sync;
- skips wiki subpages (April Fools) and non-stratagem types, and downloads the SVG icons it matches by name: exact, without the designator, designator alone, icon without its `Guard Dog ` prefix, then `icon_aliases.json` (wiki page to icon path in the icons repo); several hits means no match;
- prints a report: new entries, changed codes, mappings, entries without icon, missing translations, skipped and rejected wiki pages;
- never adds the pages listed in `excluded.json` (event or joke stratagems, e.g. `Orbital Confetti`); to retire an entry, remove it from `stratagems.json`, add its page title there and keep `nextId`.

Pages with an unknown direction, several different codes or no code are rejected and reported, never guessed. New entries need their `es`, `pt` and `ru` names added by hand.

## Checking for new stratagems

- When: after each game patch or new Warbond (Steam news / patch notes for Helldivers 2), and before each app release.
- Where to look: helldivers.wiki.gg `Stratagems` page and the pages using `Template:Stratagem_code` (what the script reads); the icons repo for new SVGs.
- What to analyze: the script report sections (new entries, changed codes, mappings, no icon, missing translations, skipped and rejected pages). Check each new type and key code on its wiki page; write `es`, `pt`, `ru` names by hand; move event or joke stratagems to `excluded.json`; add an `icon_aliases.json` entry when the icon has another name.
- Where to save: `stratagems.json`, `icons/`, `excluded.json`, `icon_aliases.json`. Run `dart analyze && dart test`, commit on `master`; Mat pushes (the app reads raw `master`, so a push reaches every user through "Update stratagems").
- App bundle: copy `stratagems.json` and `icons/` into the app's `assets/catalog/` so fresh installs ship the same version.
- No changes: if `git diff` is empty after the run, nothing to commit; note the wiki `gameVersion` seen.

## Attribution

- Key codes, names, types and cooldowns: [helldivers.wiki.gg](https://helldivers.wiki.gg) (data only; wiki images are not copied).
- Icons: [nvigneux/Helldivers-2-Stratagems-icons-svg](https://github.com/nvigneux/Helldivers-2-Stratagems-icons-svg).
