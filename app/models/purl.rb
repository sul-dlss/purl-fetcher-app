class Purl < ActiveRecord::Base

  has_and_belongs_to_many :collections
  has_many :release_tags, dependent: :destroy
  paginates_per 100
  max_paginates_per 10_000
  default_scope -> { order('published_at') }
  validates :druid, uniqueness: true

  # class level method to create or update a purl model object given a path to a purl directory
  # @param [String] `path` path to a PURL directory
  # @return [Boolean] success or failure
  def self.save_from_public_xml(path)
    public_xml = PurlParser.new(path)

    if public_xml.exists?
      purl = self.find_or_create_by(druid: public_xml.druid) # either create a new druid record or get the existing one

      # set the purl model attributes
      purl.druid = public_xml.druid
      purl.object_type = public_xml.object_type

      # add the collections they exist and if they are not already present
      public_xml.collections.each do |collection|
        collection_to_add = Collection.find_or_create_by(druid: collection)
        purl.collections << collection_to_add unless purl.collections.include?(collection_to_add)
      end

      # add the release tags
      public_xml.releases[:true].each { |release| purl.release_tags << ReleaseTag.new(name: release, release_type: true) }
      public_xml.releases[:false].each { |release| purl.release_tags << ReleaseTag.new(name: release, release_type: false) }

      purl.published_at = public_xml.modified_time
      purl.deleted_at = nil # ensure the deleted at field is nil (important for a republish of a previously deleted purl)

      purl.save
    else
      false # can't find the public xml
    end
  end

  ##
  # Specify an instance's `deleted_at` attribute which denotes when an object's
  # public xml is gone
  # @param [String] druid
  # @param [Time] `deleted_at` the time at which the PURL was deleted. If `nil`, it uses the current time.
  def self.mark_deleted(druid, deleted_at = nil)
    druid = "druid:#{druid}" unless druid.include?('druid:') # add the druid prefix if it happens to be missing
    purl = find_or_create_by(druid: druid) # either create a new druid record or get the existing one
    #  (in theory we should *always* have a previous druid here)
    purl.deleted_at = deleted_at.nil? ? Time.current : deleted_at
    purl.save
  end
end
