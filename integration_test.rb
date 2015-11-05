#!/usr/bin/env ruby

require 'securerandom'
require 'joumae'

client = Joumae::Client.create

uuid = SecureRandom.uuid
p client.create(uuid)
p client.acquire(uuid, 'test')
p client.renew(uuid, 'tet')
p client.release(uuid, 'test')

transaction = Joumae::Transaction.new(resource_name: uuid, owner: 'test', client: client)

transaction.start

sleep 10

transaction.finish
