class Purl < ActiveRecord::Base

  has_and_belongs_to_many :collections
  has_many :release_tags, dependent: :destroy

  # class level method to create or update a purl model object given a path to a purl public xml file
  def self.index(path)
    public_xml = PurlParser.new(path)
    purl = Purl.find_or_create_by(druid: public_xml.druid) # either create a new druid record or get the existing one

    # set the purl model attributes
    purl.druid = public_xml.druid
    purl.title = public_xml.title
    purl.object_type = public_xml.object_type
    purl.catkey = public_xml.catkey

    # add the collections they exist
    public_xml.collections.each { |collection| purl.collections << Collection.where(druid: collection).first_or_create }

    # add the release tags
    public_xml.releases[:true].each { |release| purl.release_tags << ReleaseTag.new(name: release, release_type: true) }
    public_xml.releases[:false].each { |release| purl.release_tags << ReleaseTag.new(name: release, release_type: false) }

    purl.save
  end

  def deleted?
    deleted_at.blank?
  end

end
