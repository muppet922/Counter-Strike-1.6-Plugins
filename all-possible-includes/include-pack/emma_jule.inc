
#if defined _emma_jule_included
	#endinput
#endif

#define _emma_jule_included

#if !defined _reapi_included
	#include <reapi>
#endif


#define VALID_PLAYER(%1)		(1 <= %1 <= MaxClients)
#define VALID_TEAM(%1)			(TEAM_TERRORIST <= get_member(%1, m_iTeam) <= TEAM_CT)


#define MOD(%1,%2)				((((%1) % (%2)) + (%2)) % (%2))
#define CLAMP(%1,%2,%3)			(max(%2, min(%3, %1)))
#define MAXIMUS()				(((1 << (cellbits - 2)) - 1) | (1 << (cellbits - 2)))


const BAD_WEAPONS = ((1 << CSW_GLOCK) | (1 << CSW_C4));
const NOCLIP_WEAPONS = (CSW_ALL_GRENADES | BAD_WEAPONS | (1 << CSW_KNIFE));
const OBS_ACCESS = ((1 << OBS_CHASE_FREE) | (1 << OBS_IN_EYE));


enum (<<=1)
{
	ALL_PISTOLS = 1, // 1
	ALL_SHOTGUNS, // 2
	ALL_SMGS, // 4
	ALL_RIFLES, // 8
	ALL_SNIPERRIFLES, // 16
	ALL_MACHINEGUNS, // 32
};


/*
	random_num с возможностью исключить определенное число
	
	return получившее число
*/
stock random_num_without(c1, c2, exclude)
{
	new n;
	
	do {
		n = random_num(c1, c2);
	}
	while (n == exclude);
	
	return n;
}


/*
	Получим кол-во проигранных раундов
	
	return: num
*/
stock rg_get_current_round()
{
	return (get_member_game(m_iTotalRoundsPlayed) + 1);
}


/*
	Проверяем если от начала раунда прошло Х секунд
	
	return: 1 - если таково | 0 - нет (-1 раунд окончен)
*/
stock rg_is_time_expired(Float:sec)
{
	if (get_member_game(m_bRoundTerminating))
		return -1;
	
	return (get_gametime() - Float:get_member_game(m_fRoundStartTime) > sec);
}


/*
	Сток вернет кол-во секунд до конца раунда\фризитайма
	
	return: время
*/
stock Float:rg_get_remaining_time()
{
	return (float(get_member_game(m_iRoundTimeSecs)) - get_gametime() + Float: get_member_game(m_fRoundStartTimeReal));
}


/*
	Проверяем если остались 1 на 1
	
	return: true - если таково | false - нет
*/
stock bool:rg_is_1v1()
{
	new iNumAliveT, iNumAliveCT;
	rg_initialize_player_counts(iNumAliveT, iNumAliveCT, _, _);
	
	return bool:(iNumAliveT == 1 && iNumAliveCT == 1);
}


/*
	return
	
	1 - у игрока есть первичное оружие
	2 - у игрока есть вторичное оружие
	4 - у игрока есть нож
	8 - у игрока есть хоть одна граната
	16 - у игрока есть С4
	
	это может быть в связке:
	- допустим 3 - у игрока есть и первичное и вторичное оружие
	- допустим 9 - у игрока есть и первичное оружие и С4
*/
stock rg_get_user_slot_status(const id)
{
	new _weaponbit;
	
	for (new InventorySlotType:i = PRIMARY_WEAPON_SLOT; i < MAX_ITEM_TYPES; i++)
		if (!is_nullent(get_member(id, m_rgpPlayerItems, i)))
			_weaponbit |= (1 << _:i);
	
	return _weaponbit;
}


/*
	Проверяем если текущий год високосний
	
	return: true - если таково | false - нет
*/
stock bool:is_leap_year(year = 0)
{
	if (!year)
		date(year);
	
	return bool:(((year % 4) == 0) && (((year % 100) != 0) || ((year % 400) == 0)));
}


