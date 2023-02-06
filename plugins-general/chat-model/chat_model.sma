#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN_NAME	                  "CHAT MODEL"
#define PLUGIN_VERSION	                       "3.0"
#define PLUGIN_AUTHOR	     "MayroN & Sanya@ (Skype: admin-zombarik)"

#define CHAT_MODEL                "models/chat_model/chat_model.mdl"

#define CHAT_MODELTIME	 3.0	//   Через сколько секунд Удалять Модель Чата

#define BOT_CHAT            //  Закомментируйте,что-бы Боты не использовали Чат и Модель

new g_PlayerModelChat[33]

#if defined BOT_CHAT
new bot_quota, ZBot
#endif

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	register_clcmd("say", "Open_Model");
	register_clcmd("say_team", "Open_Model");

	register_think("chat_model", "Close_Model");
        RegisterHam(Ham_Killed, "player", "Model_Killed");

        #if defined BOT_CHAT
	register_logevent("logevent_round_start",2, "1=Round_Start");
        bot_quota = get_cvar_pointer("bot_quota");
        #endif
} 

public plugin_precache()
{
	precache_model(CHAT_MODEL)
}

public client_putinserver(id)
{
        #if defined BOT_CHAT
        if(!ZBot && is_user_bot(id) && get_pcvar_num(bot_quota) > 0)
               set_task(0.1,"BotChat",id);
	#endif

	g_PlayerModelChat[id] = 0
}

public client_disconnected(id)
{
        g_PlayerModelChat[id] = 0
}

public Open_Model(id)
{
        if(!is_user_alive(id))
	   return;

	new i_Ent = create_entity("info_target");

        if(!is_valid_ent(i_Ent))
          return;

	engfunc(EngFunc_SetModel, i_Ent, CHAT_MODEL)
        set_pev(i_Ent, pev_classname, "chat_model");
	
	set_pev(i_Ent, pev_aiment, id)
	set_pev(i_Ent, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(i_Ent, pev_owner, id)

	g_PlayerModelChat[id] = i_Ent

	set_pev(i_Ent, pev_nextthink, get_gametime() + CHAT_MODELTIME);
}

public Close_Model(entity_id)
{
	if(is_valid_ent(entity_id))
		remove_entity(entity_id);
}

public Model_Killed(player_id)
{
        new entity = FM_NULLENT
        while((entity = fm_find_ent_by_class(entity,"chat_model")))
        {
            if(pev(entity, pev_owner) == player_id)
		engfunc(EngFunc_RemoveEntity,entity)
        }
}

/*
==========
ЧАТ БОТОВ
==========
*/

#if defined BOT_CHAT
enum (+= 100)
{
	TASK_BOT_USE_SKILL
}

#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL);

new const g_BotChat[][] = 
{
	"Следующий раз я достану тебя !",
	"Я не могу поверить в это...",
	"Этот новичок просто заебал меня !",
	"Где был тот парень ?",
	"Кто-то зайдите на сервер...",
	"Сколько фрагов мне нужно сделать на этой карте ?",
	"Есть только один лидер )))",
	"Не бери в голову это - это просто игра !",
	"Ты болтаешь слишком много",
	"Давай сходим за пивом ?",
	"Извини я не хотел в тебя стрелять",
	"Приветствуй короля, малыш : D",
	"Я покажу вам свой опыт из оружия",
	"Забей на оружие своё - Я предпочитаю КАЛАШ !",
	"МОЧИ КОЗЛОВ !",
	"Привет парни !",
	"Здарова !",
	"Почему никто не убивает меня ?)))",
	"Ваш клан это - толпа лузеров...",
	"Ты должен был убегать,пока я давал тебе шанс)",
	"Перестань убивать меня )))",
	"Мой монитор тёмный ! Может я сдох ?",
	"Я увеличу яркость,потому что я нихрена не вижу !",
	"Я ненавижу перезарядку...",
	"Играем в Camper-Strike...?)",
	"Вы уверены,что я не читер ?!",
	"Я заебался уже здесь...",
	"Есть боты на этом сервере ???",
	"Я не пойму как,ну как так...?",
	"Ты что с одним ножом бегаешь?"
}

public BotChat(id)
{
    if(!ZBot && is_user_connected(id) && is_user_bot(id) && get_pcvar_num(bot_quota) > 0)
    {
        RegisterHamFromEntity(Ham_Killed, id, "Model_Killed", 1)
        ZBot = 1
    }
}

public Open_BotChat(id)
{
        static botname[32];
        get_user_name(id, botname, charsmax(botname));

	print_chatColor(0, "\t%s\n : \g%s", botname, g_BotChat[random(sizeof(g_BotChat))]);
}

public logevent_round_start()
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(float(random_num(30,60)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}
	}
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
        if (!is_user_alive(id)) return;
	if (!is_user_bot(id)) return;

        Open_Model(id)
        Open_BotChat(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(30,60)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
#endif

stock print_chatColor(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg,190,input,3);
	replace_all(msg,190,"\g","^4");// green
	replace_all(msg,190,"\n","^1");// normal
	replace_all(msg,190,"\t","^3");// team
	
	if (id) players[0] = id; else get_players(players,count,"ch");
	for (new i=0;i<count;i++)
		if (is_user_connected(players[i]))
	{
		message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
		write_byte(players[i]);
		write_string(msg);
		message_end();
	}
}