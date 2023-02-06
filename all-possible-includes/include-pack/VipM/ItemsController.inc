#if defined _vipmodular_ic_included
	#endinput
#endif
#define _vipmodular_ic_included

/**
 * Vip Modular: Items Controller
*/

enum VipM_IC_T_Item {VipM_IC_Invalid_Item = -1}

enum E_ItemTypeEvent{

    /*
     * Описание:    Вызывается, когда читаются параметры предмета.
     * Возв. тип:   VipM_FwdReturn
     * Параметры:   (const JSON:jCfg, Trie:Params):
     *      jCfg - JSON-обьект с параметрами предмета.
     *      Params - Хеш-карта с прочитанными параметрами. Может быть изменена.
     * 
     * Примечание: Вызывается в момент чтения оружия нативом VipM_IC_JsonGetItem. Скорее всего в plugin_precache.
     * Примечание: Если возвращено VIPM_STOP, предмет будет пропущен.
     */
    ItemType_OnRead,

    /*
     * Описание:    Вызывается, когда предмет выдаётся игроку (При вызове натива VipM_IC_GiveItem).
     * Возв. тип:   VipM_FwdReturn
     * Параметры:   (const UserId, const Trie:Params):
     *      UserId - Индекс игрока, которому выдаётся предмет.
     *      Params - Хеш-карта с параметрами. Для извлечения отдельных значений можно использовать стоковые функции VipM_Params_*.
     * 
     * Примечание: Если возвращено VIPM_STOP, предмет не будет считаться выданным (Натив VipM_IC_GiveItem вернёт false).
     */
    ItemType_OnGive,
}

/**
 * Вызывается в момент инициалзиации типов предметов.
 *
 * @note    Вызывается из VipM_OnInitModules
 *
 * @noreturn
 */
forward VipM_IC_OnInitTypes();

/**
 * Вызывается после чтения предмета из JSON.
 *
 * @param jItem     JSON-обьект с параметрами предмета.
 * @param Params    Хеш-карта с прочитанными параметрами.
 *
 * @return  Если вернёт VIPM_STOP, предмет не будет загружен.
 */
forward VipM_IC_OnReadItem(const JSON:jItem, Trie:Params);

/**
 * Вызывается перед выдачей предмета игроку.
 *
 * @param UserId     Индекс игрока, которому выдаётся предмет.
 * @param Params    Хеш-карта с параметрами предмета.
 *
 * @return  Если вернёт VIPM_STOP, предмет не будет выдан.
 */
forward VipM_IC_OnGiveItem(const UserId, const Trie:Params);

/**
 * Регистрирует новый тип предмета.
 *
 * @param Type    Название типа.
 *
 * @return Индекс зарегистрированного типа
 */
native VipM_IC_RegisterType(const Type[]);

/**
 * Регистрирует обработчик события для указанного типа предмета.
 *
 * @param Type      Название типа.
 * @param Event     Событие.
 * @param Func      Название функции-обработчика.
 *
 * @return  Вернёт true, если обработчик успешно зарегистрирован.
 */
native VipM_IC_RegisterTypeEvent(const Type[], const E_ItemTypeEvent:Event, const Func[]);

/**
 * Загрузка предмета из JSON-обьекта.
 *
 * @param jItem     JSON-объект, содержащий информацию о предмете.
 *
 * @note    После загрузки предмета, JSON-объект уничтожается.
 * @note    Структура объекта:
 *              {
 *                  "Type": "НазваниеТипа",
 *                  "НазваниеПараметра1": "ЗначениеПараметра1",
 *                  "НазваниеПараметра2": "ЗначениеПараметра2",
 *                  ...
 *              }
 *
 * @return  Индекс загруженного предмета. VipM_IC_Invalid_Item, если что-то пошло не так.
 */
native VipM_IC_T_Item:VipM_IC_JsonGetItem(&JSON:jItem);

/**
 * Выдача предмета игроку.
 *
 * @param UserId     Индекс игрока.
 * @param ItemId     Индекс предмета, возвращённый нативом VipM_IC_JsonGetItem.
 *
 * @return  true, если предмет успешно выдан, иначе false.
 */
native bool:VipM_IC_GiveItem(const UserId, const VipM_IC_T_Item:ItemId);

stock Array:VipM_IC_JsonGetItems(JSON:jItems) {
    new Array:aItems = Invalid_Array;
    switch (json_get_type(jItems)) {
        case JSONArray: {
            new cItems = json_array_get_count(jItems);
            if (cItems < 1) {
                return Invalid_Array;
            }

            aItems = ArrayCreate(1, cItems);
            for (new i = 0; i < cItems; i++) {
                new JSON:jItem = json_array_get_value(jItems, i);
                new VipM_IC_T_Item:ItemId = VipM_IC_JsonGetItem(jItem);
                if (ItemId != VipM_IC_Invalid_Item) {
                    ArrayPushCell(aItems, ItemId);
                }
            }
            json_free(jItems);
        }

        case JSONObject, JSONString: {
            new VipM_IC_T_Item:ItemId = VipM_IC_JsonGetItem(jItems);
            if (ItemId == VipM_IC_Invalid_Item) {
                return Invalid_Array;
            }

            aItems = ArrayCreate(1, 1);
            ArrayPushCell(aItems, ItemId);
        }
    }
    return aItems;
}

stock bool:VipM_IC_GiveItems(const UserId, const Array:aItems) {
    if (aItems == Invalid_Array) {
        return false;
    }

    new bool:bRes = false;
    for (new i = 0; i < ArraySize(aItems); i++) {
        if (VipM_IC_GiveItem(UserId, VipM_IC_T_Item:ArrayGetCell(aItems, i))) {
            bRes = true;
        }
    }

    return bRes;
}
