json.extract! purl, :druid, :published_at, :deleted_at, :object_type, :catkey, :title
json.collections purl.collections.map(&:druid)

json.true_targets purl.true_targets if purl.true_targets.present?
json.false_targets purl.false_targets if purl.false_targets.present?
