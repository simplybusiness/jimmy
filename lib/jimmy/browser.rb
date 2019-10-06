# frozen_string_literal: true

module Types
  include Dry.Types()
end

module Jimmy
  class Browser < Dry::Struct
    attribute :user_agent, Types::String.optional
    attribute :times_seen, Types::String.optional
    attribute :simple_software_string, Types::String.optional
    attribute :simple_sub_description_string, Types::String.optional
    attribute :simple_operating_platform_string, Types::String.optional
    attribute :software, Types::String.optional
    attribute :software_name, Types::String.optional
    attribute :software_name_code, Types::String.optional
    attribute :software_version, Types::String.optional
    attribute :software_version_full, Types::String.optional
    attribute :operating_system, Types::String.optional
    attribute :operating_system_name, Types::String.optional
    attribute :operating_system_name_code, Types::String.optional
    attribute :operating_system_version, Types::String.optional
    attribute :operating_system_version_full, Types::String.optional
    attribute :operating_system_flavour, Types::String.optional
    attribute :operating_system_flavour_code, Types::String.optional
    attribute :operating_system_frameworks, Types::Array
    attribute :operating_platform, Types::String.optional
    attribute :operating_platform_code, Types::String.optional
    attribute :operating_platform_vendor_name, Types::String.optional
    attribute :software_type, Types::String.optional
    attribute :software_sub_type, Types::String.optional
    attribute :software_type_specific, Types::String.optional
    attribute :hardware_type, Types::String.optional
    attribute :hardware_sub_type, Types::String.optional
    attribute :hardware_sub_sub_type, Types::String.optional
    attribute :hardware_type_specific, Types::String.optional
    attribute :layout_engine_name, Types::String.optional
    attribute :layout_engine_version, Types::Array
    attribute :extra_info, Types::Hash
    attribute :extra_info_dict, Types::Hash
    attribute :capabilities, Types::Array
    attribute :detected_addons, Types::Array
    attribute :first_seen_at, Types::String.optional
    attribute :last_seen_at, Types::String.optional
  end
end
