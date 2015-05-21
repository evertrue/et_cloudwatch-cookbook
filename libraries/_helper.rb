module EtCloudWatch
  module Helper
    def put_metric_alarm
      alarm_options = {
        'AlarmName' => "#{node.name} #{new_resource.name}",
        'AlarmActions' => find_actions(new_resource.alarm_actions),
        'AlarmDescription' => new_resource.alarm_description,
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

      alarm_options['AlarmDescription'] = new_resource.alarm_description if new_resource.alarm_description
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
        run_context.include_recipe 'et_fog'
        require 'fog'

        Fog.mock! if new_resource.mock

        if new_resource.access_key_id
          opts = {
            aws_access_key_id: new_resource.access_key_id,
            aws_secret_access_key: new_resource.secret_access_key
          }
        else
          opts = { use_iam_profile: true }
        end

        Fog::AWS::CloudWatch.new opts
      end
    end

    def fog_sns
      @fog_sns ||= begin
        run_context.include_recipe 'et_fog'
        require 'fog'

        Fog.mock! if new_resource.mock

        if new_resource.access_key_id
          opts = {
            aws_access_key_id: new_resource.access_key_id,
            aws_secret_access_key: new_resource.secret_access_key
          }
        else
          opts = { use_iam_profile: true }
        end

        f = Fog::AWS::SNS.new opts

        # If we're mocking, create the needed topics in SNS first
        if new_resource.mock
          (new_resource.alarm_actions +
           (new_resource.ok_actions || []) +
           (new_resource.insufficient_data_actions || [])).uniq.each do |a|
            f.create_topic a
          end
        end

        f
      end
    end

    def setup_mock!
      Fog.mock!

    end
  end
end
