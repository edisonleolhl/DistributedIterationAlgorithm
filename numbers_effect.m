% will=1.5与2.0进行比较，探讨纳什均衡状态下不同网络容量对价格与带宽的影响
% qos=1与3进行比较，探讨纳什均衡状态下不同网络质量对价格与带宽的影响
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10，网络j的QoS指标
    global CAPACITY; CAPACITY = 100;
    global MAX_ITER; MAX_ITER = 200; % 最大迭代次数
    global will; will = ones(1, 30); % 用户购买意愿
    global qos; qos = ones(1, 30); % 用户对QoS的需求
    global BW; BW = zeros(1, 30); % 三十个用户，初始带宽为0
    global PRICE; PRICE = 0.1*ones(1, 30); % 网络j的初始价格
    global NUMBERS; NUMBERS = 3; % 初始测试三个用户
    n_list = [3:30];
    n_num = length(n_list);
    revenue_trends = zeros(1, n_num);
    avg_price_trends = zeros(1, n_num);
    avg_bw_trends = zeros(1, n_num);
    avg_utility_trends = zeros(1, n_num);
    for num=n_list
        fprintf('-------------------%3d users----------------\n',num);
        NUMBERS = num;
        % 回归初始条件，一定要先修改BW、PRICE数组
        BW = zeros(1, num);
        PRICE = 0.1*ones(1, num);
        for time=1:MAX_ITER
            % fprintf('-------------------%3d round----------------\n',time);
            revenue = 0;
            % 1. ISP更新定价策略
            for i=1:NUMBERS
                PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
            end
            % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
            for i=1:NUMBERS
                utility = cal_utility(i, BW(i), PRICE(i));
                next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                next_utility = cal_utility(i, next_bw, PRICE(i));
                for k=1:MAX_ITER
                    %fprintf('-------%3d epoch----------\n',k);
                    BW(i) = next_bw;
                    utility = next_utility;
                    next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                    next_utility = cal_utility(i, next_bw, PRICE(i));
                    k = k + 1;
                end
                revenue = revenue + cal_revenue(BW(i), PRICE(i));
            end
        end
        avg_price = mean(PRICE(1:NUMBERS));
        avg_bw = mean(BW(1:NUMBERS));
        avg_utility = cal_utility(1, avg_bw, avg_price); % w与q都相同，所以i=1即可
        fprintf('avg_bw = %f, avg_price = %f\n' , avg_bw, avg_price);
        fprintf('avg_utility = %f\n' , avg_utility);
        fprintf('network revenue = %f\n' , revenue);
        avg_price_trends(num-2) = avg_price;
        avg_bw_trends(num-2) = avg_bw;
        avg_utility_trends(num-2) = avg_utility;
        revenue_trends(num-2) = revenue;
    end
    fprintf('----------ENDING-----------\n');
    figure;
    plot_numbers_effect_on_pb(n_list, avg_price_trends, avg_bw_trends);
    savefig('plot_numbers_effect_on_pb');
    figure;
    plot_numbers_effect_on_ru(n_list, revenue_trends, avg_utility_trends);
    savefig('plot_numbers_effect_on_ru');
end

function plot_numbers_effect_on_pb(x, avg_price_trends, avg_bw_trends)
    yyaxis left
    plot(x, avg_price_trends, 'b-p');
    yyaxis right
    plot(x, avg_bw_trends, 'r-*');
    legend({'ISP平均定价策略', '用户平均带宽策略'}, ...,
        'FontSize', 15, 'Location', 'northwest');
    xlim([3 30]);
    yyaxis left
    ylabel('价格','FontSize', 15);
    yyaxis right
    ylabel('带宽','FontSize', 15);
    xlabel('用户数','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_numbers_effect_on_ru(x, revenue_trends, avg_utility_trends)
    yyaxis left
    plot(x, avg_utility_trends, 'b-p');
    yyaxis right
    plot(x, revenue_trends, 'r-*');
    legend({'用户平均效用', 'ISP收益'},'FontSize', 15, 'Location', 'north');
    xlabel('用户数','FontSize', 15);
    yyaxis left
    ylabel('效用','FontSize', 15);
    yyaxis right
    ylabel('收益','FontSize', 15);
    xlim([3 30]);
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
    global NUMBERS;
    rb = will(i)*repu*qos(i)/(1+repu*qos(i)*BW(i)) - PRICE(i);
    % 吞吐量大于网络容量，所以减少用户的带宽
    if sum(BW(1:NUMBERS)) > CAPACITY
        rb = -abs(rb);
    end
end

function rp=cal_change_rate_p(i)
    global BW;
    global CAPACITY;
    global NUMBERS;
    rp = BW(i);
    % 吞吐量太小，所以减少价格，诱导用户带宽需求增加
    if sum(BW(1:NUMBERS)) < CAPACITY / 5
        rp = -abs(rp);
    end
end