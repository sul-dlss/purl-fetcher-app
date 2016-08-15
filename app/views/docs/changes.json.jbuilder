json.changes @changes do |change|
  json.druid change.druid
  json.latest_change change.published_at.iso8601
  json.true_targets change.release_tags.where(release_type: true).map(&:name).push('SearchWorksPreview')
  json.false_targets change.release_tags.where(release_type: false).map(&:name) if change.release_tags.where(release_type: false).present?
  json.collections change.collections.map(&:druid)
end
json.partial! 'paginate', locals: { object: @changes }
