%% 平滑路径优化过程动画
% 可视化SOA算法如何逐步优化出平滑路径

function animate_smooth_path(result_file)
% result_file: 保存的平滑路径结果文件

clc;
clear;
close all;

if nargin < 1
    % 让用户选择文件
    [filename, pathname] = uigetfile('*.mat', '选择平滑路径结果文件');
    if isequal(filename, 0)
        fprintf('用户取消了选择。\n');
        return;
    end
    result_file = fullfile(pathname, filename);
end

% 加载数据
fprintf('正在加载文件: %s\n', result_file);
data = load(result_file);

% 检查必要的数据
if ~isfield(data, 'all_best_paths')
    fprintf('错误：文件中没有保存优化过程路径数据。\n');
    return;
end

% 提取数据
all_best_paths = data.all_best_paths;
building_info = data.building_info;
user_min_height = data.user_min_height;
user_max_height = data.user_max_height;
map_z = data.data.map_z;

% 创建动画
fprintf('正在创建平滑路径优化动画...\n');

figure('Position', [100, 100, 1200, 800], 'Color', 'white');

% 设置子图
subplot(2, 2, [1, 3]);
mesh(map_z);
hold on;
alpha(0.6);
colormap(parula);

% 绘制建筑物
for b = 1:length(building_info)
    x_vals = [building_info(b).x_min, building_info(b).x_max, ...
              building_info(b).x_max, building_info(b).x_min];
    y_vals = [building_info(b).y_min, building_info(b).y_min, ...
              building_info(b).y_max, building_info(b).y_max];
    z_vals = building_info(b).height * ones(1, 4);
    
    patch(x_vals, y_vals, z_vals, [0.7, 0.7, 0.7], 'FaceAlpha', 0.7, 'EdgeColor', 'k');
end

xlabel('X方向');
ylabel('Y方向');
zlabel('高度');
title('平滑路径优化过程');
view(45, 30);
grid on;

