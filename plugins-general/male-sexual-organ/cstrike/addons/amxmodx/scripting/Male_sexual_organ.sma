/*
 * - ----------
   Плагин - "Male sexual organ"
 * - ----------
   Описание: Добавляет игрокам мужской половой орган между ног. Забавная атмосфера обеспечена!
 * - ----------
   Поддержка плагина:

   Dev-Cs: @wellasgood
   Telegram: @WellAsGood
 * - ----------
   Благодарности:

   Limbooc - за модельку.
   Subb98 - за способ работы с entity на reapi.
   Алексеич - за баг-репорт.
  * - ----------
*/

/*
   Журнал изменений:

   ver 1.0.1:

   1. Исправлено название плагина, на правильное по смыслу.
   2. Название папки модели и модели в архиве было старое (исправлено)
   3. Изменен исходник в некоторых частях, с учетом новых обновлений.

   ver 1.1.0:

   1. Сделана еще 1 модель полового органа больше в размерах.
   2. Добавлено 2 новых режима:
       а) Большой+малый половой орган добавляется игрокам в рандом режиме.
       б) Большой половой орган добавляется только игрокам с нужным флагом.
   3. Добавлена возможность отключить иммунитет дефайном.
   4. Изменен код, с учетом новых обновлений.

   ver 1.1.1:

   1. Поправлены значения в функции random_num. (правильные по замыслу, что-бы было понятней)

   ver 1.1.2:

   1. В ходе тестирования было обнаружены ошибки при компилировании, в зависимости от разных режимов (исправлено, спасибо: Алексеич)

   ver 1.2.0:

   1. Сделаны обновления моделей маленького и большого полового органа, добавлена темная текстура. (афроамериканский половой орган)
   2. Сделана система режимов работы плагина:
        а) при спавне автоматически не выставляется, а выдается игроку по authid в меню. (задействуется include <nvault> для сохранения)
        б) основная работа плагина, когда всем игрокам выставляется в событие спавна.
   3. Режим 'а':
        * - Добавлено меню выбора игрока.
        * - Добавлено меню настроек.
        * - После выбора игрока, необходимо выбрать настройки (размер (большой|маленький|рандом размер), скин (светлый|темный|рандом скин))
        * - При нажатии на пункт Добавить, игроку добавится половой орган, а также сохранится по authid.
        * - При нажатии на пункт Удалить, у игрока удалится половой орган, а также удалится из сохраненных authid.
        * - Прямо в меню настроек добавлено краткое описание, для чего какая функция, и как пользоваться.
        * - Если нужно поменять настройки, то необходимо удалить и сохранить заново.
        * - В меню настроек, выбор размера полового органа появляется только в том случае, если откомментирован #define USE_BIG_MODE
        * - Добавлен #define на флаг доступа для команд открытия меню.
        * - Команды добавляются в const массив (какие пожелаете). Можно изменить стандартные на свои в plugin_init().
        * - При этом режиме, добавляется еще include <amxmisc>, так как, задействуется цикл по игрокам.
      Режим 'б':
        * - Многое переделано с учетом совместимости режима 'а'.
        * - Добавлен #define SKIN_MODE, отвечающий за режим скинов (1-светлый;2-темный;3-рандом)
        * - В остальном остается как и прежде, как и до этой версии. (настройки)
        * - Меню доступно только в режиме 'a', в этом режиме половой орган добавляется всем при спавне.
   4. Сделан LANG файл, с учетом режима 'a', его работа будет только в этом режиме (в режиме 'б' он не нужен)
   5. Сделаны различные функции обработчики, для целей, исходя из новых обновлений.
   6. В обоих режимах улучшена система выдачи полового органа, если рандом режим (раньше выдавался размер только при первом заходе, теперь рандом при каждом спавне)

   ver 1.2.1:

   1. Изменено название моделей, так как, новые модели с доработкой, нужно что-бы их заново перекачивали.

   ver 1.2.2:

   1. Убран некоторый хард-код, вместо него добавлены новые функции обработчики. (в части проверки на иммунитет и формирование пунктов меню и тп)
   2. Сделаны изменения в части кода, где открывается меню выбора игроков. Теперь изначально идет проверка, есть ли вообще игроки, которые должны попасть в меню, если нету, то будет сообщение в чат об этом. (что-бы не создавать меню зря)
   3. Сделана специальная функция обработчик под задачи проверки игроков. (а также и формирование пунктов меню)
   4. Дополнен LANG файл.

   ver 1.2.3:

   1. Удален не нужный код в части режима PLUGIN_MODE 2, было не нужное кеширование SKIN_MODE
   2. Удалены не нужные enum подстановки значений, оставлен только 1.
   3. Переделаны функции: FeatureValueHandler и ToGiveTheSkinAndModel.
*/

