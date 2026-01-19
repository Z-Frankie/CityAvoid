function [map_z, building_info] = generate_city_terrain(buildingCount, maxHeight, minHeight, edgeBuffer, minSpacing)
% 生成城市地形图（可配置参数）
% 输入参数（可选）：
%   buildingCount - 建筑数量（默认：16）
%   maxHeight - 建筑最大高度（默认：30）
%   minHeight - 建筑最小高度（默认：15）
%   edgeBuffer - 建筑边缘距地图边缘的最小距离（默认：5）
%   minSpacing - 建筑物最小间距（默认：5）
% 输出：
%   map_z - 100x100的地形高度矩阵
%   building_info - 建筑信息结构体数组
% 额外功能：生成纯脚本文件可用于重现相同地形

% 参数设置（带默认值）
if nargin < 1 || isempty(buildingCount)
    buildingCount = 16;          % 默认建筑数量
end
if nargin < 2 || isempty(maxHeight)
    maxHeight = 30;              % 默认最大高度
end
if nargin < 3 || isempty(minHeight)
    minHeight = 15;              % 默认最小高度
end
if nargin < 4 || isempty(edgeBuffer)
    edgeBuffer = 5;              % 默认边缘缓冲
end
if nargin < 5 || isempty(minSpacing)
    minSpacing = 5;              % 默认最小间距
end

% 验证输入参数
validateattributes(buildingCount, {'numeric'}, {'scalar', 'integer', 'positive', '<=', 100}, 'generate_city_terrain', 'buildingCount');
validateattributes(maxHeight, {'numeric'}, {'scalar', 'positive', '>=', minHeight}, 'generate_city_terrain', 'maxHeight');
validateattributes(minHeight, {'numeric'}, {'scalar', 'positive', '<=', maxHeight}, 'generate_city_terrain', 'minHeight');
validateattributes(edgeBuffer, {'numeric'}, {'scalar', 'nonnegative', '<=', 20}, 'generate_city_terrain', 'edgeBuffer');
validateattributes(minSpacing, {'numeric'}, {'scalar', 'nonnegative', '<=', 20}, 'generate_city_terrain', 'minSpacing');

mapSize = [100, 100];        % 地图大小
groundHeight = 0;            % 地面高度（平面）
maxAttempts = 1000;          % 最大尝试次数

fprintf('======================================\n');
fprintf('生成城市地形图参数：\n');
fprintf('  建筑数量: %d\n', buildingCount);
fprintf('  高度范围: %d-%d\n', minHeight, maxHeight);
fprintf('  边缘距离: %d\n', edgeBuffer);
fprintf('  最小间距: %d\n', minSpacing);
fprintf('======================================\n');

% ============================================================
% 自动生成建筑参数（满足间距要求）
% 格式：[x_center, y_center, width, depth, height]
% ============================================================
building_params = zeros(buildingCount, 5);
building_rects = zeros(buildingCount, 4); % [x_min, y_min, width, height]

for b = 1:buildingCount
    placed = false;
    attempts = 0;
    
    while ~placed && attempts < maxAttempts
        attempts = attempts + 1;
        
        % 随机生成建筑尺寸（5-15之间）
        width = randi([5, 15]);
        depth = randi([5, 15]);
        height = randi([minHeight, maxHeight]);
        
        % 确保建筑在地图内且满足边缘距离要求
        x_min_min = edgeBuffer + 1;
        x_min_max = mapSize(2) - edgeBuffer - width;
        y_min_min = edgeBuffer + 1;
        y_min_max = mapSize(1) - edgeBuffer - depth;
        
        % 检查是否有足够的空间放置建筑
        if x_min_min > x_min_max || y_min_min > y_min_max
            error('地图空间不足，无法放置建筑！请减小建筑尺寸或边缘距离。');
        end
        
        % 随机生成位置
        x_min = randi([x_min_min, x_min_max]);
        y_min = randi([y_min_min, y_min_max]);
        
        % 计算中心点
        center_x = x_min + width / 2;
        center_y = y_min + depth / 2;
        
        % 检查是否与已有建筑重叠或间距不足
        overlap = false;
        if b > 1
            for i = 1:(b-1)
                % 计算矩形膨胀后的区域（考虑最小间距）
                rect1 = [x_min - minSpacing, y_min - minSpacing, ...
                        width + 2*minSpacing, depth + 2*minSpacing];
                rect2 = [building_rects(i, 1), building_rects(i, 2), ...
                        building_rects(i, 3), building_rects(i, 4)];
                
                % 检查矩形是否相交
                if rect1(1) < rect2(1)+rect2(3) && ...
                   rect1(1)+rect1(3) > rect2(1) && ...
                   rect1(2) < rect2(2)+rect2(4) && ...
                   rect1(2)+rect1(3) > rect2(2)
                    overlap = true;
                    break;
                end
            end
        end
        
        if ~overlap
            % 放置建筑
            building_params(b, :) = [center_x, center_y, width, depth, height];
            building_rects(b, :) = [x_min, y_min, width, depth];
            placed = true;
        end
    end
    
    if ~placed
        error('无法在尝试次数内放置所有建筑！请调整参数或减少建筑数量。');
    end
