json.extract! purl, :druid, :published_at, :deleted_at, :object_type
json.collections purl.collections.map(&:druid)
json.partial! 'shared/true_targets', locals: { true_targets: purl.release_tags.where(release_type: true).map(&:name) | Settings.ALWAYS_SEND_TRUE_TARGET.to_a }
json.false_targets purl.release_tags.where(release_type: false).map(&:name) if purl.release_tags.where(release_type: false).present?
