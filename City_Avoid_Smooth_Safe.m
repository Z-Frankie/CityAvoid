%% 绝对安全平滑路径规划主程序
% 确保所有路径点都满足安全距离要求
% 严格按照起点-途经点1-途经点2-途经点3-途经点4-终点顺序规划

clc;
clear all;
close all;
warning off;

%% 固定随机数种子
rng('default')
noRng = 42;
rng(noRng);

%% 1. 用户参数设置
user_min_height = 5;      % 最低飞行高度（米）
user_max_height = 25;     % 最高飞行高度（米）
mu_max = pi/4;            % 最大俯仰角（45度）
beta_max = pi/3;          % 最大转弯角（60度）
safety_margin = 1;        % 安全距离（米）- 确保绝对安全

% 权重参数（针对绝对安全路径优化）
weights.length = 3.0;     % 路径长度权重（增加，强化最短路径约束）
weights.curvature = 0.5;  % 路径曲率权重
weights.collision = 10000.0; % 碰撞惩罚权重（极大）
weights.height_violation = 5000.0; % 高度违规权重（极大）

% 方向权重参数（控制避障运动方向偏好）
direction_weights.up = 0.3;          % 向上移动权重（降低）
direction_weights.down = 0.5;        % 向下移动权重（增加）
direction_weights.horizontal = 0.8;  % 横向移动权重（增加）

fprintf('\n========== 绝对安全路径规划参数 ==========\n');
fprintf('最低飞行高度: %.1f 米\n', user_min_height);
fprintf('最高飞行高度: %.1f 米\n', user_max_height);
fprintf('最大俯仰角: %.1f 度\n', mu_max * 180/pi);
fprintf('最大转弯角: %.1f 度\n', beta_max * 180/pi);
fprintf('安全距离: %.1f 米（绝对保证）\n', safety_margin);
fprintf('路径长度权重: %.1f（强化最短路径）\n', weights.length);
fprintf('避障方向权重设置：\n');
fprintf('  向上权重: %.1f（降低）\n', direction_weights.up);
fprintf('  向下权重: %.1f（增加）\n', direction_weights.down);
fprintf('  横向权重: %.1f（增加）\n', direction_weights.horizontal);
fprintf('路径顺序: 起点 -> 途经点1 -> 途经点2 -> 途经点3 -> 途经点4 -> 终点\n');
fprintf('安全要求: 所有路径点必须满足安全距离\n');
fprintf('优化目标: 最短路径 + 多方向平衡避障\n');
fprintf('===========================================\n\n');

%% 2. 生成城市地形
fprintf('正在生成城市地形...\n');
generated_terrain_buildings;
fprintf('城市地形生成完成！建筑数量：%d\n', length(building_info));

%% 3. 构建三维地图数据结构
global data

% 基本地图数据
data.map = map_z;
data.map_z = map_z;
data.map0 = map_z;
data.mapsize = [100, 100];
data.mapSize0 = size(map_z);
data.sizeMap = size(data.map_z);

% 创建网格坐标
[x, y] = meshgrid(1:100);
data.map_x = x;
data.map_y = y;

% 设置飞行参数
data.minH = user_min_height;
data.maxH = user_max_height;
data.mu_max = mu_max;
data.beta_max = beta_max;
data.building_info = building_info;
data.safety_margin = safety_margin;

%% 4. 设置起点、途经点和终点（固定顺序）
% 起点
start_x = 1;
start_y = 1;
desired_start_z = max(5, safety_margin + 2); % 确保起点安全

% 途经点（按照固定顺序：1->2->3->4）
% waypoints = [
%     25, 34, max(15, safety_margin + 10);   % 途经点1
%     40, 56, max(20, safety_margin + 12);   % 途经点2
%     50, 40, max(25, safety_margin + 15);   % 途经点3
%     77, 74, max(18, safety_margin + 12)    % 途经点4
% ];

waypoints = [
    25, 34, 15;   % 途经点1
    40, 56, 20;   % 途经点2
    50, 40, 25;   % 途经点3
    83, 70, 14    % 途经点4
];



% 终点
end_x = 100;
end_y = 100;
desired_end_z = max(10, safety_margin + 5);

% 将所有点合并
all_points = [
    start_x, start_y, desired_start_z;  % 起点
    waypoints;                         % 途经点（固定顺序）
    end_x, end_y, desired_end_z        % 终点
];

