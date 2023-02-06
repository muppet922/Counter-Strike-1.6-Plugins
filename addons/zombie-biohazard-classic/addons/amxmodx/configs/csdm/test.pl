#!/usr/bin/perl

opendir(DIR, ".");
@dirs = readdir(DIR);
closedir(DIR);

for ($i=0; $i<$#dirs; $i++)
{
	$name = $dirs[$i];
	if ($name =~/csdm_(.+)\.cfg/)
	{
		rename($name, "$1.spawns.cfg");
	}
}
