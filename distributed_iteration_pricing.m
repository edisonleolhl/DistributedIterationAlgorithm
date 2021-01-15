function main()
    % v: �û�i������Ե��ڲ���
    % w: ����j�ļ۸���Ե��ڲ���
    % e: ����ͨ��һ��С�ı仯��e(����e = 10-4)���������Ч�ò�����Ӱ��
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10������j��QoSָ��
    global MAX_ITER; MAX_ITER = 200; % ����������
    global CAPACITY; CAPACITY = 10;
    global NUMBERS; NUMBERS = 2;
    global will; will = [2, 2]; % �û�������Ը
    global qos; qos = [1, 5]; % 1~5���û���QoS������
    global BW; BW = [0, 0]; % �����û�����ʼ�����Ϊ0
    global PRICE; PRICE = [0.1, 0.1]; % ����j�ĳ�ʼ�۸񣬶����û�1��2����
    REVENUE_History = zeros(1, MAX_ITER);
    UTILITY_History = zeros(NUMBERS, MAX_ITER);
    UTILITY_Epoch_History = zeros(NUMBERS, MAX_ITER);
    PRICE_History = zeros(NUMBERS, MAX_ITER);
    BW_History = zeros(NUMBERS, MAX_ITER);
    for time=1:MAX_ITER
        fprintf('-------------------%3d round----------------\n',time);
        revenue = 0;
        % 1. ISP���¶��۲���
        for i=1:length(BW)
            PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
        end
        % 2. �����û�ͨ�����������Լ��Ĵ�����ԣ�ֱ���Լ���Ч�ú����ﵽ���ֵ����ΪЧ�ú����ǰ����������Կ϶�������
        for i=1:length(BW)
            utility = cal_utility(i, BW(i), PRICE(i));
            next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
            next_utility = cal_utility(i, next_bw, PRICE(i));
            for k=1:MAX_ITER
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
    end
	fprintf('----------ENDING-----------\n');
    x = [1:MAX_ITER];
    m = [1:10:MAX_ITER];
    figure;
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    plot_utility_epoch(x, m, UTILITY_Epoch_History(1:NUMBERS, 1:MAX_ITER));
    savefig('D:\˶ʿ����\matlab simulation\plot_utility_epoch');
    figure;
    plot_utility(x, m, REVENUE_History, UTILITY_History);
    savefig('D:\˶ʿ����\matlab simulation\plot_utility');
    figure;
    plot_pb(x, m, PRICE_History, BW_History);
    savefig('D:\˶ʿ����\matlab simulation\plot_pb');
end

function plot_pb(x, m, PRICE_History, BW_History)
    global MAX_ITER;
    plot_pb = plot(x, PRICE_History(1, 1:MAX_ITER), 'g-', x, PRICE_History(2, 1:MAX_ITER), 'b-', x, BW_History(1, 1:MAX_ITER), 'r-', x, BW_History(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_pb_markers = plot(x(m), PRICE_History(1, m), 'g*', x(m), PRICE_History(2, m), 'bx', x(m), BW_History(1, m), 'rd', x(m), BW_History(2, m), 'cp');
    legend({'ISP���û�1���۲���', 'ISP���û�2���۲���', '�û�1�������', '�û�2�������'}, 'Location', 'northeast', 'FontSize', 15);
    xlabel('��������','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
end

function plot_utility_epoch(x, m, UTILITY_Epoch_History)
    global MAX_ITER;
    plot_revenue = plot(x, UTILITY_Epoch_History(1, 1:MAX_ITER), 'g-', x, UTILITY_Epoch_History(2, 1:MAX_ITER), 'b-');
    hold on;
    plot_revenue_makers = plot(x(m), UTILITY_Epoch_History(1, m), 'g*', x(m), UTILITY_Epoch_History(2, m), 'bp');
    legend({'qos=1.0', 'qos=5.0'}, 'Location', 'southeast', 'FontSize', 15);
    xlabel('�û���������(ISP Epoch��)','FontSize', 15);
    ylabel('�û�Ч�ú���','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
end

function plot_utility(x, m, REVENUE_History, UTILITY_History)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History, 'r-', x, UTILITY_History(1, 1:MAX_ITER), 'g-', x, UTILITY_History(2, 1:MAX_ITER), 'b-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History(m), 'rd', x(m), UTILITY_History(1, m), 'g*', x(m), UTILITY_History(2, m), 'bx');
    legend({'ISP���溯��', '�û�1Ч�ú���', '�û�2Ч�ú���'},'FontSize', 15);
    set(gca,'YTick',[1:16])
    xlabel('��������','FontSize', 15);
    ylabel('Ч��','FontSize', 15);
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
    % �����������������������Լ����û��Ĵ���
    if sum(BW) > CAPACITY
        rb = -abs(rb);
    end
end

function rp=cal_change_rate_p(i)
    global BW;
    global CAPACITY;
    rp = BW(i);
    % ������̫С�����Լ��ټ۸��յ��û�������������
    if sum(BW) < CAPACITY / 5
        rp = -abs(rp);
    end
end