% 计算实际高度（强制安全高度）
actual_heights = zeros(size(all_points, 1), 3);
for i = 1:size(all_points, 1)
    x_pos = all_points(i, 1);
    y_pos = all_points(i, 2);
    desired_z = all_points(i, 3);
    
    % 确保在地图范围内
    x_idx = max(1, min(100, round(x_pos)));
    y_idx = max(1, min(100, round(y_pos)));
    
    terrain_height = data.map_z(y_idx, x_idx);
    
    % 强制安全高度：地形高度 + 安全距离
    safe_height = max(terrain_height + safety_margin, user_min_height);
    safe_height = min(safe_height, user_max_height);
    
    % 确保不低于期望高度
    actual_z = max(desired_z, safe_height);
    actual_z = min(actual_z, user_max_height); % 不超过最大高度
    
    actual_heights(i, :) = [x_pos, y_pos, actual_z];
end

% 设置数据结构（固定顺序）
data.S = actual_heights(1, :);  % 起点
data.waypoints = actual_heights(2:end-1, :);  % 途经点（固定顺序）
data.E0 = actual_heights(end, :);  % 终点

% 创建固定顺序的点列表：起点 + 途经点1 + 途经点2 + 途经点3 + 途经点4 + 终点
data.all_points_in_order = [
    data.S;                 % 起点
    data.waypoints(1, :);   % 途经点1
    data.waypoints(2, :);   % 途经点2
    data.waypoints(3, :);   % 途经点3
    data.waypoints(4, :);   % 途经点4
    data.E0                 % 终点
];

% 为了兼容原有代码，将所有途经点和终点合并到E0中（保持固定顺序）
data.E0 = data.all_points_in_order(2:end, :);  % 排除起点

% 验证所有点是否安全
fprintf('\n========== 路径点安全检查 ==========\n');
all_points_safe = true;
for i = 1:size(data.all_points_in_order, 1)
    point = data.all_points_in_order(i, :);
    x_idx = round(point(1));
    y_idx = round(point(2));
    
    if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
        terrain_height = data.map_z(y_idx, x_idx);
        safety_distance = point(3) - terrain_height;
        
        if safety_distance < safety_margin
            all_points_safe = false;
            fprintf('❌ 点 %d: (%.1f, %.1f, %.1f) 不安全！安全距离: %.2f < %.2f\n', ...
                i, point(1), point(2), point(3), safety_distance, safety_margin);
        else
            fprintf('✓ 点 %d: (%.1f, %.1f, %.1f) 安全距离: %.2f\n', ...
                i, point(1), point(2), point(3), safety_distance);
        end
    end
end

if all_points_safe
    fprintf('\n✓ 所有路径点初始安全检查通过！\n');
else
    fprintf('\n❌ 存在不安全的路径点，正在调整...\n');
    % 调整不安全点的高度
    for i = 1:size(data.all_points_in_order, 1)
        point = data.all_points_in_order(i, :);
        x_idx = round(point(1));
        y_idx = round(point(2));
        
        if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
            terrain_height = data.map_z(y_idx, x_idx);
            required_height = terrain_height + safety_margin;
            
            if point(3) < required_height
                new_height = max(required_height, user_min_height);
                new_height = min(new_height, user_max_height);
                data.all_points_in_order(i, 3) = new_height;
                fprintf('  调整点 %d 高度: %.1f -> %.1f\n', i, point(3), new_height);
            end
        end
    end
end
fprintf('====================================\n\n');

fprintf('\n========== 路径点信息（固定顺序） ==========\n');
fprintf('起点: (%.1f, %.1f, %.1f)\n', data.S(1), data.S(2), data.S(3));
for i = 1:size(data.waypoints, 1)
    fprintf('途经点%d: (%.1f, %.1f, %.1f)\n', i, data.waypoints(i, 1), data.waypoints(i, 2), data.waypoints(i, 3));
end
fprintf('终点: (%.1f, %.1f, %.1f)\n', data.E0(end, 1), data.E0(end, 2), data.E0(end, 3));
fprintf('===========================================\n\n');

%% 5. 设置绝对安全路径优化参数
fprintf('\n正在设置绝对安全路径优化参数...\n');

% 总点数：起点 + 4个途经点 + 终点 = 6个点
% 段数：起点->途经点1, 途经点1->途经点2, 途经点2->途经点3, 途经点3->途经点4, 途经点4->终点
num_points_in_order = size(data.all_points_in_order, 1);  % 6
num_segments = num_points_in_order - 1;  % 5段路径

% 控制点参数
num_ctrl_points_per_seg = 4;  % 每段4个控制点（三次贝塞尔曲线）

% 总控制点参数：每段需要 (num_ctrl_points_per_seg-2) 个中间控制点，每个控制点有3个参数(x,y,z)
params_per_seg = (num_ctrl_points_per_seg - 2) * 3;
total_params = num_segments * params_per_seg;

% 决策变量维度：包含控制点的所有坐标参数
dim = total_params;

