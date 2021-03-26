% repu=[10:1:30]，四个用户，探讨纳什均衡状态下不同网络质量对价格、带宽、ISP收益的影响
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10，网络j的QoS指标
    global CAPACITY; CAPACITY = 20;
    global MAX_ITER; MAX_ITER = 500;
    global MAX_EPOCH; MAX_EPOCH = 500; % 用户最大迭代次数
    global will; will = [1, 1.25, 1.5, 1.75, 2]; % 用户购买意愿
    global qos; qos = [1, 1, 1, 1, 1]; % 1~5，用户对QoS的需求
    global NUMBERS; NUMBERS = length(will);
    global BW; BW = zeros(1, NUMBERS); % 两个用户，初始带宽均为0
    global PRICE; PRICE = 0.1 * ones(1, NUMBERS); % 网络j的初始价格，对于用户1和2而言
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    orange = [1, 153/255, 0];
    deep_red = [204/255, 51/255, 0];
    blue_purple = [51/255, 51/255, 204/255];
    grey_green = [51/255, 153/255, 102/255];
    dark_yellow = [204/255, 204/255, 0];
    red_purple = [204/255, 51/255, 153/255];
    r_list = [5:0.5:10];
    r_num = length(r_list);
    REVENUE_History = zeros(1, r_num); % ISP收益随r的变化
    UTILITY_History = zeros(NUMBERS, r_num); % 各用户效用随r的变化
    PRICE_History = zeros(NUMBERS, r_num);
    BW_History = zeros(NUMBERS, r_num);
    for r=r_list
        fprintf('-------------------repu=%3d----------------\n',r);
        repu = r;
        for time=1:MAX_ITER
%             fprintf('-------------------%3d round----------------\n',time);
            % 1. ISP更新定价策略
            for i=1:NUMBERS
                PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
            end
            for k=1:MAX_EPOCH
                %fprintf('-------%3d epoch----------\n',k);
                % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
                for i=1:NUMBERS
                    new_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                    BW(i) = new_bw;
                end
            end
        end
        revenue = 0;
        for i=1:NUMBERS
            revenue = revenue + cal_revenue(BW(i), PRICE(i));
            fprintf('user = %d, bw = %f, price= %f\n', i, BW(i), PRICE(i));
        end
        fprintf('network revenue = %f\n' , revenue);
        % 记录数据
        REVENUE_History(r*2-9) = revenue;
        for i=1:NUMBERS
            UTILITY_History(i, r*2-9) = cal_utility(i, BW(i), PRICE(i));
            PRICE_History(i, r*2-9) = PRICE(i);
            BW_History(i, r*2-9) = BW(i);
        end
        % 回归初始条件
        BW = zeros(1, NUMBERS);
        PRICE = 0.1 * ones(1, NUMBERS);
    end
	fprintf('----------ENDING-----------\n');
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    figure;
    plot_diff_repu_effect_on_price(r_list, r_num, PRICE_History);
    savefig('plot_diff_repu_effect_on_price');
    figure;
    plot_diff_repu_effect_on_bw(r_list, r_num, BW_History);
    savefig('plot_diff_repu_effect_on_bw');
    figure;
    plot_diff_repu_effect_on_utility(r_list, r_num, UTILITY_History);
    savefig('plot_diff_repu_effect_on_utility');
    figure;
    plot_diff_repu_effect_on_revenue(r_list, r_num, REVENUE_History);
    savefig('plot_diff_repu_effect_on_revenue');
end

function plot_diff_repu_effect_on_price(r_list, r_num, PRICE_History)
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    plot_p = plot(r_list, PRICE_History(1, 1:r_num), '-*', ..., 
        'color', orange, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(r_list, PRICE_History(2, 1:r_num), '-p', ...,
        'color', deep_red, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(r_list, PRICE_History(3, 1:r_num), '-d', ...,
        'color', blue_purple, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(r_list, PRICE_History(4, 1:r_num), '->', ...,
        'color', grey_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p4 = plot(r_list, PRICE_History(5, 1:r_num), '-o', ...,
        'color', dark_yellow, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'ISP对用户1(w=1.00)定价策略', 'ISP对用户2(w=1.25)定价策略', ...,
        'ISP对用户3(w=1.50)定价策略', 'ISP对用户4(w=1.75)定价策略', 'ISP对用户5(w=2.00)定价策略'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('网络质量(Reputation)','FontSize', 15);
    ylabel('价格','FontSize', 15);
    ylim([1.2 2.2]); % just for presentation
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_repu_effect_on_bw(r_list, r_num, BW_History)
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    plot_p = plot(r_list, BW_History(1, 1:r_num), '-*', ..., 
        'color', orange, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(r_list, BW_History(2, 1:r_num), '-p', ...,
        'color', deep_red, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(r_list, BW_History(3, 1:r_num), '-d', ...,
        'color', blue_purple, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(r_list, BW_History(4, 1:r_num), '->', ...,
        'color', grey_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p4 = plot(r_list, BW_History(5, 1:r_num), '-o', ...,
        'color', dark_yellow, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'用户1(w=1.00)带宽策略', '用户2(w=1.25)带宽策略', ...,
        '用户3(w=1.50)带宽策略', '用户4(w=1.75)带宽策略', '用户5(w=2.00)带宽策略'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('网络质量(Reputation)','FontSize', 15);
    ylabel('带宽','FontSize', 15);
    ylim([0.5 1.2]); % just for presentation
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_repu_effect_on_utility(r_list, r_num, UTILITY_History)
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    plot_p = plot(r_list, UTILITY_History(1, 1:r_num), '-*', ..., 
        'color', orange, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(r_list, UTILITY_History(2, 1:r_num), '-p', ...,
        'color', deep_red, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(r_list, UTILITY_History(3, 1:r_num), '-d', ...,
        'color', blue_purple, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(r_list, UTILITY_History(4, 1:r_num), '->', ...,
        'color', grey_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p4 = plot(r_list, UTILITY_History(5, 1:r_num), '-o', ...,
        'color', dark_yellow, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'用户1(w=1.00)效用', '用户2(w=1.25)效用', ...,
        '用户3(w=1.50)效用', '用户4(w=1.75)效用', '用户5(w=2.00)效用'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('网络质量(Reputation)','FontSize', 15);
    ylabel('效用','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_repu_effect_on_revenue(r_list, r_num, REVENUE_History)
    plot_revenue = plot(r_list, REVENUE_History, 'r-*', 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'ISP收益'},'Location', 'northwest','FontSize', 10);
    xlabel('网络质量(Reputation))','FontSize', 15);
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