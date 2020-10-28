namespace :util do
  desc "Add user to API"
  task :useradd, [:email, :password] => [:environment] do |t, args|
    u = User.create!( 
      :email => args[:email],
      :password => args[:password], 
      :password_confirmation => args[:password]
    )
    u.email_confirmed = true
    u.save!
    puts "Added user #{args[:email]} with password: #{args[:password]}"
  end

  desc "Redact question"
  task :redact_question, [:question_id] => [:environment] do |t, args|
    q = Question.find(args[:question_id])
    puts "Confirm redaction of #{args[:question_id]}: '#{q.name}' [y/N]"
    input = STDIN.gets.chomp
    raise "Aborting redaction of #{args[:question_id]}" unless input == "y"
    q.redact!
    puts "Question #{args[:question_id]} has been redacted"
  end
end
