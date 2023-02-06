#if defined _vipmodular_l_included
	#endinput
#endif
#define _vipmodular_l_included

/**
 * Vip Modular: Limits
*/

enum T_LimitUnit {Invalid_LimitUnit = -1}

enum E_LimitEvent{

    /*
     * Описание:    Вызывается после прочтения параметров условного элемента.
     * Возв. тип:   VipM_FwdReturn
     * Параметры:   (const JSON:jUnit, Trie:tParams):
     *      jUnit - JSON-обьект с параметрами.
     *      tParams - Хэш-карта с прочитанными параметрами. Может быть изменена.
     * 
     * Примечание: Вызывается в plugin_precache
     * Примечание: Если возвращено VIPM_STOP, условный элемент будет пропущен.
     */
    Limit_OnRead,

    /*
     * Описание:    Вызывается при проверке выполнения условия.
     * Возв. тип:   bool
     * Параметры:   (const Trie:tParams, const UserId):
     *      tParams - Хэш-карта с параметрами. Для извлечения отдельных значений можно использовать стоковые функции VipM_Params_*.
     *      UserId - Индекс игрока. 0, если условный элемент не зависит от игрока.
     * 
     * Примечание: Если возвращено true, условие выполняется.
     * Примечание: Не вызывается для статических условных элементов.
     */
    Limit_OnCheck,
}

enum E_LimitsExecType {
    
    /* ИЛИ */
    Limit_Exec_OR,

    /* И */
    Limit_Exec_AND,

    /* Исключающее ИЛИ */
    Limit_Exec_XOR,
}

/**
 * Вызывается перед чтением параметров условного элемента.
 *
 * @param jUnit     JSON-обьект с параметрами.
 * @param tParams   Хэш-карта с прочитанными параметрами. Может быть изменена.
 *
 * @return          Если возвращено VIPM_STOP, условный элемент будет пропущен.
 */
forward VipM_OnReadLimitUnit(const JSON:jUnit, const Trie:tParams);

/**
 * Регистрирует в системе тип условного элемента.
 *
 * @param jUnit     Название регистрируемого типа.
 * @param tParams   Относится ли регистрируемый тип к игрокам.
 * @param tParams   Является ли регистрируемый тип статическим.
 *
 * @note            Статические типы не имеют параметров и колбэков, значения для них надо передавать через натив VipM_Limits_SetStaticValue.
 *                  Работают быстрее обычного. Могут относиться к игрокам.
 *                  Примеры статических типов есть в VipM-L-Default.sma
 *
 * @noreturn
 */
native VipM_Limits_RegisterType(const sName[], const bool:bForPlayer = true, const bool:bStatic = false);

/**
 * Регистрирует обработчик события для указанного типа условного элемента.
 *
 * @param sName     Название типа.
 * @param iEvent    Событие.
 * @param sFunc     Название функции-обработчика.
 *
 * @return  Вернёт true, если обработчик успешно зарегистрирован.
 */
native VipM_Limits_RegisterTypeEvent(const sName[], const E_LimitEvent:iEvent, const sFunc[]);

/**
 * Добавляет параметр(ы) для типа условного элемента.
 *
 * @param sName     Название типа.
 * @param any:...   Перечисление параметров.
 *
 * @note            Формат указания параметров: VipM_Limits_AddTypeParams(..., const ParamName[], const E_ParamType:ParamType, const bool:ParamRequired, ...);
 * @note            ParamName - Название параметра / ParamType - Тип параметра / ParamRequired - Обязателен ли параметр.
 * @note            Пример: VipM_Limits_AddTypeParams("ExampleModule", "Param1", ptInteger, true, "Param2", ptCustom, false);
 *
 * @noreturn
 */
native VipM_Limits_AddTypeParams(const sName[], any:...);

/**
 * Читает условный элемент из JSON-обьекта.
 *
 * @param jLimit    JSON-обьект.
 *
 * @note            После вызова натива, JSON-обьект не очищается.
 *
 * @return          Индекс прочтённого условного элемента. Invalid_LimitUnit, если что-то пошло не так.
 */
native T_LimitUnit:VipM_Limits_ReadFromJson(const JSON:jLimit);

/**
 * Читает список условных элементов из JSON-обьекта.
 *
 * @param jLimits   JSON-обьект.
 * @param aLimits   Динамический массив, в который надо добавить прочтённые элементы, либо Invalid_Array, если надо создать новый.
 *
 * @note            После вызова натива, JSON-обьект не очищается.
 * @note            При передаче параметра aLimits, функция вернёт этот же массив с новыми элементами.
 *
 * @return          Динамический массив с индексами прочтённых условных элементов. Invalid_Array, если не было прочтено ни одного элемента.
 */
native Array:VipM_Limits_ReadListFromJson(const JSON:jLimits, Array:aLimits = Invalid_Array);

/**
 * Устанавливает значение для статического типа условного элемента.
 *
 * @param sName     Название типа.
 * @param bNewValue Новое значение.
 * @param UserId    Индекс игрока, если тип относится к игрокам.
 *
 * @note            Желательно инициализировать статическое значение после регистрации типа.
 *
 * @noreturn
 */
native VipM_Limits_SetStaticValue(const sName[], const bool:bNewValue, const UserId = 0);

/**
 * Выполняет проверку условного элемента.
 *
 * @param iLimit    Индекс условного элемента.
 * @param UserId    Индекс игрока.
 *
 * @note            Если индекс игрока не передан, попытка использовать относящийся к игроку условный оператор вызовет ошибку.
 *                  Но это уже ошибка конфигурации.
 *
 * @return          true, если условие выполняется, иначе false.
 */
native bool:VipM_Limits_Execute(const T_LimitUnit:iLimit, const UserId = 0);

/**
 * Выполняет проверку списка условных элементов.
 *
 * @param aLimits   Динамический массив условных элементов.
 * @param UserId    Индекс игрока.
 * @param iType     Логический оператор. См. перечисление E_LimitsExecType.
 *
 * @note            Если индекс игрока не передан, попытка использовать относящийся к игроку условный оператор вызовет ошибку.
 *                  Но это уже ошибка конфигурации.
 *
 * @return          true, если условие выполняется, иначе false.
 */
native bool:VipM_Limits_ExecuteList(const Array:aLimits, const UserId = 0, const E_LimitsExecType:iType = Limit_Exec_OR);
