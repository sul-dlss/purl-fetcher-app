class TagController < ApplicationController
  #include Fetcher
  def show
  #/tag/:tag?first_modified=TIME UTC?last_modified=TIME_UTC
  #TODO: Allow count option
  
    result=find_by_tag(params)
    render_result(result)
    
  end
  
  def index
    #TODO: Return a list of all tag_facet entries or their counts
  end
  
end
