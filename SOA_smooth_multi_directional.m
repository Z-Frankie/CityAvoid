function [Best_score, Best_pos, curve, all_best_paths, safety_records] = SOA_smooth_multi_directional(xx, pop, Max_iter, lb, ub, dim, fobj, data, option)
% 多方向安全海鸥算法 - 专为多方向避障路径优化设计
% 强化路径最短约束，平衡方向权重
% 输出增加了safety_records，记录每次迭代的不安全点数

fc = 2;  % 可调参数

% 统一边界
if length(ub) == 1
    ub = ub * ones(1, dim);
    lb = lb * ones(1, dim);
end

% 确保pop是标量
if ~isscalar(pop)
    if isvector(pop)
        pop_size = length(pop);
    else
        pop_size = size(xx, 1);
    end
else
    pop_size = pop;
end

% 确保输入维度正确
if size(xx, 2) ~= dim
    if size(xx, 1) == dim
        xx = xx';
    else
        error('输入维度不匹配: 期望 %d 维, 实际 %d × %d', dim, size(xx, 1), size(xx, 2));
    end
end

% 如果种群数量不匹配，调整
if size(xx, 1) > pop_size
    xx = xx(1:pop_size, :);
elseif size(xx, 1) < pop_size
    needed = pop_size - size(xx, 1);
    additional = xx(randi(size(xx, 1), needed, 1), :);
    xx = [xx; additional];
end

% 初始化
X0 = xx;
X = X0;

% 获取方向权重参数
if isfield(option, 'direction_weights')
    direction_weights = option.direction_weights;
else
    % 默认方向权重
    direction_weights.up = 0.3;
    direction_weights.down = 0.5;
    direction_weights.horizontal = 0.8;
end

% 获取长度惩罚因子
if isfield(option, 'length_penalty_factor')
    length_penalty_factor = option.length_penalty_factor;
else
    length_penalty_factor = 1.5;
end

% 计算初始适应度值，并获取路径
fprintf('计算初始适应度（多方向安全检查 + 最短路径约束）...\n');
fitness = zeros(pop_size, 1);
best_paths = cell(pop_size, 1);
unsafe_counts = zeros(pop_size, 1);  % 记录每个个体的不安全点数
path_lengths = zeros(pop_size, 1);   % 记录每个个体的路径长度

for i = 1:pop_size
    try
        [fitness(i), result_i, path_i] = fobj(X(i, :), option, data);
        best_paths{i} = path_i;
        unsafe_counts(i) = result_i.unsafe_points;
        path_lengths(i) = result_i.total_length;
        
        % 对不安全路径施加额外惩罚
        if unsafe_counts(i) > 0
            fitness(i) = fitness(i) * (1 + unsafe_counts(i) * 0.5);
        end
        
        % 强化最短路径约束：增加路径长度惩罚
        if isfield(result_i, 'total_length')
            fitness(i) = fitness(i) + length_penalty_factor * result_i.total_length;
            
            % 如果路径过长，增加额外惩罚
            if isfield(result_i, 'straight_line_length') && result_i.straight_line_length > 0
                length_ratio = result_i.total_length / result_i.straight_line_length;
                if length_ratio > 1.5
                    fitness(i) = fitness(i) * (1 + (length_ratio - 1.5) * 0.5);
                end
            end
        end
    catch ME
        fprintf('个体 %d 适应度计算失败: %s\n', i, ME.message);
        fitness(i) = 1e12;
        unsafe_counts(i) = 1000;
        path_lengths(i) = 1e6;
        if isfield(data, 'all_points_in_order')
            best_paths{i} = data.all_points_in_order;
        else
            best_paths{i} = zeros(2, 3);
        end
    end
end

% 排序
[fitness_sorted, index] = sort(fitness);
GBestF = fitness_sorted(1);
GBestX = X(index(1), :);
GBestPath = best_paths{index(1)};
GBestUnsafe = unsafe_counts(index(1));  % 最优解的不安全点数
GBestLength = path_lengths(index(1));   % 最优解的路径长度

% 排序种群
X_sorted = zeros(size(X));
for i = 1:pop_size
    X_sorted(i, :) = X0(index(i), :);
end
X = X_sorted;

% 存储曲线和最优路径
curve = zeros(Max_iter, 1);
all_best_paths = cell(Max_iter, 1);
safety_records = zeros(Max_iter, 1);  % 记录每次迭代的最优解不安全点数
length_records = zeros(Max_iter, 1);  % 记录每次迭代的最优解路径长度

