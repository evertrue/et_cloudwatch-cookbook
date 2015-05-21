et_cloudwatch_alert 'test alarm' do
  alarm_actions %w(critical_alerts)
  statistic 'Average'
  threshold 85.0
  comparison_operator 'GreaterThanOrEqualToThreshold'
  metric_name 'CPUUtilization'
end
