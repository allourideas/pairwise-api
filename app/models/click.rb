class Click < ActiveRecord::Base
  belongs_to :site
  belongs_to :visitor
  
  def page
    ip = what_was_clicked.split('[ip: ')[1].split(']').first rescue nil
  end
    
  
  def ip
    ip = what_was_clicked.split('[ip: ')[1].split(']').first rescue nil
  end
  
  def to_html
    if ip
      return what_was_clicked.gsub('ip', "http://api.hostip.info/get_html.php?ip=#{ip}")
    else
      return what_was_clicked
    end
  end
end
