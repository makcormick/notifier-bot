# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
Rails.application.load_server

# ssh -i "notifier-key.pem" ubuntu@ec2-13-40-43-213.eu-west-2.compute.amazonaws.com
# nohup make dev > dev.out 2> dev.err &
# nohup make prod > prod.out 2> prod.err &
