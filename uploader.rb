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
  config = YAML.load('uploader.yml')
else
  puts "Configure o uploader.yml com as credenciais de acesso a API do site ;-)"
  exit 1
end

photos_dir = ARGV[0] || '.'

uploaded_dir = photos_dir + '/uploaded'
FileUtils.mkdir_p uploaded_dir unless File.exists? uploaded_dir

api_endpoint = "https://www.fenadoce.com.br/api/v1/realidade_aumentada_galeria_de_fotos.json"
uri = URI(api_endpoint)

RootCA = File.expand_path('./cacert.pem')

while true
    puts
    puts DateTime.now
    Dir[photos_dir+'/*.JPG'].each do |photo_path|
        puts photo_path

        photo_timestamp = File.basename(photo_path, '.JPG')
        photo_year = photo_timestamp[0,4]
        photo_month = photo_timestamp[4,2]
        photo_day = photo_timestamp[6,2]
        photo_hour = photo_timestamp[8,2]
        photo_minute = photo_timestamp[10,2]
        photo_second = photo_timestamp[12,2]

        params = {}
        params['horario'] = photo_day+'/'+photo_month+'/'+photo_year+' '+photo_hour+':'+photo_minute+':'+photo_second
        params['imagem[_][upload]'] = 'remote'
        params['imagem[_][url]'] = 'data:image/jpeg;base64,'+Base64.encode64(File.read(photo_path).chop)

        request = Net::HTTP::Post.new(uri.path)
        request.basic_auth config['username'], config['password']
        request.set_form_data(params)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.ca_file = RootCA
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.verify_depth = 5
        response = http.start {|http| http.request(request)}
        puts response.code
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
