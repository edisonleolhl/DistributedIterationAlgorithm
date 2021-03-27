% will=1.5��2.0���бȽϣ�̽����ʲ����״̬�²�ͬ���������Լ۸�������Ӱ��
% qos=1��3���бȽϣ�̽����ʲ����״̬�²�ͬ���������Լ۸�������Ӱ��
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10������j��QoSָ��
    global CAPACITY; CAPACITY = 100;
    global MAX_ITER; MAX_ITER = 200; % ����������
    global will; will = ones(1, 30); % �û�������Ը
    global qos; qos = ones(1, 30); % �û���QoS������
    global BW; BW = zeros(1, 30); % ��ʮ���û�����ʼ����Ϊ0
    global PRICE; PRICE = 0.1*ones(1, 30); % ����j�ĳ�ʼ�۸�
    global NUMBERS; NUMBERS = 3; % ��ʼ���������û�
    n_list = [3:30];
    n_num = length(n_list);
    revenue_trends = zeros(1, n_num);
    avg_price_trends = zeros(1, n_num);
    avg_bw_trends = zeros(1, n_num);
    avg_utility_trends = zeros(1, n_num);
    for num=n_list
        fprintf('-------------------%3d users----------------\n',num);
        NUMBERS = num;
        % �ع��ʼ������һ��Ҫ���޸�BW��PRICE����
        BW = zeros(1, num);
        PRICE = 0.1*ones(1, num);
        for time=1:MAX_ITER
            % fprintf('-------------------%3d round----------------\n',time);
            % 1. ISP���¶��۲���
            for i=1:NUMBERS
                PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
            end
            for k=1:MAX_ITER
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
        avg_price = mean(PRICE(1:NUMBERS));
        avg_bw = mean(BW(1:NUMBERS));
        avg_utility = cal_utility(1, avg_bw, avg_price); % w��q����ͬ������i=1����
        fprintf('avg_bw = %f, avg_price = %f\n' , avg_bw, avg_price);
        fprintf('avg_utility = %f, network revenue = %f\n' , avg_utility, revenue);
        avg_price_trends(num-2) = avg_price;
        avg_bw_trends(num-2) = avg_bw;
        avg_utility_trends(num-2) = avg_utility;
        revenue_trends(num-2) = revenue;
    end
    fprintf('----------ENDING-----------\n');
    figure;
    plot_numbers_effect_on_pb(n_list, avg_price_trends, avg_bw_trends);
    savefig('plot_numbers_effect_on_pb');
    figure;
    plot_numbers_effect_on_ru(n_list, revenue_trends, avg_utility_trends);
    savefig('plot_numbers_effect_on_ru');
end

function plot_numbers_effect_on_pb(x, avg_price_trends, avg_bw_trends)
    yyaxis left
    plot(x, avg_price_trends, 'b-p', 'LineWidth', 1.5, 'MarkerSize',10);
    yyaxis right
    plot(x, avg_bw_trends, 'r-*', 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'ISPƽ�����۲���', '�û�ƽ���������'}, ...,
        'FontSize', 15, 'Location', 'northwest');
    xlim([3 30]);
    yyaxis left
    ylabel('�۸�','FontSize', 15);
    yyaxis right
    ylabel('����','FontSize', 15);
    xlabel('�û���','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_numbers_effect_on_ru(x, revenue_trends, avg_utility_trends)
    yyaxis left
    plot(x, avg_utility_trends, 'b-p', 'LineWidth', 1.5, 'MarkerSize',10);
    yyaxis right
    plot(x, revenue_trends, 'r-*', 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'�û�ƽ��Ч��', 'ISP����'},'FontSize', 15, 'Location', 'north');
    xlabel('�û���','FontSize', 15);
    yyaxis left
    ylabel('Ч��','FontSize', 15);
    yyaxis right
    ylabel('����','FontSize', 15);
    xlim([3 30]);
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
    % �����������������������Լ����û��Ĵ���
    if sum(BW(1:NUMBERS)) > CAPACITY
        rb = -abs(rb);
    end
end

function rp=cal_change_rate_p(i)
    global BW;
    global CAPACITY;
    global NUMBERS;
    rp = BW(i);
    % ������̫С�����Լ��ټ۸��յ��û�������������
    if sum(BW(1:NUMBERS)) < CAPACITY / 5
        rp = -abs(rp);
    end
end