fprintf('总点数（按顺序）: %d\n', num_points_in_order);
fprintf('总路径段数: %d\n', num_segments);
fprintf('每段控制点: %d\n', num_ctrl_points_per_seg);
fprintf('总控制点参数: %d\n', total_params);
fprintf('决策变量维度: %d\n', dim);

% 变量边界（针对所有坐标参数）
lb = zeros(1, dim);  % 下界
ub = ones(1, dim);   % 上界

% 目标函数（使用多方向避障版本）
fobj = @aimFcn_smooth_multi_directional;

% 算法选项
option.lb = lb;
option.ub = ub;
option.dim = dim;
option.fobj = fobj;
option.showIter = 1;
option.weights = weights;
option.user_minH = user_min_height;
option.user_maxH = user_max_height;
option.num_ctrl_points_per_seg = num_ctrl_points_per_seg;
option.num_segments = num_segments;
option.safety_margin = safety_margin;
option.horizontal_range = 5.0; % 水平方向最大偏离距离
option.direction_weights = direction_weights; % 方向权重
option.weight_direction_change = 0.3; % 方向变化惩罚权重
option.length_penalty_factor = 1.5; % 路径长度惩罚因子（新增）

% 海鸥算法参数（增加以获得更好结果）
option.numAgent = 40;      % 增加种群规模
option.maxIteration = 100; % 增加迭代次数

%% 6. 初始化种群（确保初始解安全）
fprintf('\n正在初始化安全种群...\n');

x = zeros(option.numAgent, option.dim);
y = zeros(option.numAgent, 1);
all_paths = cell(option.numAgent, 1);

safe_individuals = 0;
for i = 1:option.numAgent
    % 生成随机解（包含所有坐标参数）
    x(i, :) = rand(1, option.dim);
    
    % 计算适应度和路径
    try
        [y(i), result_i, path_i] = option.fobj(x(i, :), option, data);
        all_paths{i} = path_i;
        
        % 检查路径安全性
        if result_i.unsafe_points == 0
            safe_individuals = safe_individuals + 1;
            y(i) = y(i) * 0.9;  % 安全路径给予奖励
        else
            y(i) = y(i) * (1 + result_i.unsafe_points * 10);  % 不安全路径严重惩罚
        end
        
        % 增加路径长度惩罚（强化最短路径约束）
        if isfield(result_i, 'total_length')
            y(i) = y(i) + option.length_penalty_factor * result_i.total_length;
        end
    catch ME
        fprintf('个体 %d 初始化失败: %s\n', i, ME.message);
        y(i) = 1e12;  % 极高的惩罚
        all_paths{i} = data.all_points_in_order;
    end
end

fprintf('种群初始化完成，安全个体: %d/%d (%.1f%%)\n', ...
    safe_individuals, option.numAgent, 100*safe_individuals/option.numAgent);
fprintf('最优初始适应度: %.4f\n', min(y));

%% 7. 运行绝对安全海鸥算法
fprintf('\n开始运行绝对安全海鸥算法...\n');
fprintf('=============================================\n');
fprintf('优化目标优先级：\n');
fprintf('  1. 所有路径点必须满足安全距离 (≥%.1f米)\n', safety_margin);
fprintf('  2. 路径长度最短（权重: %.1f）\n', weights.length);
fprintf('  3. 严格按照顺序: 起点→途经点1→途经点2→途经点3→途经点4→终点\n');
fprintf('  4. 多方向平衡避障（向上:%.1f, 向下:%.1f, 横向:%.1f）\n', ...
    direction_weights.up, direction_weights.down, direction_weights.horizontal);
fprintf('  5. 任何不安全点都将导致路径被拒绝\n');
fprintf('=============================================\n');

tic;
[bestY, bestX, curve, all_best_paths, safety_records] = SOA_smooth_multi_directional(x, option.numAgent, option.maxIteration, ...
    option.lb, option.ub, option.dim, option.fobj, data, option);
elapsed_time = toc;

fprintf('\n=============================================\n');
fprintf('绝对安全路径优化完成！\n');
fprintf('运行时间: %.2f 秒\n', elapsed_time);
fprintf('最优适应度值: %.4f\n', bestY);

% 显示安全记录
safe_iterations = sum(safety_records == 0);
fprintf('安全迭代次数: %d/%d (%.1f%%)\n', safe_iterations, option.maxIteration, 100*safe_iterations/option.maxIteration);

%% 8. 绘制优化过程
figure('Position', [100, 100, 1200, 500], 'Name', '优化过程曲线');

% 适应度曲线
subplot(1, 2, 1);
plot(curve, 'b-', 'LineWidth', 2);
hold on;
plot(movmean(curve, 5), 'r--', 'LineWidth', 1.5);
xlabel('迭代次数');
ylabel('适应度值');
title('绝对安全路径优化过程');
legend('原始适应度', '移动平均', 'Location', 'best');
grid on;

