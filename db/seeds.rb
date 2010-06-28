# rake db:seed
# load the API user for AOI dev environment

u = User.new(:email => "pairwisetest@dkapadia.com", :password => "wheatthins")
u.save(false)


u = User.new(:email => "photocracytest@dkapadia.com", :password => "saltines")
u.save(false)