module Artifactory
  class Resource::Artifact < Resource::Base
    class << self
      def search(name, options = {})
        query = {}.tap do |h|
          h[:name]  = name || '.*'
          h[:repos] = Array(options[:repos]).join(',') if options[:repos]
        end

        _get('/api/search/artifact', query).json['results'].map do |artifact|
          from_url(artifact['uri'])
        end
      end

      def from_url(url)
        from_hash(_get(url).json)
      end

      def from_hash(hash)
        new.tap do |instance|
          instance.api_path      = hash['uri']
          instance.md5           = hash['checksums']['md5']
          instance.sha1          = hash['checksums']['sha1']
          instance.created       = Time.parse(hash['created'])
          instance.download_path = hash['downloadUri']
          instance.last_modified = Time.parse(hash['lastModified'])
          instance.last_updated  = Time.parse(hash['lastUpdated'])
          instance.size          = hash['size']
        end
      end
    end

    attribute :api_path
    attribute :created
    attribute :download_path
    attribute :last_modified
    attribute :last_updated
    attribute :local_path
    attribute :md5
    attribute :sha1
    attribute :size

    #
    #
    #
    def initialize

    end

    #
    # The list of properties for this object.
    #
    # @example List all properties for an artifact
    #   artifact.properties #=> { 'artifactory.licenses'=>['Apache-2.0'] }
    #
    # @return [Hash<String, Object>]
    #   the list of properties
    #
    def properties
      @properties ||= _get(api_path, properties: nil).json['properties']
    end

    #
    # Download the artifact onto the local disk. If the local path already
    # exists on the object, it will be used; othwerise, +:to+ is a required
    # option. If the remote_path already exists on the object, it is used;
    # otherwise +:from+ is a required option.
    #
    # @example Download a remote artifact locally
    #   artifact.download(to: '~/Desktop/artifact.deb')
    #
    # @example Download an artifact into a folder
    #   # If a folder is given, the basename of the file is used
    #   artifact.download(to: '~/Desktop') #=> ~/Desktop/artifact.deb
    #
    # @example Download a local artifact from the remote
    #   artifact.download(from: '/libs-release-local/org/acme/artifact.deb')
    #
    # @example Download an artifact with pre-populated fields
    #   artifact.download #=> `to` and `from` are pulled from the object
    #
    # @param [Hash] options
    # @option options [String] to
    #   the path to download the artifact to disk
    # @option options [String] from
    #   the remote path on artifactory to download the artifact from
    #
    # @return [String]
    #   the path where the file was downloaded on disk
    #
    def download(options = {})
      options[:to]   ||= local_path    || raise('Local destination must be set!')
      options[:from] ||= download_path || raise('Remote path must be given!')

      destination = File.expand_path(options[:to])

      # If they gave us a folder, use the object's filename
      if File.directory?(destination)
        destination = File.join(destination, File.basename(options[:from]))
      end

      File.open(destination, 'wb') do |file|
        file.write(_get(options[:from]).body)
      end

      destination
    end
  end
end
