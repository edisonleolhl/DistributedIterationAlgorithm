function main()
    time_slot = 0.1; % ʱ���Ϊ0.1h��Ϊ�˱��ڷ��棬�Ŵ�ʮ��
    period_total_slot = 8 / time_slot; %һ��ʱ����ܹ���80��ʱ���
    days = 3; %����
    total_slot = 3*days*period_total_slot;
    
    REVENUE_UBP_History = ones(1, total_slot);
    REVENUE_DIP_History = ones(1, total_slot);
    
    x = [1:total_slot];
    m = [1:2:total_slot];
    figure;
    plot(x(m), REVENUE_UBP_History(m), 'b-', ...,
        x(m), REVENUE_DIP_History(m), 'r-',  'LineWidth', 1.5);
    legend({'UBP-ISP����', 'DIP-ISP����'}, 'Location', 'northwest', 'FontSize', 15);
    xticks([0:total_slot/9:total_slot]); % only available after R2016b(included)
%     set(gca, 'Xticks', [0:total_slot/9:total_slot]);
    xticklabels([0:total_slot/90:total_slot/10]);
%     set(gca, 'XticksLabels', [0:total_slot/90:total_slot/10]);
    xlim([0 total_slot]);
    xlabel('ʱ�䣨Сʱ��','FontSize', 15);
    ylabel('Ч��','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end