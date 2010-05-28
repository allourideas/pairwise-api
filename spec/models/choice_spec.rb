require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Choice do
  
  it {should belong_to :question}
  it {should belong_to :item}
  it {should have_many :flags}
  it {should validate_presence_of :question}
  
  before(:each) do
    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @johndoe = Factory.create(:visitor, :identifier => 'johndoe', :site => @aoi_clone)
    @question = Question.create(:name => 'which do you like better?', :site => @aoi_clone, :creator => @johndoe)
    
    @valid_attributes = {
      :creator => @johndoe,
      :question => @question,
      :data => 'hi there'
    }
  end

  it "should create a new instance given valid attributes" do
    Choice.create!(@valid_attributes)
  end
  
  it "should generate prompts after creation" do
    prev_choices = @question.choices.size
    @question.prompts.should_not be_empty
    proc {choice1 = Choice.create!(@valid_attributes.merge(:data => '1234'))}.should change(@question.prompts, :count).by(prev_choices*2)
    @question.prompts.should_not be_empty
  end

  it "should deactivate a choice" do
    choice1 = Choice.create!(@valid_attributes.merge(:data => '1234'))
    choice1.deactivate!
    choice1.should_not be_active
  end

  it "should update a question's counter cache on creation" do
	  @question.choices.size.should == 2
          choice1 = Choice.create!(@valid_attributes.merge(:data => '1234'))
	  @question.reload
	  @question.choices.size.should == 3
  end

  it "should update a question's counter cache on activation" do
	  prev_inactive = @question.inactive_choices_count
          choice1 = Choice.create!(@valid_attributes.merge(:data => '1234'))
	  choice1.deactivate!
	  @question.reload
	  @question.inactive_choices_count.should == prev_inactive + 1
	  choice1.activate!
	  @question.reload
	  @question.inactive_choices_count.should == prev_inactive
	  choice1.should be_active
  end

  it "should update a question's counter cache on deactivation" do 
	  prev_inactive = @question.inactive_choices_count
          choice1 = Choice.create!(@valid_attributes.merge(:data => '1234'))
	  choice1.deactivate!
	  @question.reload
	  @question.inactive_choices_count.should == prev_inactive + 1
  end
end
