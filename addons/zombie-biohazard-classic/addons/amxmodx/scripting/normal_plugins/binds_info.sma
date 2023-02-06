#include <amxmodx>
#include <cstrike>

#define PLUGIN  "simpleConsole"
#define VERSION "1.0"
#define AUTHOR  "TEST"

new Float:spamTime[33];
new iMes = 0

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)

  register_clcmd("say /binds", "consola")
  register_clcmd("say_team /binds", "consola")
  // daca mai vreti sa adaugai o comanda utilizati modelul de mai sus
}

public consola(id)
{
  new Float:ttime = get_gametime()
  if (spamTime[id] <= ttime)
  {
    spamTime[id] = ttime + 10
    iMes = 0

    console_print(id, "========================")
    console_print(id, "Plant lasermines: bind v +setlaser")
    console_print(id, "Deplant lasermines: bind c +dellaser")
    console_print(id, "Zombie Smoker: bind f +drag")
    console_print(id, "========================")
    // daca mai vreti sa adaugati un mesaj utizilizati modelul de mai sus
    client_cmd(id, "toggleconsole")

    iMes++
  }
  else if (iMes == 1)
  {
    client_print(id, print_chat, "[SPAM]Check your console, wait 10 seconds !")
    iMes++
  }
}