json.array!(@entries) do |entry|
  json.extract! entry, :id, :name
  json.url entry_url(entry, format: :json)
end
