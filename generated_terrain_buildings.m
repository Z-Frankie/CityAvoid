% 自动生成的地形重建脚本 - 纯脚本格式
% 生成时间: 12-Jan-2026 23:03:51
% 参数: 建筑数量=12, 高度范围=15-30, 边缘距离=5, 最小间距=5

% 地图参数
mapSize = [100, 100];
groundHeight = 0;
buildingCount = 12;
minSpacing = 5; % 最小间距参数

% 建筑参数矩阵
% 格式: [x_center, y_center, width, depth, height]
building_params = [
      88.0,   23.0,   10.0,    8.0,   19.0;  % 建筑1
      65.5,   31.5,   13.0,   15.0,   15.0;  % 建筑2
       9.5,   57.5,    5.0,    9.0,   29.0;  % 建筑3
      65.0,   64.0,   10.0,   14.0,   16.0;  % 建筑4
      41.5,   45.0,    9.0,    8.0,   22.0;  % 建筑5
      52.0,   11.5,    6.0,   11.0,   17.0;  % 建筑6
      90.0,   80.0,    8.0,   12.0,   22.0;  % 建筑7
      41.5,   75.0,   15.0,   14.0,   15.0;  % 建筑8
      25.5,   22.0,    7.0,   14.0,   29.0;  % 建筑9
      23.5,   46.5,    5.0,    9.0,   23.0;  % 建筑10
      68.0,   87.0,   12.0,   10.0,   30.0;  % 建筑11
      21.0,   88.0,   14.0,    8.0,   30.0;  % 建筑12
];

% 输出变量
map_z = groundHeight * ones(mapSize);

% 初始化建筑信息结构体
building_info = struct('id', {}, 'center_x', {}, 'center_y', {}, ...
                      'width', {}, 'depth', {}, 'height', {}, ...
                      'x_min', {}, 'x_max', {}, 'y_min', {}, ...
                      'y_max', {}, 'valid', {});

% 放置建筑
% 建筑1
center_x_1 = building_params(1, 1);
center_y_1 = building_params(1, 2);
width_1 = building_params(1, 3);
depth_1 = building_params(1, 4);
height_1 = building_params(1, 5);
x_min_1 = center_x_1 - width_1/2;
x_max_1 = center_x_1 + width_1/2;
y_min_1 = center_y_1 - depth_1/2;
y_max_1 = center_y_1 + depth_1/2;
% 在地形图上放置建筑1
x_start_1 = max(1, floor(x_min_1));
x_end_1 = min(mapSize(2), ceil(x_max_1));
y_start_1 = max(1, floor(y_min_1));
y_end_1 = min(mapSize(1), ceil(y_max_1));
map_z(y_start_1:y_end_1, x_start_1:x_end_1) = height_1;

% 保存建筑1信息
building_info(1).id = 1;
building_info(1).center_x = center_x_1;
building_info(1).center_y = center_y_1;
building_info(1).width = width_1;
building_info(1).depth = depth_1;
building_info(1).height = height_1;
building_info(1).x_min = x_min_1;
building_info(1).x_max = x_max_1;
building_info(1).y_min = y_min_1;
building_info(1).y_max = y_max_1;
building_info(1).valid = true;

% 建筑2
center_x_2 = building_params(2, 1);
center_y_2 = building_params(2, 2);
width_2 = building_params(2, 3);
depth_2 = building_params(2, 4);
height_2 = building_params(2, 5);
x_min_2 = center_x_2 - width_2/2;
x_max_2 = center_x_2 + width_2/2;
y_min_2 = center_y_2 - depth_2/2;
y_max_2 = center_y_2 + depth_2/2;
% 在地形图上放置建筑2
x_start_2 = max(1, floor(x_min_2));
x_end_2 = min(mapSize(2), ceil(x_max_2));
y_start_2 = max(1, floor(y_min_2));
y_end_2 = min(mapSize(1), ceil(y_max_2));
map_z(y_start_2:y_end_2, x_start_2:x_end_2) = height_2;

% 保存建筑2信息
building_info(2).id = 2;
building_info(2).center_x = center_x_2;
building_info(2).center_y = center_y_2;
building_info(2).width = width_2;
building_info(2).depth = depth_2;
building_info(2).height = height_2;
building_info(2).x_min = x_min_2;
building_info(2).x_max = x_max_2;
building_info(2).y_min = y_min_2;
building_info(2).y_max = y_max_2;
building_info(2).valid = true;

