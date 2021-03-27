% CAPACITY=[10:1:30]���ĸ��û���̽����ʲ����״̬�²�ͬ���������Լ۸񡢴���ISP�����Ӱ��
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10������j��QoSָ��
    global CAPACITY; CAPACITY = 10;
    global MAX_ITER; MAX_ITER = 400; % capacity������������
    global MAX_EPOCH; MAX_EPOCH = 400; % �û�����������
    global will; will = [1, 2, 1, 2]; % �û�������Ը
    global qos; qos = [1, 1, 5, 5]; % 1~5���û���QoS������
    global NUMBERS; NUMBERS = length(will);
    global BW; BW = zeros(1, NUMBERS); % �����û�����ʼ�����Ϊ0
    global PRICE; PRICE = 0.1 * ones(1, NUMBERS); % ����j�ĳ�ʼ�۸񣬶����û�1��2����
    global earth; global purple; global deep_green; global ocean_blue; global grey_earth;
    earth = [204/255, 102/255, 0];
    purple = [102/255, 0, 204/255];
    deep_green = [0, 102/255, 0];
    ocean_blue = [0, 102/255, 204/255];
    grey_earth = [153/255, 153/255, 102/255];
    c_list = [10:30];
    c_num = length(c_list);
    REVENUE_History = zeros(1, c_num); % ISP������C�ı仯
    UTILITY_History = zeros(NUMBERS, c_num); % ���û�Ч����C�ı仯
    PRICE_History = zeros(NUMBERS, c_num);
    BW_History = zeros(NUMBERS, c_num);
    for c=c_list
        CAPACITY = c;
        fprintf('-------------------capacity=%3d----------------\n',c);
        for time=1:MAX_ITER
%             fprintf('-------------------%3d round----------------\n',time);
            % 1. ISP���¶��۲���
            for i=1:NUMBERS
                PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
            end
            for k=1:MAX_EPOCH
                %fprintf('-------%3d epoch----------\n',k);
                % 2. �����û�ͨ�����������Լ��Ĵ�����ԣ�ֱ���Լ���Ч�ú����ﵽ���ֵ����ΪЧ�ú����ǰ����������Կ϶�������
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
        % ��¼����
        REVENUE_History(c-9) = revenue;
        for i=1:NUMBERS
            UTILITY_History(i, c-9) = cal_utility(i, BW(i), PRICE(i));
            PRICE_History(i, c-9) = PRICE(i);
            BW_History(i, c-9) = BW(i);
        end
        % �ع��ʼ����
        BW = zeros(1, NUMBERS);
        PRICE = 0.1 * ones(1, NUMBERS);
    end
	fprintf('----------ENDING-----------\n');
    figure;
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    plot_diff_capacity_effect_on_price(c_list, c_num, PRICE_History);
    savefig('plot_diff_capacity_effect_on_price');
    figure;
    plot_diff_capacity_effect_on_bw(c_list, c_num, BW_History);
    savefig('plot_diff_capacity_effect_on_bw');
    figure;
    plot_diff_capacity_effect_on_utility(c_list, c_num, UTILITY_History);
    savefig('plot_diff_capacity_effect_on_utility');
    figure;
    plot_diff_capacity_effect_on_revenue(c_list, c_num, REVENUE_History);
    savefig('plot_diff_capacity_effect_on_revenue');
end

function plot_diff_capacity_effect_on_price(c_list, c_num, PRICE_History)
    global earth; global purple; global deep_green; global ocean_blue; global grey_earth;
    plot_p = plot(c_list, PRICE_History(1, 1:c_num), '-*', ..., 
        'color', deep_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(c_list, PRICE_History(2, 1:c_num), '-p', ...,
        'color', ocean_blue, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(c_list, PRICE_History(3, 1:c_num), '-d', ...,
        'color', earth, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(c_list, PRICE_History(4, 1:c_num), '->', ...,
        'color', purple, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'ISP���û�1(w=1,q=1)���۲���', 'ISP���û�2(w=2,q=1)���۲���', ...,
        'ISP���û�3(w=1,q=5)���۲���', 'ISP���û�4(w=2,q=5)���۲���'}, ...,
        'Location', 'northeast', 'FontSize', 15);
    xlabel('��������(Capacity)','FontSize', 15);
    ylabel('�۸�','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_capacity_effect_on_bw(c_list, c_num, BW_History)
    global earth; global purple; global deep_green; global ocean_blue; global grey_earth;
    plot_p = plot(c_list, BW_History(1, 1:c_num), '-*', ..., 
        'color', deep_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(c_list, BW_History(2, 1:c_num), '-p', ...,
        'color', ocean_blue, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(c_list, BW_History(3, 1:c_num), '-d', ...,
        'color', earth, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(c_list, BW_History(4, 1:c_num), '->', ...,
        'color', purple, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'�û�1(w=1,q=1)�������', '�û�2(w=2,q=1)�������', ...,
        '�û�3(w=1,q=5)�������', '�û�4(w=2,q=5)�������'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('��������(Capacity)','FontSize', 15);
    ylabel('����','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_capacity_effect_on_utility(c_list, c_num, UTILITY_History)
    global earth; global purple; global deep_green; global ocean_blue; global grey_earth;
    plot_p = plot(c_list, UTILITY_History(1, 1:c_num), '-*', ..., 
        'color', deep_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(c_list, UTILITY_History(2, 1:c_num), '-p', ...,
        'color', ocean_blue, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(c_list, UTILITY_History(3, 1:c_num), '-d', ...,
        'color', earth, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(c_list, UTILITY_History(4, 1:c_num), '->', ...,
        'color', purple, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'�û�1(w=1,q=1)Ч��', '�û�2(w=2,q=1)Ч��', ...,
        '�û�3(w=1,q=5)Ч��', '�û�4(w=2,q=5)Ч��'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('��������(Capacity)','FontSize', 15);
    ylabel('Ч��','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_capacity_effect_on_revenue(c_list, c_num, REVENUE_History)
    plot_revenue = plot(c_list, REVENUE_History, 'r-*', 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'ISP����'},'Location', 'northwest','FontSize', 15);
    xlabel('��������(Capacity)','FontSize', 15);
    ylabel('����','FontSize', 15);
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