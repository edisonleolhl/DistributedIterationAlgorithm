% CAPACITY=10与5进行比较，探讨纳什均衡状态下不同网络容量对价格与带宽的影响
% repu=10与5进行比较，探讨纳什均衡状态下不同网络质量对价格与带宽的影响
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10，网络j的QoS指标
    global CAPACITY; CAPACITY = 10;
%     global MAX_ITER; MAX_ITER = 400; % capacity的最大迭代次数
    global MAX_ITER; MAX_ITER = 200; % reputation的最大迭代次数
    global MAX_EPOCH; MAX_EPOCH = 400; % 用户最大迭代次数
    global NUMBERS; NUMBERS = 2;
    global will; will = [1.5, 2]; % 用户购买意愿
    global qos; qos = [1, 1]; % 1~5，用户对QoS的需求
    global BW; BW = [0, 0]; % 两个用户，初始带宽均为0
    global PRICE; PRICE = [0.1, 0.1]; % 网络j的初始价格，对于用户1和2而言
    REVENUE_History_1 = zeros(1, MAX_ITER); %不同的c或r
    REVENUE_History_2 = zeros(1, MAX_ITER); %不同的c或r
    UTILITY_History_1 = zeros(NUMBERS, MAX_ITER); %两个用户所以是二维
    UTILITY_History_2 = zeros(NUMBERS, MAX_ITER);
    PRICE_History_1 = zeros(NUMBERS, MAX_ITER);
    PRICE_History_2 = zeros(NUMBERS, MAX_ITER);
    BW_History_1 = zeros(NUMBERS, MAX_ITER);
    BW_History_2 = zeros(NUMBERS, MAX_ITER);
    for time=1:2*MAX_ITER
        fprintf('-------------------%3d round----------------\n',time);
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
            fprintf('bw = %f, price = %f\n' ,BW(i), PRICE(i));
            if time <= MAX_ITER
                UTILITY_History_1(i, time) = utility;
                BW_History_1(i, time) = BW(i);
            else
                UTILITY_History_2(i, time-MAX_ITER) = utility;
                BW_History_2(i, time-MAX_ITER) = BW(i);
            end
        end
        fprintf('network revenue = %f\n' , revenue);
        if time <= MAX_ITER
            REVENUE_History_1(time) = revenue;
            PRICE_History_1(1, time) = PRICE(1);
            PRICE_History_1(2, time) = PRICE(2);
        else
            REVENUE_History_2(time-MAX_ITER) = revenue;
            PRICE_History_2(1, time-MAX_ITER) = PRICE(1);
            PRICE_History_2(2, time-MAX_ITER) = PRICE(2);            
        end
        if time == MAX_ITER
            % 回归初始条件
            BW = [0, 0];
            PRICE = [0.1, 0.1];
%             CAPACITY = 5;
            repu = 5;
        end
    end
	fprintf('----------ENDING-----------\n');
    x = [1:MAX_ITER];
    figure;
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    % ----------plot capacity effect----------
%     m = [1:20:MAX_ITER];
%     plot_capacity_effect_on_price(x, m, PRICE_History_1, PRICE_History_2);
%     savefig('plot_capacity_effect_on_price');
%     figure;
%     plot_capacity_effect_on_bw(x, m, BW_History_1, BW_History_2);
%     savefig('plot_capacity_effect_on_bw');
%     figure;
%     plot_capacity_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2);
%     savefig('plot_capacity_effect_on_revenue');
    % ----------plot repu effect----------
    m = [1:10:MAX_ITER];
    plot_repu_effect_on_price(x, m, PRICE_History_1, PRICE_History_2);
    savefig('plot_repu_effect_on_price');
    figure;
    plot_repu_effect_on_bw(x, m, BW_History_1, BW_History_2);
    savefig('plot_repu_effect_on_bw');
    figure;
    plot_repu_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2);
    savefig('plot_repu_effect_on_revenue');
end

