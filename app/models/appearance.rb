class Appearance < ActiveRecord::Base
      belongs_to :voter, :class_name => "Visitor", :foreign_key => 'voter_id'
      belongs_to :prompt
      belongs_to :question

      #technically, an appearance should either one vote or one skip, not one of both objects, but these declarations provide some useful helper methods
      # we could refactor this to use rails polymorphism, but currently the foreign key is stored in the vote and skip object
      has_one :vote
      has_one :skip

      def answered?
	 vote || skip
      end
end
