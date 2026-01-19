%% 路径规划结果可视化脚本
% 用于直接加载保存的路径规划结果文件并可视化
% 支持带途经点的路径规划结果

clc;
clear all;
close all;
warning off;

%% 1. 选择要加载的结果文件
fprintf('================ 路径规划结果可视化工具 ================\n');
fprintf('请选择要加载的路径规划结果文件（.mat格式）...\n');

% 让用户选择文件
[filename, pathname] = uigetfile('*.mat', '选择路径规划结果文件');
if isequal(filename, 0)
    fprintf('用户取消了选择。\n');
    return;
end

fullpath = fullfile(pathname, filename);
fprintf('正在加载文件: %s\n', fullpath);

%% 2. 加载数据
try
    % 加载MAT文件
    loaded_data = load(fullpath);
    fprintf('文件加载成功！\n');
    
    % 检查必要的变量是否存在
    required_vars = {'data', 'result', 'bestX', 'bestY', 'newPath'};
    missing_vars = {};
    
    for i = 1:length(required_vars)
        if ~isfield(loaded_data, required_vars{i})
            missing_vars{end+1} = required_vars{i};
        end
    end
    
    if ~isempty(missing_vars)
        fprintf('警告：文件中缺少以下变量：\n');
        for i = 1:length(missing_vars)
            fprintf('  - %s\n', missing_vars{i});
        end
        fprintf('继续加载，但某些功能可能不可用。\n');
    end
    
    % 提取变量
    data = loaded_data.data;
    result = loaded_data.result;
    bestX = loaded_data.bestX;
    bestY = loaded_data.bestY;
    newPath = loaded_data.newPath;
    
    % 提取其他可选变量
    if isfield(loaded_data, 'building_info')
        building_info = loaded_data.building_info;
    else
        building_info = [];
        fprintf('警告：未找到building_info变量，将不绘制建筑物。\n');
    end
    
    if isfield(loaded_data, 'user_min_height')
        user_min_height = loaded_data.user_min_height;
    elseif isfield(data, 'minH')
        user_min_height = data.minH;
    else
        user_min_height = 5;
        fprintf('警告：未找到最小高度信息，使用默认值5米。\n');
    end
    
    if isfield(loaded_data, 'user_max_height')
        user_max_height = loaded_data.user_max_height;
    elseif isfield(data, 'maxH')
        user_max_height = data.maxH;
    else
        user_max_height = 25;
        fprintf('警告：未找到最大高度信息，使用默认值25米。\n');
    end
    
catch ME
    fprintf('加载文件时出错：%s\n', ME.message);
    return;
end

%% 3. 显示文件信息
fprintf('\n========== 文件信息 ==========\n');
fprintf('文件名: %s\n', filename);
fprintf('文件路径: %s\n', pathname);
fprintf('最优适应度值: %.4f\n', bestY);
fprintf('路径总长度: %.2f 单位\n', result.fit);

% 显示起点和终点信息
if isfield(data, 'S')
    fprintf('起点坐标: (%.1f, %.1f, %.1f)\n', data.S(1), data.S(2), data.S(3));
end

if isfield(data, 'E0')
    fprintf('终点坐标: (%.1f, %.1f, %.1f)\n', data.E0(end, 1), data.E0(end, 2), data.E0(end, 3));
end

% 显示途经点信息
if isfield(data, 'waypoints') && ~isempty(data.waypoints)
    fprintf('途经点数量: %d\n', size(data.waypoints, 1));
    for i = 1:size(data.waypoints, 1)
        fprintf('途经点%d: (%.1f, %.1f, %.1f)\n', i, data.waypoints(i, 1), data.waypoints(i, 2), data.waypoints(i, 3));
    end
end

fprintf('飞行高度限制: %.0f - %.0f 米\n', user_min_height, user_max_height);
fprintf('路径节点数: %d\n', size(newPath, 1));
fprintf('================================\n\n');

