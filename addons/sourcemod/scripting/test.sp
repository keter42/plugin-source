#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#include <sdktools>
#include <sdkhooks>
#include <colorvariables>
#include <getoverit>

int nZombieCount = 0;
float g_pos[3];

public void OnPluginStart() {
    HookUserMessage(GetUserMessageId("GameMessage"), OnUserMessage, true);
    HookUserMessage(GetUserMessageId("BecameInfected"), OnUserMessage, true);
    HookUserMessage(GetUserMessageId("InfectionCured"), OnUserMessage, true);
    HookUserMessage(GetUserMessageId("Cure"), OnUserMessage, true);

    RegAdminCmd("sm_tmi", TestMotdIndex, ADMFLAG_GENERIC);

    RegAdminCmd("sm_count", CountZombies, ADMFLAG_GENERIC);
    RegAdminCmd("sm_make", MakeZombies, ADMFLAG_GENERIC);
}

public Action OnUserMessage(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
    PrintToServer("msg %d: ", msg_id);
    for (int i = 0; bf.BytesLeft > 0; i++) {
        PrintToServer("%d", bf.ReadByte());
    }
    PrintToServer("Player: ");
    for (int i = 0; i < playersNum; i++) {
        PrintToServer("%d", players[i]);
    }
    return Plugin_Continue;
}

public void ShowHiddenMOTDPanel(int client, char[] url, int type)
{
    Handle setup = CreateKeyValues("data");
    KvSetString(setup, "title", "请点击播放按钮！");
    KvSetNum(setup, "type", type);
    KvSetString(setup, "msg", url);
    ShowVGUIPanel(client, "info", setup, false);
    delete setup;
}

public void ShowNotHiddenMOTDPanel(int client, char[] url, int type)
{
    Handle setup = CreateKeyValues("data");
    KvSetString(setup, "title", "请点击播放按钮！");
    KvSetNum(setup, "type", type);
    KvSetString(setup, "msg", url);
    ShowVGUIPanel(client, "info", setup, true);
    delete setup;
}

public Action TestMotdIndex(int client, int args)
{
    char msg[128];
    GetCmdArgString(msg, sizeof(msg));
    SetLongMOTD("motd_text", msg);
    ShowNotHiddenMOTDPanel(client, "motd_text", MOTDPANEL_TYPE_INDEX);
}

bool SetLongMOTD(const String:panel[],const String:text[]) {
    int table = FindStringTable("InfoPanel");

    if(table != INVALID_STRING_TABLE) {
        int len = strlen(text);
        int str = FindStringIndex(table,panel);
        bool locked = LockStringTables(false);

        SetStringTableData(table,str,text,len);

        LockStringTables(locked);
        return true;
    }

    return false;
}

public Action CountZombies(int client, int args)
{
    int n = 0, i = MaxClients + 1, max = GetMaxEntities();
    char classname[30];
    while (i < max) {
        if (IsValidEntity(i)) {
            GetEntityClassname(i, classname, 30);
            if (StrEqual(classname, "npc_nmrih_runnerzombie"))
                n += 1;
            else if (StrEqual(classname, "npc_nmrih_kidzombie"))
                n += 1;
            else if (StrEqual(classname, "npc_nmrih_turnedzombie"))
                n += 1;
        }
        i += 1;
    }
    CPrintToChat(client, "当前有 {red}%d 个僵尸", n);
}

public Action MakeZombies(int client, int args)
{
    decl Float:vAngles[3];
    decl Float:vOrigin[3];
    decl Float:vBuffer[3];
    decl Float:vStart[3];
    decl Float:Distance;
    
    GetClientEyePosition(client,vOrigin);
    GetClientEyeAngles(client, vAngles);
    
    //get endpoint for teleport
    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
        
    if(TR_DidHit(trace))
    {   
        TR_GetEndPosition(vStart, trace);
        GetVectorDistance(vOrigin, vStart, false);
        Distance = -35.0;
        GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
        g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
        g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
        g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
    }
    else
    {
        CloseHandle(trace);
        return Plugin_Handled;
    }

    char str[10];
    GetCmdArg(1, str, 10);
    nZombieCount = StringToInt(str);

    if (nZombieCount == 0) nZombieCount = 1;
    
    CreateTimer(0.1, DelayCreateZombie, _, TIMER_REPEAT);
    
    CloseHandle(trace);
    return Plugin_Handled;
}

public Action DelayCreateZombie(Handle timer) {
    if (--nZombieCount >= 0) {
        int zombie = CreateEntityByName("npc_nmrih_runnerzombie");
        if(!IsValidEntity(zombie)) return Plugin_Continue;
        if(DispatchSpawn(zombie)) TeleportEntity(zombie, g_pos, NULL_VECTOR, NULL_VECTOR);
    }
    else return Plugin_Stop;
    return Plugin_Continue;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) 
{
    return entity > MaxClients;
}  
