#pragma semicolon 1

#include <sourcemod>
#include <colors>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required

bool g_bServerLock = false;
char g_sWhiteList[512];
char g_sPatch[256];
Handle g_hKV = INVALID_HANDLE;

TopMenu g_hAdminMenu = null;

public Plugin myinfo =  
{
	name = "Server Lock",
	author = "d4Ck(vk.com/geliydaun)",
	version = "1.0.1",
	url = "http://crystals.pw/"
};

public void OnPluginStart()
{	
	BuildPath(Path_SM, g_sPatch, sizeof(g_sPatch), "configs/server_lock.ini"); 

	if (LibraryExists("adminmenu")) 
	{
		TopMenu hTopMenu;
		hTopMenu = GetAdminTopMenu();
		if (hTopMenu != null)
		{
			OnAdminMenuReady(hTopMenu);
		}
	}
	
	RegAdminCmd("sm_sl_lock", cmdLockAdmin, ADMFLAG_ROOT);
	RegServerCmd("sm_sl_lock", cmdLock);
	
	RegAdminCmd("sm_sl_reload", cmdReloadAdmin, ADMFLAG_ROOT);
	RegServerCmd("sm_sl_reload", cmdReload);
	
	LoadCfg();
}

public void OnLibraryRemoved(const char[] szName)
{
    if (StrEqual(szName, "adminmenu")) 
		g_hAdminMenu = null;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);

	if (hTopMenu == g_hAdminMenu)
		return;

	g_hAdminMenu = hTopMenu;

	TopMenuObject hMyCategory = g_hAdminMenu.FindCategory("ServerCommands");

	if (hMyCategory != INVALID_TOPMENUOBJECT)
	{
		g_hAdminMenu.AddItem("lock_server", LockServer_Callback, hMyCategory, "lock_server", ADMFLAG_ROOT, "Закрыть/Открыть сервер");
	}
}

public void LockServer_Callback(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int client, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(sBuffer, maxlength, g_bServerLock ? "Открыть сервер" : "Закрыть сервер");
		}
		case TopMenuAction_SelectOption:
		{
			ServerCommand("sm_sl_lock");
		}
	}
}

public Action cmdLockAdmin(int client, int args)
{
	ServerCommand("sm_sl_lock");
}

public Action cmdReloadAdmin(int client, int args)
{
	ServerCommand("sm_sl_lock");
}

public Action cmdReload(int args)
{
	LoadCfg();
	
	return Plugin_Handled;
}

public Action cmdLock(int args)
{
	PrintToServer("[ServerLock] Сервер успешно %s!", g_bServerLock ? "открыт" : "закрыт");
	PrintToChatAll(" \x04[ServerLock] \x01Сервер успешно %s!", g_bServerLock ? "открыт" : "закрыт");
	
	LoadCfg();
	
	KvSetNum(g_hKV, "server_lock", (g_bServerLock ? 0 : 1));
	KvSetString(g_hKV, "white_list", g_sWhiteList);
	KeyValuesToFile(g_hKV, g_sPatch); 
	
	LoadCfg();
	
	return Plugin_Handled;
}

stock void LoadCfg()
{
	if(g_hKV != INVALID_HANDLE) CloseHandle(g_hKV);
	
	g_hKV = CreateKeyValues("Settings");
	if(!FileToKeyValues(g_hKV, g_sPatch))
		SetFailState("[ServerLock] Конфигурационный файл не найден");
		
	g_bServerLock = view_as<bool>(KvGetNum(g_hKV, "server_lock", 0));
	KvGetString(g_hKV, "white_list", g_sWhiteList, sizeof(g_sWhiteList), "0");
	
	if(g_bServerLock) KickPlayers();
}

public void OnClientPostAdminCheck(int client)
{	
	if(g_bServerLock && !IsFakeClient(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT) == 0)
	{
		char sAuth[32];
		GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));  
		
		if(StrContains(g_sWhiteList, sAuth, false) == -1)
			KickClient(client, "Доступ к серверу временно ограничен!\nПожалуйста попробуйте позже");
	}
}

stock void KickPlayers()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}