/*
	Сток выдаст рандом оружие игроку
	
	noreturn
*/
stock rg_give_random_item(const id, GiveType:type = GT_APPEND)
{
	new szWeapon[24], wId;
	
	do {
		wId =
			random_num(CSW_P228, CSW_LAST_WEAPON);
	}
	while (
		BAD_WEAPONS & (1 << wId) /* || user_has_weapon(id, _:wId) */
	);

	rg_get_weapon_info(wId, WI_NAME, szWeapon, charsmax(szWeapon));
	rg_give_item(id, szWeapon, type);
}


/*
	Выдадим сразу несколько оружий игроку (как в mp_default_primary / secondary из game.cfg)
	что может вам дать rg_give_default_items()
	
	rg_give_items(id, "ak47 m4a1 awp deagle");
	
	noreturn
*/
stock rg_give_items(const id, szGuns[]) //, bpammo = 0)
{
	new szWeapon[11], aSize = strlen(szGuns) - 1;
	while (argbreak(szGuns, szWeapon, charsmax(szWeapon), szGuns, aSize) != -1)
		rg_give_item(id, fmt("weapon_%s", szWeapon));
}


/*
	Получаем случайного игрока
	
	return	- индекс выбранного игрока
*/
stock get_random_player(const flags[] = "", const team[] = "")
{
	new aPlayers[MAX_PLAYERS], pNum;
	get_players(aPlayers, pNum, flags, team);
	
	return aPlayers[random(pNum)];
}


/*
	Проиграем звуковой файл клиенту(ам)
	
	noreturn
*/
stock UTIL_PlaySound(id = 0, const sample[], bool:bObserver = false)
{
	// Убедимся MP3 ли это
	new bIsMP3 = (equali(sample[strlen(sample) - 4], ".mp3"));
	
	if (bIsMP3)
		client_cmd(id, "mp3 play ^"sound/%s^"", sample);
	else
		client_cmd(id, "spk ^"%s^"", sample);
	
	// Проиграть также звук игрокам которые следят за ним
	if (bObserver)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!is_user_connected(i))
				continue;
			
			if (i == id)
				continue;
			
			// Не подходит режим камеры
			if (~OBS_ACCESS & (1 << get_entvar(i, var_iuser1)))
				continue;

			// Не смотрит за нашим игроком
			// if (get_entvar(i, var_iuser2) != pOwner)
			if (get_member(i, m_hObserverTarget) != pOwner)
				continue;
			
			if (bIsMP3)
				client_cmd(i, "mp3 play ^"sound/%s^"", sample);
			else
				client_cmd(i, "spk ^"%s^"", sample);
		}
	}
}


/*
	Получим какая команда выигрывает в счете Т и КТ (+ бонус разницы в счете)
	
	return TeamName
*/
stock TeamName:rg_get_team_dominate(&diff = 0)
{
	new TeamName:team = TEAM_UNASSIGNED;
	diff = get_member_game(m_iNumTerroristWins) - get_member_game(m_iNumCTWins);
	
	if (diff > 0)
		team = TEAM_TERRORIST;
	else if (diff < 0)
		team = TEAM_CT;
	
	abs(diff);
	
	return team;
}


/*
	Получим какая команда доминирует в даннный момент (побед подряд) с определенным кол-вом побед
	
	return TeamName
*/
stock TeamName:rg_get_team_wins_row(const wins)
{
	new TeamName:team = TEAM_UNASSIGNED;
	new iNumConsecutiveCTLoses = get_member_game(m_iNumConsecutiveCTLoses);
	new iNumConsecutiveTerroristLoses = get_member_game(m_iNumConsecutiveTerroristLoses);
	
	if (iNumConsecutiveCTLoses > 0)
		team = TEAM_TERRORIST;
	else if (iNumConsecutiveTerroristLoses > 0)
		team = TEAM_CT;
	
	if (iNumConsecutiveCTLoses + iNumConsecutiveTerroristLoses < wins)
		team = TEAM_UNASSIGNED;
	
	return team;
}


/*
	Проверим если это первый спавн игрока в этом раунде
	
	return: true - если таково | false - нет
*/
stock bool:rg_is_user_first_spawn(const id)
{
	return bool:(get_member(id, m_iNumSpawns) == 1);
}


