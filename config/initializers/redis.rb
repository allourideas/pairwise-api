require 'redis'
$redis = Redis.new(:host => REDIS_CONFIG['hostname'])