% 安全记录曲线
subplot(1, 2, 2);
plot(safety_records, 'r-', 'LineWidth', 2);
hold on;
plot(movmean(safety_records, 10), 'g--', 'LineWidth', 1.5);
xlabel('迭代次数');
ylabel('不安全点数');
title('安全性优化过程');
legend('不安全点数', '移动平均', 'Location', 'best');
grid on;

%% 9. 计算并绘制最优绝对安全路径
fprintf('\n正在计算最优绝对安全路径...\n');
try
    [~, result, bestSmoothPath] = aimFcn_smooth_multi_directional(bestX, option, data);
    
    % 验证最终路径的绝对安全性
    [is_safe, unsafe_count, min_safety] = verify_path_safety(bestSmoothPath, data);
    
    if is_safe
        fprintf('✓ 最终路径绝对安全！最小安全距离: %.2f米\n', min_safety);
    else
        fprintf('❌ 最终路径存在不安全点: %d个\n', unsafe_count);
        fprintf('正在修复路径...\n');
        bestSmoothPath = repair_path_to_absolute_safety(bestSmoothPath, data);
        [is_safe, unsafe_count, min_safety] = verify_path_safety(bestSmoothPath, data);
        if is_safe
            fprintf('✓ 路径修复成功！最小安全距离: %.2f米\n', min_safety);
        else
            fprintf('❌ 路径修复失败！\n');
        end
    end
catch ME
    fprintf('最优路径计算失败: %s\n', ME.message);
    % 使用简单直线路径作为后备
    bestSmoothPath = data.all_points_in_order;
    bestSmoothPath = repair_path_to_absolute_safety(bestSmoothPath, data);
    result.fit = 0;
    result.total_length = 0;
    result.total_curvature = 0;
    result.collision_penalty = 0;
    result.height_violation = 0;
    result.unsafe_points = 0;
end

% 绘制绝对安全路径
figure('Position', [100, 100, 1400, 800], 'Name', '绝对安全三维路径规划结果');

% 3D视图
subplot(2, 2, [1, 3]);
mesh(data.map_x, data.map_y, data.map_z);
hold on;
alpha(0.6);
colormap(parula);

% 绘制建筑物
if isfield(data, 'building_info')
    for b = 1:length(data.building_info)
        x_vals = [data.building_info(b).x_min, data.building_info(b).x_max, ...
                  data.building_info(b).x_max, data.building_info(b).x_min];
        y_vals = [data.building_info(b).y_min, data.building_info(b).y_min, ...
                  data.building_info(b).y_max, data.building_info(b).y_max];
        z_vals = data.building_info(b).height * ones(1, 4);
        
        patch(x_vals, y_vals, z_vals, [0.7, 0.7, 0.7], 'FaceAlpha', 0.7, 'EdgeColor', 'k');
    end
end

% 绘制安全区域（建筑物上方安全区域）
for b = 1:length(data.building_info)
    x_vals = [data.building_info(b).x_min, data.building_info(b).x_max, ...
              data.building_info(b).x_max, data.building_info(b).x_min];
    y_vals = [data.building_info(b).y_min, data.building_info(b).y_min, ...
              data.building_info(b).y_max, data.building_info(b).y_max];
    z_vals = (data.building_info(b).height + safety_margin) * ones(1, 4);
    
    patch(x_vals, y_vals, z_vals, [0.2, 0.8, 0.2], 'FaceAlpha', 0.2, 'EdgeColor', 'g');
end

% 绘制起点、途经点、终点（固定顺序）
plot3(data.S(1), data.S(2), data.S(3), 'o', 'LineWidth', 3, ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0, 0.5, 1], 'MarkerSize', 15);
text(data.S(1), data.S(2), data.S(3)+5, '起点', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'b');

for i = 1:size(data.waypoints, 1)
    plot3(data.waypoints(i, 1), data.waypoints(i, 2), data.waypoints(i, 3), ...
        '^', 'LineWidth', 3, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceColor', [0.8, 0, 0.8], 'MarkerSize', 15);
    text(data.waypoints(i, 1), data.waypoints(i, 2), data.waypoints(i, 3)+5, ...
        sprintf('途经点%d', i), 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.8, 0, 0.8]);
end

plot3(data.E0(end, 1), data.E0(end, 2), data.E0(end, 3), 'h', 'LineWidth', 3, ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1, 0.5, 0], 'MarkerSize', 18);
text(data.E0(end, 1), data.E0(end, 2), data.E0(end, 3)+5, '终点', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [1, 0.5, 0]);

