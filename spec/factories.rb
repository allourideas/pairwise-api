Factory.define(:item) do |f|
  f.sequence(:data) { |i| "Item #{i}" }
end


Factory.define(:question) do |f|
  f.sequence(:name) { |i| "Name #{i}" }
  f.site {|s| s.association(:user)}
  f.creator {|c| c.association(:visitor, :site => c.site)}
end
Factory.define(:aoi_question, :parent => :question) do |f|
  f.sequence(:name) { |i| "Name #{i}" }
  f.association :site, :factory => :user
  f.creator {|c| c.association(:visitor, :site => c.site)}
  f.choices do |question|
	      result = []
	      2.times do 
		result << Factory.build(:choice, 
					:question => question.result,
					:creator => question.creator,
					:active => true)
	      end
	      2.times do 
		      result << Factory.build(:choice, 
					  :question => question.result,
					  :creator => question.creator,
					  :active => false)
	      end
	     result
	    end
  f.prompts do |question|
	      result = []
	      1.times do 
		result << Factory.build(:prompt, 
					:question => question.result,
					:left_choice => question.choices.first,
					:right_choice => question.choices.second)

		result << Factory.build(:prompt, 
					:question => question.result,
					:left_choice => question.choices.third,
					:right_choice => question.choices.fourth)

	      end
	     result
	    end
end

Factory.define(:visitor) do |f|
  f.sequence(:identifier) { |i| "Identifier #{i}" }
  f.association :site, :factory => :user
end

Factory.define(:prompt) do |f|
  f.sequence(:tracking) { |i| "Prompt we're calling #{i}" }
end

Factory.define(:choice) do |f|
  f.sequence(:data) { |i| "Choice: #{i}" }
  f.association :question
  f.creator {|c| c.association(:visitor, :site => c.question.site)}
end

Factory.define(:vote) do |f|
  f.association :question, :factory => :aoi_question
  f.prompt {|v|  v.question.prompts.first}
  f.choice {|v|  v.prompt.left_choice}
  f.loser_choice {|v|  v.prompt.right_choice}
  f.voter {|v|  v.question.creator}
end

Factory.define(:skip) do |f|
  f.association :question, :factory => :aoi_question
  f.prompt {|s|  s.question.prompts.first}
  f.skipper {|s|  s.question.creator}
end

Factory.define(:appearance) do |f|
  f.association :question, :factory => :aoi_question
  f.prompt {|a| a.question.prompts.rand}
  f.voter {|a| a.question.creator}
  f.answerable { nil }
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
