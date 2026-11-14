fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'cobalt_mechanic'
author 'Project Cobalt'
description 'Mechanic shops: customisation, upgrades, repairs, wear, staff billing and self-service checkout'
version '1.0.0'

dependencies {
    'cobalt_mysql',
    'ox_lib',
    'ox_target',
    'cobalt_core',
    'cobalt_inventory',
    'cobalt_banking',
    'cobalt_management',
    'cobalt_vehiclekeys',
}

shared_script '@ox_lib/init.lua'

ox_libs { 'locale' }

client_script 'client/init.lua'

server_scripts {
    '@cobalt_mysql/lib/MySQL.lua',
    'server/init.lua',
}

ui_page '_nui/build/index.html'

files {
    'config.lua',
    'client/*.lua',
    'shared/*.lua',
    'data/*.lua',
    'locales/*.json',
    'data/carcols_gen9.meta',
    'data/carmodcols_gen9.meta',
    '_nui/build/index.html',
    '_nui/build/**/*',
}

data_file 'CARCOLS_GEN9_FILE' 'data/carcols_gen9.meta'
data_file 'CARMODCOLS_GEN9_FILE' 'data/carmodcols_gen9.meta'
