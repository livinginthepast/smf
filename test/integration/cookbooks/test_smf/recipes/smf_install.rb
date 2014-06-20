include_recipe 'smf'

smf 'thing' do
  start_command 'true'
  stop_command 'true'
end
