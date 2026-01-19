function newPath = drawPC(result, option, data, str)

path0 = [];
for noP = 1:length(data.noE0)
    path = result.path{noP};
    if noP == 1
        index1 = 1;
        index2 = 2;
    else
        index1 = 2;
        index2 = 3;
    end
    
    while 1
        if index2 > length(path(:, 1))
            break;
        end
        
        nowP = path(index1, 2:4);
        aimP = path(index2, 2:4);
        flag = 0;
        
        % 检查路径段是否安全（增加采样点）
        num_samples = 20;
        for i = 1:num_samples
            t = i / num_samples;
            nowP0 = nowP + (aimP - nowP) * t;
            x0 = round(nowP0(1));
            y0 = round(nowP0(2));
            
            if x0 >= 1 && x0 <= size(data.map_z, 2) && y0 >= 1 && y0 <= size(data.map_z, 1)
                H0 = data.map_z(y0, x0);
                if H0 + 1 > nowP0(3)  % 碰撞风险
                    flag = 1;
                    break;
                end
            end
        end
        
        if flag == 1
            path0 = [path0; nowP; path(index2 - 1, 2:4)];
            index1 = index2;
            index2 = index1 + 1;
        else
            index2 = index2 + 1;
        end
    end
    
    path0 = [path0; nowP; aimP];
end

figure('Position', [100, 100, 1200, 800]);

% 绘制起点
plot3(data.S(:, 2), data.S(:, 1), data.S(:, 3), 'o', 'LineWidth', 3, ...
    'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', [0, 0.5, 1], ...
    'MarkerSize', 12);
hold on;

% 绘制途经点（如果存在）
if isfield(data, 'waypoints') && ~isempty(data.waypoints)
    for i = 1:size(data.waypoints, 1)
        plot3(data.waypoints(i, 2), data.waypoints(i, 1), data.waypoints(i, 3), ...
            '^', 'LineWidth', 3, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', [0.8, 0, 0.8], ...
            'MarkerSize', 12);
    end
end

% 绘制终点
plot3(data.E0(end, 2), data.E0(end, 1), data.E0(end, 3), 'h', 'LineWidth', 3, ...
    'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', [1, 0.5, 0], ...
    'MarkerSize', 15);

% 绘制地形
mesh(data.map_x, data.map_y, data.map_z);
colormap(parula);
alpha(0.6);  % 设置地形透明度

newPath = [];
tempN = [];

