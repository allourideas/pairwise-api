class CronMailer < ActionMailer::Base

	def error_message(subject, message, sent_at= Time.now)
		@from = 'cronjob@allourideas.org'
		@recipients = "dhruv@dkapadia.com"
		@subject ="[All Our Ideas] " +  subject
		@sent_on = sent_at
		@body[:message] = message
      		@body[:host] = "www.allourideas.org"
	end

	
  

end
