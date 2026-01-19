function [fit, result, smoothPath] = aimFcn_smooth_multi_directional(x, option, data)
% 多方向平滑路径目标函数
% 允许水平和垂直方向同时调整避障
% 强化路径最短约束

%% 1. 获取安全参数
if isfield(data, 'safety_margin')
    safety_margin = data.safety_margin;
else
    safety_margin = 1.0;
end

minH = data.minH;
maxH = data.maxH;

%% 2. 使用固定顺序的点
if isfield(data, 'all_points_in_order')
    fixed_points = data.all_points_in_order;
else
    fixed_points = [data.S; data.waypoints; data.E0(end, :)];
end

num_fixed_points = size(fixed_points, 1);
num_segments = num_fixed_points - 1;

%% 3. 提取控制点参数
if isfield(option, 'num_ctrl_points_per_seg')
    num_ctrl_points_per_seg = option.num_ctrl_points_per_seg;
else
    num_ctrl_points_per_seg = 4;
end

% 计算总控制点参数数量
% 每段有 (num_ctrl_points_per_seg-2) 个中间控制点，每个控制点有3个坐标
params_per_seg = (num_ctrl_points_per_seg - 2) * 3;
total_params = num_segments * params_per_seg;

% 检查参数数量
if length(x) ~= total_params
    error('参数维度不匹配: 期望 %d, 实际 %d', total_params, length(x));
end

% 将参数重构成 [控制点索引, 3坐标] 格式
ctrl_params = reshape(x, [], 3);

%% 4. 方向选择权重参数
% 定义各方向的权重（向上、向下、横向）
if isfield(option, 'direction_weights')
    direction_weights = option.direction_weights;
else
    % 默认权重：降低向上权重，增加横向和向下权重
    % direction_weights.up = 0.3;       % 向上移动权重（降低）
    % direction_weights.down = 0.5;     % 向下移动权重（增加）
    % direction_weights.horizontal = 0.8; % 横向移动权重（增加）
    direction_weights.up = 0.1;       % 向上移动权重（降低）
    direction_weights.down = 0.1;     % 向下移动权重（增加）
    direction_weights.horizontal = 0.8; % 横向移动权重（增加）
end

% 方向变化惩罚权重
if isfield(option, 'weight_direction_change')
    weight_direction_change = option.weight_direction_change;
else
    weight_direction_change = 0.3;
end

%% 5. 生成平滑路径
smoothPath = [];
total_length = 0;
total_curvature = 0;
collision_penalty = 0;
height_violation = 0;
unsafe_points = 0;
horizontal_deviation = 0; % 新增：水平偏离代价
vertical_change_penalty = 0; % 新增：垂直方向变化惩罚
direction_change_penalty = 0; % 新增：方向变化惩罚
path_efficiency = 0; % 新增：路径效率指标

% 获取权重参数
if isfield(option, 'weights')
    weights = option.weights;
else
    weights.length = 3.0;     % 路径长度权重（增加，强化最短路径约束）
    weights.curvature = 0.5;  % 路径曲率权重
    weights.collision = 10000.0; % 碰撞惩罚权重（极大）
    weights.height_violation = 5000.0; % 高度违规权重（极大）
end

weight_length = weights.length;
weight_curvature = weights.curvature;
weight_collision = weights.collision;
weight_height_violation = weights.height_violation;
weight_unsafe_point = 100000.0;
weight_horizontal_deviation = 0.2; % 水平偏离的权重
weight_path_efficiency = 0.5; % 路径效率权重（新增）

% 水平移动范围限制
if isfield(option, 'horizontal_range')
    horizontal_range = option.horizontal_range;
else
    horizontal_range = 5.0;
end

% 每段采样点数
num_samples_per_seg = 25;

% 计算直线最短路径长度（作为基准）
straight_line_length = 0;
for seg_idx = 1:num_segments
    start_point = fixed_points(seg_idx, :);
    end_point = fixed_points(seg_idx + 1, :);
    straight_line_length = straight_line_length + norm(end_point - start_point);
end

param_counter = 1;
segment_lengths = zeros(num_segments, 1); % 记录每段长度
segment_efficiency = zeros(num_segments, 1); % 记录每段效率