while 1
    if length(path0(:, 1)) >= 2
        if isempty(tempN)
            tempN = [path0(1:2, :)];
            nextInd = 3;
        else
            tempN = [tempN(end, :); path0(1, :)];
            nextInd = 2;
        end
        
        flag = ones(1, 2);
        type = zeros(1, 2);
        
        for j = 1:2
            if tempN(1, j) == tempN(2, j)
                flag(j) = 0;
            end
            if tempN(1, j) < tempN(2, j)
                type(j) = 1;
            else
                type(j) = 2;
            end
        end
    else
        for i = 1:length(path0(:, 1))
            newPath = [newPath; path0(i, 1:3);];
        end
    end
    
    biaoji = 1;
    
    for i = nextInd:length(path0(:, 1))
        flag0 = flag;
        for j = 1:2
            if type(j) == 1
                if tempN(end, j) >= path0(i, j)
                    flag0(j) = 0;
                end
            else
                if tempN(end, j) <= path0(i, j)
                    flag0(j) = 0;
                end
            end
        end
        
        if sum(flag0) == 0
            if length(tempN(:, 1)) > 2
                tempN(end, :) = tempN(end - 1, :) + 0.5 * (tempN(end, :) - tempN(end - 1, :));
            end
            
            p = find(flag == 1);
            p = p(1);
            X = tempN(:, 1);
            Y = tempN(:, 2);
            Z = tempN(:, 3);
            
            if p == 1
                xi = tempN(1, 1):(tempN(end, 1) - tempN(1, 1)) / 100:tempN(end, 1);
                yi = interp1(X, Y, xi', 'spline');  % 使用样条插值使路径更平滑
                zi = interp1(X, Z, xi', 'spline');
                newPath = [newPath; xi', yi, zi];
            else
                yi = tempN(1, 2):(tempN(end, 2) - tempN(1, 2)) / 100:tempN(end, 2);
                xi = interp1(Y, X, yi', 'spline');
                zi = interp1(Y, Z, yi', 'spline');
                newPath = [newPath; xi, yi', zi];
            end
            
            biaoji = 0;
            path0(1:i - 1, :) = [];
            break;
        else
            flag = flag0;
            tempN = [tempN; path0(i, :)];
        end
    end
    
    if biaoji == 1
        p = find(flag == 1);
        p = p(1);
        X = tempN(:, 1);
        Y = tempN(:, 2);
        Z = tempN(:, 3);
        
        if p == 1
            xi = tempN(1, 1):(tempN(end, 1) - tempN(1, 1)) / 100:tempN(end, 1);
            yi = interp1(X, Y, xi', 'spline');
            zi = interp1(X, Z, xi', 'spline');
            newPath = [newPath; xi', yi, zi];
        else
            yi = tempN(1, 2):(tempN(end, 2) - tempN(1, 2)) / 100:tempN(end, 2);
            xi = interp1(Y, X, yi', 'spline');
            zi = interp1(Y, Z, yi', 'spline');
            newPath = [newPath; xi, yi', zi];
        end
        
        break;
    end
end

% 路径平滑处理
if size(newPath, 1) > 3
    % 使用Savitzky-Golay滤波器平滑路径
    window_size = min(7, floor(size(newPath, 1) / 2));
    if mod(window_size, 2) == 0
        window_size = window_size - 1;
    end
    
    if window_size >= 3
        % 对x, y, z分别进行平滑
        newPath(:, 1) = sgolayfilt(newPath(:, 1), 2, window_size);
        newPath(:, 2) = sgolayfilt(newPath(:, 2), 2, window_size);
        newPath(:, 3) = sgolayfilt(newPath(:, 3), 2, window_size);
    end
end

% 确保安全距离和高度限制
safety_margin = 1;
for i = 1:size(newPath, 1)
    x_pos = round(newPath(i, 1));
    y_pos = round(newPath(i, 2));
    
    if x_pos >= 1 && x_pos <= size(data.map_z, 2) && ...
       y_pos >= 1 && y_pos <= size(data.map_z, 1)
        terrain_height = data.map_z(y_pos, x_pos);
        
        % 确保安全距离
        required_height = max(terrain_height + safety_margin, data.minH);
        required_height = min(required_height, data.maxH);
        
        % 平滑调整高度，避免突变
        if i > 1
            prev_height = newPath(i - 1, 3);
            max_height_change = norm(newPath(i, 1:2) - newPath(i - 1, 1:2)) * tan(data.mu_max);
            
            if abs(required_height - prev_height) > max_height_change
                newPath(i, 3) = prev_height + sign(required_height - prev_height) * max_height_change;
            else
                newPath(i, 3) = required_height;
            end
        else
            newPath(i, 3) = required_height;
        end
        
        % 确保在高度限制内
        newPath(i, 3) = min(max(newPath(i, 3), data.minH), data.maxH);
    end
end

% 绘制平滑后的路径
plot3(newPath(:, 2), newPath(:, 1), newPath(:, 3), '-', 'LineWidth', 4, ...
    'Color', [0, 0.8, 0], ...
    'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', 'r', ...
    'MarkerSize', 10);

data.map0 = data.map;
data.mapSize0 = size(data.map0);

% 添加建筑物（如果存在）
if isfield(data, 'building_info') && ~isempty(data.building_info)
    for b = 1:length(data.building_info)
        x_vals = [data.building_info(b).x_min, data.building_info(b).x_max, ...
                  data.building_info(b).x_max, data.building_info(b).x_min];
        y_vals = [data.building_info(b).y_min, data.building_info(b).y_min, ...
                  data.building_info(b).y_max, data.building_info(b).y_max];
        z_vals = data.building_info(b).height * ones(1, 4);
        
        patch(x_vals, y_vals, z_vals, [0.7, 0.7, 0.7], 'FaceAlpha', 0.7, 'EdgeColor', 'k');
    end
end

% 添加飞行高度限制参考线
plot3([0, 100], [0, 0], [data.minH, data.minH], 'g--', 'LineWidth', 2);
plot3([0, 100], [100, 100], [data.maxH, data.maxH], 'r--', 'LineWidth', 2);

% 创建图例
if isfield(data, 'waypoints') && ~isempty(data.waypoints)
    legend('起点', '途经点', '终点', '地形', '规划路径', '建筑物', '最低高度', '最高高度', 'Location', 'best');
else
    legend('起点', '终点', '地形', '规划路径', '建筑物', '最低高度', '最高高度', 'Location', 'best');
end

xlabel('Y方向');
ylabel('X方向');
zlabel('高度');
grid on;
title([str, ' (平滑优化后) 总目标:', num2str(result.fit)]);

% 设置视角
view(45, 30);

% 添加路径统计信息
if isfield(result, 'total_length')
    annotation('textbox', [0.02, 0.02, 0.3, 0.15], 'String', ...
        sprintf('路径长度: %.2f\n高度变化: %.2f\n碰撞风险: %d\n平均曲率: %.2f', ...
        result.total_length, result.total_height_change, ...
        result.collision_penalty, mean(result.path{1}(:, 6))), ...
        'BackgroundColor', 'white', 'FontSize', 10, 'FontWeight', 'bold');
end
end