end

% 检查参数矩阵尺寸
if size(building_params, 1) ~= buildingCount
    error('建筑参数矩阵的行数必须等于建筑数量(%d)', buildingCount);
end

if size(building_params, 2) ~= 5
    error('建筑参数矩阵的列数必须为5 [x_center, y_center, width, depth, height]');
end

% 初始化地形图
map_z = groundHeight * ones(mapSize);

% 初始化建筑信息结构体
building_info = struct('id', {}, 'center_x', {}, 'center_y', {}, 'width', {}, 'depth', {}, 'height', {}, ...
                      'x_min', {}, 'x_max', {}, 'y_min', {}, 'y_max', {}, 'valid', {});

% 计算并存储所有建筑的边界信息
for b = 1:buildingCount
    % 提取当前建筑参数
    center_x = building_params(b, 1);
    center_y = building_params(b, 2);
    width = building_params(b, 3);
    depth = building_params(b, 4);
    height = building_params(b, 5);
    
    % 计算建筑边界
    half_width = width / 2;
    half_depth = depth / 2;
    x_min = center_x - half_width;
    x_max = center_x + half_width;
    y_min = center_y - half_depth;
    y_max = center_y + half_depth;
    
    % 边界检查：确保建筑在地图内且满足边缘距离要求
    adjusted = false;
    
    if x_min < edgeBuffer + 1
        center_x = edgeBuffer + 1 + half_width;
        x_min = edgeBuffer + 1;
        x_max = center_x + half_width;
        adjusted = true;
    end
    
    if x_max > mapSize(2) - edgeBuffer
        center_x = mapSize(2) - edgeBuffer - half_width;
        x_max = mapSize(2) - edgeBuffer;
        x_min = center_x - half_width;
        adjusted = true;
    end
    
    if y_min < edgeBuffer + 1
        center_y = edgeBuffer + 1 + half_depth;
        y_min = edgeBuffer + 1;
        y_max = center_y + half_depth;
        adjusted = true;
    end
    
    if y_max > mapSize(1) - edgeBuffer
        center_y = mapSize(1) - edgeBuffer - half_depth;
        y_max = mapSize(1) - edgeBuffer;
        y_min = center_y - half_depth;
        adjusted = true;
    end
    
    % 保存建筑信息
    building_info(b).id = b;
    building_info(b).center_x = center_x;
    building_info(b).center_y = center_y;
    building_info(b).width = width;
    building_info(b).depth = depth;
    building_info(b).height = height;
    building_info(b).x_min = x_min;
    building_info(b).x_max = x_max;
    building_info(b).y_min = y_min;
    building_info(b).y_max = y_max;
    
    if adjusted
        fprintf('建筑%d的位置已调整以满足边界要求\n', b);
    end
end

% 检查建筑间间距并显示结果
fprintf('\n建筑间距检查：\n');
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

% 生成地形图
for b = 1:buildingCount
    % 获取建筑边界（四舍五入为整数索引）
    x_start = max(1, floor(building_info(b).x_min));
    x_end = min(mapSize(2), ceil(building_info(b).x_max));
    y_start = max(1, floor(building_info(b).y_min));
    y_end = min(mapSize(1), ceil(building_info(b).y_max));
    
    % 在地形图上放置建筑
    map_z(y_start:y_end, x_start:x_end) = building_info(b).height;
    
    % 标记建筑有效
    building_info(b).valid = true;
