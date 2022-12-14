LIVE = false

module DB
  # host sessions
  class SESSION
    def initialize a
      @id = a
      @db = DBM.new("db/#{@id}-sessions.db")
    end
#    def db
#      @db
#    end
    def has_key? k
      @db.has_key? k
    end
    def [] k
      if @db.has_key? k
        return @db[k]
      elsif @db.invert.has_key? k
        return @db.invert[k]
      else
        return false
      end
    end
    def []= k,v
      @db[k] = v
    end
  end
  # host auth
  class AUTH
    def initialize a
      @id = a
      @db = DBM.new("db/#{@id}-passwd.db")
      @auth = DBM.new("db/#{@id}-auth.db")
      @sessions = SESSION.new @id
    end
    def session
      @sessions
    end
    
    def [] k
      @auth[k]
    end
    def auth? k, v, c
      if @db.has_key?(k) && @db[k] == v
        @auth[k] = Time.now.to_i
        if !@sessions.has_key? k
          @sessions[k] = c
        end
        return @sessions[k]
      else
        return false
      end
    end
    def auth! k, v
      @db[k] = v
    end
  end

  # jobs
  class JOBS
    def initialize a
      @id = a
      @db = DBM.new "db/#{@id}-jobs.db", 0666, DBM::WRCREAT
    end
    def db
      @db
    end
    def [] k
      JSON.parse(@db[k])
    end
    def []= k,v
      @db[k] = JSON.generate(v)
    end
  end
  
  # host data element
  class DB
    def initialize *a, **h
      @attr = a
      @id = a.join('-')
      @opts = {}
      @file = "db/#{@id}.db"
      @db = DBM.new(@file)
    end
    def id
      @attr[1] || @id
    end
    def keys
      @db.keys
    end
    def has_key? k
      @db.has_key? k.to_s
    end
    def get k
      if !@db.has_key? k.to_s
        set k.to_s, base()
      end
      JSON.parse(@db[k.to_s])
    end
    def set k,v={}
      v[:atime] = Time.now.to_i
      @db[k.to_s] = JSON.generate(v)
    end

    # lookup
    def [] k
      get(k.to_s)
    end
    
    # attribute managment
    def update u, k, v
      h = get(u)
      h[k.to_s] = v
      set u, h
      return nil
    end
    
    # credits, tokens managment
    def mod u, k, a
      h = get(u)
      p = h[k.to_s].to_i
      h[k.to_s] = p + a.to_i
      set u, h
      return nil
    end

    # group, title, item, badge managment
    def add u, k, *es
      h = get(u)
      es.each { |e| if !h[k.to_s].include?(e); h[k.to_s] << e; end }
      set(u, h)
      return nil
    end
    def rem u, k, *es
      h = get(u)
      es.each { |e| if h[k.to_s].include?(e); h[k.to_s].delete(e); end }
      set(u, h)
      return nil
    end

    # config
    def form
      # to form inputs
    end
    # blank element
    def base **h
      b = {
        new: true,
        created: Time.now.to_i,
        atime: Time.now.to_i,
        valid: (Time.now.to_i + ((60 * 60) * 24)),
        owner: nil,
        name: nil,
        desc: nil,
        about: nil,
        phone: nil,
        contact: nil,
        link: nil,
        tips: nil,
        store: nil,
        tv: nil,
        icon: nil,
        img: nil,
        bg: nil,
        group: nil,
        title: nil,
        location: nil,
        type: 0,
        credits: 0,
        tokens: 0,
        karma: 0,
        rank: 0,
        class: 0,
        items: [],
        users: [],
        badges: [],
        groups: [],
        titles: [],
        seen: [],
        see: [],
        visited: [],
        likes: []
      }
      return b.merge!(h)
    end
  end

  # host manager
  def self.[] k
    Host.new k
  end
  class Host
    def initialize h
      @host = h
      @jobs = JOBS.new h
      Z4.priv.to_h.keys.each do |e|
        h = {
          titles: "#{e}",
          groups: "#{e}s"
        }
        @jobs[e.to_sym] = h
      end
      Z4.rank.to_h.keys.each do |e|
        h = {
          titles: "#{e}",
          groups: "#{e}s"
        }
        @jobs[e.to_sym] = h
      end
      @db = Hash.new { |h,k| h[k] = DB.new(@host, k) }
    end
    def id
      @host
    end
    def uri
      if /.onion/.match(@host) || /\d+.\d+.\d+.\d+/.match(@host) || @host == 'localhost'
        pre = 'http'
      else
        pre = 'https'
      end
      return "#{pre}://#{@host}"
    end
    # lookup
    def [] k
      @db[k]
    end

    # generic positions on host
    def jobs
      @jobs
    end

    def config t, u, h={}
      h.each_pair {|k,v| @db[t].update(u, k, v) }
    end
    
    ##
    # hire user as job for group
    def hire u, j, g
      give u, @jobs[j.to_s]
      @db[:users].add u, 'groups', g
      @db[:groups].add g, 'users', u
      @db[:groups].add g, 'titles', j.to_s
      @db[:badges].add j.to_s, 'groups', g
      @db[:badges].add j.to_s, 'users', u
    end
    ##
    # fire user as job from group
    def fire u, j, g
      take u, @jobs[j.to_s]
      @db[:users].rem u, 'groups', g
      @db[:groups].rem g, 'users', u
      @db[:groups].rem g, 'titles', j.to_s
      @db[:badges].rem j.to_s, 'groups', g
      @db[:badges].rem j.to_s, 'users', u
    end

    # friendships
    ##
    # friend friend for user
    def friend u, f 
      @db[:users].add u, 'users', f
    end
    ##
    # unfriend friend from user
    def unfriend u, f
      @db[:users].rem u, 'users', f
    end

    # following
    ##
    # follow user group
    def follow u, f
      @db[:users].add u, 'groups', f
    end
    ##
    # unfollow user group
    def unfollow u, f
      @db[:users].rem u, 'groups', f
    end

    # visits
    ##
    # user visits
    def seen u, s
      @db[:users].add u, 'see', s
      @db[:users].add s, 'seen', u
    end
    ##
    # group visits
    def visit u, g
      @db[:users].add u, 'visited', g
      @db[:groups].add g, 'visited', u
    end
    ##
    # group reccomended
    def like u, g
      @db[:users].add u, 'likes', g
      @dg[:groups].add g, 'likes', u
    end
    def unlike u, g
      @db[:users].rem u, 'likes', g
      @db[:groups].rem g, 'likes', u
    end
    
    # location
    def locate u, p
      @db[:users].update u, 'location', p
    end
    def delocate u
      locate u, nil
    end
    
    # levels
    def priv u, n
      hire u, Z4.priv.to_h.keys[n.to_i].to_sym, @host
      if @db[:users][u]['class'].to_i < n.to_i
        @db[:users].update u, 'class', n.to_i
      end
    end
    def rank u, n
      hire u, Z4.rank.to_h.keys[n.to_i].to_sym, @host
      if @db[:users][u]['rank'].to_i < n.to_i
        @db[:users].update u, 'rank', n.to_i
      end
    end
    
    # bank
    def xfer **h
      @db[:users].mod h[:to], 'credits',  h[:amt]
      @db[:users].mod h[:from], 'credits', -h[:amt]
    end
    def mint u, k, a
      @db[:users].mod u, k, a
    end
    def burn u, k, a
      @db[:users].mod u, k, a
    end

    #auth
    def auth
      AUTH.new(@host)
    end
    
    # reactive db
    def give u, h={}
      h.each_pair do |k,v|
        @db[:users].add u, k.to_s, v
        @db[k].add v, 'users', u
      end
    end
    def take u, h={}
      h.each_pair do |k,v|
        @db[:users].rem u, k.to_s, v
        @db[k].rem v, 'users', u
      end
    end

    # genetic matching
    def match_user u, *m
      hh, hr = {}, {}
      usr = @db[:users][u]
      [m].flatten.each { |e| hh[e] = @db[:users][e] }
      hh.each_pair do |user, h|
        r = {}
        [:items, :users, :groups, :badges, :titles, :seen, :see, :visited, :likes].each { |e|
          s = usr[e.to_s].intersection(h[e.to_s])
          hm = h[e.to_s].length + 1
          sm = s.length + 1
          ucm = usr[e.to_s].length + 1
          r[e] = {
            max: hm + ucm,
            union: sm,
            score: ( hm + ucm ) / sm,
            data: s
          }
        }
        hr[user] = r
      end
      return hr
    end
    def match_tag u, t, *g
      hr = {}
      [g].flatten.each do |grp|
        hr[grp] = match_user(u, @db[t][grp]['users'].to_a)
      end
      return hr 
    end
  end #host
end

##
# @host API
#
# COMPATABILITY
# match_tag 'user', :tag, *values
# match_user 'user', *users
#
# RECOURCES
# hire 'user', :job, 'group'
# fire 'user', :job, 'group'
#
# SOCIAL
# follow 'user', 'follower'
# unfollow 'user', 'follower'
# friend 'user', 'friend'
# unfriend 'user', 'friend'
#
# NETWORK
# seen 'user', 'u'
#
# RECCOMENDATIONS
# like 'user', 'group'
# unlike 'user', 'group'
# visit 'user', 'group'
#
# GPS
# locate 'user', 'location'
# delocate 'user'
#
# ACCESS
# priv 'user', lvl
# rank 'user', lvl
#
# ITEMS
# mint 'user', 'type', amount
# burn 'user', 'type', amount
#
# FINANCE
# xfer from: 'user', to: 'user', amt: amount
#
# CONFIG
# config :type, 'id', key: 'value'
