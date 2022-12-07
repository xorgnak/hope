#@host = DB['localhost']

h = {
  titles: 'pedicabber',
  items: 'pedicab',
  groups: 'pedicabbers',
  badges: 'pedicabbing'
}
#@host.jobs['pedicabber'] = h

h = {
  titles: 'bartender',
  groups: 'bartenders',
  badges: 'bartending'
}
#@host.jobs['bartender'] = h

[:user, :member, :influencer, :ambassador, :manager, :agent, :operator, :developer].each do |e|
  h = {
    titles: "#{e}",
    groups: "#{e}s"
  }
  #@host.jobs[e.to_s] = h
end

#@host.hire 'xorgnak', 'pedicabber', 'my group'
#@host.priv 'xorgnak', Z4.priv.length - 1
