actions :create, :delete

attribute :name,
          kind_of: String,
          name_attribute: true
attribute :access_key_id,     kind_of: String,                  default: ''
attribute :secret_access_key, kind_of: String,                  default: ''
attribute :mock,              kind_of: [TrueClass, FalseClass], default: false
attribute :description, kind_of: String, default: 'Created with et_cloudwatch'
attribute :alarm_actions, kind_of: Array, required: true
attribute :ok_actions, kind_of: Array
attribute :insufficient_data_actions, kind_of: Array
attribute :statistic, kind_of: String, required: true
attribute :threshold, kind_of: Float, required: true
attribute :unit, kind_of: String
attribute :evaluation_periods, kind_of: Integer, default: 2
attribute :period, kind_of: Integer, default: 300
attribute :comparison_operator, kind_of: String, required: true
attribute :metric, kind_of: String, required: true
