#send hoptoad deploy notification
run "cd #{config.release_path} && rake hoptoad:deploy TO=#{config.node[:environment][:framework_env]} USER=#{config.node[:owner_name]} REVISION=#{`cat #{config.release_path}/REVISION`}"
#restart delayed jobs
run "sudo monit restart all -g pairwise2_jobs"
