require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# to do: figure out future-prompts
#        clean up repeated code

describe "Prompts" do
  include IntegrationSupport

  describe "GET 'show'" do
    before do
      @question = Factory.create(:aoi_question, :site => @api_user)
      @prompt = @question.prompts.first
    end

    it "returns a prompt object" do
      get_auth question_prompt_path(@question, @prompt)
      response.should be_success
      response.should have_tag "prompt", 1
    end
  end

  describe "POST 'skip'" do
    before do
      @visitor = Factory.create(:visitor, :site => @api_user, :identifier => "foo")
      @question = Factory.create(:aoi_question,
                                 :site => @api_user,
                                 :choices => [],
                                 :prompts => [])
      3.times{ Factory.create(:choice, :question => @question).activate! }
      info = @question.reload.get_optional_information(:with_appearance => true,
                                                      :with_prompt => true,
                                                      :visitor_identifier => @visitor.identifier )
      @appearance_id = info[:appearance_id]
      @picked_prompt_id = info[:picked_prompt_id]
    end

    it "should return a new skip object given no optional parameters" do
      post_auth skip_question_prompt_path(@question.id, @picked_prompt_id)
      response.should be_success
      response.should have_tag "skip", 1
    end

    it "should correctly set the optional attributes of the skip object" do
      pending("shouldn\'t this set appearance_id?") do
        params = {
          :skip => { 
            :visitor_identifier => @visitor.identifier,
            :skip_reason => "bar",
            :appearance_lookup => @appearance_id,
            :time_viewed => 47 } }
        post_auth skip_question_prompt_path(@question, @picked_prompt_id), params
        response.should be_success
        response.should have_tag "skip", 1
        response.should have_tag "skip appearance-id", @appearance_id.to_s
        response.should have_tag "skip skip-reason", "bar"
        response.should have_tag "skip time-viewed", "47"
        response.should have_tag "skip skipper-id", @visitor.id.to_s
      end
    end

    it "should return a prompt object if next_prompt is set" do
      params = {
        :next_prompt => {
          :visitor_identifier => @visitor.identifier,
          :with_appearance => true,
          :algorithm => "catchup",
          :with_visitor_stats => true } }
      post_auth skip_question_prompt_path(@question, @picked_prompt_id), params
      response.should be_success
      response.should have_tag "prompt", 1
      response.should have_tag "prompt appearance_id", /.+/
      response.should have_tag "prompt visitor_votes", /\d+/
      response.should have_tag "prompt visitor_ideas", /\d+/
    end

    it "should fail when trying to skip another site's questions" do
      other_user = Factory(:email_confirmed_user)
      post_auth other_user, skip_question_prompt_path(@question, @picked_prompt_id)
      response.should_not be_success
    end

  end
  
  describe "POST 'vote'" do
    before do
      # dry this up
      @visitor = Factory.create(:visitor, :site => @api_user, :identifier => "foo")
      @question = Factory.create(:aoi_question,
                                 :site => @api_user,
                                 :choices => [],
                                 :prompts => [])
      3.times{ Factory.create(:choice, :question => @question).activate! }
      info = @question.reload.get_optional_information(:with_appearance => true,
                                                      :with_prompt => true,
                                                      :visitor_identifier => @visitor.identifier )
      @appearance_id = info[:appearance_id]
      @picked_prompt_id = info[:picked_prompt_id]
    end

    it "should fail without the required 'direction' parameter" do
      post_auth vote_question_prompt_path(@question.id, @picked_prompt_id)
      response.should_not be_success
    end      

    it "should return a new vote object given no optional parameters" do
      params = { :vote => { :direction => "left" } }
      post_auth vote_question_prompt_path(@question.id, @picked_prompt_id), params
      response.should be_success
      response.should have_tag "vote", 1
    end

    it "should correctly set the optional attributes of the vote object" do
      pending("also has nil appearance id") do
        params = {
          :vote => { 
            :visitor_identifier => @visitor.identifier,
            :direction => "right",
            :appearance_lookup => @appearance_id,
            :time_viewed => 47 } }
        post_auth vote_question_prompt_path(@question, @picked_prompt_id), params
        response.should be_success
        response.should have_tag "vote", 1
        response.should have_tag "vote appearance-id", @appearance_id.to_s
        response.should have_tag "vote time-viewed", "47"
        response.should have_tag "vote voter-id", @visitor.id.to_s
      end
    end

    # copy-paste from vote --> shared behavior?
    it "should return a prompt object if next_prompt is set" do
      params = {
        :vote => {
          :direction => "left" },
        :next_prompt => {
          :visitor_identifier => @visitor.identifier,
          :with_appearance => true,
          :algorithm => "catchup",
          :with_visitor_stats => true } }
      post_auth vote_question_prompt_path(@question, @picked_prompt_id), params
      response.should be_success
      response.should have_tag "prompt", 1
      response.should have_tag "prompt appearance_id", /.+/
      response.should have_tag "prompt visitor_votes", /\d+/
      response.should have_tag "prompt visitor_ideas", /\d+/
    end

    it "should fail when trying to vote on another site's questions" do
      other_user = Factory(:email_confirmed_user)
      params = { :vote => { :direction => "left" } }
      post_auth other_user, vote_question_prompt_path(@question.id, @picked_prompt_id), params
      response.should_not be_success
    end

  end
end
