Dir[File.join(Rails.root, 'lib', 'core_ext', '*.rb')].each { |extension| require extension }
