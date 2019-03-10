public void OnMapEnd()
{
	Handle dirh = OpenDirectory("/");
	char buffer[256];

	// Delete all files which end with ".rgb" so we don't fill up the server with a bunch of data
	while (ReadDirEntry(dirh, buffer, sizeof(buffer)))
	{
		TrimString(buffer);

		if (strncmp(buffer, ".rgb", 4, true) == 0)
		{
			if (DirExists(buffer) == true)
			{
				continue;
			}

			DeleteFile(buffer);
		}
	}
}