% 起点和终点
if isfield(data, 'data')
    plot3(data.data.S(1), data.data.S(2), data.data.S(3), 'o', 'LineWidth', 3, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0, 0.5, 1], 'MarkerSize', 15);
    
    if isfield(data.data, 'waypoints') && ~isempty(data.data.waypoints)
        for i = 1:size(data.data.waypoints, 1)
            plot3(data.data.waypoints(i, 1), data.data.waypoints(i, 2), data.data.waypoints(i, 3), ...
                '^', 'LineWidth', 3, 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', [0.8, 0, 0.8], 'MarkerSize', 15);
        end
    end
    
    if isfield(data.data, 'E0')
        plot3(data.data.E0(end, 1), data.data.E0(end, 2), data.data.E0(end, 3), 'h', 'LineWidth', 3, ...
            'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1, 0.5, 0], 'MarkerSize', 18);
    end
end

% 适应度曲线
subplot(2, 2, 2);
fitness_curve = plot(1, data.curve(1), 'b-', 'LineWidth', 2);
hold on;
current_point = plot(1, data.curve(1), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
xlabel('迭代次数');
ylabel('适应度值');
title('适应度变化曲线');
grid on;
xlim([1, length(data.curve)]);
ylim([min(data.curve)*0.95, max(data.curve)*1.05]);

% 路径长度和曲率
subplot(2, 2, 4);
iter_text = text(0.5, 0.9, sprintf('迭代: 1'), 'Units', 'normalized', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
length_text = text(0.5, 0.7, sprintf('路径长度: %.2f', 0), 'Units', 'normalized', ...
    'FontSize', 11);
curvature_text = text(0.5, 0.5, sprintf('平均曲率: %.4f', 0), 'Units', 'normalized', ...
    'FontSize', 11);
safety_text = text(0.5, 0.3, sprintf('最小安全距离: %.2f', 0), 'Units', 'normalized', ...
    'FontSize', 11);
axis off;

% 动画参数
num_iterations = length(all_best_paths);
skip_frames = max(1, floor(num_iterations / 100));  % 最多显示100帧

fprintf('正在生成动画（共%d次迭代，显示%d帧）...\n', num_iterations, floor(num_iterations/skip_frames));

% 创建视频（可选）
create_video = input('是否创建动画视频？(1=是, 0=否): ');
if create_video
    video_filename = sprintf('smooth_path_animation_%s.avi', datestr(now, 'yyyymmdd_HHMMSS'));
    writerObj = VideoWriter(video_filename);
    writerObj.FrameRate = 10;
    open(writerObj);
    fprintf('正在创建视频: %s\n', video_filename);
end

% 主动画循环
frame_count = 0;
for iter = 1:skip_frames:num_iterations
    frame_count = frame_count + 1;
    
    % 清除之前的路径
    if exist('path_plot', 'var')
        delete(path_plot);
    end
    
    % 获取当前迭代的路径
    current_path = all_best_paths{iter};
    
    % 绘制当前路径
    subplot(2, 2, [1, 3]);
    path_plot = plot3(current_path(:, 1), current_path(:, 2), current_path(:, 3), ...
        'g-', 'LineWidth', 3);
    
    % 更新适应度曲线
    subplot(2, 2, 2);
    set(fitness_curve, 'XData', 1:iter, 'YData', data.curve(1:iter));
    set(current_point, 'XData', iter, 'YData', data.curve(iter));
    
    % 计算路径统计信息
    path_length = 0;
    for i = 2:size(current_path, 1)
        path_length = path_length + norm(current_path(i, :) - current_path(i-1, :));
    end
    
    % 计算平均曲率
    total_curvature = 0;
    valid_points = 0;
    for i = 2:size(current_path, 1)-1
        v1 = current_path(i, :) - current_path(i-1, :);
        v2 = current_path(i+1, :) - current_path(i, :);
        
        if norm(v1) > 1e-6 && norm(v2) > 1e-6
            cos_theta = dot(v1, v2) / (norm(v1) * norm(v2));
            cos_theta = min(max(cos_theta, -1), 1);
            curvature = acos(cos_theta);
            total_curvature = total_curvature + curvature;
            valid_points = valid_points + 1;
        end
    end
    
    avg_curvature = total_curvature / max(valid_points, 1);
    
    % 计算最小安全距离
    min_safety_distance = inf;
    for i = 1:size(current_path, 1)
        x_pos = round(current_path(i, 1));
        y_pos = round(current_path(i, 2));
        
        if x_pos >= 1 && x_pos <= size(map_z, 2) && y_pos >= 1 && y_pos <= size(map_z, 1)
            terrain_height = map_z(y_pos, x_pos);
            safety_distance = current_path(i, 3) - terrain_height;
            min_safety_distance = min(min_safety_distance, safety_distance);
        end
    end
    
    % 更新文本信息
    subplot(2, 2, 4);
    set(iter_text, 'String', sprintf('迭代: %d/%d', iter, num_iterations));
    set(length_text, 'String', sprintf('路径长度: %.2f', path_length));
    set(curvature_text, 'String', sprintf('平均曲率: %.4f', avg_curvature));
    set(safety_text, 'String', sprintf('最小安全距离: %.2f', min_safety_distance));
    
    % 更新标题
    subplot(2, 2, [1, 3]);
    title(sprintf('平滑路径优化过程 (迭代 %d/%d)', iter, num_iterations));
    
    drawnow;
    
    % 捕获帧
    if create_video
        frame = getframe(gcf);
        writeVideo(writerObj, frame);
    end
    
    % 短暂暂停
    pause(0.05);
end

% 显示最终路径
subplot(2, 2, [1, 3]);
title(sprintf('最终平滑路径 (迭代 %d)', num_iterations));

% 显示最终统计信息
fprintf('\n===== 最终路径统计 =====\n');
fprintf('总迭代次数: %d\n', num_iterations);
fprintf('最终路径长度: %.2f\n', path_length);
fprintf('最终平均曲率: %.4f\n', avg_curvature);
fprintf('最终最小安全距离: %.2f\n', min_safety_distance);
fprintf('最终适应度值: %.4f\n', data.curve(end));

% 关闭视频
if create_video
    close(writerObj);
    fprintf('动画视频已保存: %s\n', video_filename);
end

fprintf('\n动画生成完成！\n');
end