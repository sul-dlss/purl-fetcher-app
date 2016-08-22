class ApiConstraint
  attr_reader :version

  def initialize(options)
    @version = options.fetch(:version)
  end

  def matches?(request)
    accept_header = request.headers.fetch('HTTP_ACCEPT', '')
    requested_version = accept_header.scan(/version=(\d*)/).flatten.first
    return true if version == 1 && requested_version.blank?
    return true if version <= requested_version.to_i
    false
  end
end