% will=[1:0.1:2.1]探讨用户购买意愿对ISP收益的影响
% qos=1与3进行比较，探讨用户QoS需求对ISP收益的影响
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10，网络j的QoS指标
    global CAPACITY; CAPACITY = 100;
    global MAX_ITER; MAX_ITER = 200; % 最大迭代次数
    global NUMBERS; NUMBERS = 30;
    global will; will = ones(1, NUMBERS); % 用户购买意愿
    global qos; qos = ones(1, NUMBERS); % 用户对QoS的需求
    global BW; BW = zeros(1, NUMBERS); % 三十个用户，初始带宽为0
    global PRICE; PRICE = 0.1*ones(1, NUMBERS); % 网络j的初始价格
%     x = [1:0.1:1.9]; % for will
    x = [1:0.5:5]; % for qos 
    revenue_trends = zeros(1, length(x));
    for w=x
        fprintf('-------------------w = %3d----------------\n',w);
        % 回归初始条件
        BW = zeros(1, NUMBERS);
        PRICE = 0.1*ones(1, NUMBERS);
        will = w*ones(1, 30);
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
                if time == MAX_ITER
                    fprintf('bw = %f, price = %f\n' ,BW(i), PRICE(i));
                end
            end
            if time == MAX_ITER
                fprintf('network revenue = %f\n' , revenue);
            end
        end
%         revenue_trends(round(w*10-9)) = revenue; % FOR will
        revenue_trends(round(w*2-1)) = revenue; % FOR qos
    end
    fprintf('----------ENDING-----------\n');
%     figure;
%     plot_will_effect_on_revenue(x, revenue_trends);
%     savefig('plot_will_effect_on_revenue');
    figure;
    plot_qos_effect_on_revenue(x, revenue_trends);
    savefig('plot_qos_effect_on_revenue');
    end

function plot_will_effect_on_revenue(x, revenue_trends)
    plot_revenue = plot(x, revenue_trends, 'r-*');
    legend({'ISP收益'},'FontSize', 15, 'Location', 'northwest');
    xlim([0.9 2]);
    set(gca,'xtick', [0.9:0.1:2]);
    xlabel('用户购买意愿（willing）','FontSize', 15);
    ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_qos_effect_on_revenue(x, revenue_trends)
    plot_revenue = plot(x, revenue_trends, 'r-*');
    legend({'ISP收益'},'FontSize', 15, 'Location', 'northwest');
    xlim([0.5 5.5]);
    set(gca,'xtick', [0.5:0.5:5.5]);
    xlabel('用户QoS需求','FontSize', 15);
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