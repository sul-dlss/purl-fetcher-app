json.extract! purl, :druid, :published_at, :deleted_at, :object_type, :title

json.catkey purl.catkey if purl.catkey.present?
json.latest_change purl.published_at.iso8601

json.collections purl.collections.map(&:druid)

json.true_targets purl.true_targets if purl.true_targets.present?
json.false_targets purl.false_targets if purl.false_targets.present?
