# Taking your  own screenshots and creating your own gamelists

Sometimes the boxarts and other sources for scraping can be low quality and inconsistent in sizes, whereas in game screenshots are standardised to the same size. The following is a simple guide with a script that will help automate the process of taking and scraping your own screenshots.

A few disclaimers first:

- You have to be comfortable with basic Linux commands and simple file editing.

- **MAKE A BACKUP AND USE AT YOUR OWN RISK!**

- You need to have an updated version of RetroPie-Setup scripts (version 4+) ([updating instructions here](https://retropie.org.uk/download/)).

- You can only create one screenshot per game

- This only works with retroarch emulators



### Take a Screenshot

Before talk about the "scraping your own screenshots" trick, we need to know how to take screenshots in RetroArch. If you already know how to do it, you can go to the [next section](#runcommand).


#### via RGUI

Access the RGUI (usually with Select+X) and go to `Quick Menu` -> `Take Screenshot`.


#### via hotkeys
 
The default screenshot button is `F8` which means if you've configured your keyboard through emulationstation you have to hold the hotkey button (by default the button you configured as select) and then press F8. If you want to have it so that you can take a screenshot with your controller you'll change the screenshot button to a button that isn't already being used for hotkey behaviour. To do this you'll edit the overall or global `retroarch.cfg` at
`/opt/retropie/configs/all/retroarch.cfg`

The key line you want to change is ~line 580
```
# Take screenshot
# input_screenshot = f8
```
So in my case I changed it to my right analogue thumb on my xbox controller (number values vary with diff controllers)
```
# Take screenshot
input_screenshot_btn = "12"
```

So in game when I want to take a screenshot I hold select (or rather the back button on the xbox controller) and press the right analogue thumb.



## runcommand

The runcommand menu is what is run every time you play a game, It is what allows you to change emulators, set video resolutions, among other things. One lesser known function is the ability to add customised scripts to be executed on the start and/or on the end of the game.

The `runcommand-onstart.sh` script is executed (if exists) before the game starts, and `runcommand-onend.sh` is executed (if exists) after you exit the emulator. Both files must be at `/opt/retropie/configs/all/` directory.



## scraping methods

Here we have two methods to scrape your own screenshots:

**[Method 1](#method-1)**: uses the `runcommand-onstart.sh` to automatically set some screenshot related configs in system specifics `retroarch.cfg` files. And after you take some screenshots from the games, you use the SSelph scraper to create a `gamelist.xml` with your screenshots.

**[Method 2](#method-2)**: uses the `runcommand-onend.sh` to automatically set the most recent screenshot from a game to be the emulationstation image for the respective game.

The main difference between them is:

- [Method 1](#method-1): automates the `retroarch.cfg` configs but you have to use SSelph scraper tool from command line every time you want to update the `gamelist.xml` with your screenshots.

- [Method 2](#method-2): `retroarch.cfg` configs are done manually but automates the placement of your screenshots as the respective emulationstation game images.

Now you have to choose which method you want to follow (or read about both): [Method 1](#method-1) or [Method 2](#method-2).


## method 1

### runcommand-onstart.sh
You need to create a file called `runcommand-onstart.sh` in the folder `/opt/retropie/configs/all/`

copy the following contents:

```
#!/usr/bin/env bash

system="$1"
imgdir="$HOME/RetroPie/roms/$system/images"
configdir="/opt/retropie/configs" 

mainretroarch="$configdir/all/retroarch.cfg"
systemretroarch="$configdir/$system/retroarch.cfg"

source "/opt/retropie/lib/inifuncs.sh"

iniConfig " = " '"'

# Create images folder in each respective rom folder
mkdir -p "$imgdir"

# If there is no auto screenshot setting in the main retroarch.cfg add it
if ! grep -q "auto_screenshot_filename" "$mainretroarch"; then
    iniSet "auto_screenshot_filename" "false" "$mainretroarch"
fi

# If there is no system based screenshot directory defined then define it in the system based retroarch.cfg
if ! grep -q "screenshot_directory" $systemretroarch; then
    iniSet "screenshot_directory" "$imgdir" "$systemretroarch"
fi
```

Now you can play your games and take your screenshots and it will fill your images folder with your screenshots. 


### Create gamelist with Sselphs scraper

If you haven't already, download sselphs scraper from the setup script

Now that you've got your screenshots ready all you have to do is use sselph's scraper to generate a gamelist for your screenshots- this will effectually link your roms to their respective screenshots.

**You need to exit emulationstation first**

so again using the snes as an example

```
cd /home/pi/RetroPie/roms/snes
/opt/retropie/supplementary/scraper/scraper -img_format=png -add_not_found=true -download_images=false -image_suffix=
```
_For more information on the options for sselphs scraper see [here](https://github.com/sselph/scraper/wiki/Flags)_

it will create a gamelist.xml file in `/home/pi/RetroPie/roms/snes` which takes precedence over the gamelist.xml in `/home/pi/.emulationstation/gamelists/snes`

and if all went according to plan, when you boot emulationstation back up your images will be the screenshots that you took! TADA!

### Behind the Code

The following is all taken care of by the aformentioned script but if you're interested this explains essentially what the code is doing (and how you can set it up manually without a script)

#### Overall retroarch.cfg

You need to add the following line to `/opt/retropie/configs/all/retroarch.cfg`
```
auto_screenshot_filename = "false"
```
This will tell retroarch to name any screenshots taken after the rom name you are playing

#### System Specific retroarch.cfg

You need create an `images` folder in each rom folder you want screenshots for and then set the system based retroarch.cfg screenshot path to each respective `images` folder so that the images can be easily joined with sselphs scraper,  unlike the default retropie behaviour this will keep your images and gamelists in each system folder with your roms; the pattern is as follows:

`/home/pi/RetroPie/roms/<system>/images`

so for example if I'm adding screenshots to the snes I would create:

`/home/pi/RetroPie/roms/snes/images`

Then I would add that screenshot path to:

`/opt/retropie/configs/snes/retroarch.cfg` 

```
# Settings made here will only override settings in the global retroarch.cfg if placed above the #include line

input_remapping_directory = "/opt/retropie/configs/snes/"
screenshot_directory = "/home/pi/RetroPie/roms/snes/images/"

#include "/opt/retropie/configs/all/retroarch.cfg"
```

then we would take our screenshots and use sselphs scraper to generate our gamelist.xml's as above.
















## method 2

blebleble





