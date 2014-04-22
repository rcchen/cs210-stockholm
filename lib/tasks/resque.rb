require 'resque/tasks'

namespace :resque do
  puts "Loading Rails environment for Resque"
  task :setup => :environment
  ActiveRecord::Base.send(:descendants).each { |klass|  klass.columns }
end

task 'resque:setup' do
	ENV['QUEUE'] = '*'
endw