json.extract! purl, :druid, :published_at, :deleted_at, :object_type, :catkey, :title
json.collections purl.collections.map(&:druid)
json.partial! 'shared/true_targets', locals: { true_targets: purl.true_targets }
json.false_targets purl.false_targets if purl.false_targets.present?
