# CityAvoid
利用SOA进行路径规划
baseline1:
安全距离：目前保证绝对安全

程序架构：
1）generate_city_terrain.m随机生成地图和该地图的复现脚本，generated_terrain_buildings.m
2）City_Avoid_Smooth_Safe.m调用generated_terrain_buildings.m进行路径规划；

当前版本采用原始SOA，前期设计飞机在避障时选择向各方向运动的概率一致，但目前看，还有些倾向于向上。

————————
baseline2:
倾向于向上规避，但相对好用。
在此基础上该后还是倾向向上

————————
baseline3:
相对好用，存在中途路劲干涉和向上寻找建筑物顶部安全区的情况无法修正。
