Custom MOTD allows you to have multiple motds. You can serve MOTD directly from a site or take information from a file.

MOTD file (wich is .txt) should pe put in `/cstrike.`

> Structure of THE JSON:

>> /commands - trigger a MOTD | /website - trigger a MOTD | /help - trigger a MOTD

`{
    "commands": {
        "Title": "List of available commands", // MOTD TITLE
        "Url": "comenzi.txt", // MOTD FILE
        "Type": "File"
    },
    "website": {
    "Title": "My website",
    "Url": "https://pe-zona.ro",
    "Type": "Site"
},
    "help": {
        "Title": "List of available commands",
        "Url": "comenzi.txt",
        "Type": "File"
    }
}`