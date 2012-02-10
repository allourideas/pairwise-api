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
end
