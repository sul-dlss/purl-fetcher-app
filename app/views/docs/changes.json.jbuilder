json.changes @changes do |change|
  json.druid change.druid
  json.latest_change change.indexed_at.iso8601
  json.true_targets change.release_tags.where(release_type: true).map(&:name)
  json.false_targets change.release_tags.where(release_type: false).map(&:name)
  json.collections change.collections.map(&:druid)
end
