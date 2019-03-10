# Basic Teammanager
Basic team forcing all controlled with a single file. Hopefully there are no bugs, this hasn't been tested a lot, or at all.

---

# team_setup.txt
Thea team_setup.txt file needs to be located in this folder: `<csgo_ds>/csgo/addons/sourcemod/team_setup.txt`. Its setup is very specific but following the example `team_setup.txt`  shoudl be easy.

**If you want to use avatars the backend server is required. The backend server requires [ImageMagick](https://www.imagemagick.org/) to turn PNG's into RGB files.**

Simply put a file with the SteamID64 as name into the `avatars` folder. From there there server will automatically convert them into RGB files upon request and send them to your gameserver.
