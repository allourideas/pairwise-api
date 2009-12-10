class ClicksController < ApplicationController
  # GET /clicks
  # GET /clicks.xml
  def index
    @clicks = Click.find(:all, :order => 'created_at DESC', :limit => 50)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @clicks }
    end
  end

  # GET /clicks/1
  # GET /clicks/1.xml
  def show
    @click = Click.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @click }
    end
  end

  # GET /clicks/new
  # GET /clicks/new.xml
  def new
    @click = Click.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @click }
    end
  end

  # GET /clicks/1/edit
  def edit
    @click = Click.find(params[:id])
  end

  # POST /clicks
  # POST /clicks.xml
  def create
    authenticate
    if signed_in?
      p = params[:click].except(:sid).merge(:visitor_id => current_user.visitors.find_or_create_by_identifier(params[:click][:sid]).id)
      @click = Click.new(p)
    else
      render :nothing => true and return
    end

    respond_to do |format|
      if @click.save
        flash[:notice] = 'Click was successfully created.'
        format.html { redirect_to(@click) }
        format.xml  { render :xml => @click, :status => :created, :location => @click }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @click.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /clicks/1
  # PUT /clicks/1.xml
  def update
    @click = Click.find(params[:id])

    respond_to do |format|
      if @click.update_attributes(params[:click])
        flash[:notice] = 'Click was successfully updated.'
        format.html { redirect_to(@click) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @click.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /clicks/1
  # DELETE /clicks/1.xml
  def destroy
    @click = Click.find(params[:id])
    @click.destroy

    respond_to do |format|
      format.html { redirect_to(clicks_url) }
      format.xml  { head :ok }
    end
  end
end
