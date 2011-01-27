if FileTest.exists?("#{shared_path}/config/redis.yml")
  run "ln -nfs #{shared_path}/config/redis.yml #{release_path}/config/redis.yml"
end
