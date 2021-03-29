% file_name = 'algorithm_comparison.mat';
file_name = 'algorithm_comparison_capacity_varied_20210329T184610.mat';
% file_name = 'algorithm_comparison_capacity_fixed_20210328T200238.mat';
load(file_name);

theo_file_name = 'algorithm_theo_capacity_varied_20210329T184610.mat';
load(theo_file_name);

ubp_valley_mean = mean([REVENUE_UBP_History(1:80), REVENUE_UBP_History(241:320), REVENUE_UBP_History(481:560)]);
dip_valley_mean = mean([REVENUE_DIP_History(1:80), REVENUE_DIP_History(241:320), REVENUE_DIP_History(481:560)]);
theo_valley_mean = mean([THEO_REVENUE(1:80), THEO_REVENUE(241:320), THEO_REVENUE(481:560)]);

ubp_mid_mean = mean([REVENUE_UBP_History(81:160), REVENUE_UBP_History(321:400), REVENUE_UBP_History(561:640)]);
dip_mid_mean = mean([REVENUE_DIP_History(81:160), REVENUE_DIP_History(321:400), REVENUE_DIP_History(561:640)]);
theo_mid_mean = mean([THEO_REVENUE(81:160), THEO_REVENUE(321:400), THEO_REVENUE(561:640)]);

ubp_peak_mean = mean([REVENUE_UBP_History(161:240), REVENUE_UBP_History(401:480), REVENUE_UBP_History(641:720)]);
dip_peak_mean = mean([REVENUE_DIP_History(161:240), REVENUE_DIP_History(401:480), REVENUE_DIP_History(641:720)]);
theo_peak_mean = mean([THEO_REVENUE(161:240), THEO_REVENUE(401:480), THEO_REVENUE(641:720)]);

fprintf('file_name: %s\n', file_name);
fprintf('ubp_valley_mean = %f\n', ubp_valley_mean);
fprintf('dip_valley_mean = %f\n', dip_valley_mean);
fprintf('valley promotion = %0.2f%% \n', 100*(dip_valley_mean-ubp_valley_mean)/ubp_valley_mean);
fprintf('theo_valley_mean = %f, ratio = %f\n', theo_valley_mean, dip_valley_mean/theo_valley_mean);

fprintf('ubp_mid_mean = %f\n', ubp_mid_mean);
fprintf('dip_mid_mean = %f\n', dip_mid_mean);
fprintf('mid promotion = %0.2f%% \n', 100*(dip_mid_mean-ubp_mid_mean)/ubp_mid_mean);
fprintf('theo_mid_mean = %f, ratio = %f\n', theo_mid_mean, dip_mid_mean/theo_mid_mean);

fprintf('ubp_peak_mean = %f\n', ubp_peak_mean);
fprintf('dip_peak_mean = %f\n', dip_peak_mean);
fprintf('peak promotion = %0.2f%% \n', 100*(dip_peak_mean-ubp_peak_mean)/ubp_peak_mean);
fprintf('theo_peak_mean = %f, ratio = %f\n', theo_peak_mean, dip_peak_mean/theo_peak_mean);

total_slot = 720;
ratio_history = zeros(1, total_slot);
for time=1:total_slot
    ratio_history(time) = 100*REVENUE_DIP_History(time)/THEO_REVENUE(time);
end

x = [1:total_slot];
m = [1:2:total_slot];
plot(x(m), THEO_REVENUE(m), 'k-', ...,
    x(m), REVENUE_DIP_History(m), 'r-', 'LineWidth', 1);
legend({'逆向归纳法-ISP理论最大收益', 'DIP-ISP实际收益'}, 'Location', 'northwest', 'FontSize', 15);
xticks([0:total_slot/9:total_slot]); % only available after R2016b(included)
%     set(gca, 'Xticks', [0:total_slot/9:total_slot]);
xticklabels([0:total_slot/90:total_slot/10]);
%     set(gca, 'XticksLabels', [0:total_slot/90:total_slot/10]);
% yticks([80 85 90 95 100]);
% yticklabels(['80%', '85%', '90%', '95%', '100%']);
xlim([0 total_slot]);
ylim([0 80]);
xlabel('时间（小时）','FontSize', 15);
ylabel('效益','FontSize', 15);
set(0,'DefaultFigureWindowStyle','docked');
