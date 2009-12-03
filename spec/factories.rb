Factory.define(:item) do |f|
  f.sequence(:data) { |i| "Item #{i}" }
end

Factory.define(:question) do |f|
  f.sequence(:name) { |i| "Name #{i}" }
end

Factory.define(:visitor) do |f|
  f.sequence(:identifier) { |i| "Identifier #{i}" }
end

Factory.define(:prompt) do |f|
  f.sequence(:tracking) { |i| "Prompt we're calling #{i}" }
end

Factory.define(:choice) do |f|
  f.sequence(:data) { |i| "Choice: #{i}" }
end
