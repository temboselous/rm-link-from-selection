# Selection links for reMarkable

This mod adds links to a page from a lasso selection. Lasso some strokes, tap one of the two new buttons in the selection menu, and pick a page in the same document or in another one. An icon appears next to the selection. Tapping it jumps to the target. Long-pressing it lets you change, move or delete the link.

It is a fork of [linkFromSelection](https://github.com/alefaraci/xovi-qmd-extensions#linkfromselection) by Alessio Faraci, kept under the same GPL-3.0-only licence. The fork exists so the mod can be brought up to date soon after each firmware release. Links made with the original keep working, because the way they are stored has not changed.

Do not install this alongside the original `link-from-selection` package. They are the same mod and would both add their buttons.

## What it needs

A reMarkable in developer mode with [xovi](https://github.com/asivery/xovi) and `qt-resource-rebuilder` installed. It has been tested on a Paper Pure with firmware 3.29.1.0.

## Installing by hand

Plug the tablet in over USB and run:

```
tools/install.sh
```

The script first checks the mod against the tablet's own name table and stops if anything is missing. It then copies the file over and restarts the tablet's interface. If the interface does not stay up, the script removes the mod again and prints the relevant part of the log.

To remove it again, run `tools/uninstall.sh`. Links you have made stay stored inside their documents and come back if you reinstall.

## After a firmware update

The mod is a patch applied to reMarkable's own screens, so a firmware update can break it. There are two ways it breaks.

The first is that the mod refers to a name the new firmware no longer has. This one is serious: the interface refuses to start at all, restarts in a loop, and the tablet reboots without mods. It is also easy to detect in advance.

The second is that reMarkable has changed a screen so that the mod's code still loads but does the wrong thing. This can only be found by trying the mod.

The steps after an update are:

1. On the tablet, rebuild the name table: `ssh root@10.11.99.1 /home/root/xovi/rebuild_hashtable`
2. Run `tools/check-firmware.sh`. It saves the new table under `device/<version>/` and lists any line of the mod that uses a missing name.
3. Fix those lines. If the missing name is a piece of text, write the text out in plain form in place of its hash, as was done for `"number"` on 3.29.1.0. If it is the name of something on a screen, find what replaced it (step 5 helps).
4. Run `tools/install.sh`, then make one link within a document and one to another document, follow both, and long-press one.
5. Read the log for errors the screen did not show: `ssh root@10.11.99.1 'journalctl -u xochitl --since -10min | grep -iE "TypeError|ReferenceError|qmldiff"'`

To read the mod with real names in place of numbers:

```
python3 tools/hashtab.py unhash device/3.29.1.0/hashtab src/linkFromSelection.qmd > build/readable.qmd
```

New code can be written with plain names. Only names taken from reMarkable's own screens are stored as numbers, which is the form the Vellum index expects.

## Where it patches

The mod changes four of reMarkable's screens. These are the places to look when something stops working.

| Screen file | What the mod adds |
| --- | --- |
| `DeviceSceneView.qml` | Nearly all of the mod: storing links, drawing icons, following them |
| `SceneSelectionHandler.qml` | The two buttons in the selection menu, placed before "convert to text" |
| `Navigator.qml` | Picking a target document from the file browser |
| `Pages.qml` | Picking a target page |

## Releasing

`packaging/VELBUILD` is the recipe for the Vellum index. For each release, raise `pkgver`, set `_commit` to the pushed commit, set the firmware range in `depends`, and refresh the checksums with Vellum's `scripts/update-checksums.sh`. Vellum asks that pull requests and their descriptions are written by a person.

## Folders

- `src/` holds the mod itself.
- `tools/` holds the check and install scripts.
- `device/` holds name tables copied from the tablet, one folder per firmware. It is kept out of git, because the tables contain reMarkable's own names.
- `upstream/` holds the original files for 3.27 and 3.28, for comparison.
- `packaging/` holds the Vellum recipe.
