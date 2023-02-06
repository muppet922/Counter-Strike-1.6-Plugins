// Cameras by lonewolf <igorkelvin@gmail.com>
// https://github.com/igorkelvin/amxx-plugins

#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <xs>

#define PLUGIN  "Observer Cameras"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PREFIX "^4[Cameras]^1"

#if !defined MAX_MAPNAME_LENGTH
  #define MAX_MAPNAME_LENGTH  64
#endif

#define CAMERAS_SAVE_LOCATION "maps/%s.cameras"
#define MAX_CAMERAS           20
#define MAX_CAMERA_NAME_LEN   32

enum Camera
{
  NAME[MAX_CAMERA_NAME_LEN+1],
  Float:ORIGIN[3],
  Float:ANGLES[3]
};

new const commands_camera[][32] =
{
  "/cam",
  "/camera",
  "/cameras",
  "/dinix",
  ".cam",
  ".camera",
  ".cameras",
  ".dinix"
};

new cameras[MAX_CAMERAS][Camera];

new menu_check_max_callback_id;
new menu_check_enabled_callback_id;

new camera_to_set[MAX_PLAYERS+1];
new cameras_shift;

new cvar_enabled;
new cvar_spec_only;

new enabled;
new spec_only;


public plugin_cfg()
{
  new ret = cameras_load();
  log_amx("(plugin_cfg) %d camera%sloaded.", ret, ret > 1 ? "s " : " ");
}


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  menu_check_max_callback_id     = menu_makecallback("menu_check_max_callback");
  menu_check_enabled_callback_id = menu_makecallback("menu_check_enabled_callback");

  register_clcmd("camera_name", "cmd_camera_name");

  register_clcmd("+cameras_shift", "cmd_cameras_shift_set",   _, "Hold to add +10 to ^"say /cam^" argument");
  register_clcmd("-cameras_shift", "cmd_cameras_shift_unset");

  cvar_enabled   = create_cvar("amx_cameras_enabled",   "1", _, "<0/1> Disable/Enable Cameras Plugin");
  cvar_spec_only = create_cvar("amx_cameras_spec_only", "1", _, "<0/1> Only spectators can teleport");

  bind_pcvar_num(cvar_enabled,   enabled);
  bind_pcvar_num(cvar_spec_only, spec_only);
  
  register_clcmd("say", "cmd_say");
}


public client_connect(id)
{
  camera_to_set[id] = -1;
}


public cmd_cameras_shift_set(id)
{
  cameras_shift |= (1 << (id-1));
}


public cmd_cameras_shift_unset(id)
{
  cameras_shift &= ~(1 << (id-1));
}


public cameras_load()
{
  new mapname[MAX_MAPNAME_LENGTH];
  get_mapname(mapname, charsmax(mapname));

  new location[64];
  formatex(location, charsmax(location), CAMERAS_SAVE_LOCATION, mapname);

  new file = fopen(location, "rt");

  if (!file)
  {
    log_amx("(cameras_load) Failed to open ^"%s^"", location);
    return 0;
  }

  new line[128];
  new camera = 0;
  while (fgets(file, line, charsmax(line)))
  {
    if (camera >= MAX_CAMERAS)
    {
      break;
    }
    
    trim(line);
    if (!strlen(line) || line[0] == ';' || (line[0] == '/' && line[1] == '/'))
    {
      continue;
    }

    // Example of line:
    // "Camera base 01", 0.1, 0.2, 0.3, 0.4, 0.5

    new buffer[97]; // AAAAAAAAAAAAAA MY EYES
    new name[32];
    strtok2(line, name, charsmax(name), buffer, charsmax(buffer), ',', .trim=1);

    trim(name);
    remove_quotes(name);

    new Float:tmp[5];
    new arg[8];
    for (new i = 0; i < 5; ++i)
    {
      strtok2(buffer, arg, charsmax(arg), buffer, charsmax(buffer), ',', .trim=1);
      remove_quotes(arg);
      tmp[i] = str_to_float(arg);

      if (!tmp[i])
      {
        trim(arg)
        if (arg[0] != '0')
        {
          log_amx("(cameras_load) failed to parse ^"%s^" @ arg: ^"%s^"", line, arg);
          return PLUGIN_HANDLED;
        }
      }
    }
    
    copy(cameras[camera][NAME], MAX_CAMERA_NAME_LEN, name);
    cameras[camera][ORIGIN][0] = tmp[0];
    cameras[camera][ORIGIN][1] = tmp[1];
    cameras[camera][ORIGIN][2] = tmp[2];
    cameras[camera][ANGLES][0] = tmp[3];
    cameras[camera][ANGLES][1] = tmp[4];
    cameras[camera][ANGLES][2] = 0.0;

    camera++;
  }
  
  fclose(file);

  return camera;
}


