# Basic Teammanager
Basic team forcing all controlled with a single file. Hopefully there are no bugs, this hasn't been tested a lot, or at all.

A compiled version can be found [here](/client/plugin.smx).

---

# team_setup.txt
The [team_setup.txt](/client/team_setup.txt) file needs to be located in this folder: `<csgo_ds>/csgo/addons/sourcemod/team_setup.txt`. Its setup is very specific but following the example [team_setup.txt](/client/team_setup.txt) should be easy.

**If you want to use avatars the backend server is required. The backend server requires [ImageMagick](https://www.imagemagick.org/) to turn PNG's into RGB files.**

Simply put a file with the SteamID64 as name into the `avatars` folder. From there the server will automatically convert them into RGB files upon request and send them to your gameserver.
