fx_version 'cerulean'
game 'gta5'

author 'oosayeroo'
description 'sayer-shops'
version '2.0.0'

shared_scripts { 
    'config.lua',
    '@jim_bridge/starter.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/*.html',
    'html/*.js',
    'html/*.css',
    'html/images/*.png'
}

lua54 'yes'


dependency 'jim_bridge'