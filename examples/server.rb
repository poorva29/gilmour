# encoding: utf-8
require 'gilmour'

class EventServer
  include Gilmour::Base

  def initialize(backend)
    enable_backend(backend, { host: 'localhost', exchange: 'fib' })
    registered_subscribers.each do |sub|
      sub.backend = backend
    end
    $stderr.puts "Starting server. To see messaging in action run clients."
    start(true)
  end
end

class EchoSubscriber < EventServer
  # Passing second parameter as true makes only one instance of this handler handle a request

  listen_to 'foo.*' do
    if request.body 
      $stderr.puts '***'
      respond 'cool'
    end	  
  end

  listen_to 'echo.*', true do
    if request.body == 'Palmolive'
      respond nil
    else
      $stderr.puts request.body
      respond "#{request.topic}"
    end
  end
end

class FibonacciSubscriber < EventServer
  class << self
    attr_accessor :last
  end

  listen_to 'fib.next' do
    old = FibonacciSubscriber.last
    FibonacciSubscriber.last = new = request.body
    respond(old + new)
  end

  listen_to 'fib.init' do
    FibonacciSubscriber.last = request.body
  end

end

def usage(s)
  $stderr.puts(s)
  $stderr.puts("Usage: #{File.basename($0)} [backend to use: 'redis' or 'amqp']")
  exit(2)
end

usage("Please specify backend to use") if ARGV.length < 1
backend = ARGV[0]
unless backend == 'redis' || backend == 'amqp'
  usage("Unknown backend #{backend}")
end

EventServer.new backend
