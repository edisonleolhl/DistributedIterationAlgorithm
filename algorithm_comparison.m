%比较分布式迭代算法与UBP的ISP Revenue
%设置三个时间段[0,8),[8,16),[16,24)，时间槽设为0.1h，每条流持续时间设为0.1h
%DIP在每个时间槽运行一次，实时定价
function main()
    global REPUTATION; REPUTATION = 10;
    global CAPACITY; CAPACITY = 100;
    global bw_step; bw_step = 0.01;
    global price_step; price_step = 0.01;
    global MAX_ITER; MAX_ITER = 400; %TODO
    global MAX_EPOCH; MAX_EPOCH = 400;
    time_slot = 1; % 时间槽为0.1h，为了便于仿真，放大十倍
    period_total_slot = 8 / time_slot; %一个时间段总共有80个时间槽
    peak = 400; % 流量高峰期，平均每小时400条流
    mid = 200;
    valley = 100;
    will_valley = zeros(period_total_slot, valley / 10);
    qos_valley = zeros(period_total_slot, valley / 10);
    days = 1; %三天
    total_slot = 3*days*period_total_slot;
    for type=['v']
        REVENUE_UBP_History = zeros(1, total_slot);
        REVENUE_DIP_History = zeros(1, total_slot);
        UTILITY_UBP_History = zeros(1, total_slot);
        UTILITY_DIP_History = zeros(1, total_slot);
        THEO_REVENUE = zeros(1, total_slot);
        UBP_numbers = 24; % UBP每天定价24次，即每小时变更一次价格
        UBP_new_pricing_slot = 0:3*period_total_slot/UBP_numbers:total_slot-1; %重新定价的时间槽
        for time=0:total_slot-1
            fprintf('-------------------%3d time_slot----------------\n',time);
            % 先测试低谷时期，每小时100条流，每个时间槽10条流
            if mod(time,3*period_total_slot) <= period_total_slot-1
                % 当前时间槽新加入用户数服从正态分布
                num = round(randn+valley/10);
                if type == 'v'
                    CAPACITY = 100;
                end
            elseif mod(time,3*period_total_slot)<= period_total_slot*2-1
                num = round(randn+mid/10);
                if type == 'v'
                    CAPACITY = 200;
                end
            else
                num = round(randn+peak/10);
                if type == 'v'
                    CAPACITY = 400;
                end
            end
            new_wills = round(rand(1, num), 1) + 1; % will=[1,2]
            new_qoss = round(rand(1, num), 1) + 1; % qos=[1,2]
            % 加入到时间槽历史中
            will_valley(time+1, 1 : num) = new_wills; %matlab下标从1开始
            qos_valley(time+1, 1 : num) = new_qoss;
            if find(UBP_new_pricing_slot == time)
                % UBP重新决定price
                ubp_price = UBP(new_wills, new_qoss);
            end
            fprintf('UBP ubp_price = %f\n' , ubp_price);
            bws = user_epoch(new_wills, new_qoss, ubp_price);
            revenue_UBP = ubp_price*sum(bws);
            REVENUE_UBP_History(time+1) = revenue_UBP;
            fprintf('UBP network revenue = %f\n' , revenue_UBP);
%             utilitys = zeros(1, num);
%             for i=1:num
%                 utilitys(i) = cal_utility(i, new_wills, new_qoss, bws(i), ubp_price);
%             end
%             utility_UBP = mean(utilitys);
%             UTILITY_UBP_History(time+1) = utility_UBP;
%             fprintf('UBP avg user utility = %f\n' , utility_UBP);
            % DIP
            [revenue_DIP, utility_DIP] = DIP(new_wills, new_qoss);
            REVENUE_DIP_History(time+1) = revenue_DIP;
            fprintf('DIP network revenue = %f\n' , revenue_DIP);
            UTILITY_DIP_History(time+1) = utility_DIP;
%             fprintf('DIP avg user utility = %f\n' , utility_DIP);
            THEO_REVENUE(time+1) = theo(num, new_wills, new_qoss);
            fprintf('theoritical revenue = %f\n', THEO_REVENUE(time+1));
        end
        now_str = datestr(now,30);
        if type == 'v'
            mat_file = strcat(strcat('algorithm_comparison_capacity_varied_', now_str), '.mat');
%             save(mat_file,'REVENUE_UBP_History','revenue_DIP_History','UTILITY_UBP_History','UTILITY_DIP_History');
            figure;
            plot_revenue_comparison(total_slot, REVENUE_UBP_History, REVENUE_DIP_History, THEO_REVENUE);
%             savefig(strcat('plot_revenue_comparison_capacity_varied_', now_str));
%             figure;
%             plot_utility_comparison(total_slot, UTILITY_UBP_History, UTILITY_DIP_History);
%             savefig(strcat('plot_utility_comparison_capacity_varied_', now_str));
        else
            mat_file = strcat(strcat('algorithm_comparison_capacity_fixed_', now_str), '.mat');