% 建筑3
center_x_3 = building_params(3, 1);
center_y_3 = building_params(3, 2);
width_3 = building_params(3, 3);
depth_3 = building_params(3, 4);
height_3 = building_params(3, 5);
x_min_3 = center_x_3 - width_3/2;
x_max_3 = center_x_3 + width_3/2;
y_min_3 = center_y_3 - depth_3/2;
y_max_3 = center_y_3 + depth_3/2;
% 在地形图上放置建筑3
x_start_3 = max(1, floor(x_min_3));
x_end_3 = min(mapSize(2), ceil(x_max_3));
y_start_3 = max(1, floor(y_min_3));
y_end_3 = min(mapSize(1), ceil(y_max_3));
map_z(y_start_3:y_end_3, x_start_3:x_end_3) = height_3;

% 保存建筑3信息
building_info(3).id = 3;
building_info(3).center_x = center_x_3;
building_info(3).center_y = center_y_3;
building_info(3).width = width_3;
building_info(3).depth = depth_3;
building_info(3).height = height_3;
building_info(3).x_min = x_min_3;
building_info(3).x_max = x_max_3;
building_info(3).y_min = y_min_3;
building_info(3).y_max = y_max_3;
building_info(3).valid = true;

% 建筑4
center_x_4 = building_params(4, 1);
center_y_4 = building_params(4, 2);
width_4 = building_params(4, 3);
depth_4 = building_params(4, 4);
height_4 = building_params(4, 5);
x_min_4 = center_x_4 - width_4/2;
x_max_4 = center_x_4 + width_4/2;
y_min_4 = center_y_4 - depth_4/2;
y_max_4 = center_y_4 + depth_4/2;
% 在地形图上放置建筑4
x_start_4 = max(1, floor(x_min_4));
x_end_4 = min(mapSize(2), ceil(x_max_4));
y_start_4 = max(1, floor(y_min_4));
y_end_4 = min(mapSize(1), ceil(y_max_4));
map_z(y_start_4:y_end_4, x_start_4:x_end_4) = height_4;

% 保存建筑4信息
building_info(4).id = 4;
building_info(4).center_x = center_x_4;
building_info(4).center_y = center_y_4;
building_info(4).width = width_4;
building_info(4).depth = depth_4;
building_info(4).height = height_4;
building_info(4).x_min = x_min_4;
building_info(4).x_max = x_max_4;
building_info(4).y_min = y_min_4;
building_info(4).y_max = y_max_4;
building_info(4).valid = true;

% 建筑5
center_x_5 = building_params(5, 1);
center_y_5 = building_params(5, 2);
width_5 = building_params(5, 3);
depth_5 = building_params(5, 4);
height_5 = building_params(5, 5);
x_min_5 = center_x_5 - width_5/2;
x_max_5 = center_x_5 + width_5/2;
y_min_5 = center_y_5 - depth_5/2;
y_max_5 = center_y_5 + depth_5/2;
% 在地形图上放置建筑5
x_start_5 = max(1, floor(x_min_5));
x_end_5 = min(mapSize(2), ceil(x_max_5));
y_start_5 = max(1, floor(y_min_5));
y_end_5 = min(mapSize(1), ceil(y_max_5));
map_z(y_start_5:y_end_5, x_start_5:x_end_5) = height_5;

% 保存建筑5信息
building_info(5).id = 5;
building_info(5).center_x = center_x_5;
building_info(5).center_y = center_y_5;
building_info(5).width = width_5;
building_info(5).depth = depth_5;
building_info(5).height = height_5;
building_info(5).x_min = x_min_5;
building_info(5).x_max = x_max_5;
building_info(5).y_min = y_min_5;
building_info(5).y_max = y_max_5;
building_info(5).valid = true;

% 建筑6
center_x_6 = building_params(6, 1);
center_y_6 = building_params(6, 2);
width_6 = building_params(6, 3);
depth_6 = building_params(6, 4);
height_6 = building_params(6, 5);
x_min_6 = center_x_6 - width_6/2;
x_max_6 = center_x_6 + width_6/2;
y_min_6 = center_y_6 - depth_6/2;
y_max_6 = center_y_6 + depth_6/2;
% 在地形图上放置建筑6
x_start_6 = max(1, floor(x_min_6));
x_end_6 = min(mapSize(2), ceil(x_max_6));
y_start_6 = max(1, floor(y_min_6));
y_end_6 = min(mapSize(1), ceil(y_max_6));
map_z(y_start_6:y_end_6, x_start_6:x_end_6) = height_6;

