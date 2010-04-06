class Appearance < ActiveRecord::Base
      belongs_to :voter, :class_name => "Visitor", :foreign_key => 'voter_id'
      belongs_to :prompt
      belongs_to :question
      has_one :vote
end
