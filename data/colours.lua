---@alias MechanicPaintTab 'metallic'|'matte'|'util'|'worn'|'metals'

---@class MechanicColour
---@field index integer
---@field name string
---@field hex string
---@field tab MechanicPaintTab
---@field group? string

---@param tab MechanicPaintTab
---@param group string?
---@param rows [integer, string, string][]
---@param into MechanicColour[]
local function add(tab, group, rows, into)
    for _, row in ipairs(rows) do
        into[#into + 1] = { index = row[1], name = row[2], hex = row[3], tab = tab, group = group }
    end
end

---@type MechanicColour[]
local colours <const> = {}

add('metallic', 'Whites', {
    { 107, 'Cream', '#F7EDD5' },
    { 111, 'White', '#FFFFF6' },
    { 112, 'Frost White', '#EAEAEA' },
    { 134, 'Pure White', '#FFFFFF' },
}, colours)

add('metallic', 'Blacks and greys', {
    { 0, 'Black', '#0D1116' },
    { 1, 'Graphite Black', '#1C1D21' },
    { 2, 'Black Steel', '#32383D' },
    { 3, 'Dark Silver', '#454B4F' },
    { 4, 'Silver', '#999DA0' },
    { 5, 'Blue Silver', '#C2C4C6' },
    { 6, 'Steel Grey', '#979A97' },
    { 7, 'Shadow Silver', '#637380' },
    { 8, 'Stone Silver', '#63625C' },
    { 9, 'Midnight Silver', '#3C3F47' },
    { 10, 'Gun Metal', '#444E54' },
    { 11, 'Anthracite Grey', '#1D2129' },
    { 147, 'Modshop Black', '#11141A' },
    { 156, 'Default Alloy', '#81827F' },
}, colours)

add('metallic', 'Reds', {
    { 27, 'Red', '#C00E1A' },
    { 28, 'Torino Red', '#DA1918' },
    { 29, 'Formula Red', '#B6111B' },
    { 30, 'Blaze Red', '#A51E23' },
    { 31, 'Graceful Red', '#7B1A22' },
    { 32, 'Garnet Red', '#8E1B1F' },
    { 33, 'Desert Red', '#6F1818' },
    { 34, 'Cabernet Red', '#49111D' },
    { 35, 'Candy Red', '#B60F25' },
    { 143, 'Black Red', '#0E0D14' },
    { 150, 'Lava Red', '#BC1917' },
}, colours)

add('metallic', 'Oranges and golds', {
    { 36, 'Sunrise Orange', '#D44A17' },
    { 37, 'Classic Gold', '#C2944F' },
    { 38, 'Orange', '#F78616' },
    { 90, 'Bronze', '#916532' },
    { 97, 'Golden Brown', '#653F23' },
    { 104, 'Choco Orange', '#752B19' },
    { 138, 'Bright Orange', '#F6AE20' },
}, colours)

add('metallic', 'Yellows', {
    { 88, 'Taxi Yellow', '#FFCF20' },
    { 89, 'Race Yellow', '#FBE212' },
    { 91, 'Yellow Bird', '#E0E13D' },
}, colours)

add('metallic', 'Greens', {
    { 49, 'Dark Green', '#132428' },
    { 50, 'Racing Green', '#122E2B' },
    { 51, 'Sea Green', '#12383C' },
    { 52, 'Olive Green', '#31423F' },
    { 53, 'Green', '#155C2D' },
    { 54, 'Gasoline Blue Green', '#1B6770' },
    { 92, 'Lime', '#98D223' },
    { 125, 'Securicor Green', '#83C566' },
    { 139, 'Pale Green', '#B0EE6E' },
    { 144, 'Hunter Green', '#9F9E8A' },
}, colours)

add('metallic', 'Blues', {
    { 67, 'Diamond Blue', '#D6E7F1' },
    { 61, 'Midnight Blue', '#222E46' },
    { 62, 'Dark Blue', '#233155' },
    { 63, 'Saxony Blue', '#304C7E' },
    { 64, 'Blue', '#47578F' },
    { 65, 'Mariner Blue', '#637BA7' },
    { 66, 'Harbor Blue', '#394762' },
    { 68, 'Surf Blue', '#76AFBE' },
    { 69, 'Nautical Blue', '#345E72' },
    { 70, 'Bright Blue', '#0B9CF1' },
    { 71, 'Purple Blue', '#2F2D52' },
    { 72, 'Spinnaker Blue', '#282C4D' },
    { 73, 'Ultra Blue', '#2354A1' },
    { 74, 'Light Blue', '#6EA3C6' },
    { 127, 'Police Car Blue', '#4CC3DA' },
    { 140, 'Electric Blue', '#08E9FA' },
    { 141, 'Black Blue', '#0A0C17' },
    { 146, 'V Dark Blue', '#0B1421' },
    { 157, 'Epsilon Blue', '#AFD6E4' },
}, colours)

add('metallic', 'Purples and pinks', {
    { 135, 'Hot Pink', '#F21F99' },
    { 136, 'Salmon Pink', '#FDD6CD' },
    { 137, 'Vermillion Pink', '#DF5891' },
    { 142, 'Black Purple', '#0C0D18' },
    { 145, 'Purple', '#621276' },
}, colours)

add('metallic', 'Browns and beiges', {
    { 93, 'Champagne', '#9B8C78' },
    { 94, 'Pueblo Beige', '#503218' },
    { 95, 'Dark Ivory', '#473F2B' },
    { 96, 'Choco Brown', '#221B19' },
    { 98, 'Light Brown', '#775C3E' },
    { 99, 'Straw Beige', '#AC9975' },
    { 100, 'Moss Brown', '#6C6B4B' },
    { 101, 'Biston Brown', '#402E2B' },
    { 102, 'Beechwood', '#A4965F' },
    { 103, 'Dark Beechwood', '#46231A' },
    { 105, 'Beach Sand', '#BFAE7B' },
    { 106, 'Sun Bleached Sand', '#DFD5B2' },
}, colours)

add('metals', nil, {
    { 117, 'Brushed Steel', '#6A747C' },
    { 118, 'Brushed Black Steel', '#354158' },
    { 119, 'Brushed Aluminium', '#9BA0A8' },
    { 120, 'Chrome', '#5870A1' },
    { 158, 'Pure Gold', '#7A6440' },
    { 159, 'Brushed Gold', '#7F6A48' },
}, colours)

add('matte', nil, {
    { 131, 'White', '#FCF9F1' },
    { 12, 'Black', '#13181F' },
    { 13, 'Grey', '#26282A' },
    { 14, 'Light Grey', '#515554' },
    { 39, 'Red', '#CF1F21' },
    { 40, 'Dark Red', '#732021' },
    { 41, 'Orange', '#F27D20' },
    { 42, 'Yellow', '#FFC91F' },
    { 55, 'Lime Green', '#66B81F' },
    { 128, 'Green', '#4E6443' },
    { 151, 'Forest Green', '#2D362A' },
    { 152, 'Olive Drab', '#696748' },
    { 155, 'Foliage Green', '#5A6352' },
    { 82, 'Dark Blue', '#1F2852' },
    { 83, 'Blue', '#253AA7' },
    { 84, 'Midnight Blue', '#1C3551' },
    { 148, 'Purple', '#6B1F7B' },
    { 149, 'Dark Purple', '#1E1D22' },
    { 129, 'Brown', '#BCAC8F' },
    { 153, 'Desert Brown', '#7A6C55' },
    { 154, 'Desert Tan', '#C3B492' },
}, colours)

add('util', nil, {
    { 122, 'Off White', '#DFDDD0' },
    { 15, 'Black', '#151921' },
    { 16, 'Black Poly', '#1E2429' },
    { 17, 'Dark Silver', '#333A3C' },
    { 18, 'Silver', '#8C9095' },
    { 19, 'Gun Metal', '#39434D' },
    { 20, 'Shadow Silver', '#506272' },
    { 43, 'Red', '#9C1016' },
    { 44, 'Bright Red', '#DE0F18' },
    { 45, 'Garnet Red', '#8F1E17' },
    { 56, 'Dark Green', '#22383E' },
    { 57, 'Green', '#1D5A3F' },
    { 75, 'Dark Blue', '#112552' },
    { 76, 'Midnight Blue', '#1B203E' },
    { 77, 'Blue', '#275190' },
    { 78, 'Sea Foam Blue', '#608592' },
    { 79, 'Lightning Blue', '#2446A8' },
    { 80, 'Maui Blue Poly', '#4271E1' },
    { 81, 'Bright Blue', '#3B39E0' },
    { 108, 'Brown', '#3A2A1B' },
    { 109, 'Medium Brown', '#785F33' },
    { 110, 'Light Brown', '#B5A079' },
}, colours)

add('worn', nil, {
    { 132, 'White', '#FFFFFB' },
    { 121, 'Off White', '#EAE6DE' },
    { 21, 'Black', '#1E232F' },
    { 22, 'Graphite', '#363A3F' },
    { 23, 'Silver Grey', '#A0A199' },
    { 24, 'Silver', '#D3D3D3' },
    { 25, 'Blue Silver', '#B7BFCA' },
    { 26, 'Shadow Silver', '#778794' },
    { 46, 'Red', '#A94744' },
    { 47, 'Golden Red', '#B16C51' },
    { 48, 'Dark Red', '#371C25' },
    { 123, 'Orange', '#F2AD2E' },
    { 124, 'Light Orange', '#F9A458' },
    { 130, 'Pale Orange', '#F8B658' },
    { 126, 'Taxi Yellow', '#F1CC40' },
    { 58, 'Dark Green', '#2D423F' },
    { 59, 'Green', '#45594B' },
    { 60, 'Sea Wash', '#65867F' },
    { 133, 'Olive Army Green', '#81844C' },
    { 85, 'Dark Blue', '#4C5F81' },
    { 86, 'Blue', '#58688E' },
    { 87, 'Light Blue', '#74B5D8' },
    { 113, 'Honey Beige', '#B0AB94' },
    { 114, 'Brown', '#453831' },
    { 115, 'Dark Brown', '#2A282B' },
    { 116, 'Straw Beige', '#726C57' },
}, colours)

return colours