end

% 添加轻微的地面纹理
if 1
    % 为地面区域添加微小高度变化
    ground_mask = (map_z == groundHeight);
    ground_noise = randn(mapSize) * 0.1;
    map_z = map_z + ground_mask .* ground_noise;
    
    % 确保建筑高度不变
    for b = 1:buildingCount
        x_start = max(1, floor(building_info(b).x_min));
        x_end = min(mapSize(2), ceil(building_info(b).x_max));
        y_start = max(1, floor(building_info(b).y_min));
        y_end = min(mapSize(1), ceil(building_info(b).y_max));
        map_z(y_start:y_end, x_start:x_end) = building_info(b).height;
    end
end

% 保存地形为可重现代码（纯脚本格式）
saveTerrainScript(building_params, map_z, building_info, buildingCount, ...
                  maxHeight, minHeight, edgeBuffer, minSpacing);

% 可视化
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

% 显示建筑信息
fprintf('\n建筑信息汇总（共%d个建筑）：\n', buildingCount);
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
fprintf('======================================\n');

% 创建间距矩阵图
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
            % 使用if-else语句替代三元运算符
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

end

function saveTerrainScript(building_params, map_z, building_info, buildingCount, ...
                           maxHeight, minHeight, edgeBuffer, minSpacing)
% 保存地形为可重现代码（纯脚本格式）
    
    scriptName = 'generated_terrain_buildings.m';
    
    % 打开文件准备写入
    fid = fopen(scriptName, 'w');
    
    if fid == -1
        error('无法创建脚本文件！');
    end
    
    % 写入脚本头部（纯注释，无function定义）
    fprintf(fid, '%% 自动生成的地形重建脚本 - 纯脚本格式\n');
    fprintf(fid, '%% 生成时间: %s\n', datestr(now));
    fprintf(fid, '%% 参数: 建筑数量=%d, 高度范围=%d-%d, 边缘距离=%d, 最小间距=%d\n\n', ...
            buildingCount, minHeight, maxHeight, edgeBuffer, minSpacing);
    
    % 写入地图参数
    fprintf(fid, '%% 地图参数\n');
    fprintf(fid, 'mapSize = [100, 100];\n');
    fprintf(fid, 'groundHeight = 0;\n');
    fprintf(fid, 'buildingCount = %d;\n', buildingCount);
    fprintf(fid, 'minSpacing = %d; %% 最小间距参数\n\n', minSpacing);
    
    % 写入建筑参数矩阵
    fprintf(fid, '%% 建筑参数矩阵\n');
    fprintf(fid, '%% 格式: [x_center, y_center, width, depth, height]\n');
    fprintf(fid, 'building_params = [\n');
    for b = 1:size(building_params, 1)
        fprintf(fid, '    %6.1f, %6.1f, %6.1f, %6.1f, %6.1f;', building_params(b, :));
        fprintf(fid, '  %% 建筑%d\n', b);
    end
    fprintf(fid, '];\n\n');
    
    % 写入输出变量声明
    fprintf(fid, '%% 输出变量\n');
    fprintf(fid, 'map_z = groundHeight * ones(mapSize);\n\n');
    
    % 写入建筑信息结构体初始化
    fprintf(fid, '%% 初始化建筑信息结构体\n');
    fprintf(fid, 'building_info = struct(''id'', {}, ''center_x'', {}, ''center_y'', {}, ...\n');
    fprintf(fid, '                      ''width'', {}, ''depth'', {}, ''height'', {}, ...\n');
    fprintf(fid, '                      ''x_min'', {}, ''x_max'', {}, ''y_min'', {}, ...\n');
    fprintf(fid, '                      ''y_max'', {}, ''valid'', {});\n\n');
    
    % 写入建筑放置代码
    fprintf(fid, '%% 放置建筑\n');
    for b = 1:buildingCount
        fprintf(fid, '%% 建筑%d\n', b);
        fprintf(fid, 'center_x_%d = building_params(%d, 1);\n', b, b);
        fprintf(fid, 'center_y_%d = building_params(%d, 2);\n', b, b);
        fprintf(fid, 'width_%d = building_params(%d, 3);\n', b, b);
        fprintf(fid, 'depth_%d = building_params(%d, 4);\n', b, b);
        fprintf(fid, 'height_%d = building_params(%d, 5);\n', b, b);
        fprintf(fid, 'x_min_%d = center_x_%d - width_%d/2;\n', b, b, b);
        fprintf(fid, 'x_max_%d = center_x_%d + width_%d/2;\n', b, b, b);
        fprintf(fid, 'y_min_%d = center_y_%d - depth_%d/2;\n', b, b, b);
        fprintf(fid, 'y_max_%d = center_y_%d + depth_%d/2;\n', b, b, b);
        
        fprintf(fid, '%% 在地形图上放置建筑%d\n', b);
        fprintf(fid, 'x_start_%d = max(1, floor(x_min_%d));\n', b, b);
        fprintf(fid, 'x_end_%d = min(mapSize(2), ceil(x_max_%d));\n', b, b);
        fprintf(fid, 'y_start_%d = max(1, floor(y_min_%d));\n', b, b);
        fprintf(fid, 'y_end_%d = min(mapSize(1), ceil(y_max_%d));\n', b, b);
        fprintf(fid, 'map_z(y_start_%d:y_end_%d, x_start_%d:x_end_%d) = height_%d;\n\n', b, b, b, b, b);
        
        fprintf(fid, '%% 保存建筑%d信息\n', b);
        fprintf(fid, 'building_info(%d).id = %d;\n', b, b);
        fprintf(fid, 'building_info(%d).center_x = center_x_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).center_y = center_y_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).width = width_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).depth = depth_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).height = height_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).x_min = x_min_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).x_max = x_max_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).y_min = y_min_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).y_max = y_max_%d;\n', b, b);
        fprintf(fid, 'building_info(%d).valid = true;\n\n', b);
    end
    
    % 写入地面纹理（使用固定的随机种子以确保可重现）
    fprintf(fid, '%% 添加地面纹理（使用固定随机种子确保可重现）\n');
    fprintf(fid, 'rng(42); %% 固定随机种子\n');
    fprintf(fid, 'ground_mask = (map_z == groundHeight);\n');
    fprintf(fid, 'ground_noise = randn(mapSize) * 0.1;\n');
    fprintf(fid, 'map_z = map_z + ground_mask .* ground_noise;\n\n');
    
    % 恢复建筑高度
    fprintf(fid, '%% 恢复建筑高度\n');
    for b = 1:buildingCount
        fprintf(fid, 'x_start_%d = max(1, floor(x_min_%d));\n', b, b);
        fprintf(fid, 'x_end_%d = min(mapSize(2), ceil(x_max_%d));\n', b, b);
        fprintf(fid, 'y_start_%d = max(1, floor(y_min_%d));\n', b, b);
        fprintf(fid, 'y_end_%d = min(mapSize(1), ceil(y_max_%d));\n', b, b);
        fprintf(fid, 'map_z(y_start_%d:y_end_%d, x_start_%d:x_end_%d) = height_%d;\n', b, b, b, b, b);
    end
    
    % 建筑间距检查
    fprintf(fid, '\n%% 建筑间距检查\n');
    fprintf(fid, 'fprintf(''建筑间距检查：\\n'');\n');
    fprintf(fid, 'fprintf(''======================================\\n'');\n');
    fprintf(fid, 'all_spacing_ok = true;\n');
    fprintf(fid, 'for i = 1:buildingCount\n');
    fprintf(fid, '    for j = i+1:buildingCount\n');
    fprintf(fid, '        %% 计算两个建筑之间的最小距离（边缘到边缘）\n');
    fprintf(fid, '        dist_x = max(0, building_info(i).x_min - building_info(j).x_max);\n');
    fprintf(fid, '        dist_x = max(dist_x, building_info(j).x_min - building_info(i).x_max);\n');
    fprintf(fid, '        dist_y = max(0, building_info(i).y_min - building_info(j).y_max);\n');
    fprintf(fid, '        dist_y = max(dist_y, building_info(j).y_min - building_info(i).y_max);\n');
    fprintf(fid, '        edge_dist = max(dist_x, dist_y);\n');
    fprintf(fid, '        \n');
    fprintf(fid, '        if edge_dist < minSpacing\n');
    fprintf(fid, '            fprintf(''警告: 建筑%%d和建筑%%d之间的间距(%%.1f)小于最小要求(%%d)\\n'', ...\n');
    fprintf(fid, '                    i, j, edge_dist, minSpacing);\n');
    fprintf(fid, '            all_spacing_ok = false;\n');
    fprintf(fid, '        else\n');
    fprintf(fid, '            fprintf(''建筑%%d和建筑%%d之间的间距: %%.1f (符合要求)\\n'', i, j, edge_dist);\n');
    fprintf(fid, '        end\n');
    fprintf(fid, '    end\n');
    fprintf(fid, 'end\n');
    fprintf(fid, '\n');
    fprintf(fid, 'if all_spacing_ok\n');
    fprintf(fid, '    fprintf(''\\n所有建筑间距检查通过！\\n'');\n');
    fprintf(fid, 'else\n');
    fprintf(fid, '    fprintf(''\\n存在建筑间距不符合要求！\\n'');\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'fprintf(''======================================\\n\\n'');\n\n');
    
    % 显示建筑信息汇总
    fprintf(fid, '%% 显示建筑信息汇总\n');
    fprintf(fid, 'fprintf(''建筑信息汇总（共%%d个建筑）：\\n'', buildingCount);\n');
    fprintf(fid, 'fprintf(''======================================\\n'');\n');
    fprintf(fid, 'for b = 1:buildingCount\n');
    fprintf(fid, '    fprintf(''建筑 %%2d: 中心(%%3.1f,%%3.1f), 尺寸(%%2.0fx%%2.0f), 高度%%2.0f\\n'', ...\n');
    fprintf(fid, '            b, building_info(b).center_x, building_info(b).center_y, ...\n');
    fprintf(fid, '            building_info(b).width, building_info(b).depth, ...\n');
    fprintf(fid, '            building_info(b).height);\n');
    fprintf(fid, 'end\n\n');
    
    % 计算并显示建筑覆盖率
    fprintf(fid, '%% 计算并显示建筑覆盖率\n');
    fprintf(fid, 'building_area = 0;\n');
    fprintf(fid, 'for b = 1:buildingCount\n');
    fprintf(fid, '    building_area = building_area + building_info(b).width * building_info(b).depth;\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'total_area = mapSize(1) * mapSize(2);\n');
    fprintf(fid, 'coverage = building_area / total_area * 100;\n');
    fprintf(fid, '\n');
    
    % 计算建筑间的平均间距
    fprintf(fid, '%% 计算建筑间的平均间距\n');
    fprintf(fid, 'if buildingCount > 1\n');
    fprintf(fid, '    total_spacing = 0;\n');
    fprintf(fid, '    spacing_count = 0;\n');
    fprintf(fid, '    \n');
    fprintf(fid, '    for i = 1:buildingCount\n');
    fprintf(fid, '        for j = i+1:buildingCount\n');
    fprintf(fid, '            %% 计算中心距离\n');
    fprintf(fid, '            dist_center = sqrt((building_info(i).center_x - building_info(j).center_x)^2 + ...\n');
    fprintf(fid, '                              (building_info(i).center_y - building_info(j).center_y)^2);\n');
    fprintf(fid, '            total_spacing = total_spacing + dist_center;\n');
    fprintf(fid, '            spacing_count = spacing_count + 1;\n');
    fprintf(fid, '        end\n');
    fprintf(fid, '    end\n');
    fprintf(fid, '    \n');
    fprintf(fid, '    avg_spacing = total_spacing / spacing_count;\n');
    fprintf(fid, 'else\n');
    fprintf(fid, '    avg_spacing = 0;\n');
    fprintf(fid, 'end\n\n');
    
    fprintf(fid, 'fprintf(''======================================\\n'');\n');
    fprintf(fid, 'fprintf(''建筑总面积: %%.0f 单位^2\\n'', building_area);\n');
    fprintf(fid, 'fprintf(''总地图面积: %%d 单位^2\\n'', total_area);\n');
    fprintf(fid, 'fprintf(''建筑覆盖率: %%.1f%%%%\\n'', coverage);\n');
    fprintf(fid, 'fprintf(''建筑间平均中心距离: %%.1f 单位\\n'', avg_spacing);\n');
    fprintf(fid, 'fprintf(''======================================\\n\\n'');\n\n');
    
    % =================== 可视化部分 ===================
    fprintf(fid, '%% =================== 可视化部分 ===================\n');
    
    % 第一个图形：3D网格图和2D平面图
    fprintf(fid, '%% 创建第一个图形：3D网格图和2D平面图\n');
    fprintf(fid, 'figure(''Position'', [100, 100, 1400, 600]);\n');
    fprintf(fid, '\n');
    fprintf(fid, '%% 3D网格图\n');
    fprintf(fid, 'subplot(1, 2, 1);\n');
    fprintf(fid, 'mesh(map_z);\n');
    fprintf(fid, 'title(sprintf(''城市地形图（%%d个长方体建筑，最小间距%%d单位）'', buildingCount, minSpacing));\n');
    fprintf(fid, 'xlabel(''X方向'');\n');
    fprintf(fid, 'ylabel(''Y方向'');\n');
    fprintf(fid, 'zlabel(''高度'');\n');
    fprintf(fid, 'colormap(jet);\n');
    fprintf(fid, 'colorbar;\n');
    fprintf(fid, 'view(45, 30);\n');
    fprintf(fid, 'grid on;\n');
    fprintf(fid, '\n');
    fprintf(fid, '%% 2D平面图（高度图）\n');
    fprintf(fid, 'subplot(1, 2, 2);\n');
    fprintf(fid, 'imagesc(map_z);\n');
    fprintf(fid, 'title(sprintf(''城市地形高度图（%%d个建筑）'', buildingCount));\n');
    fprintf(fid, 'xlabel(''X方向'');\n');
    fprintf(fid, 'ylabel(''Y方向'');\n');
    fprintf(fid, 'colorbar;\n');
    fprintf(fid, 'axis equal tight;\n');
    fprintf(fid, 'hold on;\n');
    fprintf(fid, '\n');
    fprintf(fid, '%% 在2D图上标注建筑轮廓和编号\n');
    fprintf(fid, 'for b = 1:buildingCount\n');
    fprintf(fid, '    %% 绘制建筑轮廓\n');
    fprintf(fid, '    rectangle(''Position'', [building_info(b).x_min, building_info(b).y_min, ...\n');
    fprintf(fid, '              building_info(b).width, building_info(b).depth], ...\n');
    fprintf(fid, '              ''EdgeColor'', ''r'', ''LineWidth'', 1.5, ''LineStyle'', ''-'');\n');
    fprintf(fid, '    \n');
    fprintf(fid, '    %% 标注建筑编号\n');
    fprintf(fid, '    text(building_info(b).center_x, building_info(b).center_y, ...\n');
    fprintf(fid, '         sprintf(''%%d'', b), ''HorizontalAlignment'', ''center'', ...\n');
    fprintf(fid, '         ''VerticalAlignment'', ''middle'', ''Color'', ''w'', ''FontWeight'', ''bold'', ''FontSize'', 10);\n');
    fprintf(fid, '    \n');
    fprintf(fid, '    %% 标注建筑高度\n');
    fprintf(fid, '    text(building_info(b).center_x, building_info(b).center_y + 3, ...\n');
    fprintf(fid, '         sprintf(''H=%%d'', building_info(b).height), ''HorizontalAlignment'', ''center'', ...\n');
    fprintf(fid, '         ''VerticalAlignment'', ''middle'', ''Color'', ''y'', ''FontSize'', 8);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'hold off;\n\n');
    
    % 第二个图形：间距矩阵图
    fprintf(fid, '%% 创建第二个图形：间距矩阵图\n');
    fprintf(fid, 'figure(''Position'', [100, 100, 800, 600]);\n');
    fprintf(fid, 'spacing_matrix = zeros(buildingCount, buildingCount);\n');
    fprintf(fid, '\n');
    fprintf(fid, 'for i = 1:buildingCount\n');
    fprintf(fid, '    for j = 1:buildingCount\n');
    fprintf(fid, '        if i == j\n');
    fprintf(fid, '            spacing_matrix(i, j) = 0;\n');
    fprintf(fid, '        else\n');
    fprintf(fid, '            %% 计算边缘到边缘的最小距离\n');
    fprintf(fid, '            dist_x = max(0, building_info(i).x_min - building_info(j).x_max);\n');
    fprintf(fid, '            dist_x = max(dist_x, building_info(j).x_min - building_info(i).x_max);\n');
    fprintf(fid, '            dist_y = max(0, building_info(i).y_min - building_info(j).y_max);\n');
    fprintf(fid, '            dist_y = max(dist_y, building_info(j).y_min - building_info(i).y_max);\n');
    fprintf(fid, '            spacing_matrix(i, j) = max(dist_x, dist_y);\n');
    fprintf(fid, '        end\n');
    fprintf(fid, '    end\n');
    fprintf(fid, 'end\n');
    fprintf(fid, '\n');
    fprintf(fid, 'imagesc(spacing_matrix);\n');
    fprintf(fid, 'title(''建筑间距矩阵（边缘到边缘距离）'');\n');
    fprintf(fid, 'xlabel(''建筑编号'');\n');
    fprintf(fid, 'ylabel(''建筑编号'');\n');
    fprintf(fid, 'colorbar;\n');
    fprintf(fid, 'colormap(jet);\n');
    fprintf(fid, '\n');
    fprintf(fid, '%% 在矩阵图上标注数值\n');
    fprintf(fid, 'for i = 1:buildingCount\n');
    fprintf(fid, '    for j = 1:buildingCount\n');
    fprintf(fid, '        if i ~= j\n');
    fprintf(fid, '            %% 使用if-else语句\n');
    fprintf(fid, '            if spacing_matrix(i, j) < minSpacing\n');
    fprintf(fid, '                text_color = ''r'';\n');
    fprintf(fid, '            else\n');
    fprintf(fid, '                text_color = ''k'';\n');
    fprintf(fid, '            end\n');
    fprintf(fid, '            \n');
    fprintf(fid, '            text(j, i, sprintf(''%%.1f'', spacing_matrix(i, j)), ...\n');
    fprintf(fid, '                 ''HorizontalAlignment'', ''center'', ''FontSize'', 8, ...\n');
    fprintf(fid, '                 ''Color'', text_color);\n');
    fprintf(fid, '        else\n');
    fprintf(fid, '            text(j, i, ''X'', ''HorizontalAlignment'', ''center'', ''FontSize'', 8);\n');
    fprintf(fid, '        end\n');
    fprintf(fid, '    end\n');
    fprintf(fid, 'end\n');
    fprintf(fid, '\n');
    fprintf(fid, 'set(gca, ''XTick'', 1:buildingCount);\n');
    fprintf(fid, 'set(gca, ''YTick'', 1:buildingCount);\n');
    fprintf(fid, 'axis equal tight;\n\n');
    
    % 清理临时变量
    fprintf(fid, '%% 清理临时变量\n');
    fprintf(fid, 'clear ground_mask ground_noise all_spacing_ok edge_dist dist_x dist_y i j;\n');
    for b = 1:buildingCount
        fprintf(fid, 'clear center_x_%d center_y_%d width_%d depth_%d height_%d;\n', b, b, b, b, b);
        fprintf(fid, 'clear x_min_%d x_max_%d y_min_%d y_max_%d;\n', b, b, b, b);
        fprintf(fid, 'clear x_start_%d x_end_%d y_start_%d y_end_%d;\n', b, b, b, b);
    end
    fprintf(fid, 'clear building_area total_area coverage total_spacing spacing_count avg_spacing;\n');
    fprintf(fid, 'clear spacing_matrix text_color;\n');
    
    fprintf(fid, '\n%% 显示完成信息\n');
    fprintf(fid, 'fprintf(''地形重建完成！\\n'');\n');
    fprintf(fid, 'fprintf(''建筑数量: %%d\\n'', buildingCount);\n');
    fprintf(fid, 'fprintf(''地图尺寸: 100x100\\n'');\n');
    fprintf(fid, 'fprintf(''已生成可视化图形。\\n'');\n');
    
    fclose(fid);
    
    fprintf('\n地形已保存为脚本: %s\n', scriptName);
    fprintf('运行该脚本可重现相同地形和可视化图形。\n');
end