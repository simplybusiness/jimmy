module Jimmy
  base = '0.4.12'

  # SB-specific versioning "algorithm" to accommodate BNW/Jenkins/gemstash
  VERSION = (pre = ENV.fetch('GEM_PRE_RELEASE', '')).empty? ? base : "#{base}.#{pre}"
end
