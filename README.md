# macros-to-hd2-stratagems

Helldivers 2 stratagems catalog used by Macros to HD2 Game, plus the script that refreshes it.

## Format

`stratagems.json`:

```json
{
  "version": 2,
  "gameVersion": "1.007.200",
  "stratagems": [
    {
      "id": "030",
      "wikiPage": "Orbital Gatling Barrage",
      "type": "orbital",
      "keysCode": ["right", "down", "left", "up", "up"],
      "icon": "icons/orbital-gatling-barrage.svg",
      "cooldown": "70",
      "names": { "en": "...", "es": "...", "pt": "...", "ru": "..." }
    }
  ]
}
```

- `version`: integer, bumped by the script only when the content changes.
- `gameVersion`: highest `Last Updated` game version found on the wiki stratagem pages (`0.000.000` until the first live run).
- `id`: stable string; never reused or renumbered. New entries continue the sequence.
- `wikiPage`: helldivers.wiki.gg page title, the merge key between runs. Absent when the entry has no confident wiki match.
- `type`: `eagle`, `orbital`, `weapons`, `backpacks`, `defenses` or `mission`.
- `keysCode`: `up`, `down`, `left`, `right`.
- `icon`: path relative to the repo (`icons/<slug>.svg`). Entries not matched yet keep the app asset name (`assets/icons/*.webp`) they were seeded with; those are not files of this repo.
- `cooldown`: seconds, as a string.
- `names`: only the languages that have a translation; consumers fall back to `en`.

## Update

```
dart pub get
dart run tool/update_catalog.dart
dart analyze && dart test
```

The script (one request at a time, 1 s apart):

- lists the pages that use `Template:Stratagem_code` on helldivers.wiki.gg and reads the `stratagem_code` field of each one;
- maps entries without `wikiPage` by normalized English name, then by a key code only one page has (listed for review);
- keeps ids and translations, updates changed key codes, adds new stratagems (Support Weapon, Backpack, Emplacement, Sentry, Vehicle, Orbital, Eagle) with the page title as `en` name;
- skips wiki subpages (April Fools) and non-stratagem types, and downloads the SVG icons it matches by name: exact, without the designator, designator alone, icon without its `Guard Dog ` prefix, then `icon_aliases.json` (wiki page to icon path in the icons repo); several hits means no match;
- prints a report: new entries, changed codes, mappings, entries without icon, missing translations, skipped and rejected wiki pages.

Pages with an unknown direction, several different codes or no code are rejected and reported, never guessed. New entries need their `es`, `pt` and `ru` names added by hand.

## Attribution

- Key codes, names, types and cooldowns: [helldivers.wiki.gg](https://helldivers.wiki.gg) (data only; wiki images are not copied).
- Icons: [nvigneux/Helldivers-2-Stratagems-icons-svg](https://github.com/nvigneux/Helldivers-2-Stratagems-icons-svg).
