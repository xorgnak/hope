
Pry.config.prompt = Pry::Prompt.new(
  "z4",
  "the z4 prompt.",
  [proc { |obj, nest_level, _| "#{obj}:#{nest_level}> " }, proc { |obj, nest_level, _| "#{obj}:#{nest_level}->" }]
)

Z4.info

Pry.start
