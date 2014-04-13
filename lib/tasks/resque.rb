require 'resque/tasks'

task 'resque:setup' do
	ENV['QUEUE'] = '*'
endw