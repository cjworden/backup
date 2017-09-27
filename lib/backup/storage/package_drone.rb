require 'net/http'
require 'uri'
require 'pp'

module Backup
  module Storage
    class PackageDrone < Base
      class Error < Backup::Error; end

      ##
      # Package Drone Credentials
      attr_accessor :base_uri, :channel_id, :deploy_key, :username, :meta_data

      def initialize(model, storage_id = nil)
        super
        @uri = "#{@base_uri}/api/v3/upload/plain/channel/#{@channel_id}/"
        # @path ||= "~/backups"
      end

      private

      def transfer!
        package.filenames.each do |filename|
          src = File.join(Config.tmp_path, filename)
          Logger.info "Storing '#{src}'..."

          upload(filename, src)
        end
      end

      def upload(filename, src)
        full_uri = URI.parse("#{@uri}#{filename}")
        if @meta_data
          full_uri += "?#{@meta_data}"
        end

        Logger.info "Issuing API call to #{full_uri}"

        request = Net::HTTP::Put.new(full_uri)
        request.body = ''
        request.body << File.read(src).delete("\r\n")
        request.basic_auth(@username, @deploy_key)

        req_options = {
            use_ssl: full_uri.scheme == 'https',
        }

        response = Net::HTTP.start(full_uri.hostname, full_uri.port, req_options) do |http|
          http.request(request)
        end

        Logger.info("Response: #{response.body}")
      end

      def check_configuration
        required = %w[uri channel_id deploy_key]
        raise Error, <<-EOS if required.map { |name| send(name) }.any?(&:nil?)
          Configuration Error
          #{required.map { |name| "##{name}" }.join(', ')} are all required
        EOS
      end
    end
  end
end