#include <amxmodx>
#include <reapi>

enum { MIN, MAX, RANDOM }; //размер, скин

/*
   Режимы работы плагина (#define PLUGIN_MODE):

      Внимание!!! От режима работы зависит очень многие настройки и функции! Будьте внимательны!

      1 - при спавне автоматически не выставляется, а выдается игроку по authid в меню. (задействуется include <nvault> для сохранения)
      2 - основная работа плагина, когда всем игрокам выставляется в событие спавна.
*/
#define PLUGIN_MODE 1

#define USE_BIG_MODE //Использование большого полового органа. (влияет на оба режима)

#if PLUGIN_MODE == 1
 #include <amxmisc>
 #include <nvault>

 /*
   Флаг доступа на вход в меню выдачи пенисов.
   После запуска сервера (смены карты), можно отредактировать флаг доступа в файле по пути: "amxmodx\configs\cmdaccess.ini"
   Редактирование флагов доступа в файле cmdaccess.ini применимо только к консольным командам.
 */
 #define MENU_ACCESS ADMIN_RCON

 new Vault, GetPlayersFlags:Flags, PlayerAuthID[MAX_PLAYERS+1][MAX_AUTHID_LENGTH], SaveID[MAX_PLAYERS+1];
 new SaveName[MAX_PLAYERS+1][MAX_NAME_LENGTH], CheckSkin[MAX_PLAYERS+1];

 #if defined USE_BIG_MODE
  new CheckModel[MAX_PLAYERS+1];
 #endif
#else
 /*
    Режимы выставления скинов полового органа игроку (#define SKIN_MODE):
       0 - Только светлый скин.
       1 - Только темный скин.
       2 - Рандом между светлым и темным скином.
 */
 #define SKIN_MODE 2

 #if defined USE_BIG_MODE
  #define USE_MODE_RANDOM //Режим большого и малого полового органа (игрокам добавляется рандом моделька между ними)

  #if !defined USE_MODE_RANDOM
   /*
     Если #define USE_MODE_RANDOM закомментирован, то:
     Режим большого полового органа, моделька добавляется только тому у кого нужный флаг!
     Игрокам с этим флагом будет добавляться моделька большого полового органа. (всем остальным маленький)
   */
   #define BIG_ORGAN_FLAG ADMIN_BAN
  #endif
 #endif
#endif

//#define USE_IMMUNITY //Использование иммунитета от модели полового органа.

#if defined USE_IMMUNITY
 #define IMMUNITY_ORGAN_FLAG ADMIN_RCON //защищает игрока с этим флагом от модельки полового органа.
#endif

#define USE_BOTS //Использование ботов (если откомментировано, то на ботах тоже будет половой орган)

new const PLUGIN[] = "Male_sexual_organ";
new const VERSION[] = "1.2.3";
new const AUTHOR[] = "wellasgood";

new const ORGAN_MODELS[][] =
{
	"models/sexual_organ/sm_sexual_organ_2skin.mdl",
	"models/sexual_organ/bg_sexual_organ_2skin.mdl"
};

new Entity[MAX_PLAYERS+1], ModelIndex[2], bool:CheckValue[MAX_PLAYERS+1];

public plugin_precache()
{
	#if defined USE_BIG_MODE
	CheckModels(ORGAN_MODELS[MAX], MAX);
	#endif

	CheckModels(ORGAN_MODELS[MIN], MIN);
}