for seg_idx = 1:num_segments
    % 当前段的起点和终点
    start_point = fixed_points(seg_idx, :);
    end_point = fixed_points(seg_idx + 1, :);
    
    % 生成控制点
    ctrl_points = zeros(num_ctrl_points_per_seg, 3);
    ctrl_points(1, :) = start_point;
    ctrl_points(end, :) = end_point;
    
    % 计算基础方向向量
    base_direction = end_point - start_point;
    segment_length = norm(base_direction(1:2));
    
    % 生成中间控制点
    for i = 2:num_ctrl_points_per_seg-1
        t = (i-1)/(num_ctrl_points_per_seg-1);
        
        % 基础位置（直线上）
        base_pos = start_point + t * base_direction;
        
        if param_counter <= size(ctrl_params, 1)
            % 使用优化参数调整位置
            param = ctrl_params(param_counter, :);
            
            % 计算各方向的基础偏移量
            raw_horizontal_offset = param(1:2) * horizontal_range;
            raw_height_offset = param(3) * (maxH - minH) + minH - base_pos(3);
            
            % 应用方向权重
            % 横向偏移乘以横向权重
            weighted_horizontal = raw_horizontal_offset * direction_weights.horizontal;
            
            % 高度偏移：根据方向应用不同权重
            if raw_height_offset > 0
                % 向上移动，降低权重
                weighted_height_offset = raw_height_offset * direction_weights.up;
            else
                % 向下移动，增加权重
                weighted_height_offset = raw_height_offset * direction_weights.down;
            end
            
            % 应用加权后的偏移
            ctrl_points(i, 1:2) = base_pos(1:2) + weighted_horizontal;
            ctrl_points(i, 3) = base_pos(3) + weighted_height_offset;
            
            % 计算水平偏离代价（鼓励靠近直线）
            deviation_distance = norm(weighted_horizontal);
            horizontal_deviation = horizontal_deviation + deviation_distance^2;
            
            % 计算垂直变化惩罚（鼓励适度变化）
            vertical_change_penalty = vertical_change_penalty + abs(weighted_height_offset)^2;
            
            param_counter = param_counter + 1;
        else
            ctrl_points(i, :) = base_pos;
        end
        
        % 安全检查和控制点本身
        x_idx = round(ctrl_points(i, 1));
        y_idx = round(ctrl_points(i, 2));
        if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
            terrain_height = data.map_z(y_idx, x_idx);
            required_height = terrain_height + safety_margin;
            
            if ctrl_points(i, 3) < required_height
                % 自动调整到安全高度
                ctrl_points(i, 3) = max(ctrl_points(i, 3), required_height);
                height_violation = height_violation + (required_height - ctrl_points(i, 3))^2;
            end
        end
        
        % 确保在高度限制内
        ctrl_points(i, 3) = min(max(ctrl_points(i, 3), minH), maxH);
    end
    
    %% 6. 使用贝塞尔曲线生成平滑路径
    seg_curve = zeros(num_samples_per_seg, 3);
    
    for sample_idx = 1:num_samples_per_seg
        t = (sample_idx-1)/(num_samples_per_seg-1);
        
        % 三次贝塞尔曲线
        if num_ctrl_points_per_seg == 4
            seg_curve(sample_idx, :) = ...
                (1-t)^3 * ctrl_points(1, :) + ...
                3*(1-t)^2*t * ctrl_points(2, :) + ...
                3*(1-t)*t^2 * ctrl_points(3, :) + ...
                t^3 * ctrl_points(4, :);
        else
            % 线性插值
            seg_curve(sample_idx, :) = (1-t) * ctrl_points(1, :) + t * ctrl_points(end, :);
        end
    end
    
    %% 7. 计算路径段的代价
    % 7.1 长度代价
    seg_length = 0;
    for i = 2:num_samples_per_seg
        seg_length = seg_length + norm(seg_curve(i, :) - seg_curve(i-1, :));
    end
    total_length = total_length + seg_length;
    segment_lengths(seg_idx) = seg_length;
    
    % 7.2 计算路径效率（实际长度与直线长度的比值）
    straight_segment_length = norm(end_point - start_point);
    if straight_segment_length > 0
        segment_efficiency(seg_idx) = seg_length / straight_segment_length;
    else
        segment_efficiency(seg_idx) = 1.0;
    end
    
    % 7.3 曲率代价
    seg_curvature = 0;
    valid_curvature_points = 0;
    
    if num_samples_per_seg >= 3
        for i = 2:num_samples_per_seg-1
            p_prev = seg_curve(i-1, :);
            p_curr = seg_curve(i, :);
            p_next = seg_curve(i+1, :);
            
            v1 = p_curr - p_prev;
            v2 = p_next - p_curr;
            
            if norm(v1) > 1e-6 && norm(v2) > 1e-6
                cos_theta = dot(v1, v2) / (norm(v1) * norm(v2));
                cos_theta = min(max(cos_theta, -1), 1);
                theta = acos(cos_theta);
                seg_curvature = seg_curvature + theta^2;
                valid_curvature_points = valid_curvature_points + 1;
            end
        end
    end
    
    if valid_curvature_points > 0
        seg_curvature = seg_curvature / valid_curvature_points;
    end
    total_curvature = total_curvature + seg_curvature;
    
    %% 8. 方向变化惩罚计算
    if num_samples_per_seg > 2
        for i = 2:num_samples_per_seg-1
            % 计算三个连续点的向量
            v1 = seg_curve(i, :) - seg_curve(i-1, :);
            v2 = seg_curve(i+1, :) - seg_curve(i, :);
            
            if norm(v1) > 1e-6 && norm(v2) > 1e-6
                % 计算垂直分量变化（高度变化）
                v1_vertical = v1(3);
                v2_vertical = v2(3);
                
                % 如果高度剧烈变化（特别是向上），增加惩罚
                vertical_change = abs(v2_vertical - v1_vertical);
                
                % 向上变化惩罚较重，向下变化惩罚较轻
                if v2_vertical > v1_vertical
                    % 向上变化
                    direction_change_penalty = direction_change_penalty + ...
                        vertical_change * 1.5;
                else
                    % 向下变化
                    direction_change_penalty = direction_change_penalty + ...
                        vertical_change * 0.8;
                end
            end
        end
    end
    
    %% 9. 绝对安全检查（核心部分）
    for i = 1:num_samples_per_seg
        point = seg_curve(i, :);
        x_idx = round(point(1));
        y_idx = round(point(2));
        
        % 检查边界
        if x_idx >= 1 && x_idx <= 100 && y_idx >= 1 && y_idx <= 100
            terrain_height = data.map_z(y_idx, x_idx);
            
            % 绝对安全距离检查
            if point(3) < terrain_height + safety_margin
                unsafe_points = unsafe_points + 1;
                penalty = (terrain_height + safety_margin - point(3))^2;
                collision_penalty = collision_penalty + penalty;
            end
            
            % 高度限制检查
            if point(3) < minH
                height_violation = height_violation + (minH - point(3))^2;
            elseif point(3) > maxH
                height_violation = height_violation + (point(3) - maxH)^2;
            end
        else
            % 超出边界
            unsafe_points = unsafe_points + 1;
            collision_penalty = collision_penalty + 100;
        end
    end
    
    % 保存当前段的路径
    smoothPath = [smoothPath; seg_curve];