function plot_capacity_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History_1, 'b-', ...,
        x, REVENUE_History_2, 'r-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History_1(m), 'b*', ...,
        x(m), REVENUE_History_2(m), 'rd');
    legend(plot_revenue_makers, {'C=10, ISP收益', 'C=5, ISP收益'},'FontSize', 10);
    set(gca,'YTick',[1:16])
    xlabel('迭代次数','FontSize', 15);
    ylabel('收益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_capacity_effect_on_price(x, m, PRICE_History_1, PRICE_History_2)
    global MAX_ITER;
    plot_p = plot(x, PRICE_History_1(1, 1:MAX_ITER), 'g-', x, PRICE_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, PRICE_History_2(1, 1:MAX_ITER), 'm-', x, PRICE_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_p_markers = plot(x(m), PRICE_History_1(1, m), 'g*', x(m), PRICE_History_1(2, m), 'bx', ...,
        x(m), PRICE_History_2(1, m), 'mp', x(m), PRICE_History_2(2, m), 'cd');
    legend(plot_p_markers, {'C=10, ISP对用户1定价策略', 'C=10, ISP对用户2定价策略', ...,
        'C=5, ISP对用户1定价策略', 'C=5, ISP对用户2定价策略'}, ...,
        'Location', 'southeast', 'FontSize', 10);
    xlabel('迭代次数','FontSize', 15);
    ylabel('价格','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_capacity_effect_on_bw(x, m, BW_History_1, BW_History_2)
    global MAX_ITER;
    plot_bw = plot(x, BW_History_1(1, 1:MAX_ITER), 'g-', x, BW_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, BW_History_2(1, 1:MAX_ITER), 'm-', x, BW_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_bw_markers = plot(x(m), BW_History_1(1, m), 'g*', x(m), BW_History_1(2, m), 'bx', ...,
        x(m), BW_History_2(1, m), 'mp', x(m), BW_History_2(2, m), 'cd');
    legend(plot_bw_markers, {'C=10, 用户1带宽策略', 'C=10, 用户2带宽策略', ...,
        'C=5, 用户1带宽策略', 'C=5, 用户2带宽策略'}, ...,
        'Location', 'northeast', 'FontSize', 10);
    xlabel('迭代次数','FontSize', 15);
    ylabel('带宽','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_repu_effect_on_price(x, m, PRICE_History_1, PRICE_History_2)
    global MAX_ITER;
    plot_p = plot(x, PRICE_History_1(1, 1:MAX_ITER), 'g-', x, PRICE_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, PRICE_History_2(1, 1:MAX_ITER), 'm-', x, PRICE_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_p_markers = plot(x(m), PRICE_History_1(1, m), 'g*', x(m), PRICE_History_1(2, m), 'bx', ...,
        x(m), PRICE_History_2(1, m), 'mp', x(m), PRICE_History_2(2, m), 'cd');
    legend(plot_p_markers, {'r=10, ISP对用户1定价策略', 'r=10, ISP对用户2定价策略', ...,
        'r=5, ISP对用户1定价策略', 'r=5, ISP对用户2定价策略'}, ...,
        'Location', 'southeast', 'FontSize', 10);
    xlabel('迭代次数','FontSize', 15);
    ylabel('价格','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_repu_effect_on_bw(x, m, BW_History_1, BW_History_2)
    global MAX_ITER;
    plot_pb = plot(x, BW_History_1(1, 1:MAX_ITER), 'g-', x, BW_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, BW_History_2(1, 1:MAX_ITER), 'm-', x, BW_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_pb_markers = plot(x(m), BW_History_1(1, m), 'g*', x(m), BW_History_1(2, m), 'bx', ...,
        x(m), BW_History_2(1, m), 'mp', x(m), BW_History_2(2, m), 'cd');
    legend(plot_pb_markers, {'r=10, 用户1带宽策略', 'r=10, 用户2带宽策略', ...,
        'r=5, 用户1带宽策略', 'r=5, 用户2带宽策略'}, ...,
        'Location', 'northeast', 'FontSize', 10);
    xlabel('迭代次数','FontSize', 15);
    ylabel('带宽','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_repu_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History_1, 'b-', ...,
        x, REVENUE_History_2, 'r-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History_1(m), 'b*', ...,
        x(m), REVENUE_History_2(m), 'rd');
    legend(plot_revenue_makers, {'r=10, ISP收益', 'r=5, ISP收益'},'FontSize', 10);
    set(gca,'YTick',[1:16])
    xlabel('迭代次数','FontSize', 15);
    ylabel('效益','FontSize', 15);
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