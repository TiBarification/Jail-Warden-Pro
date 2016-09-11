void Load_SortingWardenMenu()
{
	KeyValues kv = new KeyValues("warden_menu", "", "");
	if (kv.ImportFromFile("cfg/jwp/warden_menu.txt"))
	{
		if (kv.GotoFirstSubKey(true))
		{
			char menuitem[64];
			int iFlag;
			do
			{
				if (kv.GetSectionName(menuitem, sizeof(menuitem)))
				{
					g_aSortedMenu.PushString(menuitem);
					// Flag finder
					kv.GetString("flag", menuitem, sizeof(menuitem), "");
					iFlag = ReadFlagString(menuitem);
					g_aFlags.Push(iFlag);
				}
			} while (kv.GotoNextKey(true));
		}
		else
			LogToFile(LOG_PATH, "[ERROR] GotoFirstSubKey error: cfg/jwp/warden_menu.txt");
	}
	else
		LogToFile(LOG_PATH, "[ERROR] Import file error: cfg/jwp/warden_menu.txt");
	delete kv;
}