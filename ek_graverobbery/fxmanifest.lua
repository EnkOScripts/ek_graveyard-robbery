fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'EnkO'
description 'Shop:https://enko.tebex.io'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'locales/locale.lua',
    'locales/cs.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'webhook_config.lua',
    'server/server.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target'
}

escrow_ignore {
    'config.lua',
    'webhook_config.lua',
    'locales/*.lua',
    'README.md'
}
