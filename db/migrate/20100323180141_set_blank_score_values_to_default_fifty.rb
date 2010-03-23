class SetBlankScoreValuesToDefaultFifty < ActiveRecord::Migration
  def self.up
	  ActiveRecord::Base.connection.execute('UPDATE choices SET score=50.0 where score =0')
  end

  def self.down
  end
end