/*
	Добавим\отнимем жизни клиенту
	
	noreturn
*/
stock rg_add_user_health(const id, const Float:health, bool:obey_limit = true)
{
	if (obey_limit)
		set_entvar(id, var_health, floatclamp(Float: get_entvar(id, var_health) + health, 1.0, Float: get_entvar(id, var_max_health)));
	else
		set_entvar(id, var_health, floatmax(Float: get_entvar(id, var_health) + health, 1.0));
}


/*
	Сток проверит если игрок сейчас со снайперским оружием
	
	return true - в случае успеха | false - в противном случае
*/
stock bool:rg_is_user_srfile(const id, &bool:bHasZoom = false)
{
	new pWeapon = get_member(id, m_pActiveItem);
	
	if (is_nullent(pWeapon)
		|| ~CSW_ALL_SNIPERRIFLES & (1 << get_member(pWeapon, m_iId))
	)
		return false;
	
	bHasZoom = bool:(get_member(id, m_iClientFOV) <= DEFAULT_SMALL_SNIPERS_ZOOM);
	
	return true;
}


/*
	Передаем деньги из одни руки в другие
	
	noreturn
*/
stock rg_transfer_account(const pReciever, const pSender, const iAmount)
{
	rg_add_account(pSender, -iAmount);
	rg_add_account(pReciever, iAmount);
}


/*
	WeaponIdType: get_user_weapon(id)
	
	return WeaponIdType
*/
stock WeaponIdType:rg_get_user_weapon(const id)
{
	new pWeapon = get_member(id, m_pActiveItem);
	
	return is_nullent(pWeapon) ? WEAPON_NONE : get_member(pWeapon, m_iId);
}



/*
	Проверим если сейчас уикенд (выходные)
	
	return: true - если таково | false - нет
*/
stock bool:is_weekend(&day = 0)
{
	new szTime[3];
	get_time("%u", szTime, charsmax(szTime));
	
	if (!(1 < (day = str_to_num(szTime)) < 7))
		return true;
	
	return false;
}


/*
	Проверим если у игрока сейчас в обойме последний патрон
	
	return true - в случае успеха | false - нет
*/
stock bool:rg_is_last_bullet(const id)
{
	new pWeapon = get_member(id, m_pActiveItem);
	
	if (is_nullent(pWeapon)
		|| NOCLIP_WEAPONS & (1 << get_member(pWeapon, m_iId))
	)
		return false;
	
	
	return bool: (get_member(pWeapon, m_Weapon_iClip) == 1);
}


/*
	Тот же strlen только не сжирает по 2 символа если Multi-byte
	
	return Number of valid character bytes in the string.
*/
stock strlen_ex(const string[])
{
	new len;
	for (new i; size = strlen(string); i < size; i++)
	{
		if ((string[i] & 0xE0) == 0xC0)
			i++;
		
		len++;
	}
	
	return len;
}


/*
	Проверим если игрок сейчас задыхается под водой (можно обойти ExecuteHam если pev->waterlevel != 3)
	
	return true - если таково | false - в противном случае
*/
stock bool:rg_is_user_water_pain(const id)
{
	return bool: (Float:get_entvar(id, var_pain_finished) > get_gametime());
}



/*
	Сток проверит если стринга сстоит только из цифр
	
	return true - если таково | false - в противном случае
*/
#pragma deprecated Use is_str_num() instead.
stock is_digit_string(const string[])
{
	for (new i, iSize = strlen(string); i < iSize; i++)
		if (!isdigit(string[i]))
			return false;
	
	return true;
}


/*
	Сток высчитает среднее значение пинга у конкретных игроков
	Допустим можно получить число команды которое на табле сверху всех пингов
	
	return	- среднее значение пинга
*/
stock get_players_ping(const flags[] = "", const team[] = "")
{
	new aPlayers[MAX_PLAYERS], pNum, iPing, iLoss, iCount;
	get_players(aPlayers, pNum, flags, team);
	
	while (--pNum >= 0) {
		if (get_user_ping(aPlayers[pNum], iPing, iLoss))
			iCount += iPing;
	}
	
	#pragma unused iLoss
	return iCount / pNum;
}


/*
	Сток выдаст/заберет баннихоп
	
	noreturn
*/
stock rg_set_user_bunnyhop(const id, bool:bSet)
{
	set_member(id, m_bAutoBunnyHopping, bSet);
	set_member(id, m_bMegaBunnyJumping, bSet);
}


