Well...
After reading this series of brainstorming posts, reading the [gamelist.xml doc](https://github.com/RetroPie/EmulationStation/blob/master/GAMELISTS.md), and taking a look at some `gamelist.xml` files,  I  found a simpler solution for what we want.

Let me talk about another method...

## user point of view

Take screenshots of a game and set the most recent screenshot as the emulationstation image for this game.


## prerequisites

- `auto_screenshot_filename = false` in global `retroarch.cfg`. **It will be the flag to turn on/off the "scrape your own screenshots" functionality (it can be confusing, because "false" means "on", we can think about another flag later.)**.
- `screenshot_directory` must be set to some directory in `retroarch.cfg` (system specific or global, system specific takes precedence).
- **it was made to work after a scraping (the `$HOME/.emulationstation/gamelists/$system/gamelist.xml` or `/etc/emulationstation/gamelists/$system/gamelist.xml` files must exist).**


## how it works

Summing up: put the game screenshot full path file name in the respective `<image>` entry, replacing the old content. Yeah, that simple...

Let's take a look at the `runcommand-onend.sh`:

```sh
#!/bin/bash
echo "--- start of $(basename $0) ---" >&2

readonly system="$1"
readonly full_path_rom="$3"
readonly retroarch_cfg="/opt/retropie/configs/all/retroarch.cfg"
readonly system_ra_cfg="/opt/retropie/configs/$system/retroarch.cfg"
readonly gamelist="$HOME/RetroPie/roms/$system/gamelist.xml"
readonly gamelist1="$HOME/.emulationstation/gamelists/$system/gamelist.xml"
readonly gamelist2="/etc/emulationstation/gamelists/$system/gamelist.xml"

rom="${full_path_rom##*/}"
rom="${rom%.*}"
scrap_img="$rom.png"

source "/opt/retropie/lib/inifuncs.sh"

iniConfig ' = ' '"'

# only go on if the auto_screenshot_filename is false
iniGet "auto_screenshot_filename" "$retroarch_cfg"
if ! [[ "$ini_value" =~ ^(false|0)$ ]]; then
    exit 0
fi

# getting the screenshots directory
# try system specific retroarch.cfg, if not found try the global one
iniGet "screenshot_directory" "$system_ra_cfg"
screenshot_dir="$ini_value"
if [[ -z "$screenshot_dir" ]]; then
    iniGet "screenshot_directory" "$retroarch_cfg"
    screenshot_dir="$ini_value"
    if [[ -z "$screenshot_dir" ]]; then
        echo "You must set a path for 'screenshot_directory' in \"retroarch.cfg\"." >&2
        echo "Aborting..." >&2
        exit 1
    fi
fi

# if there is no screenshot named "ROM Name.png", we have nothing to do here
if ! [[ -f "$screenshot_dir/$scrap_img" ]]; then
    echo "There is no screenshot for \"$rom\". Exiting..." >&2
    exit 0
fi

# if there is no "customized gamelist.xml", try the user specific,
# if it fails, get the global one
if ! [[ -f "$gamelist" ]]; then
    echo "Copying \"$gamelist1\" to \"$gamelist\"." >&2

    if ! cp "$gamelist1" "$gamelist" 2>/dev/null; then
        echo "Failed to copy \"$gamelist1\"." >&2
        echo "Copying \"$gamelist2\" to \"$gamelist\"." >&2

        if ! cp "$gamelist2" "$gamelist" 2>/dev/null; then
            echo "Failed to copy \"$gamelist2\"." >&2
            echo "Aborting..." >&2
            exit 1
        fi
    fi
fi

# the <image> entry MUST be on a single line and match the pattern:
# anything followed by rom name followed or not by "-image" followed by dot followed by 3 chars
old_img_regex="<image>.*$rom\(-image\)\?\....</image>"
new_img_regex="<image>$screenshot_dir/$scrap_img</image>"

sed -i "s|$old_img_regex|$new_img_regex|" "$gamelist"
echo "--- end of $(basename $0) ---" >&2
```


## limitations

[Currently this is a kind of "proof of concept". The limitations below can be overcome if we feel that this is the way to achieve what we want.]

- This method only changes the `<image>` entry of a particular game. So, if this game is NOT present in the gamelist.xml, nothing happens. [TODO: learn how to use the sselph scraper with `-append=true` option.]
- The `<image></image>` entry in the `gamelist.xml` must be in a single line (it seems to be the default, so probably we don't have to worry about it).
- The original image filename in the `<image>` entry **must** be named as `ROM Name.ext` or `ROM Name-image.ext` (`ext` can be any 3 characters, eg: png, bmp, jpg, etc), otherwise the `sed` command won't replace it.
- After a succeeded image changing, the respective `<image>` entry will have a full path to the image. It can be an inconvenience if the user wants to copy the gamelist.xml between computers (IMHO it's not so important. Besides that it probably won't be a problem to those who use the `pi` user).


## "I didn't like how it looks! I want my old scrapes back!"

Change the `auto_screenshot_filename` to true in `/opt/retropie/configs/all/retroarch.cfg` and then delete the system specific `gamelist.xml` that is at the system roms directory (example for SNES: `~/RetroPie/roms/snes/gamelist.xml`). Now emulationstation will get the gamelist from `$HOME/.emulationstation/gamelists/$system/gamelist.xml`.

Restart emulationstation and you'll get back your old scrapes.


## where to go from here?

After learn how to use the scraper with `-append=true` option (no success on my first tests) and if it proves to be good enough, we can evolve it to what I think would be a cool feature: scrape with screenshots only the games that aren't scraped. In other words: if the user is playing a non-scraped game and takes screenshots, then scrape this game with the most recent taken screenshot.