X_new = X;

fprintf('\n开始多方向安全路径优化...\n');
fprintf('初始最优解不安全点数: %d\n', GBestUnsafe);
fprintf('初始最优解路径长度: %.2f\n', GBestLength);
fprintf('方向权重: 向上=%.2f, 向下=%.2f, 横向=%.2f\n', ...
    direction_weights.up, direction_weights.down, direction_weights.horizontal);
fprintf('长度惩罚因子: %.2f\n', length_penalty_factor);

for t = 1:Max_iter
    % 显示进度
    if mod(t, 10) == 0 || t <= 5
        [~, result_tmp, ~] = fobj(GBestX, option, data);
        current_length = result_tmp.total_length;
        fprintf('迭代 %d/%d, 当前最优适应度: %.4f, 不安全点数: %d, 路径长度: %.2f\n', ...
            t, Max_iter, GBestF, GBestUnsafe, current_length);
    end
    
    Pbest = X(1, :);  % 当前最优解
    
    for i = 1:pop_size
        %% 计算Cs
        A = fc - (t * (fc / Max_iter));
        Cs = X(i, :) .* A;
        
        %% 计算Ms
        rd = rand();
        B = 2 * A^2 * rd;
        Ms = B .* (Pbest - X(i, :));
        
        %% 计算Ds
        Ds = abs(Cs + Ms);
        
        %% 局部搜索（增加多样性）
        u = 1;
        v = 1;
        theta = rand();
        r = u * exp(theta * v);
        
        % 三维螺旋搜索
        x_val = r * cos(theta * 2 * pi);
        y_val = r * sin(theta * 2 * pi);
        z_val = r * theta;
        
        %% 位置更新
        % 基础更新
        X_new(i, :) = x_val * y_val * z_val .* Ds + Pbest;
        
        % 增加安全性引导：向当前安全最优解学习
        learning_rate = 0.3 * (1 - t/Max_iter);
        X_new(i, :) = (1 - learning_rate) * X_new(i, :) + learning_rate * GBestX;
        
        %% 关键修改：添加多方向加权随机扰动，同时考虑路径长度优化
        if t < Max_iter/2
            % 根据方向权重生成扰动
            perturbation = zeros(1, dim);
            
            % 将维度分为三组：x, y, z
            num_params_per_point = 3; % 每个控制点有3个参数
            num_points = dim / num_params_per_point;
            
            for p = 1:num_points
                start_idx = (p-1)*num_params_per_point + 1;
                
                % 根据迭代进度调整扰动强度
                perturbation_strength = 0.05 * (1 - t/Max_iter);
                
                % x方向（横向）扰动 - 增加权重，但考虑路径长度
                if rand() > 0.7
                    % 70%概率向缩短路径方向扰动
                    perturbation(start_idx) = -perturbation_strength * ...
                        rand() * direction_weights.horizontal;
                else
                    perturbation(start_idx) = perturbation_strength * ...
                        (rand() - 0.5) * direction_weights.horizontal;
                end
                
                % y方向（横向）扰动 - 增加权重，但考虑路径长度
                if rand() > 0.7
                    % 70%概率向缩短路径方向扰动
                    perturbation(start_idx+1) = -perturbation_strength * ...
                        rand() * direction_weights.horizontal;
                else
                    perturbation(start_idx+1) = perturbation_strength * ...
                        (rand() - 0.5) * direction_weights.horizontal;
                end
                
                % z方向（垂直）扰动，根据上下权重调整，同时考虑路径长度
                if rand() > 0.5
                    % 向上扰动，权重较低，且概率较低
                    if rand() > 0.8  % 只有20%概率向上扰动
                        perturbation(start_idx+2) = perturbation_strength * ...
                            rand() * direction_weights.up * 0.5; % 进一步降低向上扰动
                    else
                        perturbation(start_idx+2) = 0;
                    end
                else
                    % 向下扰动，权重较高，且考虑路径长度
                    perturbation(start_idx+2) = -perturbation_strength * ...
                        rand() * direction_weights.down;
                end
            end
            
            X_new(i, :) = X_new(i, :) + perturbation;
        end
        
        % 后期迭代中，增加向缩短路径方向的引导
        if t > Max_iter/2
            % 计算当前个体与最优个体的差异
            diff_to_best = GBestX - X(i, :);
            
            % 增加向缩短路径方向的微调
            if rand() > 0.6
                % 40%概率向缩短路径方向调整
                X_new(i, :) = X_new(i, :) + 0.1 * diff_to_best .* (rand(1, dim) - 0.5);
            end
        end
    end
    
    % 边界控制
    for j = 1:pop_size
        for a = 1:dim
            if X_new(j, a) > ub(a)
                X_new(j, a) = ub(a);
            end
            if X_new(j, a) < lb(a)
                X_new(j, a) = lb(a);
            end
        end
    end
    
    % 评估新位置
    fitness_new = zeros(pop_size, 1);
    new_paths = cell(pop_size, 1);
    unsafe_counts_new = zeros(pop_size, 1);
    path_lengths_new = zeros(pop_size, 1);
    
    for j = 1:pop_size
        try
            [fitness_new(j), result_j, path_j] = fobj(X_new(j, :), option, data);
            new_paths{j} = path_j;
            unsafe_counts_new(j) = result_j.unsafe_points;
            path_lengths_new(j) = result_j.total_length;
            
            % 对不安全路径施加额外惩罚
            if unsafe_counts_new(j) > 0
                fitness_new(j) = fitness_new(j) * (1 + unsafe_counts_new(j) * 0.5);
            end
            
            % 强化最短路径约束
            fitness_new(j) = fitness_new(j) + length_penalty_factor * result_j.total_length;
            
            % 如果路径过长，增加额外惩罚
            if isfield(result_j, 'straight_line_length') && result_j.straight_line_length > 0
                length_ratio = result_j.total_length / result_j.straight_line_length;
                if length_ratio > 1.5
                    fitness_new(j) = fitness_new(j) * (1 + (length_ratio - 1.5) * 0.5);
                end
            end
        catch ME
            fprintf('个体 %d 新位置适应度计算失败: %s\n', j, ME.message);
            fitness_new(j) = 1e12;
            unsafe_counts_new(j) = 1000;
            path_lengths_new(j) = 1e6;
            new_paths{j} = GBestPath;
        end
    end
    
    % 更新全局最优（综合考虑安全性、路径长度和适应度）
    for j = 1:pop_size
        update_best = false;
        
        % 情况1：更安全的路径
        if unsafe_counts_new(j) < GBestUnsafe
            update_best = true;
        % 情况2：同样安全但路径更短
        elseif unsafe_counts_new(j) == GBestUnsafe && path_lengths_new(j) < GBestLength * 0.95
            update_best = true;
        % 情况3：同样安全、路径长度相近但适应度更好
        elseif unsafe_counts_new(j) == GBestUnsafe && ...
               abs(path_lengths_new(j) - GBestLength) < GBestLength * 0.05 && ...
               fitness_new(j) < GBestF * 0.95
            update_best = true;
        end
        
        if update_best
            GBestF = fitness_new(j);
            GBestX = X_new(j, :);
            GBestPath = new_paths{j};
            GBestUnsafe = unsafe_counts_new(j);
            GBestLength = path_lengths_new(j);
        end
    end
    
    %% 方向权重和长度惩罚因子自适应调整
    if mod(t, 10) == 0 && t > 20
        % 分析当前最优路径的方向特性
        [~, result_current, current_path] = fobj(GBestX, option, data);
        
        % 计算路径的垂直变化特性
        if size(current_path, 1) > 2
            upward_changes = 0;
            downward_changes = 0;
            
            for i = 2:size(current_path, 1)
                vertical_change = current_path(i, 3) - current_path(i-1, 3);
                
                if vertical_change > 0.1  % 微小变化不计数
                    upward_changes = upward_changes + 1;
                elseif vertical_change < -0.1
                    downward_changes = downward_changes + 1;
                end
            end
            
            % 如果向上变化过多，调整方向权重
            if upward_changes > downward_changes * 1.5
                % 降低向上权重，增加向下和横向权重
                direction_weights.up = max(0.1, direction_weights.up * 0.9);
                direction_weights.down = min(1.0, direction_weights.down * 1.05);
                direction_weights.horizontal = min(1.0, direction_weights.horizontal * 1.05);
                
                option.direction_weights = direction_weights;
                fprintf('调整方向权重：向上%.2f, 向下%.2f, 横向%.2f\n', ...
                    direction_weights.up, direction_weights.down, direction_weights.horizontal);
            end
        end
        
        % 根据路径长度调整长度惩罚因子
        if isfield(result_current, 'straight_line_length') && result_current.straight_line_length > 0
            current_ratio = result_current.total_length / result_current.straight_line_length;
            
            if current_ratio > 1.4
                % 路径过长，增加长度惩罚
                length_penalty_factor = min(3.0, length_penalty_factor * 1.1);
                option.length_penalty_factor = length_penalty_factor;
                fprintf('增加长度惩罚因子: %.2f (路径长度比: %.2f)\n', ...
                    length_penalty_factor, current_ratio);
            elseif current_ratio < 1.2 && length_penalty_factor > 1.0
                % 路径较短，适当降低长度惩罚
                length_penalty_factor = max(1.0, length_penalty_factor * 0.95);
                option.length_penalty_factor = length_penalty_factor;
                fprintf('降低长度惩罚因子: %.2f (路径长度比: %.2f)\n', ...
                    length_penalty_factor, current_ratio);
            end
        end
    end
    
    % 更新种群
    X = X_new;
    fitness = fitness_new;
    best_paths = new_paths;
    unsafe_counts = unsafe_counts_new;
    path_lengths = path_lengths_new;
    
    % 排序（综合考虑安全性、路径长度和适应度）
    % 创建综合评分
    composite_score = zeros(pop_size, 1);
    for j = 1:pop_size
        % 安全性权重最高
        safety_score = 1.0 / (1.0 + unsafe_counts(j));
        
        % 路径长度评分（越短越好）
        if max(path_lengths) > min(path_lengths)
            length_score = 1.0 - (path_lengths(j) - min(path_lengths)) / (max(path_lengths) - min(path_lengths));
        else
            length_score = 1.0;
        end
        
        % 适应度评分
        if max(fitness) > min(fitness)
            fitness_score = 1.0 - (fitness(j) - min(fitness)) / (max(fitness) - min(fitness));
        else
            fitness_score = 1.0;
        end
        
        % 综合评分（安全性权重最高）
        composite_score(j) = safety_score * 0.5 + length_score * 0.3 + fitness_score * 0.2;
    end
    
    % 按综合评分排序
    [~, composite_idx] = sort(composite_score, 'descend');
    
    X_sorted = zeros(size(X));
    for j = 1:pop_size
        X_sorted(j, :) = X(composite_idx(j), :);
        best_paths{j} = best_paths{composite_idx(j)};
        unsafe_counts(j) = unsafe_counts(composite_idx(j));
        path_lengths(j) = path_lengths(composite_idx(j));
    end
    X = X_sorted;
    
    % 记录
    curve(t) = GBestF;
    all_best_paths{t} = GBestPath;
    safety_records(t) = GBestUnsafe;
    length_records(t) = GBestLength;
