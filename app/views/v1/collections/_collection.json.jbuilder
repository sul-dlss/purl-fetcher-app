json.extract! collection, :druid, :catkey
json.partial! 'shared/true_targets', locals: { true_targets: collection.true_targets }
json.false_targets collection.false_targets if collection.false_targets.present?
