# frozen_string_literal: true
require 'test/unit'

# Guards the deferred `require 'time'` in OpenURI::Meta#last_modified. These
# run in a subprocess because this one has time loaded already.
class TestOpenURIRequire < Test::Unit::TestCase
  TIME_LOADED = '$LOADED_FEATURES.any? { |f| File.basename(f) == "time.rb" }'

  def subprocess(script)
    lib = File.expand_path('../../lib', __dir__)
    IO.popen([RbConfig.ruby, '-I', lib, '-e', script], &:read)
  end

  def test_requiring_open_uri_does_not_load_time
    assert_equal 'false', subprocess("require 'open-uri'; print #{TIME_LOADED}")
  end

  def test_last_modified_loads_time_and_parses
    script = "require 'open-uri'; " \
             "m = Object.new.extend(OpenURI::Meta); " \
             "m.instance_variable_set(:@metas, " \
             "  {'last-modified' => ['Fri, 07 Aug 2009 06:05:04 GMT']}); " \
             "print [m.last_modified == Time.utc(2009,8,7,6,5,4), #{TIME_LOADED}].join(',')"
    assert_equal 'true,true', subprocess(script)
  end

  def test_last_modified_without_the_header_does_not_load_time
    script = "require 'open-uri'; " \
             "m = Object.new.extend(OpenURI::Meta); " \
             "m.instance_variable_set(:@metas, {}); " \
             "print [m.last_modified.nil?, #{TIME_LOADED}].join(',')"
    assert_equal 'true,false', subprocess(script)
  end
end
