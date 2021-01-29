% will=[1:0.1:2.1]̽���û�������Ը��ISP�����Ӱ��
% qos=1��3���бȽϣ�̽���û�QoS�����ISP�����Ӱ��
function main()
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
%     x = [1:0.1:1.9]; % for will
    x = [1:0.5:5]; % for qos 
    revenue_trends = zeros(1, length(x));
    for w=x
        fprintf('-------------------w = %3d----------------\n',w);
        % �ع��ʼ����
        BW = zeros(1, NUMBERS);
        PRICE = 0.1*ones(1, NUMBERS);
        will = w*ones(1, 30);
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
                if time == MAX_ITER
                    fprintf('bw = %f, price = %f\n' ,BW(i), PRICE(i));
                end
            end
            if time == MAX_ITER
                fprintf('network revenue = %f\n' , revenue);
            end
        end
%         revenue_trends(round(w*10-9)) = revenue; % FOR will
        revenue_trends(round(w*2-1)) = revenue; % FOR qos
    end
    fprintf('----------ENDING-----------\n');
%     figure;
%     plot_will_effect_on_revenue(x, revenue_trends);
%     savefig('plot_will_effect_on_revenue');
    figure;
    plot_qos_effect_on_revenue(x, revenue_trends);
    savefig('plot_qos_effect_on_revenue');
    end

function plot_will_effect_on_revenue(x, revenue_trends)
    plot_revenue = plot(x, revenue_trends, 'r-*');
    legend({'ISP����'},'FontSize', 15, 'Location', 'northwest');
    xlim([0.9 2]);
    set(gca,'xtick', [0.9:0.1:2]);
    xlabel('�û�������Ը��willing��','FontSize', 15);
    ylabel('Ч��','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_qos_effect_on_revenue(x, revenue_trends)
    plot_revenue = plot(x, revenue_trends, 'r-*');
    legend({'ISP����'},'FontSize', 15, 'Location', 'northwest');
    xlim([0.5 5.5]);
    set(gca,'xtick', [0.5:0.5:5.5]);
    xlabel('�û�QoS����','FontSize', 15);
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