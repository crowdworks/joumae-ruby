#!/usr/bin/env ruby

require 'securerandom'
require 'joumae'

client = Joumae::Client.create

uuid = SecureRandom.uuid
p client.create(uuid)
p client.acquire(uuid)
p client.renew(uuid)
p client.release(uuid)

#Joumae::Command.new(resource_name: "app-development-deployment", owner: "kuoka", client: Joumae::Client.create)

transaction = Joumae::Transaction.new(resource_name: uuid, client: client)

transaction.start

sleep 10

transaction.finish

command = Joumae::Command.new("sleep 10", resource_name: uuid, client: client)

command.run!
