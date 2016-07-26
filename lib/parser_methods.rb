# methods used by the indexer for parsing XML
module ParserMethods

  # Given a path to a directory that contains a public xml file, extract the release information
  #
  # @param path [String] The path to the directory that will contain the mods file
  # @return [Hash] A hash of all trues and falses in the form of {:true => ['Target1', 'Target2'], :false => ['Target3', 'Target4']}
  # @raise Errno::ENOENT If there is no public file
  #
  # Example:
  #   release_status = get_druid_from_contentMetada('/purl/document_cache/bb')
  def get_release_status(path)
    releases = { true: [], false: [] }
    x = Nokogiri::XML(File.open(Pathname(path) + 'public'))
    nodes = x.xpath('//publicObject/releaseData/release')
    nodes.each do |node|
      target = node.attribute('to').text
      status = node.text
      releases[status.downcase.to_sym] << target
    end
    releases
  end

  # Given a full path to a public file, try and pull just the druid part out
  # @param path [String] The path to the public file (e.g. /purl/document_catch/aa/000/bb/0000/public)
  # @return [String] The druid in the form of pid (e.g. aa000bb0000) or blank string if none found
  def get_druid_from_file_path(path)
    find_druid=path.match(/[a-zA-Z]{2}\/[0-9]{3}\/[a-zA-Z]{2}\/[0-9]{4}/)
    find_druid && find_druid.size == 1 ? find_druid.to_s.gsub('/','') : ""
  end

  # Given a path to a directory that contains a public metadata file, extract the druid for the item from identityMetadata.
  #
  # @param path [String] The path to the directory that will contain the public metadata file
  # @return [String] The druid in the form of druid:pid
  # @raise Errno::ENOENT If there is no public metadata file
  #
  # Example:
  #   druid = get_druid_from_public_metadata('/purl/document_cache/bb')
  def get_druid_from_public_metadata(path)
    x = Nokogiri::XML(File.open(Pathname(path) + 'public'))
    x.xpath('//publicObject')[0].attr('id')
  end

  # Given a path to a directory that contains a mods file, extract info on the object for indexing into solr
  #
  # @param path [String] The path to the directory that will contain the mods file
  # @return [Hash{Symbol => String}] An hash of mods information in the form of {:solr_field_name => value}
  # @raise Errno::ENOENT If there is no mods file
  #
  # Example:
  #   hash = index_druid_tree_branch('/purl/document_cache/bb')
  def read_mods_for_object(path)
    mods = Stanford::Mods::Record.new
    mods.from_str(IO.read(Pathname(path + File::SEPARATOR + 'mods')))
    title = mods.sw_full_title
    { :title_tesim => title }
  end

  # Given a path to a directory that contains a public xml file, extract the collections and sets for the item from identityMetadata
  #
  # @param path [String] The path to the directory that will contain the identityMetadata file
  # @return [Array] The object types
  # @raise Errno::ENOENT If there is no identity Metadata File
  #
  # Example:
  #   get_object_type_from_identity_metadata('/purl/document_cache/bb')
  def get_object_type_from_identity_metadata(path)
    x = Nokogiri::XML(File.open(Pathname(path) + 'identityMetadata'))
    x.xpath('//identityMetadata/objectType').map(&:text)
  end

  # Given a path to a directory that contains a public xml file, extract collections and sets the item is a member of
  #
  # @param path [String] The path to the directory that will contain the public xml
  # @return [Array] The collections and sets the item is a member of
  # @raise Errno::ENOENT If there is no public xml file
  #
  # Example:
  #   get_membership_from_publicxml('/purl/document_cache/bb')
  def get_membership_from_publicxml(path)
    x = Nokogiri::XML(File.open(Pathname(path) + 'public'))
    x.remove_namespaces!
    x.xpath('//RDF/Description/isMemberOfCollection').map do |n|
      n.attribute('resource').text.split('/')[1]
    end
  end

  # Given a path to a directory that contains an indentityMetadata xml file, extract collections and sets the item is a member of
  #
  # @param path [String] The path to the directory that will contain the identity Metadata File
  # @return [String] The cat key, an empty string is returned if there is no catkey
  # @raise Errno::ENOENT If there is no identity Metadata File
  #
  # Example:
  #   get_catkey_from_identity_metadata('/purl/document_cache/bb')
  def get_catkey_from_identity_metadata(path)
    x = Nokogiri::XML(File.open(Pathname(path) + 'identityMetadata'))
    x.xpath("//otherId[@name='catkey']").text
  end

  # Returns a path the file location in the purl mount given a druid
  #
  # @param druid [String] The druid you are interested in
  # @return [String] Full path to location in purl mount
  def purl_path(druid)
    DruidTools::PurlDruid.new(druid, purl_mount_location).path
  end

  # Determine if a druid has been deleted and pruned from the document cache or not
  #
  # @param druid [String] The druid you are interested in
  # @return [Boolean] True or False
  def deleted?(druid)
    dir_name = Pathname(purl_path(druid)) # This will include the full druid on the end of the path, we don't want that for purl
    !File.directory?(dir_name) # if the directory does not exist (so File returns false) then it is really deleted
  end

end
