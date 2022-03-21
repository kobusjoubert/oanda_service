class ApplicationJob < ActiveJob::Base
  include Sneakers::Worker
end
