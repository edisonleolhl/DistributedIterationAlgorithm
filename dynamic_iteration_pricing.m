% 先两个用户迭代，然后第200轮第三个用户加入，第400轮第三个用户离开
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10;
    global MAX_ITER; MAX_ITER = 600;
    global MAX_EPOCH; MAX_EPOCH = 200;
    global CAPACITY; CAPACITY = 10;
    global NUMBERS; NUMBERS = 3;
    global will; will = [1, 2, 3];
    global qos; qos = [1, 1, 1];
    global BW; BW = [0, 0, 0];
    global PRICE; PRICE = [0.1, 0.1, 0.0];
    global OPTIMAL_REVENUE_History; OPTIMAL_REVENUE_History = zeros(1, MAX_ITER);
    cal_optimal_revenue_history();
    REVENUE_History = zeros(1, MAX_ITER);
    UTILITY_History = zeros(NUMBERS, MAX_ITER);
    UTILITY_Epoch_History = zeros(NUMBERS, MAX_ITER);
    PRICE_History = zeros(NUMBERS, MAX_ITER);
    BW_History = zeros(NUMBERS, MAX_ITER);
    for time=1:MAX_ITER
        fprintf('-------------------%3d round----------------\n',time);
        revenue = 0;
        % 1. ISP更新定价策略
        for i=1:NUMBERS
            % 第三个用户前200轮迭代不参与，第200轮预测价格，后400轮迭代不参与
            if i == 3
                if time < 200
                    continue
                elseif time == 200
                    PRICE(i) = mean(PRICE(1:2));
                    fprintf('预测价格为%f\n', PRICE(i));
                    continue;
                elseif time >= 400
                    PRICE(i) = 0;
                    continue;
                end
            end
            fprintf('总带宽为%f\n', sum(BW));
            PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
        end
        % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
        for i=1:NUMBERS
            % 第三个用户前200轮迭代不参与，后400轮迭代不参与
            if i == 3 
                if time < 200
                    continue
                elseif time >= 400
                    BW(i) = 0;
                    continue;
                end
            end
            utility = cal_utility(i, BW(i), PRICE(i));
            next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
            next_utility = cal_utility(i, next_bw, PRICE(i));
            for k=1:MAX_EPOCH
                %fprintf('-------%3d epoch----------\n',k);
                BW(i) = next_bw;
                if time == 1
                    UTILITY_Epoch_History(i, k) = utility;
                end
                utility = next_utility;
                next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                next_utility = cal_utility(i, next_bw, PRICE(i));
                % fprintf('user = %d, bw = %f, utility = %f\n', i, BW(i), utility);
                k = k + 1;
            end
            revenue = revenue + cal_revenue(BW(i), PRICE(i));
            fprintf('bw = %f, price = %f\n' ,BW(i), PRICE(i));
            UTILITY_History(i, time) = utility;
            BW_History(i, time) = BW(i);
        end
        fprintf('network revenue = %f\n' , revenue);
        REVENUE_History(time) = revenue;
        PRICE_History(1, time) = PRICE(1);
        PRICE_History(2, time) = PRICE(2);
        PRICE_History(3, time) = PRICE(3);
    end
	fprintf('----------ENDING-----------\n');
    x = [1:MAX_ITER];
    m = [1:20:MAX_ITER];
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    figure;
    plot_utility_dynamic(x, m, REVENUE_History, UTILITY_History);
    savefig('plot_utility_dynamic');
    figure;
    plot_price_dynamic(x, m, PRICE_History);
    savefig('plot_price_dynamic');
    figure;
    plot_bw_dynamic(x, m, BW_History);
    savefig('plot_bw_dynamic');
    figure;
    plot_theoretical_revenue_dynamic(x, m, REVENUE_History);
    savefig('plot_theoretical_revenue_dynamic');
    
    fprintf('optimal_revenue1 = %f\n', OPTIMAL_REVENUE_History(1));
    fprintf('optimal_revenue2 = %f\n', OPTIMAL_REVENUE_History(201));
