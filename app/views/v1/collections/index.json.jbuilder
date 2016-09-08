json.collections do
  json.array! @collections, partial: 'v1/collections/collection', as: :collection
end
json.partial! 'shared/paginate', locals: { object: @collections }
