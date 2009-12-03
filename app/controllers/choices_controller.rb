class ChoicesController < ApplicationController
  # GET /choices
  # GET /choices.xml
  def index
    @choices = Choice.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @choices }
    end
  end

  # GET /choices/1
  # GET /choices/1.xml
  def show
    @choice = Choice.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @choice }
    end
  end

  # GET /choices/new
  # GET /choices/new.xml
  def new
    @choice = Choice.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @choice }
    end
  end

  # GET /choices/1/edit
  def edit
    @choice = Choice.find(params[:id])
  end

  # POST /choices
  # POST /choices.xml
  def create
    @choice = Choice.new(params[:choice])

    respond_to do |format|
      if @choice.save
        flash[:notice] = 'Choice was successfully created.'
        format.html { redirect_to(@choice) }
        format.xml  { render :xml => @choice, :status => :created, :location => @choice }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @choice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /choices/1
  # PUT /choices/1.xml
  def update
    @choice = Choice.find(params[:id])

    respond_to do |format|
      if @choice.update_attributes(params[:choice])
        flash[:notice] = 'Choice was successfully updated.'
        format.html { redirect_to(@choice) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @choice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /choices/1
  # DELETE /choices/1.xml
  def destroy
    @choice = Choice.find(params[:id])
    @choice.destroy

    respond_to do |format|
      format.html { redirect_to(choices_url) }
      format.xml  { head :ok }
    end
  end
end
