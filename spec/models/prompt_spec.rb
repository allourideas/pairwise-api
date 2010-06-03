require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Prompt do
  it {should belong_to :question}
  it {should belong_to :left_choice}
  it {should belong_to :right_choice}
  
end
