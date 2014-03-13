if FileTest.exists?("#{config.shared_path}/config/redis.yml")
  run "ln -nfs #{config.shared_path}/config/redis.yml #{config.release_path}/config/redis.yml"
end