%% 4. 重建绘图所需的选项结构体
% 创建必要的option结构体（drawPC函数需要）
option = struct();
option.lb = 0.6;
option.ub = 1.2;
option.dim = length(bestX);
option.fobj = @aimFcn_1;
option.showIter = 0;
option.numAgent = 20;
option.maxIteration = 50;

% 确保data中有必要的字段
if ~isfield(data, 'map0')
    if isfield(data, 'map')
        data.map0 = data.map;
    elseif isfield(data, 'map_z')
        data.map0 = data.map_z;
    end
end

if ~isfield(data, 'mapSize0')
    if isfield(data, 'map0')
        data.mapSize0 = size(data.map0);
    elseif isfield(data, 'map_z')
        data.mapSize0 = size(data.map_z);
    end
end

% 确保地图坐标存在
if ~isfield(data, 'map_x') || ~isfield(data, 'map_y')
    fprintf('正在重建地图坐标...\n');
    [data.map_x, data.map_y] = meshgrid(1:size(data.map_z, 2), 1:size(data.map_z, 1));
end

%% 5. 绘制最终路径图
fprintf('正在绘制最终路径图...\n');

% 创建标题字符串
if isfield(data, 'waypoints') && ~isempty(data.waypoints)
    str = sprintf('海鸥算法三维路径规划（带途经点，高度限制: %.0f-%.0f米）', user_min_height, user_max_height);
else
    str = sprintf('海鸥算法三维路径规划（高度限制: %.0f-%.0f米）', user_min_height, user_max_height);
end

% 调用drawPC函数绘制路径
newPath = drawPC(result, option, data, str);

% 在图中添加建筑信息（如果building_info存在）
if ~isempty(building_info)
    hold on;
    for b = 1:length(building_info)
        % 绘制建筑顶部
        x_vals = [building_info(b).x_min, building_info(b).x_max, building_info(b).x_max, building_info(b).x_min];
        y_vals = [building_info(b).y_min, building_info(b).y_min, building_info(b).y_max, building_info(b).y_max];
        z_vals = building_info(b).height * ones(1, 4);
        
        % 绘制建筑侧面
        patch(x_vals, y_vals, z_vals, [0.8, 0.8, 0.8], 'FaceAlpha', 0.7, 'EdgeColor', 'k');
    end
end

% 绘制飞行高度限制参考面（半透明）
hold on;
[X_ref, Y_ref] = meshgrid(0:20:100, 0:20:100);
Z_min_ref = user_min_height * ones(size(X_ref));
Z_max_ref = user_max_height * ones(size(X_ref));

