% willing=[1:0.1:2]��̽���û�������Ը��ISP�����Ӱ�죬����ʾ����user_effect('w')
% qos=[1:0.5:5]��̽���û�QoS�����ISP�����Ӱ������ʾ����user_effect('q')
function main(type)
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10������j��QoSָ��
    global CAPACITY; CAPACITY = 100;
    global MAX_ITER; MAX_ITER = 200; % ����������
    global NUMBERS; NUMBERS = 30;
    global will; will = ones(1, NUMBERS); % �û�������Ը
    global qos; qos = ones(1, NUMBERS); % �û���QoS������
    global BW; BW = zeros(1, NUMBERS); % ��ʮ���û�����ʼ����Ϊ0
    global PRICE; PRICE = 0.1*ones(1, NUMBERS); % ����j�ĳ�ʼ�۸�
    if type == 'w'
        x_list = [1:0.1:2]; % for willing
    elseif type == 'q'
        x_list = [1:0.5:5]; % for qos
    else
        fprintf('���ô���');
        return
    end
    x_num = length(x_list);
    revenue_trends = zeros(1, x_num);
    avg_price_trends = zeros(1, x_num);
    avg_bw_trends = zeros(1, x_num);
    avg_utility_trends = zeros(1, x_num);
    for x=x_list
        fprintf('-------------------x = %3d----------------\n',x);
        % �ع��ʼ����
        BW = zeros(1, NUMBERS);
        PRICE = 0.1*ones(1, NUMBERS);
        if type == 'w'
            will = x*ones(1, NUMBERS); % for willing
        else
            qos = x*ones(1, NUMBERS); % for qos
        end
        for time=1:MAX_ITER
            % fprintf('-------------------%3d round----------------\n',time);
            revenue = 0;
            % 1. ISP���¶��۲���
            for i=1:NUMBERS
                PRICE(i) = max(0, PRICE(i) + price_step*cal_change_rate_p(i));
            end
            % 2. �����û�ͨ�����������Լ��Ĵ�����ԣ�ֱ���Լ���Ч�ú����ﵽ���ֵ����ΪЧ�ú����ǰ����������Կ϶�������
            for i=1:NUMBERS
                utility = cal_utility(i, BW(i), PRICE(i));
                next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                next_utility = cal_utility(i, next_bw, PRICE(i));
                for k=1:MAX_ITER
                    %fprintf('-------%3d epoch----------\n',k);
                    BW(i) = next_bw;
                    utility = next_utility;
                    next_bw = max(0, BW(i) + bw_step*cal_change_rate_b(i));
                    next_utility = cal_utility(i, next_bw, PRICE(i));
                    k = k + 1;
                end
                revenue = revenue + cal_revenue(BW(i), PRICE(i));
            end
        end
        avg_price = mean(PRICE(1:NUMBERS));
        avg_bw = mean(BW(1:NUMBERS));
        avg_utility = cal_utility(1, avg_bw, avg_price); % w��q����ͬ������i=1����
        fprintf('avg_bw = %f, avg_price = %f\n' , avg_bw, avg_price);
        fprintf('avg_utility = %f\n' , avg_utility);
        fprintf('network revenue = %f\n' , revenue);
        if type == 'w'
            avg_price_trends(round(x*10-9)) = avg_price;
            avg_bw_trends(round(x*10-9)) = avg_bw;
            avg_utility_trends(round(x*10-9)) = avg_utility;
            revenue_trends(round(x*10-9)) = revenue;
        else
            avg_price_trends(round(x*2-1)) = avg_price;
            avg_bw_trends(round(x*2-1)) = avg_bw;
            avg_utility_trends(round(x*2-1)) = avg_utility;
            revenue_trends(round(x*2-1)) = revenue;
        end
    end
    fprintf('----------ENDING-----------\n');
    figure;
    plot_effect_on_pb(type, x_list, avg_price_trends, avg_bw_trends);
    figure;
    plot_effect_on_ru(type, x_list, revenue_trends, avg_utility_trends);
end

function plot_effect_on_pb(type, x, avg_price_trends, avg_bw_trends)
    yyaxis left
    plot(x, avg_price_trends, 'b-p');
    yyaxis right
    plot(x, avg_bw_trends, 'r-*');
    legend({'ISPƽ�����۲���', '�û�ƽ���������'}, ...,
        'FontSize', 15, 'Location', 'northwest');
    yyaxis left
    ylabel('�۸�','FontSize', 15);
    yyaxis right
    ylabel('����','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
    if type == 'w'
        xlim([1 2]);
        yyaxis right
        ylim([0.4 1]); % just for presentation
        xlabel('�û�������Ը','FontSize', 15);
        savefig('plot_will_effect_on_pb');
    else
        xlim([1 5]);
        yyaxis left
        ylim([1.3 1.5]); % just for presentation
        yyaxis right
        ylim([0.45 0.9]); % just for presentation
        xlabel('�û�QoS����','FontSize', 15);
        savefig('plot_qos_effect_on_pb');
    end
end

function plot_effect_on_ru(type, x, revenue_trends, avg_utility_trends)
    yyaxis left
    plot(x, avg_utility_trends, 'b-p');
    yyaxis right
    plot(x, revenue_trends, 'r-*');
    legend({'�û�ƽ��Ч��', 'ISP����'},'FontSize', 15, 'Location', 'northwest');
    yyaxis left
    ylabel('Ч��','FontSize', 15);
    yyaxis right
    ylabel('����','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
    if type == 'w'
        xlim([1 2]);
        xlabel('�û�������Ը','FontSize', 15);
        savefig('plot_will_effect_on_ru');
    else
        xlim([1 5]);
        xlabel('�û�QoS����','FontSize', 15);
        savefig('plot_qos_effect_on_ru');
    end
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