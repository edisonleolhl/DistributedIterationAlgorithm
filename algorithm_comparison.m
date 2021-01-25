%�ȽϷֲ�ʽ�����㷨��UBP��ISP Revenue
%��������ʱ���[0,8),[8,16),[16,24)��ʱ�����Ϊ0.1h��ÿ��������ʱ����Ϊ0.1h
%Ϊ�˼򻯣�UBP�㷨����������ͬ�ļ۸񣬸���0��8��16�����Ϣ������������8��Сʱ�Ķ���
%DIA��ÿ��ʱ�������һ�Σ�ʵʱ����
function main()
    global REPUTATION; REPUTATION = 10;
    global CAPACITY; CAPACITY = 100; % ��������Ҫ��Ϊ�����׶Σ���С����1:2:4
    global bw_step; bw_step = 0.01;
    global price_step; price_step = 0.01;
    global MAX_ITER; MAX_ITER = 200; %TODO
    global MAX_EPOCH; MAX_EPOCH = 200;
    time_slot = 1; % ʱ���Ϊ0.1h��Ϊ�˱��ڷ��棬�Ŵ�ʮ��
    duration = 5; % ��������ʱ��������ʱ��ۣ�����Բ����㷨��̬������
    period_total_slot = 8 / 0.1; %һ��ʱ����ܹ���80��ʱ���
    peak = 400; % �����߷��ڣ�ÿСʱ400����
    mid = 200;
    valley = 100;
    will_valley = zeros(period_total_slot, valley / 10);
    qos_valley = zeros(period_total_slot, valley / 10);
    bw_valley = zeros(period_total_slot, valley / 10);
    UBP_numbers = 48; % 3��ÿ��Сʱ����һ�Σ�6��ÿ��Сʱ����һ��, ...
    UBP_new_pricing_slot = 0:period_total_slot/(UBP_numbers/3):period_total_slot-1; %���¶��۵�ʱ���
    % �Ȳ��Ե͹�ʱ�ڣ�ÿСʱ100������ÿ��ʱ���10����
    for time=0:period_total_slot-1 % ʱ��۴�0��ʼ
        fprintf('-------------------%3d time_slot----------------\n',time);
        % ��ǰʱ����¼����û���
        num = mid / 10;
        new_wills = round(rand(1, num), 1) + 1;
        new_qoss = round(4 * rand(1, num), 1) + 1;
        % ���뵽ʱ�����ʷ��
        will_valley(time+1, 1 : num) = new_wills; %matlab�±��1��ʼ
        qos_valley(time+1, 1 : num) = new_qoss;
        if find(UBP_new_pricing_slot == time)
            % UBP���¾���price
            if time + 1 - duration >= 0
                wills_mat = will_valley(time+2-duration : time+1, 1 : num);
                qoss_mat = qos_valley(time+2-duration : time+1, 1 : num);
            else
                wills_mat = will_valley(1 : time+1, 1 : num);
                qoss_mat = qos_valley(1 : time+1, 1 : num);
            end
            wills_vec = wills_mat(:);
            qoss_vec = qoss_mat(:);
            price = UBP(wills_vec, qoss_vec);
            
            % UBP��user������price�������Լ���bw
            if time + 1 - duration >= 0
                for t = time+2-duration : time+1
                    bws = user_epoch(will_valley(t, 1:num), qos_valley(t, 1:num), price);
                    bw_valley(t, 1 : num) = bws;
                end
                bw_mat = bw_valley(time+2-duration : time+1, 1 : num);
            else
                for t = 1 : time+1
                    bws = user_epoch(will_valley(t, 1:num), qos_valley(t, 1:num), price);
                    bw_valley(t, 1 : num) = bws;
                end
                bw_mat = bw_valley(1 : time + 1, 1 : num);
            end
        else
            % UBP����֮ǰprice
            bws = user_epoch(new_wills, new_qoss, price);
            bw_valley(time+1, 1 : num) = bws;
            if time + 1 - duration >= 0
                bw_mat = bw_valley(time+2-duration : time+1, 1 : num);
            else
                bw_mat = bw_valley(1 : time + 1, 1 : num);
            end
        end
        bw_vec = bw_mat(:);
        revenue_UBP = price*sum(bw_vec);
        fprintf('UBP network revenue = %f\n' , revenue_UBP);
        % DIA
        revenue_DIA = DIA(time, duration, num, will_valley, qos_valley);
        fprintf('DIA network revenue = %f\n' , revenue_DIA);
    end
end

