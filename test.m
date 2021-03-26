function main()
    % v: �û�i������Ե��ڲ���
    % w: ����j�ļ۸���Ե��ڲ���
    % e: ����ͨ��һ��С�ı仯��e(����e = 10-4)���������Ч�ò�����Ӱ��
    bw_step = 0.001;
    price_step = 0.001;
    global repu; repu = 10; % 1~10������j��QoSָ��
    global MAX_ITER; MAX_ITER = 400; % ����������
    global CAPACITY; CAPACITY = 10;
    global NUMBERS; NUMBERS = 2;
    global will; will = [2, 2]; % �û�������Ը
    global qos; qos = [1, 5]; % 1~5���û���QoS������
    global BW; BW = [0, 0]; % �����û�����ʼ�����Ϊ0
    global PRICE; PRICE = [0.1, 0.1]; % ����j�ĳ�ʼ�۸񣬶����û�1��2����
    pre_rev = 0;
    pre_utility = [0, 0];
    is_equil = [0, 0];
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
                if is_equil(i) == 1
                    break;
                end
                new_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                new_utility = cal_utility(i, new_bw, PRICE(i));
                % �жϸ��û��Ƿ��Ѵﵽ��ʲ����
                if abs(pre_utility(i) - new_utility) < 0.0001
                    is_equil(i) = 1;
                else
                    BW(i) = new_bw;
                    fprintf('bw = %f, price = %f, utility = %f\n' ,new_bw, PRICE(i), new_utility);
                    UTILITY_History(i, time) = new_utility;
                    pre_utility(i) = new_utility;
                end
                if time == 1
                    % ���ڵ�һ�ֵ����л����û�epoch�������̣���Ϊ�������Ʊ���չʾ
                    UTILITY_Epoch_History(i, k) = new_utility;
                end
            end
        end
        pre_utility = zeros(NUMBERS);
        is_equil = zeros(NUMBERS);
        revenue = 0;
        for i=1:NUMBERS
            revenue = revenue + cal_revenue(BW(i), PRICE(i));
        end
        fprintf('network revenue = %f\n' , revenue);
        if abs(pre_rev - revenue) < 0.001 * pre_rev
            for i=1:NUMBERS
                UTILITY_History(i, time+1:MAX_ITER) = UTILITY_History(i, time);
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
%     figure;
%     plot_utility_epoch(x, m, UTILITY_Epoch_History(1:NUMBERS, 1:MAX_ITER));
%     savefig('plot_utility_epoch');
    figure;
    plot_utility(x, m, REVENUE_History, UTILITY_History);
%     savefig('plot_utility');
end

function plot_utility_epoch(x, m, UTILITY_Epoch_History)
    global MAX_ITER;
    plot_revenue = plot(x, UTILITY_Epoch_History(1, 1:MAX_ITER), 'g-', ...,
        x, UTILITY_Epoch_History(2, 1:MAX_ITER), 'b-');
    hold on;
    plot_revenue_makers = plot(x(m), UTILITY_Epoch_History(1, m), 'g*', ...,
        x(m), UTILITY_Epoch_History(2, m), 'bp');
    legend(plot_revenue_makers, {'qos=1.0', 'qos=5.0'},  ...,
        'Location', 'southeast', 'FontSize', 15);
    xlabel('�û���������(ISP Epoch��)','FontSize', 15);
    ylabel('�û�Ч�ú���','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked')
end

function plot_utility(x, m, REVENUE_History, UTILITY_History)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History, 'r-', ...,
        x, UTILITY_History(1, 1:MAX_ITER), 'g-', ...,
        x, UTILITY_History(2, 1:MAX_ITER), 'b-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History(m), 'rd', ...,
        x(m), UTILITY_History(1, m), 'g*', ...,
        x(m), UTILITY_History(2, m), 'bx');
    legend(plot_revenue_makers, {'ISP���溯��', '�û�1Ч�ú���', ...,
        '�û�2Ч�ú���'},'FontSize', 15);
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