public cameras_save()
{
  new mapname[MAX_MAPNAME_LENGTH];
  get_mapname(mapname, charsmax(mapname));

  new location[64];
  formatex(location, charsmax(location), CAMERAS_SAVE_LOCATION, mapname);

  new file = fopen(location, "wt");

  if (!file)
  {
    log_amx("(cameras_save) Failed to open ^"%s^"", location);
    return 0;
  }

  fprintf(file, "// Automatic generated by ^"%s^" v%s, by %s^n", PLUGIN, VERSION, AUTHOR);
  fprintf(file, "// https://github.com/igorkelvin/amxx-plugins^n//^n");

  fprintf(file, "// ^"say /cam^"          - Camera menu^n");
  fprintf(file, "// ^"say /cam <number>^" - Teleport to Camera <number>^n");
  fprintf(file, "// ^"say /camcfg^"       - Camera config menu^n//^n");

  fprintf(file, "// Quotes (^"^") are optional^n");
  fprintf(file, "// ^"MAX_CAMERAS is set to ^"%d^"^n//^n", MAX_CAMERAS);

  fprintf(file, "// CAMERA NAME, ORIGIN_X, ORIGIN_Y, ORIGIN_Z, PITCH,  YAW^n");
  fprintf(file, "//  <31 chars>  <float>   <float>   <float>  <float> <float>^n^n");
  
  new i;
  for (i = 0; i < MAX_CAMERAS; ++i)
  {
    if (cameras[i][NAME][0] == '^0')
    {
      break;
    }

    new name[32];
    copy(name, charsmax(name), cameras[i][NAME]);
    
    new Float:o[3];
    new Float:a[3];

    xs_vec_copy(cameras[i][ORIGIN], o);
    xs_vec_copy(cameras[i][ANGLES], a);

    fprintf(file, "%s, %4.1f, %4.1f, %4.1f, %4.1f, %4.1f^n", name, o[0], o[1], o[2], a[0], a[1]);
  }

  
  fclose(file);

  return i;
}


public teleport(id, camera)
{
  if (!enabled || camera < 0 || camera >= MAX_CAMERAS || cameras[camera][NAME][0] == '^0')
  {
    return PLUGIN_CONTINUE;
  }
  
  if (spec_only && (cs_get_user_team(id) != CS_TEAM_SPECTATOR))
  {
    return PLUGIN_CONTINUE;
  }

  engclient_cmd(id, "specmode", "3");

  new Float:origin[3];
  new Float:angles[3];

  xs_vec_copy(cameras[camera][ORIGIN], origin);
  xs_vec_copy(cameras[camera][ANGLES], angles);

  entity_set_origin(id, origin);
  entity_set_vector(id, EV_VEC_angles, angles);
  entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
  entity_set_vector(id, EV_VEC_punchangle, Float:{0.0, 0.0, 0.0});
  entity_set_int(id, EV_INT_fixangle, 1);

  return PLUGIN_HANDLED;
}


public cmd_say(id)
{
  if (!is_user_connected(id))
  {
    return PLUGIN_HANDLED;
  }

  new saytext[64];
  read_args(saytext, charsmax(saytext));
  remove_quotes(saytext);

  new command[32];
  new arg[32];
  parse(saytext, command, charsmax(command), arg, charsmax(arg));

  
  new option = str_to_num(arg) - 1;

  new len = sizeof(commands_camera);
  for (new i = 0; i < len; ++i)
  {
    if (equal(command, commands_camera[i]))
    {
      if (option != -1)
      {
        if (cameras_shift & (1 << (id-1)))
        {
          option = min(option + 10, MAX_CAMERAS);
        }

        teleport(id, option);
        return PLUGIN_HANDLED;
      }

      menu_cameras(id);
      return PLUGIN_HANDLED;
    }
    
    new cmd[32];
    formatex(cmd, charsmax(cmd), "%scfg", commands_camera[i])

    if (equal(command, cmd))
    {
      menu_cameras_config(id);
      return PLUGIN_HANDLED;
    }
    
    formatex(cmd, charsmax(cmd), "%sconfig", commands_camera[i])

    if (equal(command, cmd))
    {
      menu_cameras_config(id);
      return PLUGIN_HANDLED;
    }

  }
  
  return PLUGIN_CONTINUE;
}

menu_cameras(id, page=0)
{
  new warning[32] = "";
  if (!enabled)
  {
    copy(warning, charsmax(warning), "^n\d(Disabled by server)\w");
  } 
  else if (spec_only && (cs_get_user_team(id) != CS_TEAM_SPECTATOR))
  {
    copy(warning, charsmax(warning), "^n\d(Spec only)\w");
  }
  
  new title[128];
  formatex(title, charsmax(title), "\wCamera Menu%s", warning);

  new menu = menu_create(title, "menu_cameras_handler");

  for (new i = 0; i < MAX_CAMERAS; ++i)
  {
    if (cameras[i][NAME][0] == '^0')
    {
      continue;
    }

    new info[4];
    num_to_str(i, info, charsmax(info));

    menu_additem(menu, cameras[i][NAME], info, ADMIN_ALL, menu_check_enabled_callback_id);
  }
  
  menu_display(id, menu, page);
}


public menu_check_enabled_callback(id, menu, item)
{
  return enabled && (!spec_only || (cs_get_user_team(id) == CS_TEAM_SPECTATOR)) ? ITEM_IGNORE : ITEM_DISABLED;
}


public menu_cameras_handler(id, menu, item)
{
  if (item == MENU_EXIT  || !is_user_connected(id))
  {
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  new info[4];
  menu_item_getinfo(menu, item, _, info, charsmax(info));

  new i = str_to_num(info);
  if (i < 0 || i >= MAX_CAMERAS)
  {
    log_amx("(menu_cameras_handler) cameras[%d] out of bounds.", i);
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  teleport(id, i);

  menu_destroy(menu);
  menu_cameras(id, item / 7);
  return PLUGIN_HANDLED;
}

public menu_cameras_config(id)
{
  new menu = menu_create("\wCamera Config^n\d(Admin only)", "menu_cameras_config_handler");

  new txt[32];
  formatex(txt, charsmax(txt), "%s", enabled ? "\yCameras are enabled\w" : "\rCameras are disabled\w");

  menu_additem(menu, "Edit Cameras", "",    ADMIN_CFG);
  
  menu_addtext2(menu, "");
  menu_addtext2(menu, "");
  menu_addtext2(menu, "");
  
  menu_additem(menu, txt, "tog", ADMIN_CFG);

  menu_additem(menu, "Save Cameras", "sav", ADMIN_CFG);
  menu_additem(menu, "Load Cameras", "loa", ADMIN_CFG);

  menu_display(id, menu);
}

public menu_cameras_config_handler(id, menu, item)
{
  if (item == MENU_EXIT  || !is_user_connected(id))
  {
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  new info[4];
  menu_item_getinfo(menu, item, _, info, charsmax(info));

  if (item == 0)
  {
    menu_destroy(menu);
    menu_cameras_config_list(id);

    return PLUGIN_HANDLED;
  }
  
  if (equal(info, "tog"))
  {
    set_pcvar_num(cvar_enabled, !enabled);

    client_print_color(id, print_team_red, "%s Cameras %s", PREFIX, enabled ? "^4Enabled^1" : "^3Disabled^1");
  }
  else if (equal(info, "sav"))
  {
    new ret = cameras_save();

    log_amx("%d camera%ssaved.", ret, ret > 1 ? "s " : " ");
    client_print_color(id, print_team_red, "%s %d Camera%ssaved", PREFIX, ret, (ret > 1) ? "s " : " ")
  }
  else if (equal(info, "loa"))
  {
    new ret = cameras_load();

    log_amx("%d camera%ssaved.", ret, ret > 1 ? "s " : " ");
    client_print_color(id, print_team_red, "%s %d Camera%ssaved", PREFIX, ret, (ret > 1) ? "s " : " ")
  }
  
  menu_destroy(menu);
  menu_cameras_config(id);

  return PLUGIN_HANDLED;
}


public menu_cameras_config_list(id)
{
  new title[128];
  formatex(title, charsmax(title), "\wCamera Config Menu^n\d(Admin only)^n");

  new menu = menu_create(title, "menu_cameras_config_list_handler");

  new i;
  for (i = 0; i < MAX_CAMERAS; ++i)
  {
    if (cameras[i][NAME][0] == '^0')
    {
      continue;
    }
    
    new info[4];
    num_to_str(i, info, charsmax(info));

    menu_additem(menu, cameras[i][NAME][0], info, ADMIN_CFG);
  }
  
  menu_additem(menu, "New Camera", "add", ADMIN_CFG, menu_check_max_callback_id);
  
  menu_setprop(menu, MPROP_EXITNAME, "Back");
  menu_display(id, menu);
}


public menu_check_max_callback(id)
{
  for (new i = 0; i < MAX_CAMERAS; i++)
  {
    if (cameras[i][NAME] == '^0')
    {
      return ITEM_IGNORE;
    }
  }

  return ITEM_DISABLED;
}

public menu_cameras_config_list_handler(id, menu, item)
{
  if (!is_user_connected(id))
  {
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  if (item == MENU_EXIT)
  {
    menu_cameras_config(id);
    return PLUGIN_HANDLED;
  }

  new info[4];
  menu_item_getinfo(menu, item, _, info, charsmax(info));

  if (equal(info, "add"))
  {
    menu_destroy(menu);
    
    for (new i = 0; i < MAX_CAMERAS; i++)
    {
      if (cameras[i][NAME] == '^0')
      {
        menu_cameras_edit(id, i);
        return PLUGIN_HANDLED;
      }
    }

    client_print_color(id, print_team_red, "%s cannot add more cameras! MAX_CAMERAS = %d", PREFIX, MAX_CAMERAS);
    return PLUGIN_HANDLED;
  }

  new i = str_to_num(info);
  if (i < 0 || i >= MAX_CAMERAS)
  {
    log_amx("(menu_cameras_config_handler) cameras[%d] out of bounds.", i);
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  // client_print_color(id, print_team_red, "%s you selected ^3%s^1.", PREFIX, cameras[i][NAME]);

  menu_destroy(menu);
  menu_cameras_edit(id, i);
  return PLUGIN_HANDLED;
}

public menu_cameras_edit(id, camera)
{
  // client_print_color(id, print_team_red, "%s menu_cameras_edit: %d.", PREFIX, camera);

  new title[128];
  formatex(title, charsmax(title), "\wCamera Edit Menu^n\dCamera %02d", camera + 1);
  new menu = menu_create(title, "menu_cameras_edit_handler");

  new info[4];
  num_to_str(camera, info, charsmax(info));
  
  new i = camera;
  new item_text[64];

  formatex(item_text, charsmax(item_text), "Name: ^"\y%s\w^"", cameras[i][NAME]);
  menu_additem(menu, item_text, info, ADMIN_CFG);

  formatex(item_text, charsmax(item_text), "Origin: [\y%.1f\w, \y%.1f\w, \y%.1f\w]", cameras[i][ORIGIN][0], cameras[i][ORIGIN][1], cameras[i][ORIGIN][2]);
  menu_additem(menu, item_text, info, ADMIN_CFG);

  formatex(item_text, charsmax(item_text), "Angles: [\y%.1f\w°, \y%.1f\w°]", -cameras[i][ANGLES][0], cameras[i][ANGLES][1]);
  menu_additem(menu, item_text, info, ADMIN_CFG);
  
  menu_setprop(menu, MPROP_EXITNAME, "Back");
  menu_display(id, menu);
}

public menu_cameras_edit_handler(id, menu, item)
{
  if (!is_user_connected(id))
  {
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  if (item == MENU_EXIT)
  {
    menu_cameras_config_list(id);
    return PLUGIN_HANDLED;
  }

  
  new info[4];
  menu_item_getinfo(menu, item, _, info, charsmax(info));
  new camera = str_to_num(info);

  switch (item)
  {
    case 0:
    {
      // client_print_color(id, print_team_red, "%s you selected Camera %02d's ^3Name^1.", PREFIX, camera + 1);
      camera_to_set[id] = camera;

      client_cmd(id, "messagemode camera_name");
      menu_destroy(menu);
      return PLUGIN_HANDLED;
    }
    case 1:
    {
      // client_print_color(id, print_team_red, "%s you selected Camera %02d's ^3Origin^1.", PREFIX, camera + 1);

      new Float:origin[3];
      entity_get_vector(id, EV_VEC_origin, origin);

      xs_vec_copy(origin, cameras[camera][ORIGIN]);
    }
    case 2: 
    {
      // client_print_color(id, print_team_red, "%s you selected Camera %02d's ^3Angles^1.", PREFIX, camera + 1);

      new Float:angles[3];
      entity_get_vector(id, EV_VEC_v_angle, angles);
      angles[2] = 0.0;

      xs_vec_copy(angles, cameras[camera][ANGLES]);
    }
  }
  
  menu_destroy(menu);
  menu_cameras_edit(id, camera);

  return PLUGIN_HANDLED;
}

public cmd_camera_name(id)
{
  new camera = camera_to_set[id];
  camera_to_set[id] = -1;
  
  // client_print_color(id, print_team_red, "^4(cmd_camera_name)^1 camera: %d", camera);

  if (camera < 0 || camera >= MAX_CAMERAS || !is_user_connected(id))
  {
    return PLUGIN_CONTINUE;
  }

  new name[64];
  read_args(name, charsmax(name));

  trim(name);
  remove_quotes(name);

  copy(cameras[camera][NAME], MAX_CAMERA_NAME_LEN, name);
  menu_cameras_edit(id, camera);

  return PLUGIN_CONTINUE;
}