surf(X_ref, Y_ref, Z_min_ref, 'FaceColor', 'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
surf(X_ref, Y_ref, Z_max_ref, 'FaceColor', 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');

% 添加图例
if isfield(data, 'waypoints') && ~isempty(data.waypoints)
    legend_items = {'起点', '途经点', '终点', '地形', '规划路径'};
    if ~isempty(building_info)
        legend_items{end+1} = '建筑物';
    end
    legend_items{end+1} = '最低高度面';
    legend_items{end+1} = '最高高度面';
    
    legend(legend_items, 'Location', 'best');
else
    legend_items = {'起点', '终点', '地形', '规划路径'};
    if ~isempty(building_info)
        legend_items{end+1} = '建筑物';
    end
    legend_items{end+1} = '最低高度面';
    legend_items{end+1} = '最高高度面';
    
    legend(legend_items, 'Location', 'best');
end

%% 6. 绘制2D平面路径图
figure('Position', [100, 100, 1200, 500]);

% 2D高度图
subplot(1, 2, 1);
imagesc(data.map_z);
hold on;

% 绘制起点
if isfield(data, 'S')
    plot(data.S(1), data.S(2), 'o', 'LineWidth', 2, ...
        'MarkerEdgeColor', 'k', ...
        'MarkerFaceColor', [0, 0.5, 1], ...
        'MarkerSize', 10);
end

% 绘制途经点（如果存在）
if isfield(data, 'waypoints') && ~isempty(data.waypoints)
    for i = 1:size(data.waypoints, 1)
        plot(data.waypoints(i, 1), data.waypoints(i, 2), ...
            '^', 'LineWidth', 2, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', [0.8, 0, 0.8], ...
            'MarkerSize', 10);
    end
end

% 绘制终点
if isfield(data, 'E0')
    plot(data.E0(end, 1), data.E0(end, 2), 'p', 'LineWidth', 2, ...
        'MarkerEdgeColor', 'k', ...
        'MarkerFaceColor', [1, 0.5, 0], ...
        'MarkerSize', 12);
end

% 绘制规划路径
if ~isempty(newPath)
    plot(newPath(:, 1), newPath(:, 2), 'm-', 'LineWidth', 2);
end

% 绘制建筑物轮廓（如果存在）
if ~isempty(building_info)
    for b = 1:length(building_info)
        rectangle('Position', [building_info(b).x_min, building_info(b).y_min, ...
            building_info(b).width, building_info(b).depth], ...
            'EdgeColor', 'r', 'LineWidth', 1.5);
        
        text(building_info(b).center_x, building_info(b).center_y, ...
            sprintf('%d\nH=%d', b, building_info(b).height), ...
            'HorizontalAlignment', 'center', 'FontSize', 7, 'Color', 'w', 'FontWeight', 'bold');
    end
end

colorbar;
xlabel('X方向');
ylabel('Y方向');
title('路径规划结果（2D视图）');
axis equal tight;
grid on;

% 添加高度信息标注
if isfield(data, 'S')
    text(data.S(1), data.S(2)-3, sprintf('起点:%.1fm', data.S(3)), ...
        'Color', 'b', 'FontSize', 8, 'FontWeight', 'bold');
end

if isfield(data, 'E0')
    text(data.E0(end, 1)-10, data.E0(end, 2)-3, sprintf('终点:%.1fm', data.E0(end, 3)), ...
        'Color', [1, 0.5, 0], 'FontSize', 8, 'FontWeight', 'bold');
end

% 高度分布图
subplot(1, 2, 2);
if ~isempty(newPath)
    % 计算路径长度（累积距离）
    path_length = zeros(size(newPath, 1), 1);
    for i = 2:size(newPath, 1)
        path_length(i) = path_length(i-1) + norm(newPath(i, 1:2) - newPath(i-1, 1:2));
    end
    
    plot(path_length, newPath(:, 3), 'b-', 'LineWidth', 2);
    hold on;
    
    % 标记起点、途经点和终点
    if isfield(data, 'S')
        plot(0, data.S(3), 'o', 'LineWidth', 2, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', [0, 0.5, 1], ...
            'MarkerSize', 10);
    end
    
    % 标记途经点（需要找到它们在路径中的位置）
    if isfield(data, 'waypoints') && ~isempty(data.waypoints)
        for i = 1:size(data.waypoints, 1)
            % 找到离途经点最近的路径点
            distances = sqrt((newPath(:, 1) - data.waypoints(i, 1)).^2 + ...
                            (newPath(:, 2) - data.waypoints(i, 2)).^2);
            [~, idx] = min(distances);
            
            plot(path_length(idx), data.waypoints(i, 3), '^', 'LineWidth', 2, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', [0.8, 0, 0.8], ...
                'MarkerSize', 10);
        end
    end
    
    % 标记终点
    if isfield(data, 'E0')
        distances = sqrt((newPath(:, 1) - data.E0(end, 1)).^2 + ...
                        (newPath(:, 2) - data.E0(end, 2)).^2);
        [~, idx] = min(distances);
        
        plot(path_length(idx), data.E0(end, 3), 'p', 'LineWidth', 2, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', [1, 0.5, 0], ...
            'MarkerSize', 12);
    end
    
    % 绘制高度限制线
    x_limits = get(gca, 'XLim');
    plot(x_limits, [user_min_height, user_min_height], 'g--', 'LineWidth', 1.5);
    plot(x_limits, [user_max_height, user_max_height], 'r--', 'LineWidth', 1.5);
    
    xlabel('路径长度（单位）');
    ylabel('高度（单位）');
    title('路径高度变化曲线');
    grid on;
    
    % 添加图例
    legend_items = {'路径高度', '起点', '终点', '最低高度限制', '最高高度限制'};
    if isfield(data, 'waypoints') && ~isempty(data.waypoints)
        legend_items = {'路径高度', '起点', '途经点', '终点', '最低高度限制', '最高高度限制'};
    end
    legend(legend_items, 'Location', 'best');
    
    % 标注统计信息
    max_height = max(newPath(:, 3));
    min_height = min(newPath(:, 3));
    avg_height = mean(newPath(:, 3));
    
    text(0.02, 0.95, sprintf('最高点: %.2f', max_height), ...
        'Units', 'normalized', 'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');
    text(0.02, 0.90, sprintf('最低点: %.2f', min_height), ...
        'Units', 'normalized', 'Color', 'g', 'FontSize', 10, 'FontWeight', 'bold');
    text(0.02, 0.85, sprintf('平均高度: %.2f', avg_height), ...
        'Units', 'normalized', 'Color', 'b', 'FontSize', 10, 'FontWeight', 'bold');
end

%% 7. 显示路径统计信息
fprintf('\n================ 路径规划结果统计 ================\n');
fprintf('飞行高度限制: %.0f - %.0f 米\n', user_min_height, user_max_height);

if isfield(data, 'S')
    fprintf('起点坐标: (%.1f, %.1f, %.1f)\n', data.S(1), data.S(2), data.S(3));
end

if isfield(data, 'E0')
    fprintf('终点坐标: (%.1f, %.1f, %.1f)\n', data.E0(end, 1), data.E0(end, 2), data.E0(end, 3));
end

if isfield(data, 'waypoints') && ~isempty(data.waypoints)
    fprintf('途经点数量: %d\n', size(data.waypoints, 1));
    for i = 1:size(data.waypoints, 1)
        fprintf('途经点%d坐标: (%.1f, %.1f, %.1f)\n', i, data.waypoints(i, 1), data.waypoints(i, 2), data.waypoints(i, 3));
    end
end

fprintf('最优路径适应度值: %.4f\n', bestY);
fprintf('路径总长度: %.2f 单位\n', result.fit);
fprintf('路径节点数: %d\n', size(newPath, 1));

% 显示途经点访问顺序（如果存在）
if isfield(result, 'waypoints_order')
    fprintf('途经点访问顺序: ');
    order = result.waypoints_order(1:end-1);  % 排除终点
    fprintf('%d ', order);
    fprintf('\n');
end

% 计算路径高度变化
if size(newPath, 1) > 1
    max_height = max(newPath(:, 3));
    min_height = min(newPath(:, 3));
    avg_height = mean(newPath(:, 3));
    
    fprintf('路径最高点: %.2f 单位 (限制: %.0f)\n', max_height, user_max_height);
    fprintf('路径最低点: %.2f 单位 (限制: %.0f)\n', min_height, user_min_height);
    fprintf('路径平均高度: %.2f 单位\n', avg_height);
    fprintf('路径高度变化范围: %.2f 单位\n', max_height - min_height);
    
    % 检查路径高度是否符合限制
    if max_height > user_max_height
        fprintf('警告：路径最高点超过最高飞行高度限制！\n');
    elseif max_height > user_max_height * 0.9
        fprintf('注意：路径最高点接近最高飞行高度限制。\n');
    end
    
    if min_height < user_min_height
        fprintf('警告：路径最低点低于最低飞行高度限制！\n');
    elseif min_height < user_min_height * 1.1
        fprintf('注意：路径最低点接近最低飞行高度限制。\n');
    end
    
    % 计算路径高度与限制的符合程度
    height_violation_points = 0;
    for i = 1:size(newPath, 1)
        if newPath(i, 3) < user_min_height || newPath(i, 3) > user_max_height
            height_violation_points = height_violation_points + 1;
        end
    end
    height_compliance_rate = 100 * (1 - height_violation_points / size(newPath, 1));
    fprintf('路径高度符合率: %.1f%%\n', height_compliance_rate);
end

% 检查路径是否避开建筑物（如果building_info存在）
collision_count = 0;
if ~isempty(building_info) && size(newPath, 1) > 1
    for i = 1:size(newPath, 1)
        x_pos = round(newPath(i, 1));
        y_pos = round(newPath(i, 2));
        z_pos = newPath(i, 3);
        
        % 检查是否与建筑物碰撞
        for b = 1:length(building_info)
            if x_pos >= building_info(b).x_min && x_pos <= building_info(b).x_max && ...
               y_pos >= building_info(b).y_min && y_pos <= building_info(b).y_max && ...
               z_pos <= building_info(b).height + 1  % 留出1米安全余量
                collision_count = collision_count + 1;
                break;
            end
        end
    end
    fprintf('路径建筑碰撞风险点数: %d / %d (%.1f%%)\n', collision_count, size(newPath, 1), ...
        100 * collision_count / size(newPath, 1));
end

% 路径可行性评估
fprintf('\n------ 路径可行性评估 ------\n');
if size(newPath, 1) > 1
    if exist('height_compliance_rate', 'var') && height_compliance_rate > 95 && ...
       (isempty(building_info) || collision_count/size(newPath, 1) < 0.05)
        fprintf('评估结果: 路径可行 ✓\n');
    elseif exist('height_compliance_rate', 'var') && height_compliance_rate > 90 && ...
           (isempty(building_info) || collision_count/size(newPath, 1) < 0.1)
        fprintf('评估结果: 路径基本可行，建议微调参数\n');
    else
        fprintf('评估结果: 路径存在问题，建议重新规划\n');
        fprintf('可能的原因:\n');
        if exist('max_height', 'var') && max_height > user_max_height
            fprintf('  - 最高飞行高度限制过低\n');
        end
        if exist('min_height', 'var') && min_height < user_min_height
            fprintf('  - 最低飞行高度限制过高\n');
        end
        if ~isempty(building_info) && collision_count > 0
            fprintf('  - 存在建筑碰撞风险\n');
        end
    end
end

fprintf('==================================================\n');

%% 8. 保存可视化结果
fprintf('\n是否保存可视化结果为图片？\n');
save_option = input('(1=保存所有图形, 2=只保存3D图, 3=不保存): ');

if save_option == 1 || save_option == 2
    % 保存3D路径图
    figure_handles = findobj('Type', 'figure');
    
    for i = 1:length(figure_handles)
        fig = figure_handles(i);
        
        % 获取图形标题
        fig_title = get(get(gca(fig), 'Title'), 'String');
        if isempty(fig_title)
            fig_title = sprintf('figure_%d', i);
        end
        
        % 清理文件名中的非法字符
        fig_title = regexprep(fig_title, '[<>:"/\\|?*]', '_');
        
        % 生成文件名
        if i == 1
            filename_3d = sprintf('visualization_3d_%s.png', datestr(now, 'yyyymmdd_HHMMSS'));
        else
            filename_2d = sprintf('visualization_2d_%s.png', datestr(now, 'yyyymmdd_HHMMSS'));
        end
        
        % 保存图形
        if i == 1  % 3D图
            saveas(fig, filename_3d);
            fprintf('3D路径图已保存为: %s\n', filename_3d);
            if save_option == 2
                break;  % 只保存3D图
            end
        else  % 2D图
            saveas(fig, filename_2d);
            fprintf('2D路径图已保存为: %s\n', filename_2d);
        end
    end
end

fprintf('\n可视化完成！\n');