Handle	g_fwdOnWardenChosen,
		g_fwdOnWardenZamChosen,
		g_fwdOnWardenResigned;

void Forward_Initialization()
{
	g_fwdOnWardenChosen = CreateGlobalForward("JWP_OnWardenChosen", ET_Ignore, Param_Cell);
	g_fwdOnWardenChosen = CreateGlobalForward("JWP_OnWardenZamChosen", ET_Ignore, Param_Cell);
	g_fwdOnWardenResigned = CreateGlobalForward("JWP_OnWardenResigned", ET_Ignore, Param_Cell, Param_Cell);
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

void Forward_OnWardenResigned(int client, bool themself)
{
	Call_StartForward(g_fwdOnWardenResigned);
	Call_PushCell(client);
	Call_PushCell(themself);
	Call_Finish();
}