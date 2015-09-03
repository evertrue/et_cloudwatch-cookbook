require_relative '_helper'

class Chef
  class Resource::EtCloudWatchAlert < Resource::LWRPBase
    # Chef attributes
    identity_attr :name
    provides :et_cloudwatch_alert

    # Set the resource name
    self.resource_name = :et_cloudwatch_alert

    # Actions
    actions :create, :delete, :disable, :enable
    default_action :create

    # Required Attributes
    attribute :name,
              kind_of: String,
              name_attribute: true
    attribute :alarm_actions,
              kind_of: Array
    attribute :statistic,
              kind_of: String
    attribute :threshold,
              kind_of: Float
    attribute :comparison_operator,
              kind_of: String
    attribute :metric_name,
              kind_of: String

    # Optional Attributes
    attribute :access_key_id,
              kind_of: String
    attribute :secret_access_key,
              kind_of: String
    attribute :mock,
              kind_of: [TrueClass, FalseClass],
              default: false
    attribute :alarm_description,
              kind_of: String,
              default: 'Created with et_cloudwatch'
    attribute :ok_actions,
              kind_of: Array
    attribute :insufficient_data_actions,
              kind_of: Array
    attribute :unit,
              kind_of: String
    attribute :evaluation_periods,
              kind_of: Integer,
              default: 2
    attribute :period,
              kind_of: Integer,
              default: 300

    attr_writer :enabled, :exists

    #
    # Determine if the alert exists. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !@exists.nil? && @exists
    end

    #
    # Determine if the alert is enable. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def enabled?
      !@enabled.nil? && @enabled
    end
  end
end

class Chef
  class Provider::EtCloudWatchAlert < Provider::LWRPBase
    include EtCloudWatch::Helper

    def load_current_resource
      @current_resource ||= Resource::EtCloudWatchAlert.new(new_resource.name)
      @current_resource.send('name', new_resource.send('name'))

      if current_alert
        @current_resource.exists  = true
        @current_resource.enabled = (current_alert.actions_enabled == 'true')
      else
        @current_resource.exists  = false
        @current_resource.enabled = false
      end
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    action(:create) do
      validate_config!

      if current_resource.exists?
        Chef::Log.debug("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          put_metric_alarm
        end
      end

      if config_up_to_date?
        Chef::Log.debug("#{new_resource} config up to date - skipping")
      else
        converge_by("Update #{new_resource} config") do
          put_metric_alarm
        end
      end
    end

    action(:delete) do
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          fog_cw.delete_alarms(["#{node.name} #{new_resource.name}"])
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    action(:disable) do
      fail Chef::Exceptions::ResourceNotFound unless current_resource.exists?

      if current_resource.enabled?
        converge_by("Disable #{new_resource}") do
          fog_cw.disable_alarm_actions(["#{node.name} #{new_resource.name}"])
        end
      else
        Chef::Log.debug("#{new_resource} disabled - skipping")
      end
    end

    action(:enable) do
      fail Chef::Exceptions::ResourceNotFound unless current_resource.exists?

      if current_resource.enabled?
        Chef::Log.debug("#{new_resource} enabled - skipping")
      else
        converge_by("Enable #{new_resource}") do
          fog_cw.enable_alarm_actions(["#{node.name} #{new_resource.name}"])
        end
      end
    end

    private

    #
    # Returns the alert for the current resource
    #
    # @return [nil, Hash]
    #   nil if the alert does not exist, or the alert object if it does
    #
    def current_alert
      @current_alert ||= begin
        Chef::Log.debug "Load #{new_resource} alarm information"
        response = fog_cw.alarms.get("#{node.name} #{new_resource.name}")
        return nil if response.nil?

        response
      end
    end

    def config_up_to_date?
      return false unless current_alert.unit == new_resource.unit if new_resource.unit
      return false unless current_alert.alarm_actions == find_actions(new_resource.alarm_actions)
      return false unless current_alert.ok_actions == find_actions(new_resource.ok_actions) if new_resource.ok_actions
      if new_resource.insufficient_data_actions
        return false unless current_alert.insufficient_data_actions == find_actions(new_resource.insufficient_data_actions)
      end

      %w(alarm_description
         comparison_operator
         evaluation_periods
         metric_name
         period
         statistic
         threshold).each do |r|
        return false unless current_alert.send(r) == new_resource.send(r)
      end
    end

    #
    # Validates the specified options. This should do something some day
    #
    def validate_config!
      Chef::Log.debug "Validate #{new_resource} configuration"

      return true unless @action == :create
      %w(alarm_actions
         statistic
         threshold
         comparison_operator
         metric_name).each do |r|
        fail "et_cloudwatch missing required parameter #{r} for action #{@action}" if new_resource.send(r).nil?
      end
    end
  end
end

Chef::Platform.set(resource: :et_cloudwatch_alert,
                   provider: Chef::Provider::EtCloudWatchAlert)
