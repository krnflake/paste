
#! /usr/bin/env ruby

require "sinatra/base"
require "leveldb"
require "json"

class App < Sinatra::Base
    Encoding.default_external = "UTF-8"

    set :public_folder, "public"
    set :bind, "0.0.0.0"

    dir = "uploads"
    Dir.mkdir(dir) unless Dir.exists?(dir)

    configure do
        URL = "https://paste.krnflake.ovh"
        DB = LevelDB::DB.new "leveldb"
    end

    get "/" do
        code = <<-END
boar(1)                          BOAR                          boar(1)

NAME
boar: minimalistic code sharing website.

SYNOPSIS
use this editor and the buttons on the left
file upload requires a modern browser
drag and drop a file on the left sidebar to upload it

SYNOPSIS CMD
<command> | curl -F 'code=<-' https://paste.krnflake.ovh

DESCRIPTION
add an file extension to the url to get syntax highlighting
size limit is 5 MB

EXAMPLES
~$ cat bin/ching | curl -F 'code=<-' https://paste.krnflake.ovh
{"success":true,"key":"aXZI","link":"https://paste.krnflake.ovh/aXZI","raw":"https://boar.krnflake.ovh/r/aXZI.txt"}
~$ firefox https://paste.krnflake.ovh/aXZI
        END
        erb :index, :locals => { :key => nil, :code => code }
    end

    post "/" do
        content_type :json
        key = genHash()

        if params[:code] && !params[:code].empty?
            ext = ".txt"
            target = "#{dir}/#{key + ext}"
            File.open(target, "wb") { |f| f.write(params[:code]) }
        elsif params[:blob] then
            blob = params[:blob]
            halt 403, "Forbidden" if blob.nil?
            ext = File.extname(blob[:filename])
            target = "#{dir}/#{key + ext}"
            File.open(target, "wb") { |f| f.write blob[:tempfile].read }
        else
            halt 403, "Forbidden"
        end

        DB.put(key, { :key => key, :filename => "#{key + ext}", :ip => request.ip, :time => DateTime.now  }.to_json)
        { :success => true, :key => key, :link => "#{URL}/#{key}", :raw => "#{URL}/r/#{key + ext}" }.to_json
    end

    get "/:key" do
        key = params[:key]
        key = key[0 .. key.index(".") - 1] unless key.index(".").nil?
        halt 404, "Not Found" unless DB.exists?(key)
        blob = JSON.parse(DB.get(key))
        target = %(#{dir}/#{blob["filename"]})
        code = File.open(target, "r") { |f| f.read() }
        erb :index, :locals => { :key => key, :code => code }
    end

    get "/r/:key" do
        key = params[:key]
        key = key[0 .. key.index(".") - 1] unless key.index(".").nil?
        halt 404, "Not Found" unless DB.exists?(key)
        blob = JSON.parse(DB.get(key))
        target = %(#{dir}/#{blob["filename"]})
        File.open(target, "r") { |f| p f.inspect }
        response.headers["Access-Control-Allow-Origin"] = "*" # CORS
        send_file target
    end

    def genHash(i = 4)
        hash = [*("a".."z"), *("A".."Z"), *("0".."9"), "-", "_", "~"].shuffle[0, i].join
        hash = genHash(i + 1) if DB.exists?(hash)
        hash
    end

    helpers do
        def raw(text)
            Rack::Utils.escape_html(text)
        end
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
end