/*
	Сток получит Mins / Maxs размеры из модели
	
	return true - в случае успеха | false - нет
*/
stock UTIL_GetModelSize(const szModel[], Float:vecSize[6] = NULL_VECTOR)
{
	new file, bof;

	if (!(file = fopen(szFileName, "rb")))
		return 0;
	
	// скип байтов
	//fseek(file, 176, SEEK_SET);
	fseek(file, 160, SEEK_SET);
	fread(file, bof, BLOCK_INT);
	fseek(file, bof + 8, SEEK_SET);
	fread_blocks(file, _:vecSize, 6, BLOCK_INT);
	
	fclose(file);
	
	return 1;
}


/*
	Cток высчитает длительность анимации исходя из модели укажите модель и номер желаемой анимации
	
	return - длительность анимации в успешном случае, 0.0 в случае неудачи
*/
stock Float: UTIL_CalculateAnimationLength(const szModel[], const sequence)
{
	new file = fopen(szModel, "rb");
	
	if (!file)
		return 0.0;
   
	new aData[32], i, seqs, frames, Float:FPS;
	
	// скип первых 164 байтов
	fseek(file, 164, SEEK_SET);
	{
		fread(file, seqs, BLOCK_INT);
		fread(file, i, BLOCK_INT);
		
		// fix
		if (!(0 <= sequence < seqs))
			return 0.0;
	}
   
	fseek(file, i + 176 * sequence, SEEK_SET);
	fread_blocks(file, aData, 32, BLOCK_CHAR);
   
	// fix
	if (aData[0] == '^0')
		return 0.0;
	
	fread(file, _:FPS, BLOCK_INT);
	fseek(file, 20, SEEK_CUR);
	fread(file, frames, BLOCK_INT);
	
	fclose(file);
	
	// вот и все делим получаем фреймы и фпс и делим
	return Float: (frames / FPS);
}


/*
	Сток выдаст/заберет бесконечные патроны
	@note Учтите квар mp_infinite_ammo
	
	Использование: Создайте квар к примеру infinite_ammo "abcde" и выведите число (бит) через read_flags()
	
	noreturn
*/
stock rg_set_user_infinite_clip(const id, weapon_bits, bool:bSet)
{
	if (weapon_bits == 0) {
		set_member(id, m_iWeaponInfiniteAmmo, bSet);
		return;
	}
	
	new iPlayerWeapons = get_member(id, m_iWeaponInfiniteIds);
	
	if (weapon_bits & ALL_PISTOLS)
		set_member(id, m_iWeaponInfiniteIds, bSet ? (iPlayerWeapons |= CSW_ALL_PISTOLS) : (iPlayerWeapons &= ~CSW_ALL_PISTOLS));
	
	if (weapon_bits & ALL_SHOTGUNS)
		set_member(id, m_iWeaponInfiniteIds, bSet ? (iPlayerWeapons |= CSW_ALL_SHOTGUNS) : (iPlayerWeapons &= ~CSW_ALL_SHOTGUNS));
	
	if (weapon_bits & ALL_SMGS)
		set_member(id, m_iWeaponInfiniteIds, bSet ? (iPlayerWeapons |= CSW_ALL_SMGS) : (iPlayerWeapons &= ~CSW_ALL_SMGS));
	
	if (weapon_bits & ALL_RIFLES)
		set_member(id, m_iWeaponInfiniteIds, bSet ? (iPlayerWeapons |= CSW_ALL_RIFLES) : (iPlayerWeapons &= ~CSW_ALL_RIFLES));
	
	if (weapon_bits & ALL_SNIPERRIFLES)
		set_member(id, m_iWeaponInfiniteIds, bSet ? (iPlayerWeapons |= CSW_ALL_SNIPERRIFLES) : (iPlayerWeapons &= ~CSW_ALL_SNIPERRIFLES));
	
	if (weapon_bits & ALL_SNIPERRIFLES)
		set_member(id, m_iWeaponInfiniteIds, bSet ? (iPlayerWeapons |= CSW_ALL_MACHINEGUNS) : (iPlayerWeapons &= ~CSW_ALL_MACHINEGUNS));
}

