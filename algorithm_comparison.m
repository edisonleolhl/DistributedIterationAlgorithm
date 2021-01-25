%比较分布式迭代算法与UBP的ISP Revenue
%设置三个时间段[0,8),[8,16),[16,24)，时间槽设为0.1h，每条流持续时间设为0.1h
%为了简化，UBP算法设置三个不同的价格，根据0、8、16点的信息来决定接下来8个小时的定价
%DIA在每个时间槽运行一次，实时定价
function main()
    global REPUTATION; REPUTATION = 10;
    global CAPACITY; CAPACITY = 100; % 网络容量要分为三个阶段，大小按照1:2:4
    global bw_step; bw_step = 0.01;
    global price_step; price_step = 0.01;
    global MAX_ITER; MAX_ITER = 200; %TODO
    global MAX_EPOCH; MAX_EPOCH = 200;
    time_slot = 1; % 时间槽为0.1h，为了便于仿真，放大十倍
    duration = 5; % 流量持续时间若大于时间槽，则可以测试算法动态收敛性
    period_total_slot = 8 / 0.1; %一个时间段总共有80个时间槽
    peak = 400; % 流量高峰期，每小时400条流
    mid = 200;
    valley = 100;
    will_valley = zeros(period_total_slot, valley / 10);
    qos_valley = zeros(period_total_slot, valley / 10);
    bw_valley = zeros(period_total_slot, valley / 10);
    UBP_numbers = 48; % 3：每八小时定价一次，6：每四小时定价一次, ...
    UBP_new_pricing_slot = 0:period_total_slot/(UBP_numbers/3):period_total_slot-1; %重新定价的时间槽
    % 先测试低谷时期，每小时100条流，每个时间槽10条流
    for time=0:period_total_slot-1 % 时间槽从0开始
        fprintf('-------------------%3d time_slot----------------\n',time);
        % 当前时间槽新加入用户数
        num = mid / 10;
        new_wills = round(rand(1, num), 1) + 1;
        new_qoss = round(4 * rand(1, num), 1) + 1;
        % 加入到时间槽历史中
        will_valley(time+1, 1 : num) = new_wills; %matlab下标从1开始
        qos_valley(time+1, 1 : num) = new_qoss;
        if find(UBP_new_pricing_slot == time)
            % UBP重新决定price
            if time + 1 - duration >= 0
                wills_mat = will_valley(time+2-duration : time+1, 1 : num);
                qoss_mat = qos_valley(time+2-duration : time+1, 1 : num);
            else
                wills_mat = will_valley(1 : time+1, 1 : num);
                qoss_mat = qos_valley(1 : time+1, 1 : num);
            end
            wills_vec = wills_mat(:);
            qoss_vec = qoss_mat(:);
            price = UBP(wills_vec, qoss_vec);
            
            % UBP的user根据新price，决定自己的bw
            if time + 1 - duration >= 0
                for t = time+2-duration : time+1
                    bws = user_epoch(will_valley(t, 1:num), qos_valley(t, 1:num), price);
                    bw_valley(t, 1 : num) = bws;
                end
                bw_mat = bw_valley(time+2-duration : time+1, 1 : num);
            else
                for t = 1 : time+1
                    bws = user_epoch(will_valley(t, 1:num), qos_valley(t, 1:num), price);
                    bw_valley(t, 1 : num) = bws;
                end
                bw_mat = bw_valley(1 : time + 1, 1 : num);
            end
        else
            % UBP沿用之前price
            bws = user_epoch(new_wills, new_qoss, price);
            bw_valley(time+1, 1 : num) = bws;
            if time + 1 - duration >= 0
                bw_mat = bw_valley(time+2-duration : time+1, 1 : num);
            else
                bw_mat = bw_valley(1 : time + 1, 1 : num);
            end
        end
        bw_vec = bw_mat(:);
        revenue_UBP = price*sum(bw_vec);
        fprintf('UBP network revenue = %f\n' , revenue_UBP);
        % DIA
        revenue_DIA = DIA(time, duration, num, will_valley, qos_valley);
        fprintf('DIA network revenue = %f\n' , revenue_DIA);
    end
end

