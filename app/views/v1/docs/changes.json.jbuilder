json.changes @changes do |change|
  json.druid change.druid
  json.latest_change change.published_at.iso8601
  json.partial! 'shared/true_targets', locals: { true_targets: change.true_targets }
  json.false_targets change.false_targets if change.false_targets.present?
  json.collections change.collections.map(&:druid) if change.collections.present?
end
json.partial! 'shared/paginate', locals: { object: @changes }
