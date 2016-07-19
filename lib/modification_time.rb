##
# Deals with setting a default first_modified_time and last_modified_time
class ModificationTime
  attr_reader :first_modified, :last_modified, :first_modified_time, :last_modified_time
  Y_TEN_K = '9999-12-31T23:59:59Z'.freeze

  ##
  # @param [String] first_modified
  # @param [String] last_modified
  def initialize(first_modified: Time.zone.at(0).iso8601, last_modified: Y_TEN_K)
    @first_modified = first_modified
    @last_modified = last_modified
  end

  ##
  # @return [Hash]
  def convert
    validate
    { first: first_modified_time, last: last_modified_time }
  end

  ##
  # A class method constructor used to conform to original API.
  # @return [Hash]
  def self.get_times(params = {})
    arguments = {}
    arguments[:first_modified] = params[:first_modified] if params.present? && params[:first_modified].present?
    arguments[:last_modified] = params[:last_modified] if params.present? && params[:last_modified].present?
    new(arguments).convert
  end

  private

  def validate
    begin
      @first_modified_time = Time.zone.parse(first_modified).iso8601
      @last_modified_time = Time.zone.parse(last_modified).iso8601
    rescue
      raise 'invalid time paramaters'
    end
    raise 'start time is before end time' if first_modified_time >= last_modified_time
  end
end
