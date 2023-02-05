#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#pragma semicolon 1

public stock const PluginName[] = "FPS Checker";
public stock const PluginVersion[] = "1.0.3";
public stock const PluginAuthor[] = "ufame";
public stock const PluginDescription[] = "Punishments for high FPS";
public stock const PluginURL[] = "https://dev-cs.ru/resources/1436/";

const TASKID_START_TASK = 12121;
const TASKID_CHECK_FPS = 21212;
const Float: TASK_INTERVAL = 5.0;

new g_iMaxFps;
new g_iMaxWarnings;
new bool: g_bResetSpeed;

new g_iFps[MAX_PLAYERS + 1];
new g_iFrames[MAX_PLAYERS + 1];
new Float: g_flLastCheck[MAX_PLAYERS + 1];
new g_iWarnings[MAX_PLAYERS + 1];

public plugin_init() {
  register_plugin(PluginName, PluginVersion, PluginAuthor);

  register_dictionary("high_fps_checker.txt");
  register_forward(FM_PlayerPreThink, "Hook_PlayerPrethink_Pre", ._post = 0);

  bind_pcvar_num(create_cvar("hfc_max_fps", "100", .description = "Max fps"), g_iMaxFps);
  bind_pcvar_num(create_cvar("hfc_max_warns", "3", .description = "Max warnings before kick"), g_iMaxWarnings);
  bind_pcvar_num(create_cvar("hfc_reset_speed", "1", .description = "Reset player speed on warnings?"), g_bResetSpeed);

  AutoExecConfig(true, "high-fps-checker");

  set_task(TASK_INTERVAL, "Task_CheckUsersFps", .flags = "b");
}

public client_connect(id) {
  g_iWarnings[id] = 0;
  g_flLastCheck[id] = 0.0;
}

public Hook_PlayerPrethink_Pre(id) {
  if (g_flLastCheck[id] <= get_gametime()) {
    g_iFps[id] = g_iFrames[id];

    g_iFrames[id] = 0;
    g_flLastCheck[id] = get_gametime() + 1.0;
  }

  g_iFrames[id]++;
}

public Task_CheckUsersFps() {
  new iPlayers[MAX_PLAYERS], iNum;
  get_players_ex(iPlayers, iNum, GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV);

  for (new i, id, Float: flSpeed, Float: flVelocity[3]; i < iNum; i++) {
    id = iPlayers[i];

    if (g_iFps[id] > g_iMaxFps) {
      if (g_iMaxWarnings && (++g_iWarnings[id] >= g_iMaxWarnings)) {
        user_kick(id);
        continue;
      }

      client_cmd(id, "spk ^"buttons/blip2^"");
      client_print_color(id, print_team_default, "%L", id, "FPS_CHECK", g_iMaxFps);

      if (g_bResetSpeed) {
        pev(id, pev_velocity, flVelocity);
        flSpeed = vector_length(flVelocity);

        if (flSpeed > 0.0) {
          flVelocity = NULL_VECTOR;
          set_pev(id, pev_velocity, flVelocity);
        }
      }
    }
  }
}

stock user_kick(id) {
  server_cmd("kick #%d ^"Set fps_max %d^"", get_user_userid(id), g_iMaxFps);
}
