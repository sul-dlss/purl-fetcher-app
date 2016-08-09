# class used to represent a purl, used to parse information
class PurlParser

  attr_reader :path, :public_xml # the public XML as a nokogiri doc (will be nil if the public file was not found)

  # Given a path to a directory that contains a public xml file, read in the full XML and set the public_xml accessor as a nokogiri document
  # @param path [String] The path to the directory that contains the public file
  #
  def initialize(path)
    @path = path
    begin
      @public_xml ||= Nokogiri::XML(File.open(Pathname(path) + 'public'))
    rescue => e
      IndexingLogger.error("For #{path} could not read public XML.  #{e.message} #{e.backtrace.inspect}")
    end
  end

  def exists?
    @public_xml
  end

  # Extract the release information from public_xml (load the public XML first)
  #
  # @return [Hash] A hash of all trues and falses in the form of {:true => ['Target1', 'Target2'], :false => ['Target3', 'Target4']}
  #
  def releases
    unless @releases
      @releases = { true: [], false: [] }
      nodes = public_xml.xpath('//publicObject/releaseData/release')
      nodes.each do |node|
        target = node.attribute('to').text
        status = node.text
        @releases[status.downcase.to_sym] << target
      end
    end
    @releases
  end

  # Extract the druid from publicXML identityMetadata.
  #
  # @return [String] The druid in the form of druid:pid
  #
  def druid
    @druid ||= public_xml.at_xpath('//publicObject').attr('id')
  end

  # Extract the title from publicXML DC
  #
  # @return [String] Tht title of the object
  #
  def title
    unless @title
      title_node = public_xml.xpath('//*[name()="dc:title"]')
      @title = (title_node.size == 1 ? title_node[0].content : "")
    end
    @title
  end

  # Extract the object type
  #
  # @return [String] The object types, if multiple, separated by pipes
  #
  def object_type
    @object_type ||= public_xml.xpath('//identityMetadata/objectType').map(&:text).join('|')
  end

  # Extract collections the item is a member of
  #
  # @return [Array] The collections the item is a member of
  #
  def collections
    @collections ||= public_xml.xpath('//*[name()="fedora:isMemberOfCollection"]').map { |n| n.attribute('resource').text.split('/')[1] }
  end

  # Extract collections and sets the item is a member of
  #
  # @return [String] The cat key, an empty string is returned if there is no catkey
  def catkey
    @catkey ||= public_xml.xpath("//identityMetadata/otherId[@name='catkey']").text
  end

  ##
  # Returns the file modified time, in local zone.
  # @return [Time]
  def modified_time
    File.mtime(Pathname(path))
  end
end
