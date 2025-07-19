fx_version 'cerulean'
game 'gta5'

author 'GuilhermeDuck04(GHOST)'
description 'Ghost-HUD'
version '1.3.0'

client_scripts {
    'client/main.lua',
    'client/voip.lua',
    'client/temperature.lua',
    'client/minimap.lua',
    'client/config.lua'
}

server_script 'server/server.lua'

shared_script 'config.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/config.js',
    'html/images/*.png',
    'html/images/armas/*.png',
    'stream/minimap.gfx'
}

dependencies {
    'pma-voice',
    'qb-core'
}

data_file 'DLC_ITYP_REQUEST' 'stream/minimap.gfx'