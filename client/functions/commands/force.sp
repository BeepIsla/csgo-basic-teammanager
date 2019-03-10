public Action Command_Force(int client, int args)
{
	// Remove the client names restriction
	ServerCommand("sv_load_forced_client_names_file");

	// Array of usernames and steamIDs
	char steamIDs[128][MAXPLAYERS];
	char customNames[128][MAXPLAYERS];

	char path[PLATFORM_MAX_PATH];
	char line[128];
	bool movedPlayer[MAXPLAYERS];
	char avatarsURL[512];
	int currentlySelecting = -1;
	// -1 = Spectator
	//  0 = CT
	//  1 = T
	//  2 = CT_Coach
	//  3 = T_Coach
	//  4 = Avatars

	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "team_setup.txt");
	Handle fileHandle = OpenFile(path, "r");
	while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
	{
		TrimString(line);
		if (strlen(line) <= 0) continue;

		if (strcmp(line, "# SPECTATORS") == 0)
		{
			// Spectators
			currentlySelecting = -1;
			continue;
		}
		else if (strncmp(line, "# TEAM 1:", 9, true) == 0)
		{
			// Get team 1 name
			ReplaceStringEx(line, sizeof(line), "# TEAM 1:", "", -1, -1, true);
			SetConVarString(FindConVar("mp_teamname_1"), line);

			// Team 1 selection
			currentlySelecting = 0;
			continue;
		}
		else if (strncmp(line, "# TEAM 2:", 9, true) == 0)
		{
			// Get team 2 name
			ReplaceStringEx(line, sizeof(line), "# TEAM 2:", "", -1, -1, true);
			SetConVarString(FindConVar("mp_teamname_2"), line);

			// Team 2 selection
			currentlySelecting = 1;
			continue;
		}
		else if (strcmp(line, "# TEAM 1 COACH", true) == 0)
		{
			// Team 1 Coach
			currentlySelecting = 2;
			continue;
		}
		else if (strcmp(line, "# TEAM 2 COACH", true) == 0)
		{
			// Team 2 Coach
			currentlySelecting = 3;
			continue;
		}
		else if (strncmp(line, "# AVATARS:", 10, true) == 0)
		{
			ReplaceStringEx(line, sizeof(line), "# AVATARS:", "", -1, -1, true);
			TrimString(line);
			avatarsURL = line;
			currentlySelecting = 4;
			continue;
		}

		if (currentlySelecting == 4) {
			if (strlen(avatarsURL) < 5) {
				PrintToServer("Invalid avatars URL. Cannot download files.");
				continue;
			}

			DownloadAvatar(avatarsURL, line);
			continue;
		}

		// Parse SteamID out of line
		// line_SteamID64 will be the SteamID and line the custom player name to use
		char line_SteamID64[512];
		SplitString(line, " ", line_SteamID64, sizeof(line_SteamID64));
		TrimString(line);
		if (strlen(line_SteamID64) <= 1)
		{
			// No custom name defined
			strcopy(line_SteamID64, sizeof(line_SteamID64), line);
		}
		ReplaceStringEx(line, sizeof(line), line_SteamID64, "", -1, -1, true);
		TrimString(line);

		// Fix name
		ReplaceString(line, sizeof(line), "\\", "\\\\");
		ReplaceString(line, sizeof(line), "\"", "");

		if (currentlySelecting == -1)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					char SteamID64[512];
					GetClientAuthId(i, AuthId_SteamID64, SteamID64, sizeof(SteamID64));

					if (strcmp(line_SteamID64, SteamID64, true) == 0)
					{
						ChangeClientTeam(i, CS_TEAM_SPECTATOR);
						SetEntProp(i, Prop_Send, "m_iCoachingTeam", 0);
						movedPlayer[i] = true;

						Format(steamIDs[i], 512, "%s", SteamID64);
						Format(customNames[i], 512, "%s", line);
					}
				}
			}
		}
		else if (currentlySelecting == 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					char SteamID64[512];
					GetClientAuthId(i, AuthId_SteamID64, SteamID64, sizeof(SteamID64));

					if (strcmp(line_SteamID64, SteamID64, true) == 0)
					{
						if (areTeamsSwitched() == false) ChangeClientTeam(i, CS_TEAM_CT);
						else ChangeClientTeam(i, CS_TEAM_T);
						CS_UpdateClientModel(i);
						movedPlayer[i] = true;

						Format(steamIDs[i], 512, "%s", SteamID64);
						Format(customNames[i], 512, "%s", line);
					}
				}
			}
		}
		else if (currentlySelecting == 1)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					char SteamID64[512];
					GetClientAuthId(i, AuthId_SteamID64, SteamID64, sizeof(SteamID64));

					if (strcmp(line_SteamID64, SteamID64, true) == 0)
					{
						if (areTeamsSwitched() == false) ChangeClientTeam(i, CS_TEAM_T);
						else ChangeClientTeam(i, CS_TEAM_CT);
						CS_UpdateClientModel(i);
						movedPlayer[i] = true;

						Format(steamIDs[i], 512, "%s", SteamID64);
						Format(customNames[i], 512, "%s", line);
					}
				}
			}
		}
		else if (currentlySelecting == 2)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					char SteamID64[512];
					GetClientAuthId(i, AuthId_SteamID64, SteamID64, sizeof(SteamID64));

					if (strcmp(line_SteamID64, SteamID64, true) == 0)
					{
						char ClientName[512];
						GetClientName(i, ClientName, sizeof(ClientName));
						if (areTeamsSwitched() == false) PrintValveTranslationToAll(3, "#CSGO_Coach_Join_CT", ClientName);
						else PrintValveTranslationToAll(3, "#CSGO_Coach_Join_T", ClientName);

						ChangeClientTeam(i, CS_TEAM_SPECTATOR);
						if (areTeamsSwitched() == false) SetEntProp(i, Prop_Send, "m_iCoachingTeam", 3);
						else SetEntProp(i, Prop_Send, "m_iCoachingTeam", 2);
						movedPlayer[i] = true;

						Format(steamIDs[i], 512, "%s", SteamID64);
						Format(customNames[i], 512, "%s", line);
					}
				}
			}
		}
		else if (currentlySelecting == 3)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					char SteamID64[512];
					GetClientAuthId(i, AuthId_SteamID64, SteamID64, sizeof(SteamID64));

					if (strcmp(line_SteamID64, SteamID64, true) == 0)
					{
						char ClientName[512];
						GetClientName(i, ClientName, sizeof(ClientName));
						if (areTeamsSwitched() == false) PrintValveTranslationToAll(3, "#CSGO_Coach_Join_T", ClientName);
						else PrintValveTranslationToAll(3, "#CSGO_Coach_Join_CT", ClientName);

						ChangeClientTeam(i, CS_TEAM_SPECTATOR);
						if (areTeamsSwitched() == false) SetEntProp(i, Prop_Send, "m_iCoachingTeam", 2);
						else SetEntProp(i, Prop_Send, "m_iCoachingTeam", 3);
						movedPlayer[i] = true;

						Format(steamIDs[i], 512, "%s", SteamID64);
						Format(customNames[i], 512, "%s", line);
					}
				}
			}
		}
	}
	CloseHandle(fileHandle);

	// Move all unassigned players to spectator
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
		{
			if (movedPlayer[i] != true)
			{
				ChangeClientTeam(i, CS_TEAM_SPECTATOR);
				SetEntProp(i, Prop_Send, "m_iCoachingTeam", 0);
			}
		}
	}

	// Write forcednames.txt
	Handle hFile = OpenFile("forcednames.txt", "w");
	WriteFileLine(hFile, "\"Names\"");
	WriteFileLine(hFile, "{");
	for (int i = 0; i < sizeof(steamIDs); i++)
	{
		if (strlen(steamIDs[i]) <= 0) continue;
		if (strlen(customNames[i]) <= 0) continue;

		SetClientInfo(i, "name", customNames[i]);
		SetEntPropString(i, Prop_Data, "m_szNetname", customNames[i]);

		char toWrite[512];
		Format(toWrite, sizeof(toWrite), "	\"%s\" \"%s\"", steamIDs[i], customNames[i]);
		WriteFileLine(hFile, toWrite);
	}
	WriteFileLine(hFile, "}");
	CloseHandle(hFile);

	ServerCommand("sv_load_forced_client_names_file \"forcednames.txt\"");
}
