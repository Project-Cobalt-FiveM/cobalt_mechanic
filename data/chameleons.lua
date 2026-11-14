---@class MechanicChameleon
---@field index integer
---@field name string
---@field series string
---@field from string
---@field to string

---@type MechanicChameleon[]
local chameleons <const> = {}

---@param series string
---@param rows [integer, string, string, string][]
local function add(series, rows)
    for _, row in ipairs(rows) do
        chameleons[#chameleons + 1] = { index = row[1], name = row[2], from = row[3], to = row[4], series = series }
    end
end

add('Anodized', {
    { 161, 'Anodized Red', '#FF1F1F', '#841010' },
    { 162, 'Anodized Wine', '#7F1F1F', '#3D0808' },
    { 163, 'Anodized Purple', '#9B36E0', '#3D125C' },
    { 164, 'Anodized Blue', '#1F66E0', '#0E2C66' },
    { 165, 'Anodized Green', '#21A33A', '#0E4717' },
    { 166, 'Anodized Lime', '#A6E028', '#3B7211' },
    { 167, 'Anodized Copper', '#E6541E', '#7A1F0E' },
    { 168, 'Anodized Bronze', '#A86B22', '#5C3812' },
    { 169, 'Anodized Champagne', '#D5B566', '#5E4824' },
    { 170, 'Anodized Gold', '#E0BB34', '#6B4F0F' },
})

add('Flip', {
    { 171, 'Green/Blue Flip', '#21A33A', '#1F66E0' },
    { 172, 'Green/Red Flip', '#21A33A', '#FF1F1F' },
    { 173, 'Green/Brown Flip', '#21A33A', '#7A4A1F' },
    { 174, 'Green/Turquoise Flip', '#21A33A', '#1FB7B1' },
    { 175, 'Green/Purple Flip', '#21A33A', '#9B36E0' },
    { 176, 'Teal/Purple Flip', '#1FB7B1', '#9B36E0' },
    { 177, 'Turquoise/Red Flip', '#28C6A0', '#FF1F1F' },
    { 178, 'Turquoise/Purple Flip', '#28C6A0', '#9B36E0' },
    { 179, 'Cyan/Purple Flip', '#1FE0E0', '#9B36E0' },
    { 180, 'Blue/Pink Flip', '#1F66E0', '#FF66B3' },
    { 181, 'Blue/Green Flip', '#1F66E0', '#21A33A' },
    { 182, 'Purple/Red Flip', '#9B36E0', '#FF1F1F' },
    { 183, 'Purple/Green Flip', '#9B36E0', '#21A33A' },
    { 184, 'Magenta/Green Flip', '#E03EA8', '#21A33A' },
    { 185, 'Magenta/Yellow Flip', '#E03EA8', '#F2DC0C' },
    { 186, 'Burgundy/Green Flip', '#7F1F1F', '#21A33A' },
    { 187, 'Magenta/Cyan Flip', '#E03EA8', '#1FE0E0' },
    { 188, 'Copper/Purple Flip', '#E6541E', '#9B36E0' },
    { 189, 'Magenta/Orange Flip', '#E03EA8', '#FF8B12' },
    { 190, 'Red/Orange Flip', '#FF1F1F', '#FF8B12' },
    { 191, 'Orange/Purple Flip', '#FF8B12', '#9B36E0' },
    { 192, 'Orange/Blue Flip', '#FF8B12', '#1F66E0' },
    { 193, 'White/Purple Flip', '#FFFFFF', '#9B36E0' },
    { 194, 'Red/Rainbow Flip', '#FF1F1F', '#A6E028' },
    { 195, 'Blue/Rainbow Flip', '#1F66E0', '#A6E028' },
})

add('Pearl', {
    { 196, 'Dark Green Pearl', '#0E4717', '#3B7211' },
    { 197, 'Dark Teal Pearl', '#0E4D4B', '#1FB7B1' },
    { 198, 'Dark Blue Pearl', '#0E2C66', '#1F66E0' },
    { 199, 'Dark Purple Pearl', '#3D125C', '#9B36E0' },
    { 200, 'Oil Slick Pearl', '#1F0A47', '#1FB7B1' },
    { 201, 'Light Green Pearl', '#A6E028', '#E6FF99' },
    { 202, 'Light Blue Pearl', '#9CB8F2', '#D9F0FF' },
    { 203, 'Light Purple Pearl', '#C99CF2', '#E89CF2' },
    { 204, 'Light Pink Pearl', '#FFB3D9', '#FFE0EE' },
    { 205, 'Off White Pearl', '#F5F5EA', '#FFFFFF' },
    { 206, 'Pink Pearl', '#FF66B3', '#FFB3D9' },
    { 207, 'Yellow Pearl', '#F2DC0C', '#FFF2A6' },
    { 208, 'Green Pearl', '#21A33A', '#7FE08C' },
    { 209, 'Blue Pearl', '#1F66E0', '#9CB8F2' },
    { 210, 'Cream Pearl', '#F5E6BA', '#FFF5DA' },
})

add('Prismatic', {
    { 211, 'White Prismatic', '#FFFFFF', '#E0F0FF' },
    { 212, 'Graphite Prismatic', '#3A3A3A', '#1A1A1A' },
    { 213, 'Dark Blue Prismatic', '#0E316D', '#3D5C9E' },
    { 214, 'Dark Purple Prismatic', '#3D125C', '#9B36E0' },
    { 215, 'Hot Pink Prismatic', '#FF66B3', '#A12C5E' },
    { 216, 'Dark Red Prismatic', '#841010', '#FF1F1F' },
    { 217, 'Dark Green Prismatic', '#0E4717', '#21A33A' },
    { 218, 'Black Prismatic', '#0F0F0F', '#3A3A3A' },
    { 219, 'Black Oil Spill', '#0F0F0F', '#1FB7B1' },
    { 220, 'Black Rainbow', '#0F0F0F', '#9B36E0' },
})

add('Holographic', {
    { 221, 'Black Holographic', '#0F0F0F', '#9B36E0' },
    { 222, 'White Holographic', '#FFFFFF', '#A6E028' },
    { 223, 'Monochrome', '#FFFFFF', '#0F0F0F' },
    { 224, 'Night and Day', '#0F0F1F', '#FFE066' },
    { 225, 'Verlierer 2', '#FF1F1F', '#0F0F0F' },
    { 226, 'Sprunk Extreme', '#A6E028', '#21A33A' },
    { 227, 'Vice City', '#FF66B3', '#1FB7B1' },
    { 228, 'Synthwave', '#FF66B3', '#9B36E0' },
    { 229, 'Four Seasons', '#A6E028', '#FF8B12' },
    { 230, 'Maisonette 9 Throwback', '#E0BB34', '#9B36E0' },
    { 231, 'Bubblegum', '#FFB3D9', '#FF66B3' },
    { 232, 'Full Rainbow', '#FF1F1F', '#9B36E0' },
    { 233, 'Sunsets', '#FF8B12', '#9B36E0' },
    { 234, 'The Seven', '#1F66E0', '#E0BB34' },
    { 235, 'Kamen Rider', '#FF1F1F', '#21A33A' },
    { 236, 'Chrome Aberration', '#FF1F1F', '#1FB7B1' },
    { 237, "It's Christmas", '#21A33A', '#FF1F1F' },
    { 238, 'Temperature', '#1F66E0', '#FF1F1F' },
    { 239, 'Haos Special Works', '#FFE066', '#9B36E0' },
    { 240, 'Electro', '#1FE0E0', '#9B36E0' },
    { 241, 'Monika', '#FF66B3', '#FFB3D9' },
    { 242, 'Fubuki', '#FFFFFF', '#1FB7B1' },
})

return chameleons
