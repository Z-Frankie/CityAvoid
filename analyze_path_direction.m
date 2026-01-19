function [direction_stats] = analyze_path_direction(path)
% 分析路径方向特性
% 返回包含方向统计信息的结构体
% 增加路径长度分析

direction_stats = struct();

if size(path, 1) < 2
    direction_stats.valid = false;
    return;
end

direction_stats.valid = true;
direction_stats.num_segments = size(path, 1) - 1;

% 初始化统计
direction_stats.upward_segments = 0;
direction_stats.downward_segments = 0;
direction_stats.horizontal_segments = 0;

direction_stats.total_upward_change = 0;
direction_stats.total_downward_change = 0;
direction_stats.total_horizontal_change = 0;

% 路径长度相关统计
direction_stats.total_path_length = 0;
direction_stats.straight_line_length = norm(path(end, 1:2) - path(1, 1:2));
direction_stats.accumulated_lengths = zeros(size(path, 1), 1);

% 定义方向阈值（度）
vertical_threshold = 5; % 垂直方向阈值
horizontal_threshold = 85; % 水平方向阈值

% 计算累积长度
for i = 1:size(path, 1)
    if i > 1
        segment_length = norm(path(i, :) - path(i-1, :));
        direction_stats.total_path_length = direction_stats.total_path_length + segment_length;
        direction_stats.accumulated_lengths(i) = direction_stats.accumulated_lengths(i-1) + segment_length;
    end
end

% 路径效率
if direction_stats.straight_line_length > 0
    direction_stats.path_efficiency = direction_stats.total_path_length / direction_stats.straight_line_length;
else
    direction_stats.path_efficiency = 1.0;
end

for i = 2:size(path, 1)
    % 计算段向量
    segment = path(i, :) - path(i-1, :);
    segment_length = norm(segment);
    
    if segment_length < 1e-6
        continue;
    end
    
    % 计算垂直角度（与水平面的夹角）
    vertical_angle = asind(abs(segment(3)) / segment_length);
    
    % 判断方向
    if vertical_angle < vertical_threshold
        % 主要是水平移动
        direction_stats.horizontal_segments = direction_stats.horizontal_segments + 1;
        direction_stats.total_horizontal_change = direction_stats.total_horizontal_change + ...
            norm(segment(1:2));
    elseif segment(3) > 0
        % 向上移动
        direction_stats.upward_segments = direction_stats.upward_segments + 1;
        direction_stats.total_upward_change = direction_stats.total_upward_change + segment(3);
    else
        % 向下移动
        direction_stats.downward_segments = direction_stats.downward_segments + 1;
        direction_stats.total_downward_change = direction_stats.total_downward_change + abs(segment(3));
    end
end

% 计算百分比
total_segments = direction_stats.num_segments;
if total_segments > 0
    direction_stats.upward_percent = direction_stats.upward_segments / total_segments * 100;
    direction_stats.downward_percent = direction_stats.downward_segments / total_segments * 100;
    direction_stats.horizontal_percent = direction_stats.horizontal_segments / total_segments * 100;
else
    direction_stats.upward_percent = 0;
    direction_stats.downward_percent = 0;
    direction_stats.horizontal_percent = 0;
end

% 计算平均变化
if direction_stats.upward_segments > 0
    direction_stats.avg_upward_change = direction_stats.total_upward_change / direction_stats.upward_segments;
else
    direction_stats.avg_upward_change = 0;
end

if direction_stats.downward_segments > 0
    direction_stats.avg_downward_change = direction_stats.total_downward_change / direction_stats.downward_segments;
else
    direction_stats.avg_downward_change = 0;
end

if direction_stats.horizontal_segments > 0
    direction_stats.avg_horizontal_change = direction_stats.total_horizontal_change / direction_stats.horizontal_segments;
else
    direction_stats.avg_horizontal_change = 0;
end

% 计算方向平衡度
% 平衡度越接近1，方向分布越均匀
total_changes = [direction_stats.upward_segments, direction_stats.downward_segments, direction_stats.horizontal_segments];
max_change = max(total_changes);
if max_change > 0
    direction_stats.balance_ratio = 1 - (max(total_changes) - min(total_changes)) / total_segments;
else
    direction_stats.balance_ratio = 0;
end

% 计算路径平滑度（曲率变化）
if size(path, 1) > 2
    total_curvature = 0;
    valid_points = 0;
    
    for i = 2:size(path, 1)-1
        v1 = path(i, :) - path(i-1, :);
        v2 = path(i+1, :) - path(i, :);
        
        if norm(v1) > 1e-6 && norm(v2) > 1e-6
            cos_theta = dot(v1, v2) / (norm(v1) * norm(v2));
            cos_theta = min(max(cos_theta, -1), 1);
            curvature = acos(cos_theta);
            total_curvature = total_curvature + curvature;
            valid_points = valid_points + 1;
        end
    end
    
    if valid_points > 0
        direction_stats.avg_curvature = total_curvature / valid_points;
    else
        direction_stats.avg_curvature = 0;
    end
else
    direction_stats.avg_curvature = 0;
end

% 计算高度变化统计
if size(path, 1) > 1
    heights = path(:, 3);
    direction_stats.max_height = max(heights);
    direction_stats.min_height = min(heights);
    direction_stats.avg_height = mean(heights);
    direction_stats.height_range = direction_stats.max_height - direction_stats.min_height;
    direction_stats.height_variance = var(heights);
end

% 判断是否需要调整方向
if direction_stats.upward_percent > 60
    direction_stats.need_adjustment = true;
    direction_stats.adjustment_suggestion = '减少向上移动，增加横向和向下移动';
elseif direction_stats.horizontal_percent < 40
    direction_stats.need_adjustment = true;
    direction_stats.adjustment_suggestion = '增加横向移动';
elseif direction_stats.path_efficiency > 1.5
    direction_stats.need_adjustment = true;
    direction_stats.adjustment_suggestion = '路径过长，需要优化路径长度';
else
    direction_stats.need_adjustment = false;
    direction_stats.adjustment_suggestion = '方向分布合理';
end

% 路径质量评分
% 安全性评分（假设已经安全）
direction_stats.safety_score = 1.0;

% 效率评分
if direction_stats.path_efficiency <= 1.2
    direction_stats.efficiency_score = 1.0;
elseif direction_stats.path_efficiency <= 1.5
    direction_stats.efficiency_score = 0.7;
else
    direction_stats.efficiency_score = 0.4;
end

% 方向平衡评分
direction_stats.balance_score = direction_stats.balance_ratio;

% 平滑度评分
if direction_stats.avg_curvature < 0.2
    direction_stats.smoothness_score = 1.0;
elseif direction_stats.avg_curvature < 0.5
    direction_stats.smoothness_score = 0.7;
else
    direction_stats.smoothness_score = 0.4;
end

% 综合评分
direction_stats.overall_score = 0.3 * direction_stats.safety_score + ...
                                0.3 * direction_stats.efficiency_score + ...
                                0.2 * direction_stats.balance_score + ...
                                0.2 * direction_stats.smoothness_score;

% 评分等级
if direction_stats.overall_score >= 0.9
    direction_stats.quality_grade = '优秀';
elseif direction_stats.overall_score >= 0.7
    direction_stats.quality_grade = '良好';
elseif direction_stats.overall_score >= 0.5
    direction_stats.quality_grade = '合格';
else
    direction_stats.quality_grade = '需要改进';
end
end