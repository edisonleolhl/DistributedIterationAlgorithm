% 先两个用户迭代，然后第200轮第三个用户加入，第400轮第三个用户离开
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10;
    global MAX_ITER; MAX_ITER = 200;
    global CAPACITY; CAPACITY = 10;
    global NUMBERS; NUMBERS = 3;
    global will; will = [1, 1.5, 2];
    global qos; qos = [1, 2, 3];
    global BW; BW = [0, 0, 0];
    global PRICE; PRICE = [0.1, 0.1, 0.0];
    global xrange; xrange = 3*MAX_ITER;
    global OPTIMAL_REVENUE_History; OPTIMAL_REVENUE_History = zeros(1, xrange);
    cal_optimal_revenue_history();
    REVENUE_History = zeros(1, xrange);
    UTILITY_History = zeros(NUMBERS, xrange);
    UTILITY_Epoch_History = zeros(NUMBERS, xrange);
    PRICE_History = zeros(NUMBERS, xrange);
    BW_History = zeros(NUMBERS, xrange);
    for time=1:xrange
        fprintf('-------------------%3d round----------------\n',time);
        % 1. ISP更新定价策略
        for i=1:NUMBERS
            % 第三个用户前200轮迭代不参与，第200轮预测价格，后400轮迭代不参与
            if i == 3
                if time < MAX_ITER
                    continue
                elseif time == MAX_ITER
                    PRICE(i) = mean(PRICE(1:2));
                    fprintf('预测价格为%f\n', PRICE(i));
                    continue;
                elseif time >= 2*MAX_ITER
                    PRICE(i) = 0;
                    continue;
                end
            end
            fprintf('总带宽为%f\n', sum(BW));
            PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
        end
        for k=1:MAX_ITER
            %fprintf('-------%3d epoch----------\n',k);
            % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
            for i=1:NUMBERS
                % 第三个用户前200轮迭代不参与，后400轮迭代不参与
                if i == 3
                    if time < MAX_ITER
                        continue
                    elseif time >= 2*MAX_ITER
                        BW(i) = 0;
                        continue;
                    end
                end
                new_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                BW(i) = new_bw;
                new_utility = cal_utility(i, new_bw, PRICE(i));
                UTILITY_History(i, time) = new_utility;
                fprintf('bw = %f, price = %f, utility = %f\n' ,BW(i), PRICE(i), new_utility);
            end
        end
        revenue = 0;
        for i=1:NUMBERS
            revenue = revenue + cal_revenue(BW(i), PRICE(i));
            BW_History(i, time) = BW(i);
            PRICE_History(i, time) = PRICE(i);
        end
        fprintf('network revenue = %f\n' , revenue);
        REVENUE_History(time) = revenue;
    end
	fprintf('----------ENDING-----------\n');
    x = [1:xrange];
    m = [1:20:xrange];
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
    global xrange;
    plot_pb = plot(x, PRICE_History(1, 1:xrange), 'g-', ...,
        x, PRICE_History(2, 1:xrange), 'k-', x, ...,
        PRICE_History(3, 1:xrange), 'b-', 'LineWidth', 1.5);
    hold on;
    plot_p_markers = plot(x(m), PRICE_History(1, m), 'g*', ...,
        x(m), PRICE_History(2, m), 'kx',  ...,
        x(m), PRICE_History(3, m), 'bp', 'MarkerSize',10);
    legend(plot_p_markers, {'ISP对用户1定价策略', 'ISP对用户2定价策略', 'ISP对用户3定价策略'}, 'Location', 'northwest', 'FontSize', 15);
    ylim([0 4]);
    xlabel('迭代次数','FontSize', 15);
    ylabel('价格','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_bw_dynamic(x, m, BW_History)
    global xrange;
    plot_pb = plot(x, BW_History(1, 1:xrange), 'r-', ...,
        x, BW_History(2, 1:xrange), 'c-', ...,
        x, BW_History(3, 1:xrange), 'm-', 'LineWidth', 1.5);
    hold on;
    plot_pb_markers = plot(x(m), BW_History(1, m), 'rd', ...,
        x(m), BW_History(2, m), 'c+', ...,
        x(m), BW_History(3, m), 'ms', 'MarkerSize',10);
    legend(plot_pb_markers, {'用户1带宽策略', '用户2带宽策略', '用户3带宽策略'}, 'Location', 'northeast', 'FontSize', 15);
    xlabel('迭代次数','FontSize', 15);
    ylabel('带宽','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_utility_dynamic(x, m, REVENUE_History, UTILITY_History)
    global xrange;
    plot_revenue = plot(x, REVENUE_History, 'r-', ...,
        x, UTILITY_History(1, 1:xrange), 'g-', ...,
        x, UTILITY_History(2, 1:xrange), 'b-', ...,
        x, UTILITY_History(3, 1:xrange), 'c-', 'LineWidth', 1.5);
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History(m), 'rd', ...,
        x(m), UTILITY_History(1, m), 'g*', ...,
        x(m), UTILITY_History(2, m), 'bx', ...,
        x(m), UTILITY_History(3, m), 'cp', 'MarkerSize',10);
    legend(plot_revenue_makers, {'ISP收益函数', '用户1效用函数', '用户2效用函数', '用户3效用函数'},'FontSize', 15);
    ylim([0 10]);
    xlabel('迭代次数','FontSize', 15);
    ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_theoretical_revenue_dynamic(x, m, REVENUE_History)
    global OPTIMAL_REVENUE_History;
    global xrange;
    plot_revenue = plot(x, OPTIMAL_REVENUE_History, 'k-', ...,
        x, REVENUE_History, 'r-', 'LineWidth', 1.5);
    hold on;
    plot_revenue_makers = plot(x(m), OPTIMAL_REVENUE_History(m), 'k*', ...,
        x(m), REVENUE_History(m), 'rd', 'MarkerSize',10);
    legend(plot_revenue_makers, {'逆向归纳法-ISP理论最大收益', '分布式迭代-ISP实际收益'},'FontSize', 15);
    ylim([0 10]);
    xlabel('迭代次数','FontSize', 15);
    ylabel('收益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function cal_optimal_revenue_history()
    global MAX_ITER;
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
    OPTIMAL_REVENUE_History(1:MAX_ITER) = revenue1;
    OPTIMAL_REVENUE_History(MAX_ITER+1:2*MAX_ITER) = revenue2;
    OPTIMAL_REVENUE_History(2*MAX_ITER+1:3*MAX_ITER) = revenue1;
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