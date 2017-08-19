Handle	g_fwdOnWardenChoosing,
		g_fwdOnWardenChosen,
		g_fwdOnWardenZamChosen,
		g_fwdOnWardenResign,
		g_fwdOnWardenResigned,
		g_fwdOnWardenZamResigned;

void Forward_Initialization()
{
	g_fwdOnWardenChoosing = CreateGlobalForward("JWP_OnWardenChoosing", ET_Hook);
	g_fwdOnWardenChosen = CreateGlobalForward("JWP_OnWardenChosen", ET_Ignore, Param_Cell);
	g_fwdOnWardenZamChosen = CreateGlobalForward("JWP_OnWardenZamChosen", ET_Ignore, Param_Cell);
	g_fwdOnWardenResign = CreateGlobalForward("JWP_OnWardenResign", ET_Hook, Param_Cell);
	g_fwdOnWardenResigned = CreateGlobalForward("JWP_OnWardenResigned", ET_Ignore, Param_Cell, Param_Cell);
	g_fwdOnWardenZamResigned = CreateGlobalForward("JWP_OnWardenZamResigned", ET_Ignore, Param_Cell);
}

bool Forward_OnWardenChoosing()
{
	bool status = true;
	Call_StartForward(g_fwdOnWardenChoosing);
	if (Call_Finish(status) != SP_ERROR_NONE)
		LogToFile(LOG_PATH, "Forward_OnWardenChoosing error");
	
	return status;
}

void Forward_OnWardenChosen(int client)
{
	Call_StartForward(g_fwdOnWardenChosen);
	Call_PushCell(client);
	if (Call_Finish() != SP_ERROR_NONE)
		LogToFile(LOG_PATH, "Forward_OnWardenChosen error");
}

void Forward_OnWardenZamChosen(int client)
{
	Call_StartForward(g_fwdOnWardenZamChosen);
	Call_PushCell(client);
	if (Call_Finish() != SP_ERROR_NONE)
		LogToFile(LOG_PATH, "Forward_OnWardenZamChosen error");
}

bool Forward_OnWardenResign(int client)
{
	bool status = true;
	Call_StartForward(g_fwdOnWardenResign);
	Call_PushCell(client);
	if (Call_Finish(status) != SP_ERROR_NONE)
		LogToFile(LOG_PATH, "Forward_OnWardenResign error");
	
	return status;
}

void Forward_OnWardenResigned(int client, bool themself)
{
	Call_StartForward(g_fwdOnWardenResigned);
	Call_PushCell(client);
	Call_PushCell(themself);
	if (Call_Finish() != SP_ERROR_NONE)
		LogToFile(LOG_PATH, "Forward_OnWardenResigned error");
}

void Forward_OnWardenZamResigned(int client)
{
	Call_StartForward(g_fwdOnWardenZamResigned);
	Call_PushCell(client);
	if (Call_Finish() != SP_ERROR_NONE)
		LogToFile(LOG_PATH, "Forward_OnWardenZamResigned error");
}