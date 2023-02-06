#if defined _vipmodular_m_included
	#endinput
#endif
#define _vipmodular_m_included

/**
 * Vip Modular: Modules
*/

#define VIPM_MODULE_MAX_NAME 32

enum E_ModuleEvent{

    /*
     * Описание:    Вызывается, когда модуль был активирован.
     * Возв. тип:   VipM_FwdReturn
     * Параметры:   ()
     * 
     * Примечание: Вызывается в plugin_precache
     * Примечание: Если возвращено VIPM_STOP, моудль не будет активирован.
     */
    Module_OnActivated,

    /*
     * Описание:    Вызывается, когда читаются параметры модуля.
     * Возв. тип:   VipM_FwdReturn
     * Параметры:   (const JSON:jCfg, Trie:Params):
     *      jCfg - JSON-обьект с параметрами.
     *      Params - Хэш-карта с прочитанными параметрами. Может быть изменена.
     * 
     * Примечание: Вызывается в plugin_precache
     * Примечание: Если возвращено VIPM_STOP, элемент модуля будет пропущен.
     */
    Module_OnRead,

    /*
     * Описание:    Вызывается, когда надо обьединить два набора параметров модуля. Только для модулей с Once = false.
     * Возв. тип:   Trie
     * Параметры:   (const Trie:MainParams, const Trie:NewParams):
     *      MainParams - Основной набор параметров модуля.
     *      NewParams - Добавляемый набор параметров модуля.
     * 
     * Примечание: Результат обьединения должен быть возвращён обработчиком события.
     */
    Module_OnCompareParams,
}

forward VipM_OnReadModuleUnit(const JSON:jUnit, const Trie:tParams);

/**
 * Регистрирует новый модуль.
 *
 * @param Module    Название модуля.
 * @param Once      Обьединять ли параметры элементов модуля. true - Нет, false - Да. Подразумевает использование события OnCompareParams.
 *
 * @noreturn
 */
native VipM_Modules_Register(const Module[], const bool:Once = true);

/**
 * Регистрирует обработчик события для указанного модуля.
 *
 * @param Module    Название модуля.
 * @param Event     Событие.
 * @param Func      Название функции-обработчика.
 *
 * @return  Вернёт true, если обработчик успешно зарегистрирован.
 */
native bool:VipM_Modules_RegisterEvent(const Module[], const E_ModuleEvent:Event, const Func[]);

/**
 * Добавляет набор параметров для указанного модуля.
 *
 * @param Module    Название модуля.
 * @param any:...   Перечисление параметров.
 *
 * @note    Формат указания параметров: VipM_Modules_AddParams(..., const ParamName[], const E_ParamType:ParamType, const bool:ParamRequired, ...);
 * @note    ParamName - Название параметра / ParamType - Тип параметра / ParamRequired - Обязателен ли параметр.
 * @note    Пример: VipM_Modules_AddParams("ExampleModule", "Param1", ptInteger, true, "Param2", ptCustom, false);
 *
 * @noreturn
 */
native VipM_Modules_AddParams(const Module[], const any:...);
#define VipM_SetModuleParams VipM_Modules_AddParams

/**
 * Активен ли указанный модуль.
 *
 * @param Module    Название модуля.
 *
 * @return true, если модуль активен, иначе false.
 */
native bool:VipM_Modules_IsActive(const Module[]);

/**
 * Получение набора параметров модуля для указанного игрока.
 *
 * @param Module    Название модуля.
 * @param UserId    Индекс игрока.
 *
 * @return Хэш-карту с параметрами.
 */
native Trie:VipM_Modules_GetParams(const Module[], const UserId);