CheckModels(const model[], num)
{
	if(!file_exists(fmt("\%s", model)))
	{
		set_fail_state("Error! Model '%s' not found", model);
	}
	else
	{
		ModelIndex[num] = precache_model(model);
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	#if PLUGIN_MODE == 1
	register_dictionary("ms_organ.txt");

	//Команды на вход в меню выдачи пенисов. (можно менять/добавлять соблюдая структуру)
	//Если Вы укажите здесь консольную команду на открытие меню, то вводя команду в игре подставьте рядом любое значение.
	new const CMD_MENU_OPEN[][] =
	{
		"say /give_organ",
		"say /penis-menu",
		"say_team /penis-menu",
		"say_team /give_organ",
		"give_organ"
	};

	for(new i; i < sizeof CMD_MENU_OPEN; i++)
	{
		register_clcmd(CMD_MENU_OPEN[i], "@Open_Menu", MENU_ACCESS, "Usage console: command all value | Usage chat: command");
	}

	Vault = nvault_open("ms_organ");

	if(Vault == INVALID_HANDLE)
	{
		set_fail_state("Error opening nVault file!");
	}

	Flags = GetPlayers_ExcludeHLTV;

	#if !defined USE_BOTS
	Flags += GetPlayers_ExcludeBots;
	#endif
	#endif

	RegisterHookChain(RG_CBasePlayer_Spawn, "@EventSpawn", true);
}

public client_putinserver(PlayerID)
{
	#if !defined USE_BOTS
	if(is_user_bot(PlayerID)) return;
	#endif

	if(is_user_hltv(PlayerID)) return;

	#if defined USE_IMMUNITY
	if(ImmunityCheck(PlayerID)) return;
	#endif

	CheckValue[PlayerID] = false;

	#if PLUGIN_MODE == 1
	arrayset(PlayerAuthID[PlayerID], 0, charsmax(PlayerAuthID[]));
	get_user_authid(PlayerID, PlayerAuthID[PlayerID], charsmax(PlayerAuthID[]));

	#if defined USE_BIG_MODE
	CheckModel[PlayerID] = 0;
	#endif
	CheckSkin[PlayerID] = 0;

	nVault_Handler(3, PlayerID);
	#endif

	if(!CheckValue[PlayerID])
	{
		CreateEnt(PlayerID);
	}
}

public client_disconnected(PlayerID)
{
	RemoveOrgan(PlayerID);
}

@EventSpawn(PlayerID)
{
	if(!is_user_alive(PlayerID)) return;

	if(SignEnt(PlayerID))
	{
		FeatureValueHandler(PlayerID);
	}
}

CreateEnt(PlayerID)
{
	if((Entity[PlayerID] = rg_create_entity("info_target")))
	{
		set_entvar(Entity[PlayerID], var_classname, "_male_sexual_organ");

		FeatureValueHandler(PlayerID);

		set_entvar(Entity[PlayerID], var_movetype, MOVETYPE_FOLLOW);
		set_entvar(Entity[PlayerID], var_aiment, PlayerID);
	}
}

FeatureValueHandler(PlayerID)
{
	new check_model, check_skin;

	#if PLUGIN_MODE == 1
	#if defined USE_BIG_MODE
	check_model = (CheckModel[PlayerID] == RANDOM ? random_num(MIN, MAX) : CheckModel[PlayerID]);
	#endif
	check_skin = (CheckSkin[PlayerID] == RANDOM ? random_num(MIN, MAX) : CheckSkin[PlayerID]);
	#else
	#if SKIN_MODE == 2
	check_skin = random_num(MIN, MAX);
	#else
	check_skin = SKIN_MODE;
	#endif
	#if defined USE_BIG_MODE
	#if !defined USE_MODE_RANDOM
	if(get_user_flags(PlayerID) & BIG_ORGAN_FLAG)
	{
		check_model = MAX;
	}
	#else
	check_model = random_num(MIN, MAX);
	#endif
	#endif
	#endif

	ToGiveTheSkinAndModel(PlayerID, 0, check_model);
	ToGiveTheSkinAndModel(PlayerID, 1, check_skin);
}

ToGiveTheSkinAndModel(PlayerID, sign, value)
{
	switch(sign)
	{
		case 0:
		{
			set_entvar(Entity[PlayerID], var_model, ORGAN_MODELS[value]);
			set_entvar(Entity[PlayerID], var_modelindex, ModelIndex[value]);
		}
		case 1:
		{
			set_entvar(Entity[PlayerID], var_skin, value);
		}
	}
}

SignEnt(PlayerID)
{
	return (Entity[PlayerID] && is_entity(Entity[PlayerID])) ? 1 : 0;
}

RemoveOrgan(PlayerID)
{
	if(SignEnt(PlayerID))
	{
		set_entvar(Entity[PlayerID], var_flags, FL_KILLME);
		set_entvar(Entity[PlayerID], var_nextthink, get_gametime());
		Entity[PlayerID] = 0;
	}
}

#if PLUGIN_MODE == 1
@Open_Menu(PlayerID, level, cid)
{
	if(!cmd_access(PlayerID, level, cid, 2)) return;

	//проверяем есть ли вообще игроки для создания меню.
	if(HandlerForGettingPlayers(1, "dummy", _, _, PlayerID)) return;

	Organ_Menu(PlayerID);
}

Organ_Menu(PlayerID)
{
	if(!is_user_connected(PlayerID)) return;

	new TempString[MAX_MENU_LENGTH];
	formatex(TempString, charsmax(TempString), "%L", PlayerID, "MSO_MENU_TITLE");

	new Menu = menu_create(TempString, "@Handle_Organ_Menu");

	HandlerForGettingPlayers(2, TempString, charsmax(TempString), Menu, PlayerID);
	FormationOfMenuItems(PlayerID, TempString, charsmax(TempString), Menu);

	menu_display(PlayerID, Menu);
}

@Handle_Organ_Menu(PlayerID, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}

	new Info[6];
	menu_item_getinfo(Menu, Item, _, Info, charsmax(Info));

	SaveID[PlayerID] = str_to_num(Info);

	menu_destroy(Menu);

	Settings_Menu(PlayerID);
}

