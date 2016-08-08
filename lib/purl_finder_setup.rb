# setup methods used by the finder
module PurlFinderSetup

  def app_config
    PurlFetcher::Application.config.app_config
  end

  def default_output_file
    File.join(base_path_finder_log, base_filename_finder_log)
  end

  # file location in the rails app to store the results of file system find operation
  def base_path_finder_log
    app_config['base_path_finder_log']
  end

  # the base filename of the file to stores the results of the find operation
  def base_filename_finder_log
    app_config['base_filename_finder_log']
  end

  # Return the absolute path to the .deletes dir
  #
  # @return [String] The absolute path
  def path_to_deletes_dir
    Pathname(File.join(purl_mount_location, app_config['deletes_dir'])).to_s
  end

  # Accessor to get the purl document cache path
  #
  # @return [String] The path
  def purl_mount_location
    app_config['purl_document_path']
  end

  # Returns a path to the file location in the purl mount given a druid
  #
  # @param druid [String] The druid you are interested in
  # @return [String] Full path to location in purl mount
  def purl_path(druid)
    DruidTools::PurlDruid.new(druid, purl_mount_location).path
  end

  # Given a full path to a public file, try and pull just the druid part out
  # @param path [String] The path to the public file (e.g. /purl/document_cache/aa/000/bb/0000/public)
  # @return [String] The druid in the form of pid (e.g. aa000bb0000) or blank string if none found
  def get_druid_from_file_path(path)
    find_druid = path.match(/[a-zA-Z]{2}\/[0-9]{3}\/[a-zA-Z]{2}\/[0-9]{4}/)
    find_druid && find_druid.size == 1 ? find_druid.to_s.delete('/') : ""
  end

  # Given a full path to a deleted file, try and pull just the druid part out
  # @param path [String] The path to the deleted file (e.g. /purl/document_cache/.deletes/aa000bb0000)
  # @return [String] The druid in the form of pid (e.g. aa000bb0000) or blank string if none found
  def get_druid_from_delete_path(path)
    find_druid = path.match(/[a-zA-Z]{2}[0-9]{3}[a-zA-Z]{2}[0-9]{4}/)
    find_druid && find_druid.size == 1 ? find_druid.to_s.delete('/') : ""
  end

  # Determine if public purl xml path exists for a given druid
  #
  # @param druid [String] The druid you are interested in
  # @return [Boolean] True or False
  def public_xml_exists?(druid)
    dir_name = Pathname(purl_path(druid)) # This will include the full druid on the end of the path, we don't want that for purl
    File.directory?(dir_name) # if the directory does not exist (so File returns false) then it is really deleted
  end

end
