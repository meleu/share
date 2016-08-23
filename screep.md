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



## Runcommand

The runcommand menu is what is run every time you play a game, It is what allows you to change emulators, set video resolutions, among other things. One lesser known function is the ability to add customised scripts to be executed on the start and/or on the end of the game.

The `runcommand-onstart.sh` script is executed (if exists) before the game starts, and `runcommand-onend.sh` is executed (if exists) after you exit the emulator. Both files must be at `/opt/retropie/configs/all/` directory.



## scraping methods

Here we have two methods to scrape your own screenshots:

**Method 1**: uses the `runcommand-onstart.sh` to automatically set some screenshot related configs in system specifics `retroarch.cfg` files. And after you take some screenshots from differente games, you use the SSelph scraper to create a `gamelist.xml` with your screenshots.

**Method 2**: uses the `runcommand-onend.sh` to automatically set the most recent screenshot from a game to be the emulationstation image for the respective game.

The main difference between them is:

- Method 1: automates the `retroarch.cfg` configs but the scraping process is done manually.

- Method 2: `retroarch.cfg` configs are done manually but automates the placement of your screenshots as the respective emulationstation game images.


## method 1

blablabla


## method 2

blebleble
