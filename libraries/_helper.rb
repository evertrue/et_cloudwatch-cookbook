module EtCloudWatch
  module Helper
    def put_metric_alarm
      alarm_options = {
        'AlarmName' => "#{node.name} #{new_resource.name}",
        'AlarmActions' => find_actions(new_resource.alarm_actions),
        'AlarmDescription' => new_resource.description,
        'ComparisonOperator' => new_resource.comparison_operator,
        'Dimensions' => [{ "Name" => "InstanceId",
                           "Value" => node['ec2']['instance_id'] }],
        'EvaluationPeriods' => new_resource.evaluation_periods,
        'MetricName' => new_resource.metric_name,
        'Namespace' => 'AWS/EC2',
        'OKActions' => new_resource.ok_actions,
        'Period' => new_resource.period,
        'Statistic' => new_resource.statistic,
        'Threshold' => new_resource.threshold
      }

      alarm_options['AlarmDescription'] = new_resource.description if new_resource.description
      alarm_options['OKActions'] = find_actions(new_resource.ok_actions) if new_resource.ok_actions
      alarm_options['Unit'] = new_resource.unit if new_resource.unit

      if new_resource.insufficient_data_actions
        alarm_options['InsufficientDataActions'] = find_actions(new_resource.insufficient_data_actions)
      end

      fog_cw.put_metric_alarm alarm_options
    end

    def find_actions(actions)
      actions.map do |a|
        if a =~ /^arn:/
          r = sns_topics.find { |t| t.id == a }
          r || fail("SNS Topic #{a} does not exist")
        else
          r = sns_topics.select { |t| t.id =~ /:#{a}$/ }.map(&:id)
          fail "Action #{a} not found among SNS topics" if r.empty?
          r
        end
      end.flatten
    end

    def sns_topics
      @sns_topics ||= fog_sns.topics
    end

    def fog_cw
      @fog_cw ||= begin
        require 'fog'

        Fog::AWS::CloudWatch.new(aws_access_key_id: new_resource.access_key_id,
                                 aws_secret_access_key: new_resource.secret_access_key)
      end
    end

    def fog_sns
      @fog_sns ||= begin
        require 'fog'

        Fog::AWS::SNS.new(aws_access_key_id: new_resource.access_key_id,
                          aws_secret_access_key: new_resource.secret_access_key)
      end
    end
  end
end