Settings_Menu(PlayerID)
{
	if(!is_user_connected(PlayerID)) return;

	new TempString[MAX_MENU_LENGTH];
	formatex(TempString, charsmax(TempString), "%L \d%s", PlayerID, "MSO_ST_MENU_TITLE", SaveName[SaveID[PlayerID]]);

	new Menu = menu_create(TempString, "@Handle_Settings_Menu");

	#if defined USE_BIG_MODE
	formatex(TempString, charsmax(TempString), "%L \y[\r%L\y]", PlayerID, "MSO_ST_MENU_INFO1", PlayerID, fmt("MSO_ST_MENU_ORGAN_MODEL_%d", CheckModel[SaveID[PlayerID]]));
	menu_additem(Menu, TempString, "0");
	#endif

	formatex(TempString, charsmax(TempString), "%L \y[\r%L\y]^n", PlayerID, "MSO_ST_MENU_INFO2", PlayerID, fmt("MSO_ST_MENU_ORGAN_SKIN_%d", CheckSkin[SaveID[PlayerID]]));
	menu_additem(Menu, TempString, "1");

	formatex(TempString, charsmax(TempString), "%L \y[\d%L\y]^n^n\d%L^n", PlayerID, "MSO_ST_MENU_SIGN_INFO", PlayerID, SignEnt(SaveID[PlayerID]) ? "MSO_ST_MENU_SIGN_YES" : "MSO_ST_MENU_SIGN_NO", PlayerID, SignEnt(SaveID[PlayerID]) ? "MSO_ST_MENU_SIGN_YES_INFO" : "MSO_ST_MENU_SIGN_NO_INFO");
	menu_additem(Menu, TempString, "2");

	formatex(TempString, charsmax(TempString), "%L", PlayerID, "MSO_ST_MENU_ADDED");
	menu_additem(Menu, TempString, "3");

	formatex(TempString, charsmax(TempString), "%L", PlayerID, "MSO_ST_MENU_DELETE");
	menu_additem(Menu, TempString, "4");

	FormationOfMenuItems(PlayerID, TempString, charsmax(TempString), Menu);
	menu_display(PlayerID, Menu);
}

