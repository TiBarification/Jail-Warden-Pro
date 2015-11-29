void Load_SortingWardenMenu()
{
	KeyValues kv = new KeyValues("warden_menu", "", "");
	if (kv.ImportFromFile("cfg/jwp/warden_menu.txt"))
	{
		if (kv.GotoFirstSubKey(true))
		{
			char menuitem[64];
			int bFlag;
			do
			{
				if (kv.GetSectionName(menuitem, sizeof(menuitem)))
				{
					g_aSortedMenu.PushString(menuitem);
					// Flag finder
					kv.GetString("flag", menuitem, sizeof(menuitem), "");
					bFlag = ReadFlagString(menuitem);
					g_aFlags.Push(bFlag);
				}
			} while (kv.GotoNextKey(true));
		}
		else
			LogError("GotoFirstSubKey error: cfg/jwp/warden_menu.txt");
	}
	else
		LogError("ImportFile error: cfg/jwp/warden_menu.txt");
	delete kv;
}