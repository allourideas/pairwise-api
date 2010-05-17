#send hoptoad deploy notification
run "cd #{release_path} && rake hoptoad:deploy TO=#{node[:environment][:framework_env]} USER=#{node[:owner_name]} REVISION=#{`cat #{release_path}/REVISION`}"
#restart delayed jobs
run "sudo monit restart all -g pairwise2_jobs"