@Handle_Settings_Menu(PlayerID, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);

		Organ_Menu(PlayerID);
		return;
	}

	new Info[6];
	menu_item_getinfo(Menu, Item, _, Info, charsmax(Info));

	menu_destroy(Menu);

	switch(str_to_num(Info))
	{
		#if defined USE_BIG_MODE
		case 0:
		{
			CheckModel[SaveID[PlayerID]] = (CheckModel[SaveID[PlayerID]] + 1) % 3;
		}
		#endif
		case 1:
		{
			CheckSkin[SaveID[PlayerID]] = (CheckSkin[SaveID[PlayerID]] + 1) % 3;
		}
		case 3:
		{
			if(!SignEnt(SaveID[PlayerID]))
			{
				CreateEnt(SaveID[PlayerID]);
				nVault_Handler(1, SaveID[PlayerID]);
			}
		}
		case 4:
		{
			if(SignEnt(SaveID[PlayerID]))
			{
				RemoveOrgan(SaveID[PlayerID]);
				nVault_Handler(2, SaveID[PlayerID]);
			}
		}
	}

	Settings_Menu(PlayerID);
}

HandlerForGettingPlayers(value, TempString[], len = 0, Menu = 0, PlayerID)
{
	new PlayersID[MAX_PLAYERS], PlayersCount, check_value;
	get_players_ex(PlayersID, PlayersCount, Flags);

	for(new i; i < PlayersCount; i++)
	{
		#if defined USE_IMMUNITY
		if(ImmunityCheck(PlayersID[i])) continue;
		#endif

		switch(value)
		{
			case 1:
			{
				check_value++;
			}
			case 2:
			{
				arrayset(SaveName[PlayersID[i]], 0, charsmax(SaveName[]));
				get_user_name(PlayersID[i], SaveName[PlayersID[i]], charsmax(SaveName[]));

				formatex(TempString, len, "%s \y[\r%L\y]", SaveName[PlayersID[i]], PlayerID, SignEnt(PlayersID[i]) ? "MSO_MENU_ORGAN_ON" : "MSO_MENU_ORGAN_OFF");

				menu_additem(Menu, TempString, fmt("%d", PlayersID[i]));
			}
		}
	}

	if(value == 1)
	{
		if(check_value == 0)
		{
			client_print_color(PlayerID, print_team_default, "%l", "MSO_MENU_LACK_OF_THE_RIGHT_PLAYERS");
			return 1;
		}
	}

	return 0;
}

FormationOfMenuItems(PlayerID, TempString[], len, Menu)
{
	formatex(TempString, len, "%L", PlayerID, "MSO_MENU_BACK");
	menu_setprop(Menu, MPROP_BACKNAME, TempString);

	formatex(TempString, len, "%L", PlayerID, "MSO_MENU_NEXT");
	menu_setprop(Menu, MPROP_NEXTNAME, TempString);

	formatex(TempString, len, "%L", PlayerID, "MSO_MENU_EXIT");
	menu_setprop(Menu, MPROP_EXITNAME, TempString);
}

nVault_Handler(value, save_id)
{
	new Data[12], timestamp, AccessResult = nvault_lookup(Vault, PlayerAuthID[save_id], Data, charsmax(Data), timestamp);

	switch(value)
	{
		case 1:
		{
			if(!AccessResult)
			{
				new buff[12];

				#if defined USE_BIG_MODE
				formatex(buff, charsmax(buff), "%d %d", CheckModel[save_id], CheckSkin[save_id]);
				#else
				formatex(buff, charsmax(buff), "%d", CheckSkin[save_id]);
				#endif

				nvault_set(Vault, PlayerAuthID[save_id], buff);
			}
		}
		case 2:
		{
			if(AccessResult)
			{
				nvault_remove(Vault, PlayerAuthID[save_id]);
			}
		}
		case 3:
		{
			if(!AccessResult)
			{
				CheckValue[save_id] = true;
			}
			else
			{
				#if defined USE_BIG_MODE
				new skin[6], model[6];
				strtok(Data, skin, charsmax(skin), model, charsmax(model), _, 1);

				CheckModel[save_id] = str_to_num(model);
				CheckSkin[save_id] = str_to_num(skin);
				#else
				CheckSkin[save_id] = str_to_num(Data);
				#endif
			}
		}
	}
}

public plugin_end()
{
	nvault_close(Vault);
}
#endif

#if defined USE_IMMUNITY
ImmunityCheck(PlayerID)
{
	return (get_user_flags(PlayerID) & IMMUNITY_ORGAN_FLAG) ? 1 : 0;
}
#endif