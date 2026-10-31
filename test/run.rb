# frozen_string_literal: true

# Runs every test: ruby test/run.rb
Dir[File.join(__dir__, "*_test.rb")].each { |file| require file }
