class VisitorsController < ApplicationController
  # GET /visitors
  # GET /visitors.xml
  def index
    @visitors = Visitor.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @visitors }
    end
  end

  # GET /visitors/1
  # GET /visitors/1.xml
  def show
    @visitor = Visitor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @visitor }
    end
  end

  # GET /visitors/new
  # GET /visitors/new.xml
  def new
    @visitor = Visitor.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @visitor }
    end
  end

  # GET /visitors/1/edit
  def edit
    @visitor = Visitor.find(params[:id])
  end

  # POST /visitors
  # POST /visitors.xml
  def create
    @visitor = Visitor.new(params[:visitor])

    respond_to do |format|
      if @visitor.save
        flash[:notice] = 'Visitor was successfully created.'
        format.html { redirect_to(@visitor) }
        format.xml  { render :xml => @visitor, :status => :created, :location => @visitor }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @visitor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /visitors/1
  # PUT /visitors/1.xml
  def update
    @visitor = Visitor.find(params[:id])

    respond_to do |format|
      if @visitor.update_attributes(params[:visitor])
        flash[:notice] = 'Visitor was successfully updated.'
        format.html { redirect_to(@visitor) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @visitor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /visitors/1
  # DELETE /visitors/1.xml
  def destroy
    @visitor = Visitor.find(params[:id])
    @visitor.destroy

    respond_to do |format|
      format.html { redirect_to(visitors_url) }
      format.xml  { head :ok }
    end
  end
end
