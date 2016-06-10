Handle	g_fwdOnWardenChoosing,
		g_fwdOnWardenChosen,
		g_fwdOnWardenZamChosen,
		g_fwdOnWardenResign,
		g_fwdOnWardenResigned;

void Forward_Initialization()
{
	g_fwdOnWardenChoosing = CreateGlobalForward("JWP_OnWardenChoosing", ET_Hook);
	g_fwdOnWardenChosen = CreateGlobalForward("JWP_OnWardenChosen", ET_Ignore, Param_Cell);
	g_fwdOnWardenZamChosen = CreateGlobalForward("JWP_OnWardenZamChosen", ET_Ignore, Param_Cell);
	g_fwdOnWardenResign = CreateGlobalForward("JWP_OnWardenResign", ET_Hook, Param_Cell);
	g_fwdOnWardenResigned = CreateGlobalForward("JWP_OnWardenResigned", ET_Ignore, Param_Cell, Param_Cell);
}

bool Forward_OnWardenChoosing()
{
	bool status = true;
	Call_StartForward(g_fwdOnWardenChoosing);
	Call_Finish(status);
	
	return status;
}

void Forward_OnWardenChosen(int client)
{
	Call_StartForward(g_fwdOnWardenChosen);
	Call_PushCell(client);
	Call_Finish();
}

void Forward_OnWardenZamChosen(int client)
{
	Call_StartForward(g_fwdOnWardenZamChosen);
	Call_PushCell(client);
	Call_Finish();
}

bool Forward_OnWardenResign(int client)
{
	bool status = true;
	Call_StartForward(g_fwdOnWardenResign);
	Call_PushCell(client);
	Call_Finish(status);
	
	return status;
}

void Forward_OnWardenResigned(int client, bool themself)
{
	Call_StartForward(g_fwdOnWardenResigned);
	Call_PushCell(client);
	Call_PushCell(themself);
	Call_Finish();
}