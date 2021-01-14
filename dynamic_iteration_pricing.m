% 先两个用户迭代，然后第100轮第三个用户加入
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10;
    global MAX_ITER; MAX_ITER = 500;
    global CAPACITY; CAPACITY = 10;
    global NUMBERS; NUMBERS = 3;
    global will; will = [2, 2, 2];
    global qos; qos = [1, 5, 1];
    global BW; BW = [0, 0, 0];
    global PRICE; PRICE = [0.1, 0.1, 0.0];
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
            % 第三个用户前一百轮迭代不参与
            if i == 3
                if time < 200
                    continue
                elseif time == 200
                    PRICE(i) = PRICE(min_distance_index());
                    fprintf('预测价格为%f\n', PRICE(i));
                    continue;
                end
            end
            PRICE(i) = PRICE(i) + max(0, price_step*cal_change_rate_p(i));
        end
        % 2. 单个用户通过迭代调节自己的带宽策略，直到自己的效用函数达到最大值，因为效用函数是凹函数，所以肯定会收敛
        for i=1:NUMBERS
            % 第三个用户前一百轮迭代不参与
            if i == 3 && time < 200
                continue
            end
            utility = cal_utility(i, BW(i), PRICE(i));
            next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
            next_utility = cal_utility(i, next_bw, PRICE(i));
            k = 1;
            %for k=1:MAX_ITER
            fprintf('-------%3d epoch----------\n',k);
            while abs(utility - next_utility) > 10^(-3)
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
        % 3. ISP收益函数不是凹函数，得看是否收敛
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
    savefig('D:\硕士毕设\matlab simulation\plot_utility_dynamic');
    figure;
    plot_price_dynamic(x, m, PRICE_History);
    savefig('D:\硕士毕设\matlab simulation\plot_price_dynamic');
    figure;
    plot_bw_dynamic(x, m, BW_History);
    savefig('D:\硕士毕设\matlab simulation\plot_bw_dynamic');
end

function plot_price_dynamic(x, m, PRICE_History)
    global MAX_ITER;
    plot_pb = plot(x, PRICE_History(1, 1:MAX_ITER), 'g-', ...,
        x, PRICE_History(2, 1:MAX_ITER), 'k-', x, PRICE_History(3, 1:MAX_ITER), 'b-');
    hold on;
    plot_pb_markers = plot(x(m), PRICE_History(1, m), 'g*', ...,
        x(m), PRICE_History(2, m), 'kx',  x(m), PRICE_History(3, m), 'bp');
    legend({'ISP对用户1定价策略', 'ISP对用户2定价策略', 'ISP对用户3定价策略'}, 'Location', 'northwest', 'FontSize', 10);
    xlabel('迭代次数','FontSize', 15);
    %ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
end

function plot_bw_dynamic(x, m, BW_History)
    global MAX_ITER;
    plot_pb = plot(x, BW_History(1, 1:MAX_ITER), 'r-', x, BW_History(2, 1:MAX_ITER), 'c-', ...,
        x, BW_History(3, 1:MAX_ITER), 'm-');
    hold on;
    plot_pb_markers = plot(x(m), BW_History(1, m), 'rd', x(m), BW_History(2, m), 'c+', x(m), BW_History(3, m), 'ms');
    legend({'用户1带宽策略', '用户2带宽策略', '用户3带宽策略'}, 'Location', 'northeast', 'FontSize', 10);
    xlabel('迭代次数','FontSize', 15);
    %ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
end

function plot_utility_dynamic(x, m, REVENUE_History, UTILITY_History)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History, 'r-', x, UTILITY_History(1, 1:MAX_ITER), ...,
        'g-', x, UTILITY_History(2, 1:MAX_ITER), 'b-', x, UTILITY_History(3, 1:MAX_ITER), 'c-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History(m), 'rd', ...,
        x(m), UTILITY_History(1, m), 'g*', x(m), UTILITY_History(2, m), 'bx', ...,
        x(m), UTILITY_History(3, m), 'cp');
    legend({'ISP收益函数', '用户1效用函数', '用户2效用函数', '用户3效用函数'},'FontSize', 10);
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
end

function rp=cal_change_rate_p(i)
    global BW;
    global CAPACITY;
    rp = BW(i);
    if sum(BW) < CAPACITY / 5
        rp = -rp;
    end
end

function index=min_distance_index()
    global BW;
    global CAPACITY;
    global will;
    global qos;
    global NUMBERS;
    min_d = 1000;
    index = 1;
    for i=1:NUMBERS-1
        d = sqrt((will(i)-will(NUMBERS)) ^ 2 + (qos(i)-qos(NUMBERS)) ^ 2);
        if d < min_d
            min_d = d;
            index = i;
        end
    end  
end