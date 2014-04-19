$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/autorun'
require 'activeresource/ldp'

RSpec.configure do |config|

end
