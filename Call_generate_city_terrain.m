clear all
% 使用默认参数（16个建筑，高度15-30，边缘距离5，最小间距5）
% [map_z, building_info] = generate_city_terrain_16buildings();

% 自定义参数：10个建筑，高度20-40，边缘距离8，最小间距6
% [map_z, building_info] = generate_city_terrain_16buildings(10, 40, 20, 8, 6);

% 部分自定义：指定建筑数量，其他用默认值
[map_z, building_info] = generate_city_terrain(12);