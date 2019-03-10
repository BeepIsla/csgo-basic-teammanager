stock bool areTeamsSwitched()
{
	// Works best with even numbers for "mp_maxrounds" and "mp_overtime_maxrounds". Not tested on odd numbers (Who uses those anyways?)
	int maxRounds = GetConVarInt(FindConVar("mp_maxrounds"));
	int maxRoundsOT = GetConVarInt(FindConVar("mp_overtime_maxrounds"));
	int amountOfOvertimes = 0;
	int curRound = GameRules_GetProp("m_totalRoundsPlayed");
	int gamePhase = GameRules_GetProp("m_gamePhase");

	if (gamePhase == 4 || gamePhase == 5) // Halftime or PostGame (Credit: https://github.com/splewis/get5/blob/master/scripting/get5/util.sp#L19)
	{
		curRound--;
	}

	if (curRound >= RoundFloat(float(maxRounds / 2)) && curRound <= maxRounds)
	{
		return true;
	}
	else if (curRound <= maxRounds)
	{
		return false;
	}
	else
	{
		amountOfOvertimes++;
		curRound -= maxRounds;
		while (curRound >= maxRoundsOT)
		{
			curRound -= maxRoundsOT;
			amountOfOvertimes++;
		}

		if ((amountOfOvertimes % 2) == 1) // Is "amountOfOvertimes" odd?
		{
			if (curRound >= RoundFloat(float(maxRoundsOT / 2)) && curRound <= maxRoundsOT)
			{
				return false;
			}
			else if (curRound <= maxRoundsOT)
			{
				return true;
			}
		}
		else
		{
			if (curRound >= RoundFloat(float(maxRoundsOT / 2)) && curRound <= maxRoundsOT)
			{
				return true;
			}
			else if (curRound <= maxRoundsOT)
			{
				return false;
			}
		}
	}

	// Code should never reach down here
	return false;
}

void DownloadAvatar(char[] baseURL, char[] id/*, char[] authToken*/) {
	Handle httpRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, baseURL);

	/*if (SteamWorks_SetHTTPRequestHeaderValue(httpRequest, "auth", authToken) == false) {
		CloseHandle(httpRequest);
		PrintToServer("[%s] Failed to set header value", id);
		return;
	}*/

	if (SteamWorks_SetHTTPRequestGetOrPostParameter(httpRequest, "id", id) == false) {
		CloseHandle(httpRequest);
		PrintToServer("[%s] Failed to set GET parameter", id);
		return;
	}

	if (SteamWorks_SetHTTPCallbacks(httpRequest, SteamWorksHTTPRequestCompleted) == false) {
		CloseHandle(httpRequest);
		PrintToServer("[%s] Failed to set callback", id);
		return;
	}

	if (SteamWorks_SendHTTPRequest(httpRequest) == false) {
		CloseHandle(httpRequest);
		PrintToServer("[%s] Failed to send HTTP request", id);
		return;
	}

	PrintToServer("[%s] Sending HTTP request...", id);
	return;
}

int SteamWorksHTTPRequestCompleted(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode) {
	if (eStatusCode == k_EHTTPStatusCode408RequestTimeout || eStatusCode == k_EHTTPStatusCode504GatewayTimeout) {
		PrintToServer("Failed to send request - Timeout - %d", eStatusCode);
		CloseHandle(hRequest);
		return;
	}

	char id[512];
	if (SteamWorks_GetHTTPResponseHeaderValue(hRequest, "id", id, sizeof(id)) == false) {
		PrintToServer("Failed to get ID header");
		CloseHandle(hRequest);
		return;
	}

	if (eStatusCode != k_EHTTPStatusCode200OK) {
		char errorPrint[1024];
		Format(errorPrint, sizeof(errorPrint), "[%s]", id);

		if (eStatusCode == k_EHTTPStatusCode400BadRequest) {
			Format(errorPrint, sizeof(errorPrint), "%s Sent an invalid request", errorPrint);
		} else if (eStatusCode == k_EHTTPStatusCode204NoContent) {
			Format(errorPrint, sizeof(errorPrint), "%s File does not exist on download server", errorPrint);
		} else {
			Format(errorPrint, sizeof(errorPrint), "%s Did not get response 200 but got %d", errorPrint, eStatusCode);
		}

		PrintToServer(errorPrint);
		CloseHandle(hRequest);
		return;
	}

	if (bRequestSuccessful == false || bFailure == true) {
		PrintToServer("[%s] Request failed for one reason or another", id);
		CloseHandle(hRequest);
		return;
	}

	if (DirExists("./avatars") == false) {
		CreateDirectory("./avatars", 511);
	}

	char path[512];
	Format(path, sizeof(path), "./avatars/%s.rgb", id);

	if (SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path) == false) {
		PrintToServer("[%s] Failed to save file", id);
		CloseHandle(hRequest);
		return;
	}

	PrintToServer("[%s] Successfully saved file", id);
	CloseHandle(hRequest);
}

/*
	Credit: https://github.com/powerlord/sourcemod-tf2-scramble/blob/master/addons/sourcemod/scripting/include/valve.inc#L18
*/
void PrintValveTranslation(int[] clients, int numClients, int msg_dest, const char[] msg_name, const char[] param1 = "", const char[] param2 = "", const char[] param3 = "", const char[] param4 = "")
{
	Handle bf = StartMessage("TextMsg", clients, numClients, USERMSG_RELIABLE);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(bf, "msg_dst", msg_dest);
		PbAddString(bf, "params", msg_name);
		
		PbAddString(bf, "params", param1);
		PbAddString(bf, "params", param2);
		PbAddString(bf, "params", param3);
		PbAddString(bf, "params", param4);
	}
	else
	{
		BfWriteByte(bf, msg_dest);
		BfWriteString(bf, msg_name);
		
		BfWriteString(bf, param1);
		BfWriteString(bf, param2);
		BfWriteString(bf, param3);
		BfWriteString(bf, param4);
	}
	
	EndMessage();
}

void PrintValveTranslationToAll(int msg_dest, const char[] msg_name, const char[] param1 = "", const char[] param2 = "", const char[] param3 = "", const char[] param4 = "")
{
	int total = 0;
	int clients[MAXPLAYERS];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			clients[total++] = i;
		}
	}

	PrintValveTranslation(clients, total, msg_dest, msg_name, param1, param2, param3, param4);
}