end

%% 10. 计算路径效率指标（新增）
% 计算整体路径效率
if straight_line_length > 0
    overall_efficiency = total_length / straight_line_length;
else
    overall_efficiency = 1.0;
end

% 计算路径效率惩罚（鼓励路径接近最短直线路径）
path_efficiency = (overall_efficiency - 1.0)^2 * 10; % 效率偏离惩罚

% 计算各段效率的方差（鼓励各段效率均衡）
if num_segments > 1
    efficiency_variance = var(segment_efficiency);
    path_efficiency = path_efficiency + efficiency_variance * 5;
end

%% 11. 计算总适应度（增加路径最短约束）
% 基础适应度
fit = weight_length * total_length + ...
      weight_curvature * total_curvature + ...
      weight_collision * collision_penalty + ...
      weight_height_violation * height_violation + ...
      weight_horizontal_deviation * horizontal_deviation + ...
      weight_direction_change * direction_change_penalty + ...
      0.1 * vertical_change_penalty + ... % 垂直变化惩罚权重
      weight_path_efficiency * path_efficiency; % 路径效率惩罚

% 对不安全点施加额外惩罚
if unsafe_points > 0
    fit = fit + weight_unsafe_point * unsafe_points;
    fit = fit * (1 + unsafe_points * 0.5);
end

% 强化最短路径约束：如果路径过长，增加额外惩罚
if total_length > straight_line_length * 1.5
    % 路径长度超过直线长度的1.5倍，增加额外惩罚
    length_excess_ratio = total_length / straight_line_length;
    excess_penalty = (length_excess_ratio - 1.5)^2 * 100;
    fit = fit + excess_penalty;
    
    % 如果非常长，施加更重惩罚
    if total_length > straight_line_length * 2.0
        fit = fit * 1.5;
    end
end

%% 12. 返回结果
if nargout > 1
    result.fit = fit;
    result.total_length = total_length;
    result.total_curvature = total_curvature;
    result.collision_penalty = collision_penalty;
    result.height_violation = height_violation;
    result.unsafe_points = unsafe_points;
    result.horizontal_deviation = horizontal_deviation;
    result.direction_change_penalty = direction_change_penalty;
    result.vertical_change_penalty = vertical_change_penalty;
    result.path_efficiency = path_efficiency;
    result.overall_efficiency = overall_efficiency;
    result.straight_line_length = straight_line_length;
    result.segment_lengths = segment_lengths;
    result.segment_efficiency = segment_efficiency;
    result.path_order = '起点->途经点1->途经点2->途经点3->途经点4->终点';
    
    if isempty(smoothPath)
        smoothPath = fixed_points;
    end
end
end