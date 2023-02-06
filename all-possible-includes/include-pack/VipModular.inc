#if defined _vipmodular_included
	#endinput
#endif
#define _vipmodular_included

#include amxmodx
#include json

stock const VIPM_LIBRARY[] = "VipModular";
#define _VIPM_VERSION "5.0.0-beta.7"
stock const VIPM_VERSION[] = _VIPM_VERSION;
stock const VIPM_CFG_PATH[] = "plugins/VipModular";
#define _VIPM_PLUGIN_URL "https://github.com/ArKaNeMaN/amxx-VipModular-pub"

/**
 * Получение пути, относительно папки с конфигами вип-системы или AmxModX.
 *
 * @note    Если название файла начинается со слеша `/`, файл будет взят из папки amxmodx/configs.
 *          Иначе из папки вип-системы (см. константу VIPM_CFG_PATH).
 *
 * @param Path      Путь / Название файла.
 * @param Out       Буффер для записи полученного пути.
 * @param Len       Размер буфера.
 *
 * @return  Кол-во записанных в буфер ячеек.
 */
stock VipM_GetCfgPath(const Path[], Out[], const Len){
    static __amxx_configsdir[PLATFORM_MAX_PATH];
    if (!__amxx_configsdir[0]) {
        get_localinfo("amxx_configsdir", __amxx_configsdir, charsmax(__amxx_configsdir));
    }
    
    return (Path[0] == '/')
        ? formatex(Out, Len, "%s%s", __amxx_configsdir, Path)
        : formatex(Out, Len, "%s/%s/%s", __amxx_configsdir, VIPM_CFG_PATH, Path);
}

// Инлайн версия предыдущего стока.
// Сорян за извращения :))
stock __inl_VipM_GetCfgPath[PLATFORM_MAX_PATH] = "";
#define inl_VipM_GetCfgPath(%1) \
    ( \
        VipM_GetCfgPath(%1, __inl_VipM_GetCfgPath, charsmax(__inl_VipM_GetCfgPath)) \
        ? __inl_VipM_GetCfgPath \
        : NULL_STRING \
    )

enum _:VipM_FwdReturn{
    /*
     * Продолжить действие
     */
    VIPM_CONTINUE = 0,
    
    /*
     * Прервать действие
     */
    VIPM_STOP = 1,
}

/**
 * Вызывается в момент инициалзиации модулей, типов условных элементов и режимов доступа.
 *
 * @note    Вызывается из plugin_precache
 *
 * @noreturn
 */
forward VipM_OnInitModules();

/**
 * Вызывается в момент чтения элемента конфига (модуля или ограничения).
 *
 * @param jUnit     JSON-обьект с параметрами
 * @param tParams   Хэш-карта с прочитанными параметрами. Может быть изменена.
 *
 * @note    Параметр tParams содержит только прочитанные ядром параметры.
 *
 * @note    Соответствует событиям Limit_OnRead и Module_OnRead,
 *          и форвардам VipM_OnReadLimitUnit и VipM_OnReadModuleUnit.
 *          Вызывается перед ними.
 *
 * @return По умолчанию VIPM_CONTINUE. Если вернуть VIPM_STOP, элемент конфига будет проигнорирован.
 */
forward VipM_OnReadUnit(const JSON:jUnit, const Trie:tParams);

/**
 * Вызывается после полной загрузки вип-системы.
 *
 * @note    Вызывается из plugin_precache
 *
 * @noreturn
 */
forward VipM_OnLoaded();

/**
 * Вызывается после загрузки привилегий игрока.
 *
 * @param UserId    Индекс игрока, чьи привилегии были загружены.
 *
 * @note            Можно использовать для кэширования параметров привилегий.
 *
 * @noreturn
 */
forward VipM_OnUserUpdated(const UserId);

/**
 * Обновляет привилегии указанного пользователя.
 *
 * @param UserId    Индекс игрока, чьи привилегии надо обновить.
 *
 * @noreturn
 */
native VipM_UserUpdate(const UserId);

/**
 * Выводит лог с указанием JSON-файла, из которого было прочитано указанное значене.
 *
 * @param jValue    Значение, для которого надо вывести лог.
 * @param sPrefix   Префикс лога. Например: ERROR, WARNING, INFO
 * @param sMessage  Текст сообщения.
 * @param any:...   Параметры форматирования сообщения.
 *
 * @noreturn
 */
native VipM_Json_LogForFile(const JSON:jValue, const sPrefix[], const sMessage[], any:...);

#include <VipM/Modules>
#include <VipM/Limits>
#include <VipM/ItemsController>
#include <VipM/Params>
