fx_version 'cerulean'
game 'gta5'

author 'DieselScripts / Scrap & Boost add-on'
description 'Configurable scrapyard + illegal boosting contracts for qb-core'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'qb-core',
    'qb-target',
    'oxmysql',
    'progressbar',
    'ox_lib',
    'qb-policejob'
}
