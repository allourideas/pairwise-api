class Click < ActiveRecord::Base
  belongs_to :site
  belongs_to :visitor
end
