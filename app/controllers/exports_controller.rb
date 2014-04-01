class ExportsController < InheritedResources::Base
  before_filter :authenticate

  def show
    e = Export.find_by_name(params[:id])
    if e.nil? || e.data.nil? || !current_user.question_ids.include?(e.question_id)
      render :text => "Not found.", :status => 404, :content_type => 'text/html' and return
    end
    if e.compressed?
      zstream = Zlib::Inflate.new
      data = zstream.inflate(e.data)
      zstream.finish
      zstream.close
    else
      data = e.data
    end
    send_data(data, :type => 'text/csv; charset=utf-8; header=present')
  end
end
