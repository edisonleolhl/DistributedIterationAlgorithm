% file_name = 'algorithm_comparison.mat';
% file_name = 'algorithm_comparison_capacity_varied_20210202T005104.mat';
file_name = 'algorithm_comparison_capacity_varied_20210202T090640.mat';
load(file_name);

ubp_valley_mean = mean([REVENUE_UBP_History(1:80), REVENUE_UBP_History(241:320), REVENUE_UBP_History(481:560)]);
dia_valley_mean = mean([REVENUE_DIA_History(1:80), REVENUE_DIA_History(241:320), REVENUE_DIA_History(481:560)]);
ubp_mid_mean = mean([REVENUE_UBP_History(81:160), REVENUE_UBP_History(321:400), REVENUE_UBP_History(561:640)]);
dia_mid_mean = mean([REVENUE_DIA_History(81:160), REVENUE_DIA_History(321:400), REVENUE_DIA_History(561:640)]);
ubp_peak_mean = mean([REVENUE_UBP_History(161:240), REVENUE_UBP_History(401:480), REVENUE_UBP_History(641:720)]);
dia_peak_mean = mean([REVENUE_DIA_History(161:240), REVENUE_DIA_History(401:480), REVENUE_DIA_History(641:720)]);

fprintf('file_name: %s\n', file_name);
fprintf('ubp_valley_mean = %f\n', ubp_valley_mean);
fprintf('dia_valley_mean = %f\n', dia_valley_mean);
fprintf('valley promotion = %0.2f%% \n', 100*(dia_valley_mean-ubp_valley_mean)/ubp_valley_mean);

fprintf('ubp_mid_mean = %f\n', ubp_mid_mean);
fprintf('dia_mid_mean = %f\n', dia_mid_mean);
fprintf('mid promotion = %0.2f%% \n', 100*(dia_mid_mean-ubp_mid_mean)/ubp_mid_mean);

fprintf('ubp_peak_mean = %f\n', ubp_peak_mean);
fprintf('dia_peak_mean = %f\n', dia_peak_mean);
fprintf('peak promotion = %0.2f%% \n', 100*(dia_peak_mean-ubp_peak_mean)/ubp_peak_mean);