% 保存建筑6信息
building_info(6).id = 6;
building_info(6).center_x = center_x_6;
building_info(6).center_y = center_y_6;
building_info(6).width = width_6;
building_info(6).depth = depth_6;
building_info(6).height = height_6;
building_info(6).x_min = x_min_6;
building_info(6).x_max = x_max_6;
building_info(6).y_min = y_min_6;
building_info(6).y_max = y_max_6;
building_info(6).valid = true;

% 建筑7
center_x_7 = building_params(7, 1);
center_y_7 = building_params(7, 2);
width_7 = building_params(7, 3);
depth_7 = building_params(7, 4);
height_7 = building_params(7, 5);
x_min_7 = center_x_7 - width_7/2;
x_max_7 = center_x_7 + width_7/2;
y_min_7 = center_y_7 - depth_7/2;
y_max_7 = center_y_7 + depth_7/2;
% 在地形图上放置建筑7
x_start_7 = max(1, floor(x_min_7));
x_end_7 = min(mapSize(2), ceil(x_max_7));
y_start_7 = max(1, floor(y_min_7));
y_end_7 = min(mapSize(1), ceil(y_max_7));
map_z(y_start_7:y_end_7, x_start_7:x_end_7) = height_7;

% 保存建筑7信息
building_info(7).id = 7;
building_info(7).center_x = center_x_7;
building_info(7).center_y = center_y_7;
building_info(7).width = width_7;
building_info(7).depth = depth_7;
building_info(7).height = height_7;
building_info(7).x_min = x_min_7;
building_info(7).x_max = x_max_7;
building_info(7).y_min = y_min_7;
building_info(7).y_max = y_max_7;
building_info(7).valid = true;

% 建筑8
center_x_8 = building_params(8, 1);
center_y_8 = building_params(8, 2);
width_8 = building_params(8, 3);
depth_8 = building_params(8, 4);
height_8 = building_params(8, 5);
x_min_8 = center_x_8 - width_8/2;
x_max_8 = center_x_8 + width_8/2;
y_min_8 = center_y_8 - depth_8/2;
y_max_8 = center_y_8 + depth_8/2;
% 在地形图上放置建筑8
x_start_8 = max(1, floor(x_min_8));
x_end_8 = min(mapSize(2), ceil(x_max_8));
y_start_8 = max(1, floor(y_min_8));
y_end_8 = min(mapSize(1), ceil(y_max_8));
map_z(y_start_8:y_end_8, x_start_8:x_end_8) = height_8;

% 保存建筑8信息
building_info(8).id = 8;
building_info(8).center_x = center_x_8;
building_info(8).center_y = center_y_8;
building_info(8).width = width_8;
building_info(8).depth = depth_8;
building_info(8).height = height_8;
building_info(8).x_min = x_min_8;
building_info(8).x_max = x_max_8;
building_info(8).y_min = y_min_8;
building_info(8).y_max = y_max_8;
building_info(8).valid = true;

% 建筑9
center_x_9 = building_params(9, 1);
center_y_9 = building_params(9, 2);
width_9 = building_params(9, 3);
depth_9 = building_params(9, 4);
height_9 = building_params(9, 5);
x_min_9 = center_x_9 - width_9/2;
x_max_9 = center_x_9 + width_9/2;
y_min_9 = center_y_9 - depth_9/2;
y_max_9 = center_y_9 + depth_9/2;
% 在地形图上放置建筑9
x_start_9 = max(1, floor(x_min_9));
x_end_9 = min(mapSize(2), ceil(x_max_9));
y_start_9 = max(1, floor(y_min_9));
y_end_9 = min(mapSize(1), ceil(y_max_9));
map_z(y_start_9:y_end_9, x_start_9:x_end_9) = height_9;

