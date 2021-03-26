function main()
    % v: 用户i带宽策略调节步长
    % w: 网络j的价格策略调节步长
    % e: 可以通过一个小的变化量e(例如e = 10-4)来计算其对效用产生的影响
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10，网络j的QoS指标
    global MAX_ITER; MAX_ITER = 200; % 最大迭代次数
    global CAPACITY; CAPACITY = 10;
    global NUMBERS; NUMBERS = 2;
    global will; will = [1, 2]; % 用户购买意愿
    global qos; qos = [1, 1]; % 1~5，用户对QoS的需求
    global BW; BW = [0, 0]; % 两个用户，初始带宽均为0
    global PRICE; PRICE = [0.1, 0.1]; % 网络j的初始价格，对于用户1和2而言
    pre_rev = 0;
    REVENUE_History = zeros(1, MAX_ITER);
    UTILITY_History = zeros(NUMBERS, MAX_ITER);
    UTILITY_Epoch_History = zeros(NUMBERS, MAX_ITER);
    PRICE_History = zeros(NUMBERS, MAX_ITER);
    BW_History = zeros(NUMBERS, MAX_ITER);
    for time=1:MAX_ITER
        fprintf('-------------------%3d round----------------\n',time);
        % 1. ISP更新定价策略
        for i=1:NUMBERS
            PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
        end
        for k=1:MAX_ITER
%             fprintf('-------%3d epoch----------\n',k);
            % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
            for i=1:NUMBERS
                new_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                BW(i) = new_bw;
                new_utility = cal_utility(i, new_bw, PRICE(i));
                UTILITY_History(i, time) = new_utility;
                fprintf('bw = %f, price = %f, utility = %f\n' ,new_bw, PRICE(i), new_utility);
                if time == 1
                    % 绘制用户epoch迭代过程，因为曲线趋势便于展示
                    UTILITY_Epoch_History(i, k) = new_utility;
                end
            end
        end
        revenue = 0;
        for i=1:NUMBERS
            revenue = revenue + cal_revenue(BW(i), PRICE(i));
            BW_History(i, time) = BW(i);
            PRICE_History(i, time) = PRICE(i);
        end
        fprintf('network revenue = %f\n' , revenue);
        if abs(pre_rev - revenue) < 0.001 * pre_rev
            for i=1:NUMBERS
                UTILITY_History(i, time+1:MAX_ITER) = UTILITY_History(i, time);
                BW_History(i, time+1:MAX_ITER) = BW_History(i, time);
                PRICE_History(i, time+1:MAX_ITER) = PRICE_History(i, time);
            end
            REVENUE_History(time:MAX_ITER) = revenue;
            break;
        end
        pre_rev = revenue;
        REVENUE_History(time) = revenue;           
    end
	fprintf('----------ENDING-----------\n');
    x = [1:MAX_ITER];
    m = [1:10:MAX_ITER];
    figure;
    plot_utility_epoch(x, m, UTILITY_Epoch_History(1:NUMBERS, 1:MAX_ITER));
    savefig('plot_utility_epoch');
    figure;
    plot_utility(x, m, REVENUE_History, UTILITY_History);
    savefig('plot_utility');
    figure;
    plot_pb(x, m, PRICE_History, BW_History);
    savefig('plot_pb');
end

function plot_utility_epoch(x, m, UTILITY_Epoch_History)
    global MAX_ITER;
    plot_revenue = plot(x, UTILITY_Epoch_History(1, 1:MAX_ITER), 'g-', ...,
        x, UTILITY_Epoch_History(2, 1:MAX_ITER), 'b-', 'LineWidth', 1.5);
    hold on;
    plot_revenue_makers = plot(x(m), UTILITY_Epoch_History(1, m), 'g*', ...,
        x(m), UTILITY_Epoch_History(2, m), 'bp', 'MarkerSize',10);
    legend(plot_revenue_makers, {'w=1.0', 'w=2.0'},  ...,
        'Location', 'southeast', 'FontSize', 15);
    xlabel('用户迭代次数(ISP Epoch内)','FontSize', 15);
    ylabel('用户效用','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
end

function plot_pb(x, m, PRICE_History, BW_History)
    global MAX_ITER;
    plot_pb = plot(x, PRICE_History(1, 1:MAX_ITER), 'g-', ...,
        x, PRICE_History(2, 1:MAX_ITER), 'b-', ...,
        x, BW_History(1, 1:MAX_ITER), 'r-', ...,
        x, BW_History(2, 1:MAX_ITER), 'c-', 'LineWidth', 1.5);
    hold on;
    plot_pb_markers = plot(x(m), PRICE_History(1, m), 'g*', ...,
            x(m), PRICE_History(2, m), 'bx', ...,
            x(m), BW_History(1, m), 'rd', ...,
            x(m), BW_History(2, m), 'cp', 'MarkerSize',10);
    legend(plot_pb_markers, {'ISP对用户1定价策略', 'ISP对用户2定价策略', ...,
        '用户1带宽策略', '用户2带宽策略'}, 'Location', 'northeast', 'FontSize', 15);
    xlabel('迭代次数','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
end


function plot_utility(x, m, REVENUE_History, UTILITY_History)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History, 'r-', ...,
        x, UTILITY_History(1, 1:MAX_ITER), 'g-', ...,
        x, UTILITY_History(2, 1:MAX_ITER), 'b-', 'LineWidth', 1.5);
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History(m), 'rd', ...,
        x(m), UTILITY_History(1, m), 'g*', ...,
        x(m), UTILITY_History(2, m), 'bx', 'MarkerSize',10);
    legend(plot_revenue_makers, {'ISP收益', '用户1效用', ...,
        '用户2效用'},'FontSize', 15);
    set(gca,'YTick',[1:16])
    xlabel('迭代次数','FontSize', 15);
    ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
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