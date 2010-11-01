class Appearance < ActiveRecord::Base
  belongs_to :voter, :class_name => "Visitor", :foreign_key => 'voter_id'
  belongs_to :prompt
  belongs_to :question
  belongs_to :answerable, :polymorphic => true

  default_scope :conditions => {:valid_record => true}

  def answered?
    !self.answerable_id.nil?
  end
end