function revenue_DIA = DIA(time, duration, num, will_valley, qos_valley)
    global MAX_ITER;
    global MAX_EPOCH;
    global bw_step;
    global price_step;
    if time + 1 - duration >= 0
        wills_mat = will_valley(time + 2 - duration : time + 1, 1 : num);
        qoss_mat = qos_valley(time + 2 - duration : time + 1, 1 : num);
    else
        wills_mat = will_valley(1 : time + 1, 1 : num);
        qoss_mat = qos_valley(1 : time + 1, 1 : num);
    end
    wills = wills_mat(:);
    qoss = qoss_mat(:);
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    prices = 0.1* ones(1, NUMBERS); % DIA是分别定价
    for iter=1:MAX_ITER
%         fprintf('-------------------%3d round----------------\n',iter);
        revenue_DIA = 0;
        % 1. ISP更新定价策略
        for i=1:NUMBERS
            prices(i) = max(0, prices(i) + price_step*cal_change_rate_p(i, bws));
        end
        % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
        for i=1:NUMBERS
            utility = cal_utility(i, wills, qoss, bws(i), prices(i));
            next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, prices(i)));
            next_utility = cal_utility(i, wills, qoss, next_bw, prices(i));
            for k=1:MAX_EPOCH
                bws(i) = next_bw;
                utility = next_utility;
                next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, prices(i)));
                next_utility = cal_utility(i, wills, qoss, next_bw, prices(i));
                k = k + 1;
            end
            revenue_DIA = revenue_DIA + cal_revenue(bws(i), prices(i));
        end
%         fprintf('network revenue = %f\n' , revenue_DIA);
    end
    fprintf('price = %f\n', prices(1));
end

function price = UBP(wills, qoss)
    global MAX_ITER;
    global MAX_EPOCH;
    global bw_step;
    global price_step;
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    price = 0.1; % UBP是统一定价
    for iter=1:MAX_ITER
%         fprintf('-------------------%3d round----------------\n',iter);
        revenue = 0;
        % 1. ISP更新定价策略
        price = max(0, price + price_step*cal_change_rate_p_UBP(bws));
        % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
        for i=1:NUMBERS
            utility = cal_utility(i, wills, qoss, bws(i), price);
            next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
            next_utility = cal_utility(i, wills, qoss, next_bw, price);
            for k=1:MAX_EPOCH
                bws(i) = next_bw;
                utility = next_utility;
                next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
                next_utility = cal_utility(i, wills, qoss, next_bw, price);
                k = k + 1;
            end
            revenue = revenue + cal_revenue(bws(i), price);
        end
%         fprintf('network revenue = %f\n' , revenue);
    end
    fprintf('price = %f\n' , price);
end

function bws = user_epoch(wills, qoss, price)
    % 对于给定price，NUMBERS个用户最大化自己的效用函数，输出带宽向量
    global MAX_EPOCH;
    global bw_step;
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    for i=1:NUMBERS
        utility = cal_utility(i, wills, qoss, bws(i), price);
        next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
        next_utility = cal_utility(i, wills, qoss, next_bw, price);
        for k=1:MAX_EPOCH
            bws(i) = next_bw;
            utility = next_utility;
            next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
            next_utility = cal_utility(i, wills, qoss, next_bw, price);
            k = k + 1;
        end
%         fprintf('bw = %f, ' , bws(i));
    end
%     fprintf('\n');
end

function util=cal_utility(i, wills, qoss, b, p)
    global REPUTATION;
    util = wills(i)*log(1 + REPUTATION*qoss(i)*b) - p*b;
end

function reve=cal_revenue(b, p)
    reve = b*p;
end

function rb=cal_change_rate_b(i, wills, qoss, bws, price)
    global REPUTATION;
    global CAPACITY;
    rb = wills(i)*REPUTATION*qoss(i)/(1+REPUTATION*qoss(i)*bws(i)) - price;
    % 吞吐量大于网络容量，所以减少用户的带宽
    if sum(bws) > CAPACITY
        rb = -abs(rb);
    end
end

function rp=cal_change_rate_p(i, bws)
    global CAPACITY;
    rp = bws(i);
    % 吞吐量太小，所以减少价格，诱导用户带宽需求增加
    if sum(bws) < CAPACITY / 5
        rp = -abs(rp);
    end
end

function rp=cal_change_rate_p_UBP(bws)
    global CAPACITY;
    rp = sum(bws);
    % 吞吐量太小，所以减少价格，诱导用户带宽需求增加
    if sum(bws) < CAPACITY / 5
        rp = -abs(rp);
    end
end