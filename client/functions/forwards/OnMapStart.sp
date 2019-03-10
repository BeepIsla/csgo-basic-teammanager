public void OnMapStart()
{
	// Remove the client names restriction
	ServerCommand("sv_load_forced_client_names_file");

	// Array of usernames and steamIDs
	char steamIDs[128][512];
	char customNames[128][512];

	// Setup file reading
	char path[PLATFORM_MAX_PATH];
	char line[128];
	int currentLine = 0;
	bool areProcessingAvatars = false;
	char avatarsURL[512];

	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "team_setup.txt");
	Handle fileHandle = OpenFile(path, "r");

	// Loop through each line in the file
	while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
	{
		// Keep track of the current line
		currentLine++;

		TrimString(line);

		// Ignore empty lines
		if (strlen(line) <= 0) continue;

		// Check if lines are team separators, set the team names and skip the line for further checking
		if (strcmp(line, "# SPECTATORS", true) == 0)
		{
			areProcessingAvatars = false;
			continue;
		}
		else if (strncmp(line, "# TEAM 1:", 9, true) == 0)
		{
			areProcessingAvatars = false;
			ReplaceStringEx(line, sizeof(line), "# TEAM 1:", "", -1, -1, true);
			TrimString(line);
			SetConVarString(FindConVar("mp_teamname_1"), line);
			continue;
		}
		else if (strncmp(line, "# TEAM 2:", 9, true) == 0)
		{
			areProcessingAvatars = false;
			ReplaceStringEx(line, sizeof(line), "# TEAM 2:", "", -1, -1, true);
			TrimString(line);
			SetConVarString(FindConVar("mp_teamname_2"), line);
			continue;
		}
		else if (strcmp(line, "# TEAM 1 COACH", true) == 0)
		{
			areProcessingAvatars = false;
			continue;
		}
		else if (strcmp(line, "# TEAM 2 COACH", true) == 0)
		{
			areProcessingAvatars = false;
			continue;
		}
		else if (strncmp(line, "# AVATARS:", 10, true) == 0)
		{
			ReplaceStringEx(line, sizeof(line), "# AVATARS:", "", -1, -1, true);
			TrimString(line);
			avatarsURL = line;
			areProcessingAvatars = true;
			continue;
		}

		if (areProcessingAvatars == true) {
			if (strlen(avatarsURL) < 5) {
				PrintToServer("Invalid avatars URL. Cannot download files.");
				continue;
			}

			DownloadAvatar(avatarsURL, line);
			continue;
		}

		// Parse SteamID out of line
		// "line_SteamID64" will be the SteamID and "line" the custom player name to use
		char line_SteamID64[512];
		SplitString(line, " ", line_SteamID64, sizeof(line_SteamID64));
		TrimString(line);

		// Check if there is a SteamID64 (If there is no custom name "line_SteamID64" will be empty)
		if (strlen(line_SteamID64) <= 1)
		{
			continue;
		}

		ReplaceStringEx(line, sizeof(line), line_SteamID64, "", -1, -1, true);
		TrimString(line);

		// Fix name
		ReplaceString(line, sizeof(line), "\\", "\\\\");
		ReplaceString(line, sizeof(line), "\"", "");

		// Set the SteamID64 and name in the arrays
		Format(steamIDs[currentLine], 128, "%s", line_SteamID64);
		Format(customNames[currentLine], 128, "%s", line);
	}
	// Dont forget to close the handle
	CloseHandle(fileHandle);

	// Write fresh forcednames.txt
	Handle hFile = OpenFile("forcednames.txt", "w");

	// Write default lines (http://blog.counter-strike.net/index.php/2017/10/19582/)
	WriteFileLine(hFile, "\"Names\"");
	WriteFileLine(hFile, "{");

	// Go through each steamID entry (will also have a name entry) and write to file
	for (int i = 0; i < sizeof(steamIDs); i++)
	{
		// Make sure none of them are empty
		if (strlen(steamIDs[i]) <= 0) continue;
		if (strlen(customNames[i]) <= 0) continue;

		// Format "toWrite" for proper formatting
		char toWrite[512];
		Format(toWrite, sizeof(toWrite), "	\"%s\" \"%s\"", steamIDs[i], customNames[i]);

		// Write line
		WriteFileLine(hFile, toWrite);
	}

	// Write closing line
	WriteFileLine(hFile, "}");

	// Dont forget to close the handle
	CloseHandle(hFile);

	// Enable the client names restriction
	ServerCommand("sv_load_forced_client_names_file \"forcednames.txt\"");
}