% 保存建筑9信息
building_info(9).id = 9;
building_info(9).center_x = center_x_9;
building_info(9).center_y = center_y_9;
building_info(9).width = width_9;
building_info(9).depth = depth_9;
building_info(9).height = height_9;
building_info(9).x_min = x_min_9;
building_info(9).x_max = x_max_9;
building_info(9).y_min = y_min_9;
building_info(9).y_max = y_max_9;
building_info(9).valid = true;

% 建筑10
center_x_10 = building_params(10, 1);
center_y_10 = building_params(10, 2);
width_10 = building_params(10, 3);
depth_10 = building_params(10, 4);
height_10 = building_params(10, 5);
x_min_10 = center_x_10 - width_10/2;
x_max_10 = center_x_10 + width_10/2;
y_min_10 = center_y_10 - depth_10/2;
y_max_10 = center_y_10 + depth_10/2;
% 在地形图上放置建筑10
x_start_10 = max(1, floor(x_min_10));
x_end_10 = min(mapSize(2), ceil(x_max_10));
y_start_10 = max(1, floor(y_min_10));
y_end_10 = min(mapSize(1), ceil(y_max_10));
map_z(y_start_10:y_end_10, x_start_10:x_end_10) = height_10;

% 保存建筑10信息
building_info(10).id = 10;
building_info(10).center_x = center_x_10;
building_info(10).center_y = center_y_10;
building_info(10).width = width_10;
building_info(10).depth = depth_10;
building_info(10).height = height_10;
building_info(10).x_min = x_min_10;
building_info(10).x_max = x_max_10;
building_info(10).y_min = y_min_10;
building_info(10).y_max = y_max_10;
building_info(10).valid = true;

% 建筑11
center_x_11 = building_params(11, 1);
center_y_11 = building_params(11, 2);
width_11 = building_params(11, 3);
depth_11 = building_params(11, 4);
height_11 = building_params(11, 5);
x_min_11 = center_x_11 - width_11/2;
x_max_11 = center_x_11 + width_11/2;
y_min_11 = center_y_11 - depth_11/2;
y_max_11 = center_y_11 + depth_11/2;
% 在地形图上放置建筑11
x_start_11 = max(1, floor(x_min_11));
x_end_11 = min(mapSize(2), ceil(x_max_11));
y_start_11 = max(1, floor(y_min_11));
y_end_11 = min(mapSize(1), ceil(y_max_11));
map_z(y_start_11:y_end_11, x_start_11:x_end_11) = height_11;

% 保存建筑11信息
building_info(11).id = 11;
building_info(11).center_x = center_x_11;
building_info(11).center_y = center_y_11;
building_info(11).width = width_11;
building_info(11).depth = depth_11;
building_info(11).height = height_11;
building_info(11).x_min = x_min_11;
building_info(11).x_max = x_max_11;
building_info(11).y_min = y_min_11;
building_info(11).y_max = y_max_11;
building_info(11).valid = true;

% 建筑12
center_x_12 = building_params(12, 1);
center_y_12 = building_params(12, 2);
width_12 = building_params(12, 3);
depth_12 = building_params(12, 4);
height_12 = building_params(12, 5);
x_min_12 = center_x_12 - width_12/2;
x_max_12 = center_x_12 + width_12/2;
y_min_12 = center_y_12 - depth_12/2;
y_max_12 = center_y_12 + depth_12/2;
% 在地形图上放置建筑12
x_start_12 = max(1, floor(x_min_12));
x_end_12 = min(mapSize(2), ceil(x_max_12));
y_start_12 = max(1, floor(y_min_12));
y_end_12 = min(mapSize(1), ceil(y_max_12));
map_z(y_start_12:y_end_12, x_start_12:x_end_12) = height_12;

% 保存建筑12信息
building_info(12).id = 12;
building_info(12).center_x = center_x_12;
building_info(12).center_y = center_y_12;
building_info(12).width = width_12;
building_info(12).depth = depth_12;
building_info(12).height = height_12;
building_info(12).x_min = x_min_12;
building_info(12).x_max = x_max_12;
building_info(12).y_min = y_min_12;
building_info(12).y_max = y_max_12;
building_info(12).valid = true;

% 添加地面纹理（使用固定随机种子确保可重现）
rng(42); % 固定随机种子
ground_mask = (map_z == groundHeight);
ground_noise = randn(mapSize) * 0.1;
map_z = map_z + ground_mask .* ground_noise;

