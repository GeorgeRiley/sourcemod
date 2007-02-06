#define LEVEL_STATE_NONE		0
#define LEVEL_STATE_LEVELS		1
#define LEVEL_STATE_FLAGS		2

static Handle:g_hLevelParser = INVALID_HANDLE;
static g_LevelState = LEVEL_STATE_NONE;

/* :TODO: log line numbers? */

LoadDefaultLetters()
{
	for (new i='t'; i<'z'; i++)
	{
		g_FlagsSet[i-'a'] = false;
	}
	
	g_FlagLetters['a'-'a'] = Admin_Reservation;
	g_FlagLetters['b'-'a'] = Admin_Kick;
	g_FlagLetters['c'-'a'] = Admin_Ban;
	g_FlagLetters['d'-'a'] = Admin_Unban;
	g_FlagLetters['e'-'a'] = Admin_Slay;
	g_FlagLetters['f'-'a'] = Admin_Changemap;
	g_FlagLetters['g'-'a'] = Admin_Convars;
	g_FlagLetters['h'-'a'] = Admin_Config;
	g_FlagLetters['i'-'a'] = Admin_Chat;
	g_FlagLetters['j'-'a'] = Admin_Vote;
	g_FlagLetters['k'-'a'] = Admin_Password;
	g_FlagLetters['l'-'a'] = Admin_RCON;
	g_FlagLetters['m'-'a'] = Admin_Cheats;
	g_FlagLetters['n'-'a'] = Admin_Custom1;
	g_FlagLetters['o'-'a'] = Admin_Custom2;
	g_FlagLetters['p'-'a'] = Admin_Custom3;
	g_FlagLetters['q'-'a'] = Admin_Custom4;
	g_FlagLetters['r'-'a'] = Admin_Custom5;
	g_FlagLetters['s'-'a'] = Admin_Custom6;
	g_FlagLetters['z'-'a'] = Admin_Root;
}

static LogLevelError(const String:format[], {Handle,String,Float,_}:...)
{
	decl String:buffer[512];
	
	if (!g_LoggedFileName)
	{
		LogError("Error(s) detected parsing admin_levels.cfg:");
		g_LoggedFileName = true;
	}
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	LogError(" (%d) %s", ++g_ErrorCount, buffer);
}

public SMCResult:ReadLevels_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if (g_LevelState == LEVEL_STATE_NONE)
	{
		if (StrEqual(name, "Levels"))
		{
			g_LevelState = LEVEL_STATE_LEVELS;
		}
	} else if (g_LevelState == LEVEL_STATE_LEVELS) {
		if (StrEqual(name, "Flags"))
		{
			g_LevelState = LEVEL_STATE_FLAGS;
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult:ReadLevels_KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (g_LevelState == LEVEL_STATE_FLAGS)
	{
		new chr = value[0];
		
		if (chr < 'a' || chr > 'z')
		{
			LogLevelError("Unrecognized character: \"%s\"", value);
			return SMCParse_Continue;
		}
		
		chr -= 'a';
		
		new AdminFlag:flag;
		
		if (StrEqual(key, "reservation"))
		{
			flag = Admin_Reservation;
		} else if (StrEqual(key, "kick")) {
			flag = Admin_Kick;
		} else if (StrEqual(key, "ban")) {
			flag = Admin_Ban;
		} else if (StrEqual(key, "unban")) {
			flag = Admin_Unban;
		} else if (StrEqual(key, "slay")) {
			flag = Admin_Slay;
		} else if (StrEqual(key, "changemap")) {
			flag = Admin_Changemap;
		} else if (StrEqual(key, "cvars")) {
			flag = Admin_Convars;
		} else if (StrEqual(key, "config")) {
			flag = Admin_Config;
		} else if (StrEqual(key, "chat")) {
			flag = Admin_Chat;
		} else if (StrEqual(key, "vote")) {
			flag = Admin_Vote;
		} else if (StrEqual(key, "password")) {
			flag = Admin_Password;
		} else if (StrEqual(key, "rcon")) {
			flag = Admin_RCON;
		} else if (StrEqual(key, "cheats")) {
			flag = Admin_Cheats;
		} else if (StrEqual(key, "root")) {
			flag = Admin_Root;
		} else if (StrEqual(key, "custom1")) {
			flag = Admin_Custom1;
		} else if (StrEqual(key, "custom2")) {
			flag = Admin_Custom2;
		} else if (StrEqual(key, "custom3")) {
			flag = Admin_Custom3;
		} else if (StrEqual(key, "custom4")) {
			flag = Admin_Custom4;
		} else if (StrEqual(key, "custom5")) {
			flag = Admin_Custom5;
		} else if (StrEqual(key, "custom6")) {
			flag = Admin_Custom6;
		} else {
			LogLevelError("Unrecognized flag type: %s", key);
		}
		
		g_FlagLetters[chr] = flag;
		g_FlagsSet[chr] = true;
	}
	
	return SMCParse_Continue;
}

public SMCResult:ReadLevels_EndSection(Handle:smc)
{
	if (g_LevelState == LEVEL_STATE_FLAGS)
	{
		/* We're totally done parsing */
		g_LevelState = LEVEL_STATE_LEVELS;
		return SMCParse_Halt;
	} else if (g_LevelState == LEVEL_STATE_LEVELS) {
		g_LevelState = LEVEL_STATE_NONE;
	}
	
	return SMCParse_Continue;
}

static InitializeLevelParser()
{
	if (g_hLevelParser == INVALID_HANDLE)
	{
		g_hLevelParser = SMC_CreateParser();
		SMC_SetReaders(g_hLevelParser, 
				   	ReadLevels_NewSection,
				   	ReadLevels_KeyValue,
				   	ReadLevels_EndSection);
	}
}

RefreshLevels()
{
	new String:path[PLATFORM_MAX_PATH];
	
	LoadDefaultLetters();
	InitializeLevelParser();
	
	BuildPath(Path_SM, path, sizeof(path), "configs/admin_levels.cfg");
	
	/* Set states */
	g_LevelState = LEVEL_STATE_NONE;
	g_LoggedFileName = false;
	g_ErrorCount = 0;
		
	new SMCError:err = SMC_ParseFile(g_hLevelParser, path);
	if (err != SMCError_Okay)
	{
		decl String:buffer[64];
		if (SMC_GetErrorString(err, buffer, sizeof(buffer)))
		{
			LogLevelError("%s", buffer);
		} else {
			LogLevelError("Fatal parse error");
		}
	}
}
