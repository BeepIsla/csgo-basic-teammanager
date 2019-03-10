public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if (GetConVarBool(g_hForceAssignTeams) != true/* || GetConVarBool(g_hDisableTeamMenu) != true*/)
	{
		SetConVarBool(g_hForceAssignTeams, true);
		// SetConVarBool(g_hDisableTeamMenu, true);
	}
}
