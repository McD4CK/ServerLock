#pragma semicolon 1

#include <sourcemod>
#include <colors>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required

bool g_bServerLock;
char g_sWhiteList[512];
char g_sPatch[256];
Handle g_hKV;

TopMenu g_hAdminMenu = null;

public Plugin myinfo =  
{
	name = "Server Lock",
	author = "d4Ck(vk.com/geliydaun)",
	version = "1.0.0",
	url = "http://crystals.pw/"
};

public void OnPluginStart()
{	
	BuildPath(Path_SM, g_sPatch, sizeof(g_sPatch), "configs/server_lock.ini"); 

	if (LibraryExists("adminmenu")) 
	{
		TopMenu hTopMenu = GetAdminTopMenu();
		if (hTopMenu != null)
		{
			OnAdminMenuReady(hTopMenu);
		}
	}
	
	RegAdminCmd("sm_sl_lock", cmdLock, ADMFLAG_ROOT);
	RegAdminCmd("sm_sl_reload", cmdReload, ADMFLAG_ROOT);
	
	LoadCfg();
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
			strcopy(sBuffer, maxlength, g_bServerLock ? "Открыть сервер" : "Закрыть сервер");
		}
		case TopMenuAction_SelectOption:
		{
			cmdLock(client, 0);
		}
	}
}

public Action cmdLock(int client, int args)
{
	if(client == 0) PrintToServer("[ServerLock] Сервер успешно %s!", g_bServerLock ? "открыт" : "закрыт");
	else PrintToChat(client, " \x04[ServerLock] \x01Сервер успешно %s!", g_bServerLock ? "открыт" : "закрыт");
	
	LoadCfg();
	
	KvSetNum(g_hKV, "server_lock", (g_bServerLock ? 0 : 1));
	KvSetString(g_hKV, "white_list", g_sWhiteList);
	KeyValuesToFile(g_hKV, g_sPatch); 
	
	LoadCfg();
	
	return Plugin_Handled;
}

public Action cmdReload(int client, int args)
{
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