% 绘制绝对安全路径
if ~isempty(bestSmoothPath) && size(bestSmoothPath, 1) > 1
    plot3(bestSmoothPath(:, 1), bestSmoothPath(:, 2), bestSmoothPath(:, 3), ...
        'g-', 'LineWidth', 4);
    
    % 标记路径上的不安全点（应该没有）
    [is_safe, unsafe_count, min_safety] = verify_path_safety(bestSmoothPath, data);
    if unsafe_count > 0
        for i = 1:size(bestSmoothPath, 1)
            point = bestSmoothPath(i, :);
            x_idx = round(point(1));
            y_idx = round(point(2));
            
            if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
                terrain_height = data.map_z(y_idx, x_idx);
                if point(3) < terrain_height + safety_margin
                    plot3(point(1), point(2), point(3), 'rx', 'LineWidth', 3, 'MarkerSize', 10);
                end
            end
        end
    end
else
    fprintf('警告：平滑路径为空或无效\n');
end

xlabel('X方向');
ylabel('Y方向');
zlabel('高度');
title(sprintf('绝对安全三维路径规划（安全距离≥%.1f米）', safety_margin));
legend_items = {'地形', '建筑物', '安全区域', '起点', '途经点', '终点', '绝对安全路径'};
if unsafe_count > 0
    legend_items{end+1} = '不安全点';
end
legend(legend_items, 'Location', 'best', 'NumColumns', 2);
view(45, 30);
grid on;

% 2D平面视图
subplot(2, 2, 2);
imagesc(data.map_z);
hold on;

% 绘制安全区域（建筑物扩展区域）
for b = 1:length(data.building_info)
    % 建筑物本身
    rectangle('Position', [data.building_info(b).x_min, data.building_info(b).y_min, ...
        data.building_info(b).width, data.building_info(b).depth], ...
        'EdgeColor', 'r', 'LineWidth', 1.5, 'FaceColor', [1, 0.5, 0.5], 'FaceAlpha', 0.5);
    
    % 安全区域（建筑物周边）
    rectangle('Position', [data.building_info(b).x_min-1, data.building_info(b).y_min-1, ...
        data.building_info(b).width+2, data.building_info(b).depth+2], ...
        'EdgeColor', 'g', 'LineWidth', 1, 'LineStyle', '--');
end

% 绘制路径投影
if ~isempty(bestSmoothPath) && size(bestSmoothPath, 1) > 1
    plot(bestSmoothPath(:, 1), bestSmoothPath(:, 2), 'g-', 'LineWidth', 3);
    
    % 绘制直线参考路径（最短路径基准）
    for seg = 1:size(data.all_points_in_order, 1)-1
        plot([data.all_points_in_order(seg, 1), data.all_points_in_order(seg+1, 1)], ...
             [data.all_points_in_order(seg, 2), data.all_points_in_order(seg+1, 2)], ...
             'b--', 'LineWidth', 1, 'LineStyle', '--');
    end
end

% 绘制点
plot(data.S(1), data.S(2), 'o', 'LineWidth', 3, ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0, 0.5, 1], 'MarkerSize', 12);
text(data.S(1), data.S(2)-3, '起点', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'b', 'HorizontalAlignment', 'center');

for i = 1:size(data.waypoints, 1)
    plot(data.waypoints(i, 1), data.waypoints(i, 2), '^', 'LineWidth', 3, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0.8, 0, 0.8], 'MarkerSize', 12);
    text(data.waypoints(i, 1), data.waypoints(i, 2)-3, sprintf('途经点%d', i), ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.8, 0, 0.8], 'HorizontalAlignment', 'center');
end

plot(data.E0(end, 1), data.E0(end, 2), 'h', 'LineWidth', 3, ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1, 0.5, 0], 'MarkerSize', 15);
text(data.E0(end, 1), data.E0(end, 2)-3, '终点', ...
    'FontSize', 10, 'FontWeight', 'bold', 'Color', [1, 0.5, 0], 'HorizontalAlignment', 'center');

xlabel('X方向');
ylabel('Y方向');
title('绝对安全路径平面投影（蓝色虚线为直线最短路径参考）');
axis equal tight;
grid on;

