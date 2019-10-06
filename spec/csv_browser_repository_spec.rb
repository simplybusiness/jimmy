# frozen_string_literal: true

require 'spec_helper'

describe Jimmy::CSVBrowserRepository do
  describe '#find_by' do
    
    it 'when browser is found by user agent it returns the correct browser' do
      repository = described_class.new(csv: csv_buffer_from(two_browser_definitions_csv))
      browser = repository.find_by(user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/600.8.9 (KHTML, like Gecko) Version/8.0.8 Safari/600.8.9")
      expect(browser.attributes).to eq(
        capabilities: [],
        detected_addons: [],
        extra_info: {},
        extra_info_dict: {},
        hardware_sub_sub_type: nil,
        hardware_sub_type: nil,
        hardware_type: 'computer',
        hardware_type_specific: nil,
        layout_engine_name: 'WebKit',
        layout_engine_version: ['600', '8', '9'],
        operating_platform: nil,
        operating_platform_code: nil,
        operating_platform_vendor_name: nil,
        operating_system: 'Mac OS X (Yosemite)',
        operating_system_flavour: nil,
        operating_system_flavour_code: nil,
        operating_system_frameworks: [],
        operating_system_name: 'Mac OS X',
        operating_system_name_code: 'mac-os-x',
        operating_system_version: 'Yosemite',
        operating_system_version_full: '10.10.5',
        simple_operating_platform_string: nil,
        simple_software_string: 'Safari 8 on Mac OS X (Yosemite)',
        simple_sub_description_string: nil,
        software: 'Safari 8',
        software_name: 'Safari',
        software_name_code: 'safari',
        software_sub_type: 'web-browser',
        software_type: 'browser',
        software_type_specific: nil,
        software_version: '8',
        software_version_full: '8.0.8',
        user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/600.8.9 (KHTML, like Gecko) Version/8.0.8 Safari/600.8.9'
      )
    end
  end

  def csv_buffer_from(contents)
    buffer = StringIO.new(contents)
    buffer.rewind
    buffer
  end

  def two_browser_definitions_csv
    %Q{id,user_agent,times_seen,simple_software_string,simple_sub_description_string,simple_operating_platform_string,software,software_name,software_name_code,software_version,software_version_full,operating_system,operating_system_name,operating_system_name_code,operating_system_version,operating_system_version_full,operating_system_flavour,operating_system_flavour_code,operating_system_frameworks,operating_platform,operating_platform_code,operating_platform_vendor_name,software_type,software_sub_type,software_type_specific,hardware_type,hardware_sub_type,hardware_sub_sub_type,hardware_type_specific,layout_engine_name,layout_engine_version,extra_info,extra_info_dict,capabilities,detected_addons,first_seen_at,last_seen_at,updated_at
6,"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/600.8.9 (KHTML, like Gecko) Version/8.0.8 Safari/600.8.9",62506,Safari 8 on Mac OS X (Yosemite),,,Safari 8,Safari,safari,8,8.0.8,Mac OS X (Yosemite),Mac OS X,mac-os-x,Yosemite,10.10.5,,,[],,,,browser,web-browser,,computer,,,,WebKit,"[""600"", ""8"", ""9""]",{},{},[],[],2015-08-15 06:30:23.000000,2019-09-27 00:00:00.000000,NULL
25,"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.10240",87653,Edge 20 on Windows 10,,,Edge 20,Edge,edge,20,20.10240,Windows 10,Windows,windows,10,NT 10.0,,,[],,,,browser,web-browser,,computer,,,,EdgeHTML,"[""12"", ""10240""]","{""20"": [""64-bit Edition""]}","{""Hardware Architecture"": ""64-bit processor (AMD)""}",[],[],2015-07-31 00:40:57.000000,2019-09-28 06:01:00.909420,NULL}
  end
end
