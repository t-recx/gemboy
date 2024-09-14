# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "gemboy"

require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/hooks/default'

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]
