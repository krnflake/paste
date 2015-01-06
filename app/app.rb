require "sinatra/base"
require "leveldb"
require "json"

class App < Sinatra::Base
    set :public_folder, "public"

    dir = "uploads"
    Dir.mkdir(dir) unless Dir.exists?(dir)

    configure do
        URL = "https://boar.krn.ovh"
        DB = LevelDB::DB.new 'leveldb'
    end

    get "/" do
        code = <<-END
boar(1)                          BOAR                          boar(1)

NAME
boar: minimalistic code sharing website.

SYNOPSIS
use this form and the buttons on the left

SYNOPSIS CMD
<command> | curl -F 'code=<-' https://boar.krn.ovh/p

DESCRIPTION
add an file extension to the url to get syntax highlighting

EXAMPLES
~$ cat bin/ching | curl -F 'code=<-' https://boar.krn.ovh/p
{"success":true,"key":"aXZI","link":"https://boar.krn.ovh/aXZI","raw":"https://boar.krn.ovh/r/aXZI.txt"}
~$ firefox https://boar.krn.ovh/aXZI
        END
        erb :index, :locals => { :key => nil, :code => code }
    end

    get "/:key" do
        key = params[:key]
        key = key[0 .. key.index(".") - 1] unless key.index(".").nil?
        redirect to('/') unless DB.exists?(key)
        blob = JSON.parse(DB.get(key))
        target = %(#{dir}/#{blob["filename"]})
        code = File.open(target, "r") { |f| f.read() }
        erb :index, :locals => { :key => key, :code => code }
    end

    post "/p" do
        content_type :json
        key = genHash()
        if params[:code] && !params[:code].empty?
            ext = ".txt"
            target = "#{dir}/#{key + ext}"
            File.open(target, "wb") { |f| f.write(params[:code]) }
        elsif params[:blob] then
            blob = params[:blob]
            ext = File.extname(blob[:filename])
            target = "#{dir}/#{key + ext}"
            File.open(target, "wb") { |f| f.write blob[:tempfile].read }
        else
            halt 403, "Forbidden"
        end
        DB.put(key, { :key => key, :filename => "#{key + ext}", :ip => request.ip, :time => DateTime.now  }.to_json)
        { :success => true, :key => key, :link => "#{URL}/#{key}", :raw => "#{URL}/r/#{key + ext}" }.to_json
    end

    get "/r/:key" do
        key = params[:key]
        key = key[0 .. key.index(".") - 1] unless key.index(".").nil?
        redirect to('/') unless DB.exists?(key)
        blob = JSON.parse(DB.get(key))
        target = %(#{dir}/#{blob["filename"]})
        send_file target
    end

    def genHash(i = 4)
        hash = [*("a".."z"), *("A".."Z"), *("0".."9"), "-", "_", ".", "~"].shuffle[0, i].join
        hash = genHash(i + 1) if DB.exists?(hash)
        hash
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
end
