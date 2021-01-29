% CAPACITY=10��5���бȽϣ�̽����ʲ����״̬�²�ͬ���������Լ۸�������Ӱ��
% repu=10��5���бȽϣ�̽����ʲ����״̬�²�ͬ���������Լ۸�������Ӱ��
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10������j��QoSָ��
    global CAPACITY; CAPACITY = 10;
%     global MAX_ITER; MAX_ITER = 400; % capacity������������
    global MAX_ITER; MAX_ITER = 200; % reputation������������
    global MAX_EPOCH; MAX_EPOCH = 400; % �û�����������
    global NUMBERS; NUMBERS = 2;
    global will; will = [1.5, 2]; % �û�������Ը
    global qos; qos = [1, 1]; % 1~5���û���QoS������
    global BW; BW = [0, 0]; % �����û�����ʼ�����Ϊ0
    global PRICE; PRICE = [0.1, 0.1]; % ����j�ĳ�ʼ�۸񣬶����û�1��2����
    REVENUE_History_1 = zeros(1, MAX_ITER); %��ͬ��c��r
    REVENUE_History_2 = zeros(1, MAX_ITER); %��ͬ��c��r
    UTILITY_History_1 = zeros(NUMBERS, MAX_ITER); %�����û������Ƕ�ά
    UTILITY_History_2 = zeros(NUMBERS, MAX_ITER);
    PRICE_History_1 = zeros(NUMBERS, MAX_ITER);
    PRICE_History_2 = zeros(NUMBERS, MAX_ITER);
    BW_History_1 = zeros(NUMBERS, MAX_ITER);
    BW_History_2 = zeros(NUMBERS, MAX_ITER);
    for time=1:2*MAX_ITER
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
            for k=1:MAX_EPOCH
                %fprintf('-------%3d epoch----------\n',k);
                BW(i) = next_bw;
                utility = next_utility;
                next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                next_utility = cal_utility(i, next_bw, PRICE(i));
                % fprintf('user = %d, bw = %f, utility = %f\n', i, BW(i), utility);
                k = k + 1;
            end
            revenue = revenue + cal_revenue(BW(i), PRICE(i));
            fprintf('bw = %f, price = %f\n' ,BW(i), PRICE(i));
            if time <= MAX_ITER
                UTILITY_History_1(i, time) = utility;
                BW_History_1(i, time) = BW(i);
            else
                UTILITY_History_2(i, time-MAX_ITER) = utility;
                BW_History_2(i, time-MAX_ITER) = BW(i);
            end
        end
        fprintf('network revenue = %f\n' , revenue);
        if time <= MAX_ITER
            REVENUE_History_1(time) = revenue;
            PRICE_History_1(1, time) = PRICE(1);
            PRICE_History_1(2, time) = PRICE(2);
        else
            REVENUE_History_2(time-MAX_ITER) = revenue;
            PRICE_History_2(1, time-MAX_ITER) = PRICE(1);
            PRICE_History_2(2, time-MAX_ITER) = PRICE(2);            
        end
        if time == MAX_ITER
            % �ع��ʼ����
            BW = [0, 0];
            PRICE = [0.1, 0.1];
%             CAPACITY = 5;
            repu = 5;
        end
    end
	fprintf('----------ENDING-----------\n');
    x = [1:MAX_ITER];
    figure;
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    % ----------plot capacity effect----------
%     m = [1:20:MAX_ITER];
%     plot_capacity_effect_on_price(x, m, PRICE_History_1, PRICE_History_2);
%     savefig('plot_capacity_effect_on_price');
%     figure;
%     plot_capacity_effect_on_bw(x, m, BW_History_1, BW_History_2);
%     savefig('plot_capacity_effect_on_bw');
%     figure;
%     plot_capacity_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2);
%     savefig('plot_capacity_effect_on_revenue');
    % ----------plot repu effect----------
    m = [1:10:MAX_ITER];
    plot_repu_effect_on_price(x, m, PRICE_History_1, PRICE_History_2);
    savefig('plot_repu_effect_on_price');
    figure;
    plot_repu_effect_on_bw(x, m, BW_History_1, BW_History_2);
    savefig('plot_repu_effect_on_bw');
    figure;
    plot_repu_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2);
    savefig('plot_repu_effect_on_revenue');
end

