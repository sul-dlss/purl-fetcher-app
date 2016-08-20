json.changes @changes do |change|
  json.druid change.druid
  json.latest_change change.published_at.iso8601
  json.partial! 'shared/true_targets', locals: { true_targets: change.release_tags.where(release_type: true).map(&:name) | Settings.ALWAYS_SEND_TRUE_TARGET.to_a }
  json.false_targets change.release_tags.where(release_type: false).map(&:name) if change.release_tags.where(release_type: false).present?
  json.collections change.collections.map(&:druid) if change.collections.present?
end
json.partial! 'shared/paginate', locals: { object: @changes }
