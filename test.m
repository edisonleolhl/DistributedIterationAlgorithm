function main()
    time_slot = 0.1; % 时间槽为0.1h，为了便于仿真，放大十倍
    period_total_slot = 8 / time_slot; %一个时间段总共有80个时间槽
    days = 3; %三天
    total_slot = 3*days*period_total_slot;
    
    REVENUE_UBP_History = ones(1, total_slot);
    REVENUE_DIP_History = ones(1, total_slot);
    
    x = [1:total_slot];
    m = [1:2:total_slot];
    figure;
    plot(x(m), REVENUE_UBP_History(m), 'b-', ...,
        x(m), REVENUE_DIP_History(m), 'r-',  'LineWidth', 1.5);
    legend({'UBP-ISP收益', 'DIP-ISP收益'}, 'Location', 'northwest', 'FontSize', 15);
    xticks([0:total_slot/9:total_slot]); % only available after R2016b(included)
%     set(gca, 'Xticks', [0:total_slot/9:total_slot]);
    xticklabels([0:total_slot/90:total_slot/10]);
%     set(gca, 'XticksLabels', [0:total_slot/90:total_slot/10]);
    xlim([0 total_slot]);
    xlabel('时间（小时）','FontSize', 15);
    ylabel('效益','FontSize', 15);
    set(0,'DefaultFigureWindowStyle','docked');
end