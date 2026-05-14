fx_version 'cerulean'
game 'gta5'

author 'TinySprite Scripts (TSS)'
description 'tss-shops'
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

escrow_ignore {
	'config.lua',
	'client.lua',
	'server.lua',
	'Readme.md',
    'html/*.html',
    'html/*.js',
    'html/*.css',
}


dependency 'jim_bridge'
