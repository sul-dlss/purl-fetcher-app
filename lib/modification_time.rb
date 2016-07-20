##
# Deals with setting a default first_modified_time and last_modified_time
class ModificationTime
  attr_reader :first_modified, :last_modified, :first_modified_time, :last_modified_time
  Y_TEN_K = '9999-12-31T23:59:59Z'.freeze

  ##
  # @param [String] first_modified
  # @param [String] last_modified
  def initialize(first_modified: Time.zone.at(0).iso8601, last_modified: Y_TEN_K)
    @first_modified = Time.zone.parse(first_modified)
    @last_modified = Time.zone.parse(last_modified)
    raise ArgumentError, 'invalid time parameters' if @first_modified.nil? || @last_modified.nil?
    raise ArgumentError, 'start time is before end time' if @first_modified >= @last_modified
  end

  ##
  # @return [Hash]
  def convert_to_iso8601
    { first: first_modified.iso8601, last: last_modified.iso8601 }
  end

  ##
  # A class method constructor used to conform to original API.
  # @return [Hash]
  def self.get_times(params = {})
    arguments = {}
    arguments[:first_modified] = params[:first_modified] if params.present? && params[:first_modified].present?
    arguments[:last_modified] = params[:last_modified] if params.present? && params[:last_modified].present?
    new(arguments).convert_to_iso8601
  end
end
