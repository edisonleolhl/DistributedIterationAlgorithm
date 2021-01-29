% CAPACITY=[10:1:30]，四个用户，探讨纳什均衡状态下不同网络容量对价格、带宽、ISP收益的影响
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10，网络j的QoS指标
    global CAPACITY; CAPACITY = 10;
    global MAX_ITER; MAX_ITER = 500; % capacity的最大迭代次数
    global MAX_EPOCH; MAX_EPOCH = 500; % 用户最大迭代次数
    global NUMBERS; NUMBERS = 4;
    global will; will = [1, 2, 1, 2]; % 用户购买意愿
    global qos; qos = [1, 1, 5, 5]; % 1~5，用户对QoS的需求
    global BW; BW = zeros(1, NUMBERS); % 两个用户，初始带宽均为0
    global PRICE; PRICE = 0.1 * ones(1, NUMBERS); % 网络j的初始价格，对于用户1和2而言
    c_list = [10:30];
    c_num = length(c_list);
    REVENUE_History = zeros(1, c_num); % ISP收益随C的变化
    UTILITY_History = zeros(NUMBERS, c_num); % 各用户效用随C的变化
    PRICE_History = zeros(NUMBERS, c_num);
    BW_History = zeros(NUMBERS, c_num);
    for c=c_list
        CAPACITY = c;
        fprintf('-------------------capacity=%3d----------------\n',c);
        for time=1:MAX_ITER
%             fprintf('-------------------%3d round----------------\n',time);
            revenue = 0;
            % 1. ISP更新定价策略
            for i=1:length(BW)
                PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
            end
            % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
            for i=1:length(BW)
                utility = cal_utility(i, BW(i), PRICE(i));
                next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                next_utility = cal_utility(i, next_bw, PRICE(i));
                for k=1:MAX_EPOCH
                    %fprintf('-------%3d epoch----------\n',k);
                    BW(i) = next_bw;
                    utility = next_utility;
                    next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                    next_utility = cal_utility(i, next_bw, PRICE(i));
                    % fprintf('user = %d, bw = %f, utility = %f\n', i, BW(i), utility);
                    k = k + 1;
                end
                revenue = revenue + cal_revenue(BW(i), PRICE(i));
            end
        end
        fprintf('network revenue = %f\n' , revenue);
        % 记录数据
        REVENUE_History(c-9) = revenue;
        for i=1:NUMBERS
            UTILITY_History(i, c-9) = cal_utility(i, BW(i), PRICE(i));
            PRICE_History(i, c-9) = PRICE(i);
            BW_History(i, c-9) = BW(i);
        end
        % 回归初始条件
        BW = zeros(1, NUMBERS);
        PRICE = 0.1 * ones(1, NUMBERS);
    end
	fprintf('----------ENDING-----------\n');
    figure;
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    plot_diff_capacity_effect_on_price(c_list, c_num, PRICE_History);
    savefig('plot_diff_capacity_effect_on_price');
    figure;
    plot_diff_capacity_effect_on_bw(c_list, c_num, BW_History);
    savefig('plot_diff_capacity_effect_on_bw');
    figure;
    plot_diff_capacity_effect_on_utility(c_list, c_num, UTILITY_History);
    savefig('plot_diff_capacity_effect_on_utility');
    figure;
    plot_diff_capacity_effect_on_revenue(c_list, c_num, REVENUE_History);
    savefig('plot_diff_capacity_effect_on_revenue');
end

function plot_diff_capacity_effect_on_price(c_list, c_num, PRICE_History)
    plot_p = plot(c_list, PRICE_History(1, 1:c_num), 'b-*', ...,
        c_list, PRICE_History(2, 1:c_num), 'r-p', ...,
        c_list, PRICE_History(3, 1:c_num), 'c-d', ...,
        c_list, PRICE_History(4, 1:c_num), 'm->');
    legend({'ISP对用户1(w=1,q=1)定价策略', 'ISP对用户2(w=2,q=1)定价策略', ...,
        'ISP对用户3(w=1,q=5)定价策略', 'ISP对用户4(w=2,q=5)定价策略'}, ...,
        'Location', 'northeast', 'FontSize', 10);
    xlabel('网络容量(Capacity)','FontSize', 15);
    ylabel('价格','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_capacity_effect_on_bw(c_list, c_num, BW_History)
    plot_bw = plot(c_list, BW_History(1, 1:c_num), 'b-*', ...,
        c_list, BW_History(2, 1:c_num), 'r-p', ...,
        c_list, BW_History(3, 1:c_num), 'c-d', ...,
        c_list, BW_History(4, 1:c_num), 'm->');
    legend({'用户1(w=1,q=1)带宽策略', '用户2(w=2,q=1)带宽策略', ...,
        '用户3(w=1,q=5)带宽策略', '用户4(w=2,q=5)带宽策略'}, ...,
        'Location', 'northwest', 'FontSize', 10);
    xlabel('网络容量(Capacity)','FontSize', 15);
    ylabel('带宽','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_capacity_effect_on_utility(c_list, c_num, UTILITY_History)
    plot_p = plot(c_list, UTILITY_History(1, 1:c_num), 'b-*', ...,
        c_list, UTILITY_History(2, 1:c_num), 'r-p', ...,
        c_list, UTILITY_History(3, 1:c_num), 'c-d', ...,
        c_list, UTILITY_History(4, 1:c_num), 'm->');
    legend({'用户1(w=1,q=1)效用', '用户2(w=2,q=1)效用', ...,
        '用户3(w=1,q=5）效用', '用户4(w=2,q=5)效用'}, ...,
        'Location', 'northwest', 'FontSize', 10);
    xlabel('网络容量(Capacity)','FontSize', 15);
    ylabel('价格','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_capacity_effect_on_revenue(c_list, c_num, REVENUE_History)
    plot_revenue = plot(c_list, REVENUE_History, 'r-*');
    legend({'ISP收益'},'Location', 'northwest','FontSize', 10);
    xlabel('网络容量(Capacity)','FontSize', 15);
    ylabel('收益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function util=cal_utility(i, b, p)
    global will;
    global qos;
    global repu;
    util = will(i)*log(1 + repu*qos(i)*b) - p*b;
end

function reve=cal_revenue(b, p)
    reve = b*p;
end

function rb=cal_change_rate_b(i)
    global BW;
    global PRICE;
    global will;
    global qos;
    global repu;
    global CAPACITY;
    rb = will(i)*repu*qos(i)/(1+repu*qos(i)*BW(i)) - PRICE(i);
    % 吞吐量大于网络容量，所以减少用户的带宽
    if sum(BW) > CAPACITY
        rb = -abs(rb);
    end
end

function rp=cal_change_rate_p(i)
    global BW;
    global CAPACITY;
    rp = BW(i);
    % 吞吐量太小，所以减少价格，诱导用户带宽需求增加
    if sum(BW) < CAPACITY / 5
        rp = -abs(rp);
    end
end