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
    global will; will = [1, 2]; % �û�������Ը
    global qos; qos = [1, 1]; % 1~5���û���QoS������
    global BW; BW = [0, 0]; % �����û�����ʼ�����Ϊ0
    global PRICE; PRICE = [0.1, 0.1]; % ����j�ĳ�ʼ�۸񣬶����û�1��2����
    pre_rev = 0;
    REVENUE_History = zeros(1, MAX_ITER);
    UTILITY_History = zeros(NUMBERS, MAX_ITER);
    UTILITY_Epoch_History = zeros(NUMBERS, MAX_ITER);
    PRICE_History = zeros(NUMBERS, MAX_ITER);
    BW_History = zeros(NUMBERS, MAX_ITER);
    for time=1:MAX_ITER
        fprintf('-------------------%3d round----------------\n',time);
        % 1. ISP���¶��۲���
        for i=1:NUMBERS
            PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
        end
        for k=1:MAX_ITER
%             fprintf('-------%3d epoch----------\n',k);
            % 2. �����û�ͨ�����������Լ��Ĵ�����ԣ�ֱ���Լ���Ч�ú����ﵽ���ֵ����ΪЧ�ú����ǰ����������Կ϶�������
            for i=1:NUMBERS
                new_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                BW(i) = new_bw;
                new_utility = cal_utility(i, new_bw, PRICE(i));
                UTILITY_History(i, time) = new_utility;
                fprintf('bw = %f, price = %f, utility = %f\n' ,new_bw, PRICE(i), new_utility);
                if time == 1
                    % �����û�epoch�������̣���Ϊ�������Ʊ���չʾ
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
    xlabel('�û���������(ISP Epoch��)','FontSize', 15);
    ylabel('�û�Ч��','FontSize', 15);
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
    legend(plot_pb_markers, {'ISP���û�1���۲���', 'ISP���û�2���۲���', ...,
        '�û�1�������', '�û�2�������'}, 'Location', 'northeast', 'FontSize', 15);
    xlabel('��������','FontSize', 15);
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
    legend(plot_revenue_makers, {'ISP����', '�û�1Ч��', ...,
        '�û�2Ч��'},'FontSize', 15);
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