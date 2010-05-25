class Flag < ActiveRecord::Base
  belongs_to :question
  belongs_to :visitor
  belongs_to :choice
  belongs_to :site
  
  validates_presence_of :choice_id
  validates_presence_of :question_id
  
end
