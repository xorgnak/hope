
module Z4
  # cute cat face.
  def self.info
    puts "=^.^="
  end
  # very basic color scheme
  COLORS = [
    "black",
    "yellow",
    "green",
    "blue",
    "purple",
    "red",
    "orange",
    "lightblue",
    "silver",
    "gold"
  ]
  def self.fg
    COLORS
  end
  def self.bd
    COLORS
  end
  def self.bg
    COLORS.reverse
  end
  

  
  # app privledges
  RANKS     = ['outsider', 'regular', 'local', 'ledgend', 'royalty']
  RANK_PRIV = ['visit',    'scan',    'zap',   'tag',     'award']

  def self.rank
    a = []
    RANKS.each_with_index { |e, i| a[i] = [e, RANK_PRIV[0..i]]  }
    return a
  end

  # authed privledges
  CLASSES    = ['onboard',  'member',   'influencer', 'ambassador', 'manager', 'agent', 'operator']
  CLASS_PRIV = ['train',    'invite', 'messenger',  'tag',        'group',   'area',  'system']

  def self.priv
    a = []
    CLASSES.each_with_index { |e, i| a[i] = [e,  CLASS_PRIV[0..i]] }
    return a
  end
  
  # ENTITY attributes
  class X
    def initialize
      @x = {}
      @category = Hash.new {|h,k| h[k] = [] }
      @tag = Hash.new {|h,k| h[k] = [] }
      @alias = Hash.new {|h,k| h[k] = [] }
      Emoji.all.each {|e|
        @x[e.name] = {
          raw: e.raw,
          image: e.image_filename,
          desc:  e.description
        }
        e.tags.each { |x| @tag[x] << e.name }
        e.aliases.each { |x| @alias[x] << e.name }
        @category[e.category] << e.name
      }
      [
        "total: #{@x.keys.length}",
        "categories: #{@category.keys.length}",
        "tags: #{@tag.keys.length}",
        "aliases: #{@alias.keys.length}"
      ].each {|e| puts e }
    end
    def category
      @category
    end
    def tag
      @tag
    end
    def alias
      @alias
    end
    def json
      JSON.generate(@x)
    end
    def all
      h = {}
      @x.each_pair {|k,v| h[k] = v[:raw] }
      return h
    end
    def [] k
      if @x.has_key? k
        @x[k]
      elsif @category.has_key? k
        @category[k]
      elsif @tag.has_key? k
        @tag[k]
      elsif @alias.has_key? k
        @alias[k]
      end
    end
  end
  @@X = X.new
  def self.x
    @@X
  end
  
  
  @@XX = Redis::Set.new("Z4::XX")
  class Xx
    include Redis::Objects
    sorted_set :stat
    hash_key :attr
    def initialize i
      @id = i
    end
    def id; @id; end
    def icon
      Z4.x[self.attr[:icon]]
    end
  end
  def self.xx *k
    if k[0]
      @@XX << k[0]
      Xx.new(k[0])
    else
      @@XX.members
    end
  end
end
