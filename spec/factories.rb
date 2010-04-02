Factory.define(:item) do |f|
  f.sequence(:data) { |i| "Item #{i}" }
end

Factory.define(:question) do |f|
  f.sequence(:name) { |i| "Name #{i}" }
end
Factory.define(:aoi_question, :parent => :question) do |f|
  f.sequence(:name) { |i| "Name #{i}" }
  f.association :site, :factory => :user
  f.association :creator, :factory => :visitor
end

Factory.define(:visitor) do |f|
  f.sequence(:identifier) { |i| "Identifier #{i}" }
end

Factory.define(:prompt) do |f|
  f.sequence(:tracking) { |i| "Prompt we're calling #{i}" }
end

Factory.define(:choice) do |f|
  f.sequence(:data) { |i| "Choice: #{i}" }
end

Factory.sequence :email do |n|
  "user#{n}@example.com"
end

Factory.define :user do |user|
  user.email                 { Factory.next :email }
  user.password              { "password" }
  user.password_confirmation { "password" }
end

Factory.define :email_confirmed_user, :parent => :user do |user|
  user.email_confirmed { true }
end
