json.extract! collection, :druid, :catkey
json.partial! 'shared/true_targets', locals: { true_targets: collection.release_tags.where(release_type: true).map(&:name) | Settings.ALWAYS_SEND_TRUE_TARGET.to_a }
json.false_targets collection.release_tags.where(release_type: false).map(&:name) if collection.release_tags.where(release_type: false).present?
