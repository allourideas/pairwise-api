
namespace :testserver do 
	

       desc "Start a server for testing purposes on port 4000"
       task :start do

	       system "export RAILS_ENV=test && #{Rails.root.to_s}/script/server -p 4000"
       end


       task :prepare => :test do 
	       Rake::Task["db:test:prepare"].invoke

	       u = User.create!(:email => 'testing@dkapadia.com', :password => 'wheatthins', :password_confirmation => "wheatthins")

	       u.email_confirmed = true
	       u.save
	       
               #photocracy username
               u = User.create!(:email => 'photocracytest@dkapadia.com', :password => 'saltines', :password_confirmation => "saltines")
	       u.email_confirmed = true
	       u.save
       end

       task :launch => [:prepare, :start]
end

