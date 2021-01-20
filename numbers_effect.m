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
    revenue_trends = zeros(1, 10);
    x = [3:3:30];
    for num=x
        fprintf('-------------------%3d users----------------\n',num);
        % �ع��ʼ����
        BW = zeros(1, num);
        PRICE = 0.1*ones(1, num);
        NUMBERS = num;
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
        revenue_trends(num/3) = revenue;
    end
    fprintf('----------ENDING-----------\n');
    figure;
    plot_numbers_effect_on_revenue(x, revenue_trends);
    savefig('plot_numbers_effect_on_revenue');
end

function plot_numbers_effect_on_revenue(x, revenue_trends)
    plot_revenue = plot(x, revenue_trends, 'r-*');
    legend({'ISP����'},'FontSize', 15, 'Location', 'northwest');
    xlim([0 35]);
    xlabel('�û���','FontSize', 15);
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