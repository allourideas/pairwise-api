Delayed::Worker.backend = :active_record
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5 
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 10.minutes

#class Delayed::Worker
#  alias_method :original_handle_failed_job, :handle_failed_job
#
#protected
#  def handle_failed_job(job, error)
#    HoptoadNotifier.notify(error)
#    original_handle_failed_job(job,error)
#  end
#end
