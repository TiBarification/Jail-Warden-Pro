stock void StringToLower(char[] buffer)
{
    for(int i = 0; buffer[i]; ++i)
    {
        if(IsCharUpper(buffer[i]))
        buffer[i] = CharToLower(buffer[i]);
    }
}