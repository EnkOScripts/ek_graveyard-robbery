Locales = {}

function _U(str, ...)
    if Locales[Config.Locale] and Locales[Config.Locale][str] then
        return string.format(Locales[Config.Locale][str], ...)
    else
        return ''
    end
end
