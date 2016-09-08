json.purls do
  json.array! @purls, partial: 'v1/purls/purl', as: :purl
end
json.partial! 'shared/paginate', locals: { object: @purls }