end

function plot_price_dynamic(x, m, PRICE_History)
    global MAX_ITER;
    plot_pb = plot(x, PRICE_History(1, 1:MAX_ITER), 'g-', ...,
        x, PRICE_History(2, 1:MAX_ITER), 'k-', x, PRICE_History(3, 1:MAX_ITER), 'b-');
    hold on;
    plot_p_markers = plot(x(m), PRICE_History(1, m), 'g*', ...,
        x(m), PRICE_History(2, m), 'kx',  x(m), PRICE_History(3, m), 'bp');
    legend(plot_p_markers, {'ISP对用户1定价策略', 'ISP对用户2定价策略', 'ISP对用户3定价策略'}, 'Location', 'northwest', 'FontSize', 10);
    ylim([0 4]);
    xlabel('迭代次数','FontSize', 15);
    ylabel('价格','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_bw_dynamic(x, m, BW_History)
    global MAX_ITER;
    plot_pb = plot(x, BW_History(1, 1:MAX_ITER), 'r-', x, BW_History(2, 1:MAX_ITER), 'c-', ...,
        x, BW_History(3, 1:MAX_ITER), 'm-');
    hold on;
    plot_pb_markers = plot(x(m), BW_History(1, m), 'rd', x(m), BW_History(2, m), 'c+', x(m), BW_History(3, m), 'ms');
    legend(plot_pb_markers, {'用户1带宽策略', '用户2带宽策略', '用户3带宽策略'}, 'Location', 'northeast', 'FontSize', 10);
    xlabel('迭代次数','FontSize', 15);
    ylabel('带宽','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_utility_dynamic(x, m, REVENUE_History, UTILITY_History)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History, 'r-', x, UTILITY_History(1, 1:MAX_ITER), ...,
        'g-', x, UTILITY_History(2, 1:MAX_ITER), 'b-', x, UTILITY_History(3, 1:MAX_ITER), 'c-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History(m), 'rd', ...,
        x(m), UTILITY_History(1, m), 'g*', x(m), UTILITY_History(2, m), 'bx', ...,
        x(m), UTILITY_History(3, m), 'cp');
    legend(plot_revenue_makers, {'ISP收益函数', '用户1效用函数', '用户2效用函数', '用户3效用函数'},'FontSize', 10);
    ylim([0 10]);
    xlabel('迭代次数','FontSize', 15);
    ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_theoretical_revenue_dynamic(x, m, REVENUE_History)
    global OPTIMAL_REVENUE_History;
    global MAX_ITER;
    plot_revenue = plot(x, OPTIMAL_REVENUE_History, 'k-', x, REVENUE_History, 'r-');
    hold on;
    plot_revenue_makers = plot(x(m), OPTIMAL_REVENUE_History(m), 'k*', x(m), REVENUE_History(m), 'rd');
    legend(plot_revenue_makers, {'ISP理论收益', 'ISP实际收益'},'FontSize', 10);
    ylim([0 10]);
    xlabel('迭代次数','FontSize', 15);
    ylabel('收益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function cal_optimal_revenue_history()
    global will;
    global qos;
    global repu;
    global CAPACITY;
    global OPTIMAL_REVENUE_History;
    revenue1 = 0;
    revenue2 = 0;
    for nums=[2,3]
        temp1 = 0;
        for i=1:nums
            temp1 = temp1 + (repu*qos(i)) ^ (-1);
        end
        temp2 = 0;
        for i=1:nums
            temp2 = temp2 + (repu*qos(i)) ^ (-1) * will(i);
        end
        revenue = sum(will(1:nums)) - nums * temp2 / (CAPACITY+temp1);    
        if nums == 2
            revenue1 = revenue;
        else
            revenue2 = revenue;
        end
    end
    OPTIMAL_REVENUE_History(1:200) = revenue1;
    OPTIMAL_REVENUE_History(201:400) = revenue2;
    OPTIMAL_REVENUE_History(401:600) = revenue1;
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