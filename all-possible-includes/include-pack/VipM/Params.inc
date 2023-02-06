#if defined _vipmodular_params_included
	#endinput
#endif
#define _vipmodular_params_included

#include amxmodx

/**
 * Vip Modular: Parameters
*/

enum E_ParamType {

    /*
     * Пользовательский тип параметра. Подразумевает использование события OnRead.
     * Обязательность таких параметров игнорируется.
     */
    ptCustom = 0,
    
    /*
     * Целое число.
     */
    ptInteger,
    
    /*
     * Дробное число.
     */
    ptFloat,
    
    /*
     * true/false.
     */
    ptBoolean,
    
    /*
     * Строка.
     */
    ptString,
    
    /*
     * Цвет (Массив из трёх целых чисел).
     */
    ptColor,
    
    /*
     * Двумерный вектор (Массив из двух дробных чисел).
     */
    ptVector2,
    
    /*
     * Трёхмерный вектор (Массив из трёх дробных чисел).
     */
    ptVector3,
    
    /*
     * Условный элемент.
     */
    ptLimit,
    
    /*
     * Массив условных элементов.
     */
    ptLimits,
}
stock const VIPM_PARAM_TYPE_NAMES[E_ParamType][] = {"Custom", "Integer", "Float", "Bool", "String", "Color", "Vector2", "Vector3", "Limit", "Limits"};

stock VipM_Params_GetInt(const Trie:Params, const Key[], const Def = 0) {
    new Val;
    if (Params == Invalid_Trie) {
        return Def;
    }
    return TrieGetCell(Params, Key, Val) ? Val : Def;
}

stock any:VipM_Params_GetCell(const Trie:Params, const Key[], const any:Def = 0) {
    return any:VipM_Params_GetInt(Params, Key, _:Def);
}

stock bool:VipM_Params_GetBool(const Trie:Params, const Key[], const bool:Def = false) {
    new bool:Val;
    if (Params == Invalid_Trie) {
        return Def;
    }
    return TrieGetCell(Params, Key, Val) ? Val : Def;
}

stock Float:VipM_Params_GetFloat(const Trie:Params, const Key[], const Float:Def = 0.0) {
    new Float:Val;
    if (Params == Invalid_Trie) {
        return Def;
    }
    return TrieGetCell(Params, Key, Val) ? Val : Def;
}

stock VipM_Params_GetStr(const Trie:Params, const Key[], Out[], const Len, const Def[] = NULL_STRING) {
    new s = 0;
    if (
        Params != Invalid_Trie
        && TrieGetString(Params, Key, Out, Len, s)
    ) {
        return s;
    }

    return formatex(Out, Len, Def);
}

stock Array:VipM_Params_GetArr(const Trie:Params, const Key[]) {
    new Array:Arr = Invalid_Array;
    if (
        Params == Invalid_Trie
        || !TrieGetCell(Params, Key, Arr)
    ) {
        return Invalid_Array;
    }

    return Arr;
}

stock T_LimitUnit:VipM_Params_GetLimit(const Trie:Params, const Key[], const T_LimitUnit:Def = Invalid_LimitUnit) {
    new T_LimitUnit:iLimit;
    if (Params == Invalid_Trie) {
        return Def;
    }
    return TrieGetCell(Params, Key, iLimit) ? iLimit : Def;
}

stock bool:VipM_Params_ExecuteLimit(
    const Trie:tParams,
    const sKey[] = "Limit",
    const UserId = 0,
    const bool:bDef = true
) {
    new T_LimitUnit:iLimit = VipM_Params_GetLimit(tParams, sKey);
    if (iLimit == Invalid_LimitUnit) {
        return bDef;
    }
    return VipM_Limits_Execute(iLimit, UserId);
}

stock bool:VipM_Params_ExecuteLimitsList(
    const Trie:tParams,
    const sKey[] = "Limits",
    const UserId = 0,
    const E_LimitsExecType:iType = Limit_Exec_OR,
    const bool:bDef = true
) {
    new Array:aLimits = VipM_Params_GetArr(tParams, sKey);
    if (aLimits == Invalid_Array) {
        return bDef;
    }
    return VipM_Limits_ExecuteList(aLimits, UserId, iType);
}