% 恢复建筑高度
x_start_1 = max(1, floor(x_min_1));
x_end_1 = min(mapSize(2), ceil(x_max_1));
y_start_1 = max(1, floor(y_min_1));
y_end_1 = min(mapSize(1), ceil(y_max_1));
map_z(y_start_1:y_end_1, x_start_1:x_end_1) = height_1;
x_start_2 = max(1, floor(x_min_2));
x_end_2 = min(mapSize(2), ceil(x_max_2));
y_start_2 = max(1, floor(y_min_2));
y_end_2 = min(mapSize(1), ceil(y_max_2));
map_z(y_start_2:y_end_2, x_start_2:x_end_2) = height_2;
x_start_3 = max(1, floor(x_min_3));
x_end_3 = min(mapSize(2), ceil(x_max_3));
y_start_3 = max(1, floor(y_min_3));
y_end_3 = min(mapSize(1), ceil(y_max_3));
map_z(y_start_3:y_end_3, x_start_3:x_end_3) = height_3;
x_start_4 = max(1, floor(x_min_4));
x_end_4 = min(mapSize(2), ceil(x_max_4));
y_start_4 = max(1, floor(y_min_4));
y_end_4 = min(mapSize(1), ceil(y_max_4));
map_z(y_start_4:y_end_4, x_start_4:x_end_4) = height_4;
x_start_5 = max(1, floor(x_min_5));
x_end_5 = min(mapSize(2), ceil(x_max_5));
y_start_5 = max(1, floor(y_min_5));
y_end_5 = min(mapSize(1), ceil(y_max_5));
map_z(y_start_5:y_end_5, x_start_5:x_end_5) = height_5;
x_start_6 = max(1, floor(x_min_6));
x_end_6 = min(mapSize(2), ceil(x_max_6));
y_start_6 = max(1, floor(y_min_6));
y_end_6 = min(mapSize(1), ceil(y_max_6));
map_z(y_start_6:y_end_6, x_start_6:x_end_6) = height_6;
x_start_7 = max(1, floor(x_min_7));
x_end_7 = min(mapSize(2), ceil(x_max_7));
y_start_7 = max(1, floor(y_min_7));
y_end_7 = min(mapSize(1), ceil(y_max_7));
map_z(y_start_7:y_end_7, x_start_7:x_end_7) = height_7;
x_start_8 = max(1, floor(x_min_8));
x_end_8 = min(mapSize(2), ceil(x_max_8));
y_start_8 = max(1, floor(y_min_8));
y_end_8 = min(mapSize(1), ceil(y_max_8));
map_z(y_start_8:y_end_8, x_start_8:x_end_8) = height_8;
x_start_9 = max(1, floor(x_min_9));
x_end_9 = min(mapSize(2), ceil(x_max_9));
y_start_9 = max(1, floor(y_min_9));
y_end_9 = min(mapSize(1), ceil(y_max_9));
map_z(y_start_9:y_end_9, x_start_9:x_end_9) = height_9;
x_start_10 = max(1, floor(x_min_10));
x_end_10 = min(mapSize(2), ceil(x_max_10));
y_start_10 = max(1, floor(y_min_10));
y_end_10 = min(mapSize(1), ceil(y_max_10));
map_z(y_start_10:y_end_10, x_start_10:x_end_10) = height_10;
x_start_11 = max(1, floor(x_min_11));
x_end_11 = min(mapSize(2), ceil(x_max_11));
y_start_11 = max(1, floor(y_min_11));
y_end_11 = min(mapSize(1), ceil(y_max_11));
map_z(y_start_11:y_end_11, x_start_11:x_end_11) = height_11;
x_start_12 = max(1, floor(x_min_12));
x_end_12 = min(mapSize(2), ceil(x_max_12));
y_start_12 = max(1, floor(y_min_12));
y_end_12 = min(mapSize(1), ceil(y_max_12));
map_z(y_start_12:y_end_12, x_start_12:x_end_12) = height_12;