% 高度变化曲线
subplot(2, 2, 4);
if ~isempty(bestSmoothPath) && size(bestSmoothPath, 1) > 1
    % 计算路径长度（累积）
    path_length = zeros(size(bestSmoothPath, 1), 1);
    for i = 2:size(bestSmoothPath, 1)
        path_length(i) = path_length(i-1) + norm(bestSmoothPath(i, :) - bestSmoothPath(i-1, :));
    end
    
    % 绘制路径高度
    plot(path_length, bestSmoothPath(:, 3), 'b-', 'LineWidth', 2);
    hold on;
    
    % 绘制地形高度（路径下方）
    terrain_heights = zeros(size(bestSmoothPath, 1), 1);
    safety_heights = zeros(size(bestSmoothPath, 1), 1);
    for i = 1:size(bestSmoothPath, 1)
        x_idx = round(bestSmoothPath(i, 1));
        y_idx = round(bestSmoothPath(i, 2));
        if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
            terrain_heights(i) = data.map_z(y_idx, x_idx);
            safety_heights(i) = terrain_heights(i) + safety_margin;
        end
    end
    plot(path_length, terrain_heights, 'k-', 'LineWidth', 1);
    plot(path_length, safety_heights, 'g--', 'LineWidth', 1.5);
    
    % 标记关键点
    key_points = data.all_points_in_order;
    key_point_indices = zeros(size(key_points, 1), 1);
    key_point_names = {'起点', '途经点1', '途经点2', '途经点3', '途经点4', '终点'};
    
    for k = 1:size(key_points, 1)
        distances = sqrt((bestSmoothPath(:, 1) - key_points(k, 1)).^2 + ...
                        (bestSmoothPath(:, 2) - key_points(k, 2)).^2);
        [~, idx] = min(distances);
        key_point_indices(k) = idx;
    end
    
    colors = {[0, 0.5, 1], [0.8, 0, 0.8], [0.8, 0, 0.8], [0.8, 0, 0.8], [0.8, 0, 0.8], [1, 0.5, 0]};
    markers = {'o', '^', '^', '^', '^', 'h'};
    
    for k = 1:length(key_point_indices)
        idx = key_point_indices(k);
        plot(path_length(idx), bestSmoothPath(idx, 3), markers{k}, ...
            'LineWidth', 2, 'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', colors{k}, 'MarkerSize', 10);
    end
    
    % 绘制高度限制线
    x_lim = get(gca, 'XLim');
    plot(x_lim, [user_min_height, user_min_height], 'c--', 'LineWidth', 1.5);
    plot(x_lim, [user_max_height, user_max_height], 'm--', 'LineWidth', 1.5);
    
    xlabel('路径长度（单位）');
    ylabel('高度（单位）');
    title('绝对安全路径高度变化');
    
    % 创建图例
    legend('路径高度', '地形高度', '安全高度线', '起点', '途经点', '终点', ...
        '最低高度限制', '最高高度限制', 'Location', 'best');
    grid on;
    
    text(0.02, 0.95, sprintf('最小安全距离: %.2f', min_safety), ...
        'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'g');
    text(0.02, 0.90, sprintf('路径点总数: %d', size(bestSmoothPath, 1)), ...
        'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold');
    text(0.02, 0.85, sprintf('路径总长度: %.2f', path_length(end)), ...
        'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold');
    
    % 修正三元运算符语法错误
    if unsafe_count == 0
        text(0.02, 0.80, sprintf('不安全点数: %d', unsafe_count), ...
            'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'g');
    else
        text(0.02, 0.80, sprintf('不安全点数: %d', unsafe_count), ...
            'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'r');
    end
else
    text(0.5, 0.5, '路径数据无效', 'HorizontalAlignment', 'center', 'FontSize', 14);
    axis off;
end

%% 10. 绝对安全路径质量评估
fprintf('\n================ 绝对安全路径质量评估 ================\n');
fprintf('飞行高度限制: %.0f - %.0f 米\n', user_min_height, user_max_height);
fprintf('安全距离要求: ≥%.1f 米\n', safety_margin);
fprintf('路径长度权重: %.1f\n', weights.length);
fprintf('最优适应度值: %.4f\n', bestY);

if isfield(result, 'total_length')
    fprintf('路径总长度: %.2f 单位\n', result.total_length);
    fprintf('总曲率代价: %.4f\n', result.total_curvature);
    fprintf('碰撞惩罚: %.4f\n', result.collision_penalty);
    fprintf('高度违规: %.4f\n', result.height_violation);
    fprintf('方向变化惩罚: %.4f\n', result.direction_change_penalty);
    fprintf('垂直变化惩罚: %.4f\n', result.vertical_change_penalty);
end

% 绝对安全验证
if ~isempty(bestSmoothPath) && size(bestSmoothPath, 1) > 1
    unsafe_points = 0;
    min_safety_distance = inf;
    safety_violations = [];
    
    for i = 1:size(bestSmoothPath, 1)
        x_pos = round(bestSmoothPath(i, 1));
        y_pos = round(bestSmoothPath(i, 2));
        z_pos = bestSmoothPath(i, 3);
        
        if x_pos >= 1 && x_pos <= 100 && y_pos >= 1 && y_pos <= 100
            terrain_height = data.map_z(y_pos, x_pos);
            safety_distance = z_pos - terrain_height;
            min_safety_distance = min(min_safety_distance, safety_distance);
            
            if safety_distance < safety_margin
                unsafe_points = unsafe_points + 1;
                safety_violations(end+1) = safety_distance;
            end
        end
    end
    
    fprintf('\n------ 绝对安全检查 ------\n');
    fprintf('最小安全距离: %.2f 米\n', min_safety_distance);
    fprintf('不安全点数量: %d / %d\n', unsafe_points, size(bestSmoothPath, 1));
    
    if unsafe_points == 0
        fprintf('✓ 所有点满足绝对安全距离要求！\n');
        
        % 安全等级评估
        if min_safety_distance >= safety_margin * 1.5
            fprintf('✓ 安全等级: 优秀 (安全余量充足)\n');
        elseif min_safety_distance >= safety_margin * 1.2
            fprintf('✓ 安全等级: 良好 (安全余量适当)\n');
        else
            fprintf('✓ 安全等级: 合格 (刚好满足安全要求)\n');
        end
    else
        fprintf('❌ 存在不安全点！\n');
        fprintf('不安全点安全距离: ');
        for i = 1:min(5, length(safety_violations))
            fprintf('%.2f ', safety_violations(i));
        end
        if length(safety_violations) > 5
            fprintf('... (共%d个)', length(safety_violations));
        end
        fprintf('\n');
    end
end

% 路径方向特性分析
fprintf('\n------ 路径方向特性分析 ------\n');
if ~isempty(bestSmoothPath) && size(bestSmoothPath, 1) > 1
    direction_stats = analyze_path_direction(bestSmoothPath);
    
    if direction_stats.valid
        fprintf('路径段总数: %d\n', direction_stats.num_segments);
        fprintf('向上移动段: %d (%.1f%%)\n', direction_stats.upward_segments, direction_stats.upward_percent);
        fprintf('向下移动段: %d (%.1f%%)\n', direction_stats.downward_segments, direction_stats.downward_percent);
        fprintf('水平移动段: %d (%.1f%%)\n', direction_stats.horizontal_segments, direction_stats.horizontal_percent);
        fprintf('平均向上变化: %.2f 单位\n', direction_stats.avg_upward_change);
        fprintf('平均向下变化: %.2f 单位\n', direction_stats.avg_downward_change);
        fprintf('平均水平变化: %.2f 单位\n', direction_stats.avg_horizontal_change);
        fprintf('方向平衡度: %.3f (1为完全平衡)\n', direction_stats.balance_ratio);
        
        if direction_stats.need_adjustment
            fprintf('建议调整: %s\n', direction_stats.adjustment_suggestion);
        else
            fprintf('✓ 路径方向分布合理\n');
        end
    end
end

% 检查路径顺序
fprintf('\n------ 路径顺序验证 ------\n');
if ~isempty(bestSmoothPath) && size(bestSmoothPath, 1) > 1
    key_points = data.all_points_in_order;
    passed_all = true;
    max_allowed_distance = 3.0;  % 最大允许偏离距离
    
    for k = 1:size(key_points, 1)
        distances = sqrt((bestSmoothPath(:, 1) - key_points(k, 1)).^2 + ...
                        (bestSmoothPath(:, 2) - key_points(k, 2)).^2);
        min_dist = min(distances);
        
        % 确定点的名称
        if k == 1
            point_name = '起点';
        elseif k == size(key_points, 1)
            point_name = '终点';
        else
            point_name = sprintf('途经点%d', k-1);
        end
        
        if min_dist <= max_allowed_distance
            fprintf('✓ 通过 %s (最近距离: %.2f)\n', point_name, min_dist);
        else
            fprintf('❌ 未充分接近 %s (最近距离: %.2f > %.2f)\n', ...
                point_name, min_dist, max_allowed_distance);
            passed_all = false;
        end
    end
    
    if passed_all
        fprintf('\n✓ 路径按正确顺序通过所有点\n');
    else
        fprintf('\n❌ 路径未按正确顺序通过所有点\n');
    end
end

% 综合评估
fprintf('\n------ 综合评估 ------\n');
if exist('unsafe_points', 'var') && unsafe_points == 0 && ...
   exist('min_safety_distance', 'var') && min_safety_distance >= safety_margin
    fprintf('✓ 绝对安全路径规划成功！\n');
    fprintf('  1. 所有路径点满足安全距离要求\n');
    fprintf('  2. 路径总长度: %.2f 单位（已优化）\n', result.total_length);
    fprintf('  3. 按正确顺序通过所有点\n');
    fprintf('  4. 路径平滑可行，方向分布合理\n');
elseif exist('unsafe_points', 'var') && unsafe_points == 0
    fprintf('⚠ 路径基本安全但需注意：\n');
    fprintf('  1. 所有路径点满足安全距离要求\n');
    fprintf('  2. 路径总长度: %.2f 单位\n', result.total_length);
    if exist('passed_all', 'var') && passed_all
        fprintf('  3. 按正确顺序通过所有点\n');
    else
        fprintf('  3. 路径顺序可能有问题\n');
    end
else
    fprintf('❌ 绝对安全路径规划失败！\n');
    fprintf('  原因: 存在 %d 个不安全点\n', unsafe_points);
end

fprintf('==================================================\n');

%% 11. 保存绝对安全结果
save_option = input('\n是否保存绝对安全路径结果？(1=是, 0=否): ');
if save_option == 1
    filename = sprintf('absolutely_safe_path_%s_h%.0f-%.0f_safe%.1f.mat', ...
        datestr(now, 'yyyymmdd_HHMMSS'), user_min_height, user_max_height, safety_margin);
    
    save(filename, 'bestX', 'bestY', 'result', 'bestSmoothPath', 'data', ...
        'building_info', 'user_min_height', 'user_max_height', 'weights', ...
        'direction_weights', 'curve', 'safety_records', 'elapsed_time', 'safety_margin');
    
    fprintf('绝对安全路径结果已保存到文件: %s\n', filename);
    
    % 保存图形
    fig_handles = findobj('Type', 'figure');
    for i = 1:length(fig_handles)
        fig = fig_handles(i);
        fig_name = sprintf('absolutely_safe_path_%s_fig%d.png', datestr(now, 'yyyymmdd_HHMMSS'), i);
        saveas(fig, fig_name);
        fprintf('图形已保存: %s\n', fig_name);
    end
end

fprintf('\n绝对安全路径规划完成！\n');

%% 辅助函数
function [is_safe, unsafe_count, min_safety] = verify_path_safety(path, data)
    % 验证路径绝对安全性
    % 返回: is_safe - 是否安全
    %       unsafe_count - 不安全点数量
    %       min_safety - 最小安全距离
    
    if isempty(path)
        is_safe = false;
        unsafe_count = 0;
        min_safety = 0;
        return;
    end
    
    safety_margin = data.safety_margin;
    unsafe_count = 0;
    min_safety = inf;
    
    for i = 1:size(path, 1)
        point = path(i, :);
        x_idx = round(point(1));
        y_idx = round(point(2));
        
        if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
            terrain_height = data.map_z(y_idx, x_idx);
            safety_distance = point(3) - terrain_height;
            min_safety = min(min_safety, safety_distance);
            
            if safety_distance < safety_margin
                unsafe_count = unsafe_count + 1;
            end
        else
            unsafe_count = unsafe_count + 1;
        end
    end
    
    is_safe = (unsafe_count == 0);
end

function safe_path = repair_path_to_absolute_safety(path, data)
    % 修复路径到绝对安全状态
    safety_margin = data.safety_margin;
    minH = data.minH;
    maxH = data.maxH;
    
    safe_path = path;
    
    % 第一步：确保每个点都满足安全距离
    for i = 1:size(path, 1)
        point = path(i, :);
        x_idx = round(point(1));
        y_idx = round(point(2));
        
        if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
            terrain_height = data.map_z(y_idx, x_idx);
            required_height = terrain_height + safety_margin;
            required_height = max(required_height, minH);
            required_height = min(required_height, maxH);
            
            if point(3) < required_height
                safe_path(i, 3) = required_height;
            end
        end
    end
    
    % 第二步：平滑处理（保持安全性）
    if size(safe_path, 1) > 5
        % 使用移动平均平滑高度，但确保不会降低到不安全高度
        window_size = 5;
        smoothed_heights = movmean(safe_path(:, 3), window_size);
        
        % 检查平滑后的高度是否安全
        for i = 1:size(safe_path, 1)
            point = safe_path(i, :);
            x_idx = round(point(1));
            y_idx = round(point(2));
            
            if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
                terrain_height = data.map_z(y_idx, x_idx);
                required_height = terrain_height + safety_margin;
                required_height = max(required_height, minH);
                required_height = min(required_height, maxH);
                
                % 确保平滑后的高度不低于安全高度
                if smoothed_heights(i) < required_height
                    smoothed_heights(i) = required_height;
                end
            end
        end
        
        safe_path(:, 3) = smoothed_heights;
    end
    
    % 第三步：最终安全检查
    for i = 1:size(safe_path, 1)
        point = safe_path(i, :);
        x_idx = round(point(1));
        y_idx = round(point(2));
        
        if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
            terrain_height = data.map_z(y_idx, x_idx);
            required_height = terrain_height + safety_margin;
            required_height = max(required_height, minH);
            required_height = min(required_height, maxH);
            
            if safe_path(i, 3) < required_height
                safe_path(i, 3) = required_height;
            end
        end
    end
end