function plot_capacity_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History_1, 'b-', ...,
        x, REVENUE_History_2, 'r-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History_1(m), 'b*', ...,
        x(m), REVENUE_History_2(m), 'rd');
    legend(plot_revenue_makers, {'C=10, ISP����', 'C=5, ISP����'},'FontSize', 10);
    set(gca,'YTick',[1:16])
    xlabel('��������','FontSize', 15);
    ylabel('����','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_capacity_effect_on_price(x, m, PRICE_History_1, PRICE_History_2)
    global MAX_ITER;
    plot_p = plot(x, PRICE_History_1(1, 1:MAX_ITER), 'g-', x, PRICE_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, PRICE_History_2(1, 1:MAX_ITER), 'm-', x, PRICE_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_p_markers = plot(x(m), PRICE_History_1(1, m), 'g*', x(m), PRICE_History_1(2, m), 'bx', ...,
        x(m), PRICE_History_2(1, m), 'mp', x(m), PRICE_History_2(2, m), 'cd');
    legend(plot_p_markers, {'C=10, ISP���û�1���۲���', 'C=10, ISP���û�2���۲���', ...,
        'C=5, ISP���û�1���۲���', 'C=5, ISP���û�2���۲���'}, ...,
        'Location', 'southeast', 'FontSize', 10);
    xlabel('��������','FontSize', 15);
    ylabel('�۸�','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_capacity_effect_on_bw(x, m, BW_History_1, BW_History_2)
    global MAX_ITER;
    plot_bw = plot(x, BW_History_1(1, 1:MAX_ITER), 'g-', x, BW_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, BW_History_2(1, 1:MAX_ITER), 'm-', x, BW_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_bw_markers = plot(x(m), BW_History_1(1, m), 'g*', x(m), BW_History_1(2, m), 'bx', ...,
        x(m), BW_History_2(1, m), 'mp', x(m), BW_History_2(2, m), 'cd');
    legend(plot_bw_markers, {'C=10, �û�1�������', 'C=10, �û�2�������', ...,
        'C=5, �û�1�������', 'C=5, �û�2�������'}, ...,
        'Location', 'northeast', 'FontSize', 10);
    xlabel('��������','FontSize', 15);
    ylabel('����','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_repu_effect_on_price(x, m, PRICE_History_1, PRICE_History_2)
    global MAX_ITER;
    plot_p = plot(x, PRICE_History_1(1, 1:MAX_ITER), 'g-', x, PRICE_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, PRICE_History_2(1, 1:MAX_ITER), 'm-', x, PRICE_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_p_markers = plot(x(m), PRICE_History_1(1, m), 'g*', x(m), PRICE_History_1(2, m), 'bx', ...,
        x(m), PRICE_History_2(1, m), 'mp', x(m), PRICE_History_2(2, m), 'cd');
    legend(plot_p_markers, {'r=10, ISP���û�1���۲���', 'r=10, ISP���û�2���۲���', ...,
        'r=5, ISP���û�1���۲���', 'r=5, ISP���û�2���۲���'}, ...,
        'Location', 'southeast', 'FontSize', 10);
    xlabel('��������','FontSize', 15);
    ylabel('�۸�','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_repu_effect_on_bw(x, m, BW_History_1, BW_History_2)
    global MAX_ITER;
    plot_pb = plot(x, BW_History_1(1, 1:MAX_ITER), 'g-', x, BW_History_1(2, 1:MAX_ITER), 'b-', ...,
        x, BW_History_2(1, 1:MAX_ITER), 'm-', x, BW_History_2(2, 1:MAX_ITER), 'c-');
    hold on;
    plot_pb_markers = plot(x(m), BW_History_1(1, m), 'g*', x(m), BW_History_1(2, m), 'bx', ...,
        x(m), BW_History_2(1, m), 'mp', x(m), BW_History_2(2, m), 'cd');
    legend(plot_pb_markers, {'r=10, �û�1�������', 'r=10, �û�2�������', ...,
        'r=5, �û�1�������', 'r=5, �û�2�������'}, ...,
        'Location', 'northeast', 'FontSize', 10);
    xlabel('��������','FontSize', 15);
    ylabel('����','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_repu_effect_on_revenue(x, m, REVENUE_History_1, REVENUE_History_2)
    global MAX_ITER;
    plot_revenue = plot(x, REVENUE_History_1, 'b-', ...,
        x, REVENUE_History_2, 'r-');
    hold on;
    plot_revenue_makers = plot(x(m), REVENUE_History_1(m), 'b*', ...,
        x(m), REVENUE_History_2(m), 'rd');
    legend(plot_revenue_makers, {'r=10, ISP����', 'r=5, ISP����'},'FontSize', 10);
    set(gca,'YTick',[1:16])
    xlabel('��������','FontSize', 15);
    ylabel('Ч��','FontSize', 15);
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