% 建筑间距检查
fprintf('建筑间距检查：\n');
fprintf('======================================\n');
all_spacing_ok = true;
for i = 1:buildingCount
    for j = i+1:buildingCount
        % 计算两个建筑之间的最小距离（边缘到边缘）
        dist_x = max(0, building_info(i).x_min - building_info(j).x_max);
        dist_x = max(dist_x, building_info(j).x_min - building_info(i).x_max);
        dist_y = max(0, building_info(i).y_min - building_info(j).y_max);
        dist_y = max(dist_y, building_info(j).y_min - building_info(i).y_max);
        edge_dist = max(dist_x, dist_y);
        
        if edge_dist < minSpacing
            fprintf('警告: 建筑%d和建筑%d之间的间距(%.1f)小于最小要求(%d)\n', ...
                    i, j, edge_dist, minSpacing);
            all_spacing_ok = false;
        else
            fprintf('建筑%d和建筑%d之间的间距: %.1f (符合要求)\n', i, j, edge_dist);
        end
    end
end

if all_spacing_ok
    fprintf('\n所有建筑间距检查通过！\n');
else
    fprintf('\n存在建筑间距不符合要求！\n');
end
fprintf('======================================\n\n');

% 显示建筑信息汇总
fprintf('建筑信息汇总（共%d个建筑）：\n', buildingCount);
fprintf('======================================\n');
for b = 1:buildingCount
    fprintf('建筑 %2d: 中心(%3.1f,%3.1f), 尺寸(%2.0fx%2.0f), 高度%2.0f\n', ...
            b, building_info(b).center_x, building_info(b).center_y, ...
            building_info(b).width, building_info(b).depth, ...
            building_info(b).height);
end

% 计算并显示建筑覆盖率
building_area = 0;
for b = 1:buildingCount
    building_area = building_area + building_info(b).width * building_info(b).depth;
end
total_area = mapSize(1) * mapSize(2);
coverage = building_area / total_area * 100;

% 计算建筑间的平均间距
if buildingCount > 1
    total_spacing = 0;
    spacing_count = 0;
    
    for i = 1:buildingCount
        for j = i+1:buildingCount
            % 计算中心距离
            dist_center = sqrt((building_info(i).center_x - building_info(j).center_x)^2 + ...
                              (building_info(i).center_y - building_info(j).center_y)^2);
            total_spacing = total_spacing + dist_center;
            spacing_count = spacing_count + 1;
        end
    end
    
    avg_spacing = total_spacing / spacing_count;
else
    avg_spacing = 0;
end

fprintf('======================================\n');
fprintf('建筑总面积: %.0f 单位^2\n', building_area);
fprintf('总地图面积: %d 单位^2\n', total_area);
fprintf('建筑覆盖率: %.1f%%\n', coverage);
fprintf('建筑间平均中心距离: %.1f 单位\n', avg_spacing);
fprintf('======================================\n\n');

% =================== 可视化部分 ===================
% 创建第一个图形：3D网格图和2D平面图
figure('Position', [100, 100, 1400, 600]);

% 3D网格图
subplot(1, 2, 1);
mesh(map_z);
title(sprintf('城市地形图（%d个长方体建筑，最小间距%d单位）', buildingCount, minSpacing));
xlabel('X方向');
ylabel('Y方向');
zlabel('高度');
colormap(jet);
colorbar;
view(45, 30);
grid on;

% 2D平面图（高度图）
subplot(1, 2, 2);
imagesc(map_z);
title(sprintf('城市地形高度图（%d个建筑）', buildingCount));
xlabel('X方向');
ylabel('Y方向');
colorbar;
axis equal tight;
hold on;

% 在2D图上标注建筑轮廓和编号
for b = 1:buildingCount
    % 绘制建筑轮廓
    rectangle('Position', [building_info(b).x_min, building_info(b).y_min, ...
              building_info(b).width, building_info(b).depth], ...
              'EdgeColor', 'r', 'LineWidth', 1.5, 'LineStyle', '-');
    
    % 标注建筑编号
    text(building_info(b).center_x, building_info(b).center_y, ...
         sprintf('%d', b), 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 10);
    
    % 标注建筑高度
    text(building_info(b).center_x, building_info(b).center_y + 3, ...
         sprintf('H=%d', building_info(b).height), 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'Color', 'y', 'FontSize', 8);
end
hold off;

% 创建第二个图形：间距矩阵图
figure('Position', [100, 100, 800, 600]);
spacing_matrix = zeros(buildingCount, buildingCount);

