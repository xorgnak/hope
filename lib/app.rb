module Z4
  
  class App < Sinatra::Base
    connections = {}
    configure do
      set :port, 4567
      set :bind, '0.0.0.0'
      set :views, 'views/'
      set :public_folder, 'public/'
    end

    helpers do
      def public_key
        @public_key ||= File.read('./vapid_keys/public_key')
      end

      def private_key
        @private_key ||= File.read('./vapid_keys/private_key')
      end
      def webpush h={}
        puts "WEBPUSH: #{h}"
        message = {
          title: h[:title] || @host.id,
          body: h[:body] || '',
          icon: h[:icon] || "http://example.com/icon.pn"
        }
        Webpush.payload_send(
          message: JSON.generate(message),
          endpoint: h['subscription']['endpoint'],
          p256dh: h['subscription']['keys']['p256dh'],
          auth: h['subscription']['keys']['auth'],
          vapid: {
            subject: "mailto:sender@example.com",
            public_key: public_key,
            private_key: private_key
          }
        )
      end
    end
    
    error do
      erb :error
    end
    
    before do
      @host = DB[request.host]
    end

    ##
    #
    #
    # PRE CONDITIONS
    #
    #
    ##

    get('/manifest.webmanifest') { content_type 'application/javascript'; erb :manifest, layout: false }
    get('/favicon.ico') {}
    get('/term') { erb :term }

    get('/sw.js') { content_type 'application/javascript'; erb :sw, layout: false }
    post('/sw') do
      content_type 'application/json'
#      webpush params
    end
    
    post '/' do
      puts "POST: " + JSON.generate(params)
      @out = {}
      @goto = @host.uri
      case params[:do]
      when 'auth'
        if params.has_key?(:invite) && "#{params[:user]}".length > 0
          @host.friend params[:invite], params[:user]
          @host.friend params[:user], params[:invite]
          @host.auth.auth! params[:user], params[:pass]
          @host[:users][params[:user]]
          params[:config].each_pair { |k,v| @host[:users].update(params[:user], k, v) }
        end
        if c = @host.auth.auth?(params[:user], params[:pass], params[:cha])
          tok = []; 16.times { tok << rand(16).to_s(16) }
          @goto += '/?cha=' + c + "&tok=" + tok.join('')
        end
      end
      redirect @goto
    end
    
    post('/js') do
      content_type 'application/json'
      puts "POSTJS: " + JSON.generate(params)
      if "#{@host.auth.session[params[:cha]]}".length > 0
        @user = @host.auth.session[params[:cha]]
      else
        @user = nil
      end
      @out = {}
      case params[:do]
      when 'visit'
      # scan user
      when 'give'
      # scan push
      when 'make'
      # create badge
        
      when 'config'
        params[:config].each_pair { |k,v| @host[:users].update(@host.auth.session[params[:cha]], k, v) }
        @out['reboot'] = true
      when 'admin'
        params[:config].each_pair { |k,v| @host[:groups].update(params[:group], k, v) }
        @out['reboot'] = true
      when 'group'
        if params.has_key? :groups
          params[:groups].each_pair { |g,h| h.each_pair { |k,v| @host[:groups].update(g, k, v) } }
          @out['reboot'] = true
        end
        if "#{params[:group][:name]}".length > 0
          @grp = params[:group][:name]
          @host[:groups].update(@grp, 'about', params[:group][:about])
          @host[:groups].update(@grp, 'desc', params[:group][:desc])
          @host[:groups].update(@grp, 'owner', @host.auth.session[params[:cha]])
          @host[:groups].update(@grp, 'parent', @host[:users][@user]['group'] || @host.id)
          @out['reboot'] = true
        end
      when 'feed'
        # mqtt push
      end
      return JSON.generate(@out)
    end
    
    get '*.img' do |path|
      if File.exists? "public/#{path}.img"
        return File.read "public/#{path}.img"
      else
        return ""
      end
    end

    post '/dev' do
      content_type 'application/json'
      g = params.delete(:goto)
      a = []; params.each_pair { |k,v| a << %[#{k}=#{v}] }
      params[:goto] = g + '/?' + a.join('&')
      return JSON.generate(params)
    end
    
    get '/dev' do
      if @host[:users].has_key? params[:u]
        if @host.auth.auth? params[:u], params[:p], @host.auth.session[params[:u]]
          @user = @host[:users][params[:u]];
          erb :box
        else
          redirect '/'
        end
      else
        redirect '/'
      end
    end
    
    get '/' do
      if params.has_key?(:cha) && "#{params[:cha]}".length > 0
        if params.has_key?(:tok) && "#{params[:tok]}".length > 0
          @user = @host[:users][@host.auth.session[params[:cha]]]
          erb :authed
        else
          erb :auth
        end
      else
        erb :app
      end
    end
    
    get '/*' do |p|
      case
      when /.*.js/.match(p)
        content_type 'application/javascript'
        return File.read "public/#{p}"
      when /.*.png/.match(p)
        content_type 'image/png'
        return File.read "public/#{p}"
      when /.*.jpg/.match(p) || /.*.jpeg/.match(p)
        content_type 'image/jpg'
        return File.read "public/#{p}"
      else
        @path = p.split('/')
        puts "GET: #{@path}"
        @user, @group, @badge = nil, nil, nil
        if @path[0]
          @user = @host[:users][CGI.unescape(@path[0])]
        end
        if @path[1]
          @group = @host[:groups][CGI.unescape(@path[1])]
        end
        if @path[2]
          @badge = @host[:badges][CGI.unescape(@path[2])]
        end
        puts "get: user: #{@user}\n\ngroup: #{@group}\n\nbadge: #{@badge}"
        erb :app
      end
    end
  end
  def self.run!
    Process.detach(fork { App.run! })
  end
end