%             save(mat_file,'REVENUE_UBP_History','REVENUE_DIP_History','UTILITY_UBP_History','UTILITY_DIP_History');
            figure;
            plot_revenue_comparison(total_slot, REVENUE_UBP_History, REVENUE_DIP_History, THEO_REVENUE);
%             savefig(strcat('plot_revenue_comparison_capacity_fixed_', now_str));
%             figure;
%             plot_utility_comparison(total_slot, UTILITY_UBP_History, UTILITY_DIP_History);
%             savefig(strcat('plot_utility_comparison_capacity_fixed_', now_str));
        end
    end
end

function plot_revenue_comparison(total_slot, REVENUE_UBP_History, REVENUE_DIP_History, THEO_REVENUE)
    x = [1:total_slot];
    m = [1:2:total_slot];
    plot(x(m), REVENUE_UBP_History(m), 'b-', ...,
        x(m), REVENUE_DIP_History(m), 'r-', ...,
        x(m), THEO_REVENUE(m), 'k-.');
    legend({'UBP-ISP收益', 'DIP-ISP收益', '逆向归纳-ISP理论最大收益'}, 'Location', 'northwest', 'FontSize', 15);
%     xticks([0:total_slot/9:total_slot]); % only available after
%     R2016b(included)
    set(gca, 'Xticks', [0:total_slot/9:total_slot]);
%     xticklabels([0:total_slot/90:total_slot/10]);
    set(gca, 'XticksLabels', [0:total_slot/90:total_slot/10]);
    xlim([0 total_slot]);
    xlabel('时间（小时）','FontSize', 15);
    ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_utility_comparison(total_slot, UTILITY_UBP_History, UTILITY_DIP_History)
    x = [1:total_slot];
    m = [1:2:total_slot];
    plot(x(m), UTILITY_UBP_History(m), 'b-', ...,
        x(m), UTILITY_DIP_History(m), 'r-');
    legend({'UBP-用户平均效益', 'DIP-用户平均效益'}, 'Location', 'northwest', 'FontSize', 15);
%     xticks([0:total_slot/9:total_slot]);
    set(gca, 'Xticks', [0:total_slot/9:total_slot]);
%     xticklabels([0:total_slot/90:total_slot/10]);
    set(gca, 'XticksLabels', [0:total_slot/90:total_slot/10]);
    xlabel('时间（小时）','FontSize', 15);
    ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function [revenue_DIP, utility_DIP] = DIP(wills, qoss)
    global MAX_ITER;
    global MAX_EPOCH;
    global bw_step;
    global price_step;
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    prices = 0.1* ones(1, NUMBERS); % DIP是分别定价
    utilitys = zeros(1, NUMBERS);
    utility_DIP = 0;
    for iter=1:MAX_ITER
%         fprintf('-------------------%3d round----------------\n',iter);
        % 1. ISP更新定价策略
        for i=1:NUMBERS
            prices(i) = max(0, prices(i) + price_step*cal_change_rate_p(i, bws));
        end
        for k=1:MAX_EPOCH
            %fprintf('-------%3d epoch----------\n',k);
            % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
            for i=1:NUMBERS
                new_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, prices(i)));
                bws(i) = new_bw;
            end
        end
    end
    revenue_DIP = 0;
    for i=1:NUMBERS
        revenue_DIP = revenue_DIP + cal_revenue(bws(i), prices(i));
%         utilitys(i) = cal_utility(i, wills, qoss, bws(i), prices(i));
%         fprintf('user = %d, bw = %f, price = %f, utility = %f\n', i, bws(i), prices(i), utilitys(i));
    end
%     fprintf('network revenue_DIP = %f\n' , revenue_DIP);
    fprintf('DIP avg_price = %f, avg_bw = %f\n', mean(prices), mean(bws));
%     utility_DIP = mean(utilitys);
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
        for k=1:MAX_EPOCH
            %fprintf('-------%3d epoch----------\n',k);
            % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
            for i=1:NUMBERS
                new_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
                bws(i) = new_bw;
            end
        end
    end
end

function bws = user_epoch(wills, qoss, price)
    % 对于给定price，NUMBERS个用户最大化自己的效用函数，输出带宽向量
    global MAX_EPOCH;
    global bw_step;
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    for k=1:MAX_EPOCH
        %fprintf('-------%3d epoch----------\n',k);
        % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
        for i=1:NUMBERS
            new_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
            bws(i) = new_bw;
        end
    end
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

function r=theo(num, wills, qoss)
    global REPUTATION;
    global CAPACITY;
    r = 0;
    temp1 = 0;
    for i=1:num
        temp1 = temp1 + (REPUTATION*qoss(i)) ^ (-1);
    end
    temp2 = 0;
    for i=1:num
        temp2 = temp2 + (REPUTATION*qoss(i)) ^ (-1) * wills(i);
    end
    r = sum(wills(1:num)) - num * temp2 / (CAPACITY+temp1);  
end