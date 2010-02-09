class CronMailer < ActionMailer::Base

	def info_message(recipients, subject, message, sent_at= Time.now)
		@recipients = recipients
		@from = 'cronjob@allourideas.org'
		@subject ="[All Our Ideas] " +  subject
		@sent_on = sent_at
		@body[:message] = message
      		@body[:host] = "www.allourideas.org"
	end

	
  

end
