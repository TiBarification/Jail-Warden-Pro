/**************************************************************************
 *                             CS:GO COLORS                               *
 *                     Автор: Феникс(komashchenko)                        *
 *                            Version: 1.4                                *
 *                  http://zizt.ru/  http://hlmod.ru/                     *
 * 03.07.2014 - V1.0: Релиз                                               *
 * 13.10.2014 - V1.1: Обнова                                              *
 * 24.10.2014 - V1.2: Обнова                                              *
 * 17.11.2014 - V1.3: Исправление ошибок                                  *
 * 23.12.2015 - V1.4: Исправление ошибок, Обнова                          *
 **************************************************************************/

#define ZCOLOR 13
 
static const char color_t[ZCOLOR][] = {"{DEFAULT}", "{RED}", "{LIGHTPURPLE}", "{GREEN}", "{LIME}", "{LIGHTGREEN}", "{LIGHTRED}", "{GRAY}", "{LIGHTOLIVE}", "{OLIVE}", "{LIGHTBLUE}", "{BLUE}", "{PURPLE}"},
	color_c[ZCOLOR][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0C", "\x0E"};
 

stock void CGOPrintToChat(int iClient, const char[] message, any ...)
{
	int a = strlen(message)+190, l;
	char[] b = new char[a];
	l = ReplaceString(b, VFormat(b, a, message, 3), "\n", "", false);
	for(int i; i < ZCOLOR; i++) ReplaceString(b, a, color_t[i], color_c[i]);
	if(l)
	{
		l++;
		char[][] s = new char[l][192];
		for (int m = ExplodeString(b, "", s, l, 192), p; p < m; p++) PrintToChat(iClient, " %s", s[p]);
	}
	else  PrintToChat(iClient, " %s", b);
}

stock void CGOPrintToChatAll(const char[] message, any ...)
{
	int a = strlen(message)+190, l;
	char[] b = new char[a];
	l = ReplaceString(b, VFormat(b, a, message, 2), "\n", "", false);
	for(int i = 0; i < ZCOLOR; i++) ReplaceString(b, a, color_t[i], color_c[i]);
	if(l)
	{
		l++;
		char[][] s = new char[l][192];
		for (int m = ExplodeString(b, "", s, l, 192), p; p < m; p++) PrintToChatAll(" %s", s[p]);
	}
	else  PrintToChatAll(" %s", b);
}

stock void CGOReplaceColorSay(char[] text, int maxlength)
{
	for(int i; i < ZCOLOR; i++) ReplaceString(text, maxlength, color_t[i], color_c[i]);
}

stock void GOPrintToChat(int iClient, const char[] message, any ...)
{
	int a = strlen(message)+190, l;
	char[] b = new char[a];
	if((l=ReplaceString(b, VFormat(b, a, message, 3), "\n", "", false)))
	{
		l++;
		char[][] s = new char[l][192];
		for (int m = ExplodeString(b, "", s, l, 192), p; p < m; p++) PrintToChat(iClient, s[p]);
	}
	else  PrintToChat(iClient, b);
}

stock void GOPrintToChatAll(const char[] message, any ...)
{
	int a = strlen(message)+190, l;
	char[] b = new char[a];
	if((l=ReplaceString(b, VFormat(b, a, message, 2), "\n", "", false)))
	{
		l++;
		char[][] s = new char[l][192];
		for (int m = ExplodeString(b, "", s, l, 192), p; p < m; p++) PrintToChatAll(s[p]);
	}
	else PrintToChatAll(b);
}

stock void CGOPrintHintText(int iClient, const char[] message, any ...)
{
	int size = strlen(message)+190;  
	char[] text = new char[size];
	VFormat(text, size, message, 3);
	if(ReplaceString(text, size, "{{", "<font color='") && ReplaceString(text, size, "}}", "</font>")) ReplaceString(text, size, "==", "'>");
	PrintHintText(iClient, text);
}

stock void CGOPrintHintTextToAll(const char[] message, any ...)
{
	int size = strlen(message)+190;  
	char[] text = new char[size];
	VFormat(text, size, message, 2);
	if(ReplaceString(text, size, "{{", "<font color='") && ReplaceString(text, size, "}}", "</font>")) ReplaceString(text, size, "==", "'>");
	PrintHintTextToAll(text);
}

stock void CGOReplaceColorHsay(char[] text, int size)
{
	if(ReplaceString(text, size, "{{", "<font color='") && ReplaceString(text, size, "}}", "</font>")) ReplaceString(text, size, "==", "'>");
}

stock void CGOPrintCenterText(int iClient, const char[] message, any ...)
{
	int size = strlen(message)+190;  
	char[] text = new char[size];
	VFormat(text, size, message, 3);
	if(ReplaceString(text, size, "{{", "<font color='") && ReplaceString(text, size, "}}", "</font>")) ReplaceString(text, size, "==", "'>");
	PrintCenterText(iClient, text);
}

stock void CGOPrintCenterTextAll(const char[] message, any ...)
{
	int size = strlen(message)+190;  
	char[] text = new char[size];
	VFormat(text, size, message, 2);
	if(ReplaceString(text, size, "{{", "<font color='") && ReplaceString(text, size, "}}", "</font>")) ReplaceString(text, size, "==", "'>");
	PrintCenterTextAll(text);
}

stock void CGOReplaceColorCsay(char[] text, int size)
{
	if(ReplaceString(text, size, "{{", "<font color='") && ReplaceString(text, size, "}}", "</font>")) ReplaceString(text, size, "==", "'>");
}