for i = 1:buildingCount
    for j = 1:buildingCount
        if i == j
            spacing_matrix(i, j) = 0;
        else
            % 计算边缘到边缘的最小距离
            dist_x = max(0, building_info(i).x_min - building_info(j).x_max);
            dist_x = max(dist_x, building_info(j).x_min - building_info(i).x_max);
            dist_y = max(0, building_info(i).y_min - building_info(j).y_max);
            dist_y = max(dist_y, building_info(j).y_min - building_info(i).y_max);
            spacing_matrix(i, j) = max(dist_x, dist_y);
        end
    end
end

imagesc(spacing_matrix);
title('建筑间距矩阵（边缘到边缘距离）');
xlabel('建筑编号');
ylabel('建筑编号');
colorbar;
colormap(jet);

% 在矩阵图上标注数值
for i = 1:buildingCount
    for j = 1:buildingCount
        if i ~= j
            % 使用if-else语句
            if spacing_matrix(i, j) < minSpacing
                text_color = 'r';
            else
                text_color = 'k';
            end
            
            text(j, i, sprintf('%.1f', spacing_matrix(i, j)), ...
                 'HorizontalAlignment', 'center', 'FontSize', 8, ...
                 'Color', text_color);
        else
            text(j, i, 'X', 'HorizontalAlignment', 'center', 'FontSize', 8);
        end
    end
end

set(gca, 'XTick', 1:buildingCount);
set(gca, 'YTick', 1:buildingCount);
axis equal tight;

% 清理临时变量
clear ground_mask ground_noise all_spacing_ok edge_dist dist_x dist_y i j;
clear center_x_1 center_y_1 width_1 depth_1 height_1;
clear x_min_1 x_max_1 y_min_1 y_max_1;
clear x_start_1 x_end_1 y_start_1 y_end_1;
clear center_x_2 center_y_2 width_2 depth_2 height_2;
clear x_min_2 x_max_2 y_min_2 y_max_2;
clear x_start_2 x_end_2 y_start_2 y_end_2;
clear center_x_3 center_y_3 width_3 depth_3 height_3;
clear x_min_3 x_max_3 y_min_3 y_max_3;
clear x_start_3 x_end_3 y_start_3 y_end_3;
clear center_x_4 center_y_4 width_4 depth_4 height_4;
clear x_min_4 x_max_4 y_min_4 y_max_4;
clear x_start_4 x_end_4 y_start_4 y_end_4;
clear center_x_5 center_y_5 width_5 depth_5 height_5;
clear x_min_5 x_max_5 y_min_5 y_max_5;
clear x_start_5 x_end_5 y_start_5 y_end_5;
clear center_x_6 center_y_6 width_6 depth_6 height_6;
clear x_min_6 x_max_6 y_min_6 y_max_6;
clear x_start_6 x_end_6 y_start_6 y_end_6;
clear center_x_7 center_y_7 width_7 depth_7 height_7;
clear x_min_7 x_max_7 y_min_7 y_max_7;
clear x_start_7 x_end_7 y_start_7 y_end_7;
clear center_x_8 center_y_8 width_8 depth_8 height_8;
clear x_min_8 x_max_8 y_min_8 y_max_8;
clear x_start_8 x_end_8 y_start_8 y_end_8;
clear center_x_9 center_y_9 width_9 depth_9 height_9;
clear x_min_9 x_max_9 y_min_9 y_max_9;
clear x_start_9 x_end_9 y_start_9 y_end_9;
clear center_x_10 center_y_10 width_10 depth_10 height_10;
clear x_min_10 x_max_10 y_min_10 y_max_10;
clear x_start_10 x_end_10 y_start_10 y_end_10;
clear center_x_11 center_y_11 width_11 depth_11 height_11;
clear x_min_11 x_max_11 y_min_11 y_max_11;
clear x_start_11 x_end_11 y_start_11 y_end_11;
clear center_x_12 center_y_12 width_12 depth_12 height_12;
clear x_min_12 x_max_12 y_min_12 y_max_12;
clear x_start_12 x_end_12 y_start_12 y_end_12;
clear building_area total_area coverage total_spacing spacing_count avg_spacing;
clear spacing_matrix text_color;

% 显示完成信息
fprintf('地形重建完成！\n');
fprintf('建筑数量: %d\n', buildingCount);
fprintf('地图尺寸: 100x100\n');
fprintf('已生成可视化图形。\n');