function revenue_DIA = DIA(time, duration, num, will_valley, qos_valley)
    global MAX_ITER;
    global MAX_EPOCH;
    global bw_step;
    global price_step;
    if time + 1 - duration >= 0
        wills_mat = will_valley(time + 2 - duration : time + 1, 1 : num);
        qoss_mat = qos_valley(time + 2 - duration : time + 1, 1 : num);
    else
        wills_mat = will_valley(1 : time + 1, 1 : num);
        qoss_mat = qos_valley(1 : time + 1, 1 : num);
    end
    wills = wills_mat(:);
    qoss = qoss_mat(:);
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    prices = 0.1* ones(1, NUMBERS); % DIA�Ƿֱ𶨼�
    for iter=1:MAX_ITER
%         fprintf('-------------------%3d round----------------\n',iter);
        revenue_DIA = 0;
        % 1. ISP���¶��۲���
        for i=1:NUMBERS
            prices(i) = max(0, prices(i) + price_step*cal_change_rate_p(i, bws));
        end
        % 2. �����û�ͨ�����������Լ��Ĵ�����ԣ�ֱ���Լ���Ч�ú����ﵽ���ֵ����ΪЧ�ú����ǰ����������Կ϶�������
        for i=1:NUMBERS
            utility = cal_utility(i, wills, qoss, bws(i), prices(i));
            next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, prices(i)));
            next_utility = cal_utility(i, wills, qoss, next_bw, prices(i));
            for k=1:MAX_EPOCH
                bws(i) = next_bw;
                utility = next_utility;
                next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, prices(i)));
                next_utility = cal_utility(i, wills, qoss, next_bw, prices(i));
                k = k + 1;
            end
            revenue_DIA = revenue_DIA + cal_revenue(bws(i), prices(i));
        end
%         fprintf('network revenue = %f\n' , revenue_DIA);
    end
    fprintf('price = %f\n', prices(1));
end

function price = UBP(wills, qoss)
    global MAX_ITER;
    global MAX_EPOCH;
    global bw_step;
    global price_step;
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    price = 0.1; % UBP��ͳһ����
    for iter=1:MAX_ITER
%         fprintf('-------------------%3d round----------------\n',iter);
        revenue = 0;
        % 1. ISP���¶��۲���
        price = max(0, price + price_step*cal_change_rate_p_UBP(bws));
        % 2. �����û�ͨ�����������Լ��Ĵ�����ԣ�ֱ���Լ���Ч�ú����ﵽ���ֵ����ΪЧ�ú����ǰ����������Կ϶�������
        for i=1:NUMBERS
            utility = cal_utility(i, wills, qoss, bws(i), price);
            next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
            next_utility = cal_utility(i, wills, qoss, next_bw, price);
            for k=1:MAX_EPOCH
                bws(i) = next_bw;
                utility = next_utility;
                next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
                next_utility = cal_utility(i, wills, qoss, next_bw, price);
                k = k + 1;
            end
            revenue = revenue + cal_revenue(bws(i), price);
        end
%         fprintf('network revenue = %f\n' , revenue);
    end
    fprintf('price = %f\n' , price);
end

function bws = user_epoch(wills, qoss, price)
    % ���ڸ���price��NUMBERS���û�����Լ���Ч�ú����������������
    global MAX_EPOCH;
    global bw_step;
    NUMBERS = length(wills);
    bws = zeros(1, NUMBERS);
    for i=1:NUMBERS
        utility = cal_utility(i, wills, qoss, bws(i), price);
        next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
        next_utility = cal_utility(i, wills, qoss, next_bw, price);
        for k=1:MAX_EPOCH
            bws(i) = next_bw;
            utility = next_utility;
            next_bw = max(0, bws(i) + bw_step*cal_change_rate_b(i, wills, qoss, bws, price));
            next_utility = cal_utility(i, wills, qoss, next_bw, price);
            k = k + 1;
        end
%         fprintf('bw = %f, ' , bws(i));
    end
%     fprintf('\n');
end

function util=cal_utility(i, wills, qoss, b, p)
    global REPUTATION;
    util = wills(i)*log(1 + REPUTATION*qoss(i)*b) - p*b;
end

function reve=cal_revenue(b, p)
    reve = b*p;
end

function rb=cal_change_rate_b(i, wills, qoss, bws, price)
    global REPUTATION;
    global CAPACITY;
    rb = wills(i)*REPUTATION*qoss(i)/(1+REPUTATION*qoss(i)*bws(i)) - price;
    % �����������������������Լ����û��Ĵ���
    if sum(bws) > CAPACITY
        rb = -abs(rb);
    end
end

function rp=cal_change_rate_p(i, bws)
    global CAPACITY;
    rp = bws(i);
    % ������̫С�����Լ��ټ۸��յ��û�������������
    if sum(bws) < CAPACITY / 5
        rp = -abs(rp);
    end
end

function rp=cal_change_rate_p_UBP(bws)
    global CAPACITY;
    rp = sum(bws);
    % ������̫С�����Լ��ټ۸��յ��û�������������
    if sum(bws) < CAPACITY / 5
        rp = -abs(rp);
    end
end