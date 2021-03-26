% repu=[10:1:30]���ĸ��û���̽����ʲ����״̬�²�ͬ���������Լ۸񡢴���ISP�����Ӱ��
function main()
    bw_step = 0.01;
    price_step = 0.01;
    global repu; repu = 10; % 1~10������j��QoSָ��
    global CAPACITY; CAPACITY = 20;
    global MAX_ITER; MAX_ITER = 500;
    global MAX_EPOCH; MAX_EPOCH = 500; % �û�����������
    global will; will = [1, 1.25, 1.5, 1.75, 2]; % �û�������Ը
    global qos; qos = [1, 1, 1, 1, 1]; % 1~5���û���QoS������
    global NUMBERS; NUMBERS = length(will);
    global BW; BW = zeros(1, NUMBERS); % �����û�����ʼ�����Ϊ0
    global PRICE; PRICE = 0.1 * ones(1, NUMBERS); % ����j�ĳ�ʼ�۸񣬶����û�1��2����
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    orange = [1, 153/255, 0];
    deep_red = [204/255, 51/255, 0];
    blue_purple = [51/255, 51/255, 204/255];
    grey_green = [51/255, 153/255, 102/255];
    dark_yellow = [204/255, 204/255, 0];
    red_purple = [204/255, 51/255, 153/255];
    r_list = [5:0.5:10];
    r_num = length(r_list);
    REVENUE_History = zeros(1, r_num); % ISP������r�ı仯
    UTILITY_History = zeros(NUMBERS, r_num); % ���û�Ч����r�ı仯
    PRICE_History = zeros(NUMBERS, r_num);
    BW_History = zeros(NUMBERS, r_num);
    for r=r_list
        fprintf('-------------------repu=%3d----------------\n',r);
        repu = r;
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
        REVENUE_History(r*2-9) = revenue;
        for i=1:NUMBERS
            UTILITY_History(i, r*2-9) = cal_utility(i, BW(i), PRICE(i));
            PRICE_History(i, r*2-9) = PRICE(i);
            BW_History(i, r*2-9) = BW(i);
        end
        % �ع��ʼ����
        BW = zeros(1, NUMBERS);
        PRICE = 0.1 * ones(1, NUMBERS);
    end
	fprintf('----------ENDING-----------\n');
    % MarkerIndices became available in R2016b version.
    % The workaround is plotting two times:
    figure;
    plot_diff_repu_effect_on_price(r_list, r_num, PRICE_History);
    savefig('plot_diff_repu_effect_on_price');
    figure;
    plot_diff_repu_effect_on_bw(r_list, r_num, BW_History);
    savefig('plot_diff_repu_effect_on_bw');
    figure;
    plot_diff_repu_effect_on_utility(r_list, r_num, UTILITY_History);
    savefig('plot_diff_repu_effect_on_utility');
    figure;
    plot_diff_repu_effect_on_revenue(r_list, r_num, REVENUE_History);
    savefig('plot_diff_repu_effect_on_revenue');
end

function plot_diff_repu_effect_on_price(r_list, r_num, PRICE_History)
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    plot_p = plot(r_list, PRICE_History(1, 1:r_num), '-*', ..., 
        'color', orange, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(r_list, PRICE_History(2, 1:r_num), '-p', ...,
        'color', deep_red, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(r_list, PRICE_History(3, 1:r_num), '-d', ...,
        'color', blue_purple, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(r_list, PRICE_History(4, 1:r_num), '->', ...,
        'color', grey_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p4 = plot(r_list, PRICE_History(5, 1:r_num), '-o', ...,
        'color', dark_yellow, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'ISP���û�1(w=1.00)���۲���', 'ISP���û�2(w=1.25)���۲���', ...,
        'ISP���û�3(w=1.50)���۲���', 'ISP���û�4(w=1.75)���۲���', 'ISP���û�5(w=2.00)���۲���'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('��������(Reputation)','FontSize', 15);
    ylabel('�۸�','FontSize', 15);
    ylim([1.2 2.2]); % just for presentation
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_repu_effect_on_bw(r_list, r_num, BW_History)
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    plot_p = plot(r_list, BW_History(1, 1:r_num), '-*', ..., 
        'color', orange, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(r_list, BW_History(2, 1:r_num), '-p', ...,
        'color', deep_red, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(r_list, BW_History(3, 1:r_num), '-d', ...,
        'color', blue_purple, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(r_list, BW_History(4, 1:r_num), '->', ...,
        'color', grey_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p4 = plot(r_list, BW_History(5, 1:r_num), '-o', ...,
        'color', dark_yellow, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'�û�1(w=1.00)�������', '�û�2(w=1.25)�������', ...,
        '�û�3(w=1.50)�������', '�û�4(w=1.75)�������', '�û�5(w=2.00)�������'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('��������(Reputation)','FontSize', 15);
    ylabel('����','FontSize', 15);
    ylim([0.5 1.2]); % just for presentation
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_repu_effect_on_utility(r_list, r_num, UTILITY_History)
    global orange; global deep_red; global blue_purple; global grey_green; global dark_yellow; global red_purple;
    plot_p = plot(r_list, UTILITY_History(1, 1:r_num), '-*', ..., 
        'color', orange, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p1 = plot(r_list, UTILITY_History(2, 1:r_num), '-p', ...,
        'color', deep_red, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p2 = plot(r_list, UTILITY_History(3, 1:r_num), '-d', ...,
        'color', blue_purple, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p3 = plot(r_list, UTILITY_History(4, 1:r_num), '->', ...,
        'color', grey_green, 'LineWidth', 1.5, 'MarkerSize',10); hold on;
    plot_p4 = plot(r_list, UTILITY_History(5, 1:r_num), '-o', ...,
        'color', dark_yellow, 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'�û�1(w=1.00)Ч��', '�û�2(w=1.25)Ч��', ...,
        '�û�3(w=1.50)Ч��', '�û�4(w=1.75)Ч��', '�û�5(w=2.00)Ч��'}, ...,
        'Location', 'northwest', 'FontSize', 15);
    xlabel('��������(Reputation)','FontSize', 15);
    ylabel('Ч��','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end

function plot_diff_repu_effect_on_revenue(r_list, r_num, REVENUE_History)
    plot_revenue = plot(r_list, REVENUE_History, 'r-*', 'LineWidth', 1.5, 'MarkerSize',10);
    legend({'ISP����'},'Location', 'northwest','FontSize', 10);
    xlabel('��������(Reputation))','FontSize', 15);
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