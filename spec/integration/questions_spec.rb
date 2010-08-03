require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Questions" do
  include IntegrationSupport
  before do
      3.times{ Factory.create(:aoi_question, :site => @api_user) }
  end

  describe "GET 'index'" do
    it "should return an array of questions" do
      get_auth questions_path(:format => 'xml')
      response.body.should have_tag("questions question", 3)
      response.should be_success
    end

    context "when calling index as another user" do
      before do
        @orig_user = @api_user
        @api_user = Factory(:email_confirmed_user)
      end
      
      it "should not return the questions of the original user" do
        get_auth questions_path(:format => 'xml')
        response.should be_success
        response.body.should_not have_tag("question")
      end
      after { @api_user = @orig_user }
    end
  end

  describe "GET 'new'" do
    it "should return an empty question object" do
      get_auth new_question_path(:format => 'xml')
      response.should be_success
      response.body.should have_tag "question", 1
      response.body.should have_tag "question name", ""
      response.body.should have_tag "question creator-id", ""
      response.body.should have_tag "question created-at", ""
    end      
  end 

  describe "POST 'create'" do
    before { @visitor = Factory.create(:visitor, :site => @api_user) }

    it "should fail when required parameters are omitted" do
      post_auth questions_path(:format => 'xml')
      response.should_not be_success
    end

    it "should return a question object given no optional parameters" do
      pending("choice count doesn't reflect # seed ideas") do
        params = { :question => { :visitor_identifier => @visitor.identifier, :ideas => "foo\r\nbar\r\nbaz" } }

        post_auth questions_path(:format => 'xml'), params

        response.should be_success
        response.should have_tag "question", 1
        response.should have_tag "question creator-id", @visitor.id.to_s
        response.should have_tag "question choices-count", 3
      end
    end

    it "should correctly set optional attributes" do
      params = {
        :question => {
          :visitor_identifier => @visitor.identifier,
          :ideas => "foo\r\nbar\r\nbaz",
          :name => "foo",
          :local_identifier => "bar",
          :information => "baz" } }

      post_auth questions_path(:format => 'xml'), params
      response.should be_success
      response.should have_tag "question", 1
      response.should have_tag "question creator-id", @visitor.id.to_s
      # response.should have_tag "question choices-count", 3
      response.should have_tag "question name", "foo"
      response.should have_tag "question local-identifier", "bar"
      response.should have_tag "question information", "baz"
    end
  end

  describe "POST 'export'" do
    before { @question = Factory.create(:aoi_question, :site => @api_user) }

    it "should fail without any of the required parameters" do
      post_auth export_question_path(@question,  :format => 'xml')
      response.should be_success
      response.body.should =~ /Error/
    end

    it "should fail given invalid parameters" do
      params = { :type => "ideas", :response_type => "foo", :redisk_key => "bar" }
      post_auth export_question_path(@question, :format => 'xml')
      response.should be_success
      response.body.should =~ /Error/
    end

    it "should succeed given valid parameters" do
      params = { :type => "ideas", :response_type => "redis", :redis_key => "foo" }
      post_auth export_question_path(@question,  :format => 'xml'), params
      response.should be_success
      response.body.should =~ /Ok!/
    end
  end

  describe "GET 'show'" do
    before { @question = Factory.create(:aoi_question, :site => @api_user) }

    it "should succeed given no optional parameters" do
      get_auth question_path(@question, :format => 'xml')
      response.should be_success
      response.should have_tag "question", 1
      response.should have_tag "question id", @question.id.to_s
    end

    it "should correctly set optional parameters" do
      @visitor = Factory.create(:visitor, :site => @api_user)
      params = {
        :visitor_identifier => @visitor.identifier,
        :with_prompt => true,
        :with_appearance => true,
        :with_visitor_stats => true }
      get_auth question_path(@question, :format => 'xml'), params
      response.should be_success
      response.should have_tag "question", 1
      response.should have_tag "question id", @question.id.to_s
      response.should have_tag "question picked_prompt_id"
      response.should have_tag "question appearance_id"
      response.should have_tag "question visitor_votes"
      response.should have_tag "question visitor_ideas"
    end

    it "should fail if 'with_prompt' is set but 'visitor_identifier' not provided" do
      pending("figure out argument dependencies") do
        params = { :with_prompt => true }
        get_auth question_path(@question, :format => 'xml'), params
        response.should_not be_success
      end
    end

    context "GET 'show' trying to view others sites' questions" do
      before do
        @orig_user = @api_user
        @api_user = Factory(:email_confirmed_user)
      end

      it "should fail" do
        get_auth question_path(@question, :format => 'xml')
        response.should_not be_success
      end
      after { @api_user = @orig_user }
    end
  end

  describe "PUT 'update'" do
    before { @question = Factory.create(:aoi_question, :site => @api_user) }

    it "should succeed give valid attributes" do
      params = {
        :question => {
          :active => false,
          :information => "foo",
          :name => "bar",
          :local_identifier => "baz" } }
      put_auth question_path(@question, :format => 'xml'), params
      response.should be_success
    end

    it "should not be able to change the site id" do
      original_site_id = @question.site_id
      params = { :question => { :site_id => -1 } }
      put_auth question_path(@question, :format => 'xml'), params
      @question.reload.site_id.should == original_site_id
    end

    it "should ignore protected attributes" do
        params = { :question => { :votes_count => 999 } }
        put_auth question_path(@question, :format => 'xml'), params
        response.should be_success
        @question.reload.site_id.should_not == 999
    end

    context "when updatng another site's question" do
      before do
        @orig_user = @api_user
        @api_user = Factory(:email_confirmed_user)
      end

      it "should fail" do
        params = { :question => { :name => "foo" } }
        put_auth question_path(@question, :format => 'xml'), params
        response.should_not be_success
      end

      after { @api_user = @orig_user }
    end
  end

  describe "GET 'all_object_info_totals_by_date'" do
  end

  describe "GET 'object_info_totals_by_date'" do
  end

end
