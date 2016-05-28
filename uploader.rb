# encoding: utf-8
#
# photo uploader via API REST
#
# André Camargo
# Portais Eletrônicos
# May 2016
#
# Script to upload timestamp named photos to Fenadoce's photo gallery
#
# $ ruby uploader.rb <photos path>

require 'yaml'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'
require 'base64'
require 'date'

if File.exist? 'uploader.yml'
  config = YAML.load_file('uploader.yml')
else
  puts "Configure o uploader.yml com as credenciais de acesso a API do site ;-)"
  exit 1
end

photos_dir = File.expand_path(ARGV[0] || '.')

uploaded_dir = photos_dir + '/uploaded'
FileUtils.mkdir_p uploaded_dir unless File.exists? uploaded_dir

api_endpoint = config['url']
uri = URI(api_endpoint)

RootCA = File.expand_path('./cacert.pem')

while true
    puts
    puts DateTime.now
    files = Dir[photos_dir+'/[0-9][0-9][0-9][0-9]_[0-9][0-9]_[0-9][0-9]-[0-9][0-9]_[0-9][0-9]_[0-9][0-9].PNG']
    files_total = files.length
    files.each.with_index(1) do |photo_path, i|
        puts "%s %04d/%04d %s" % [DateTime.now, i, files_total, photo_path]

        photo_timestamp = File.basename(photo_path, '.PNG')
        photo_timestamp.gsub!(/[^\d]/, '')
        photo_year = photo_timestamp[0,4]
        photo_month = photo_timestamp[4,2]
        photo_day = photo_timestamp[6,2]
        photo_hour = photo_timestamp[8,2]
        photo_minute = photo_timestamp[10,2]
        photo_second = photo_timestamp[12,2]

        params = {}
        params['horario'] = photo_day+'/'+photo_month+'/'+photo_year+' '+photo_hour+':'+photo_minute+':'+photo_second
        params['imagem[_][upload]'] = 'remote'
        params['imagem[_][url]'] = 'data:image/png;base64,'+Base64.encode64(File.open(photo_path, 'rb').read).chop

        request = Net::HTTP::Post.new(uri.path)
        request.basic_auth config['username'], config['password']
        request.set_form_data(params)

        start_time = Time.now

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.ca_file = RootCA
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.verify_depth = 5
        #http.set_debug_output($stdout)
        response = http.start {|http| http.request(request)}

        end_time = Time.now

        puts "%s %s %.3fs" % [DateTime.now, response.code, end_time - start_time]

        if response.code.to_i == 201
            destination_path = uploaded_dir + '/' +photo_year+'/'+photo_month+'/'+photo_day+'/'+photo_hour
            FileUtils.mkdir_p destination_path unless File.exists? destination_path
            FileUtils.mv photo_path, destination_path
        else
            puts response.body
        end
    end
    sleep 60
end
