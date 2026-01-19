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