end

Best_pos = GBestX;
Best_score = GBestF;

fprintf('多方向安全路径优化完成！\n');
fprintf('最终不安全点数: %d\n', GBestUnsafe);
fprintf('最终路径长度: %.2f\n', GBestLength);

% 计算路径效率
[~, result_final, ~] = fobj(Best_pos, option, data);
if isfield(result_final, 'straight_line_length') && result_final.straight_line_length > 0
    efficiency_ratio = result_final.total_length / result_final.straight_line_length;
    fprintf('路径效率比: %.2f (直线长度: %.2f)\n', efficiency_ratio, result_final.straight_line_length);
    
    if efficiency_ratio < 1.3
        fprintf('✓ 路径长度优化效果良好！\n');
    elseif efficiency_ratio < 1.5
        fprintf('✓ 路径长度优化效果一般\n');
    else
        fprintf('⚠ 路径长度有优化空间\n');
    end
end

if GBestUnsafe == 0
    fprintf('✓ 成功找到绝对安全路径！\n');
else
    fprintf('❌ 未找到绝对安全路径，最小不安全点数: %d\n', GBestUnsafe);
end

% 绘制优化过程附加图
figure('Position', [100, 100, 1200, 400]);
subplot(1, 2, 1);
plot(length_records, 'b-', 'LineWidth', 2);
hold on;
plot(movmean(length_records, 5), 'r--', 'LineWidth', 1.5);
xlabel('迭代次数');
ylabel('路径长度');
title('路径长度优化过程');
legend('路径长度', '移动平均', 'Location', 'best');
grid on;

subplot(1, 2, 2);
if isfield(result_final, 'straight_line_length') && result_final.straight_line_length > 0
    efficiency_records = length_records / result_final.straight_line_length;
    plot(efficiency_records, 'g-', 'LineWidth', 2);
    hold on;
    plot(movmean(efficiency_records, 5), 'm--', 'LineWidth', 1.5);
    xlabel('迭代次数');
    ylabel('路径效率比');
    title('路径效率优化过程');
    legend('效率比', '移动平均', 'Location', 'best');
    grid on;
end
end