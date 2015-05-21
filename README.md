![CloudWatch Logo](http://www.boundary.com/wp-content/themes/boundary2014/images/integrations/cloudwatch.png)

et_cloudwatch Cookbook
======================

Provides a resource called `et_cloudwatch_alarm` that sets up CloudWatch alarms targeted at the node where the resource has been applied.

Requirements
------------
* `et_fog` cookbook (installs Fog for AWS api calls)
* `AWS` - Obviously. CloudWatch being an AWS service and all.

Examples
--------
This will set up a CloudWatch alarm called "#{node.name} test alarm":

    et_cloudwatch_alert 'test alarm' do
      alarm_actions %w(critical_alerts)
      statistic 'Average'
      threshold 85.0
      comparison_operator 'GreaterThanOrEqualToThreshold'
      metric_name 'CPUUtilization'
    end

Before you can use this example, you must create an SNS topic called `critical_alerts`.

Resource Attributes
-------------------
* Parameters specific to this cookbook
    * `access_key_id`/`secret_access_key` - Used to specify AWS credentials. Leave these out to use an IAM profile instead.
    * `mock` - Run in mocking mode (e.g. for testing with Test Kitchen)
* Parameters implemented by AWS and documented [here](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-cw-alarm.html) (note that "List of Strings" is the equivalent of "array")
    * `alarm_description` - Defaults to "Created with et_cloudwatch"
    * `alarm_actions` - REQUIRED
    * `comparison_operator` - REQUIRED
    * `evaluation_periods` - Defaults to 2
    * `insufficient_data_actions`
    * `metric_name` - REQUIRED
    * `ok_actions`
    * `period` - Defaults to 300
    * `statistic` - REQUIRED
    * `threshold` - REQUIRED
    * `unit`

**A note about actions**: You have the option of either specifying the entire ARN for an [SNS](http://aws.amazon.com/sns/) topic OR you can specify just the actual name string (the part after the last colon) and the resource will try to determine the correct ARN automatically based on existing topics in your account.

Actions
-------
The following actions are available:

* `create` - Used in the example above
* `delete`
* `enable`
* `disable`

For *create*, *delete*, *enable*, and *disable*, only the name needs to be specified.

License & Authors
-----------------
* Author:: Eric Herot [eric.herot@evertrue.com](mailto:eric.herot@evertrue.com)

```text
Copyright:: 2015, EverTrue, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
