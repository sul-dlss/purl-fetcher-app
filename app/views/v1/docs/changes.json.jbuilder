json.changes @changes do |change|
  json.druid change.druid
  json.updated_at change.updated_at.iso8601
  json.latest_change change.published_at.iso8601
  json.catkey change.catkey if change.catkey.present?
  json.true_targets change.true_targets if change.true_targets.present?
  json.false_targets change.false_targets if change.false_targets.present?
  json.collections change.collections.map(&:druid) if change.collections.present?
end
json.partial! 'shared/paginate', locals: { object: @changes }
json.range do
  json.first_modified @first_modified.iso8601
  json.last_modified @last_modified.iso8601
end
