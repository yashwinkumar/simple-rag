# frozen_string_literal: true

require 'faraday'
require 'json'

# This class is a simple HTTP client specifically for the ChromaDB v2 API.
class ChromaApiClient
  attr_reader :base_url, :tenant, :database, :base_collection_path, :http_client
  def initialize(url:)
    @base_url = url
    @tenant = 'default_tenant'
    @database = 'default_database'
    @base_collection_path = "/api/v2/tenants/#{@tenant}/databases/#{@database}"

    @http_client = Faraday.new(url: @base_url) do |faraday|
      faraday.request :json # Automatically sets Content-Type to application/json
      faraday.adapter Faraday.default_adapter
    end
  end

  # Checks if the ChromaDB server is alive.
  # @return [Boolean] True if the server returns a valid heartbeat.
  def alive?
    response = @http_client.get('/api/v2/heartbeat')
    return false unless response.success?
    body = JSON.parse(response.body)
    body.key?('nanosecond heartbeat')
  rescue Faraday::ConnectionFailed, JSON::ParserError
    false
  end

  # Gets a collection by name, or creates it if it doesn't exist.
  # @param name [String] The name of the collection.
  # @return [Hash] The JSON response body for the collection.
  def get_or_create_collection(name:)
    payload = { name: name, metadata: { 'hnsw:space': 'cosine' } }
    response = @http_client.post("#{@base_collection_path}/collections", payload.to_json)

    if response.success?
      body = JSON.parse(response.body)
      return body
    end

    raise "Failed to get or create collection. Status: #{response.status}, Body: #{response.body}"
  rescue Faraday::ConnectionFailed => e
    raise "Connection failed while getting/creating collection: #{e.message}"
  rescue JSON::ParserError
    raise "Failed to parse JSON response from get/create collection."
  end

  # Deletes a collection by its name.
  # @param name [String] The name of the collection to delete.
  def delete_collection(name:)
    response = @http_client.delete("#{@base_collection_path}/collections/#{name}")

    if response.success? || response.status == 404
      return true
    end

    raise "Failed to delete collection. Status: #{response.status}, Body: #{response.body}"
  rescue Faraday::ConnectionFailed => e
    raise "Connection failed while trying to delete collection: #{e.message}"
  end

  # Adds documents and their embeddings to a collection.
  # @param collection_id [String] The UUID of the collection.
  # @param payload [Hash] A hash containing ids, embeddings, documents, and metadatas.
  def add(collection_id:, payload:)
    response = @http_client.post("#{@base_collection_path}/collections/#{collection_id}/add", payload)

    if response.success?
      body = JSON.parse(response.body)
      return body
    end

    raise "Failed to add documents. Status: #{response.status}, Body: #{response.body}"
  rescue Faraday::ConnectionFailed => e
    raise "Connection failed while adding documents: #{e.message}"
  rescue JSON::ParserError
    raise "Failed to parse JSON response from add documents."
  end

  # Queries a collection for documents similar to the query embeddings.
  # @param collection_id [String] The UUID of the collection.
  # @param query_embeddings [Array<Array<Float>>] An array of query embeddings.
  # @param results_count [Integer] The number of results to return.
  def query(collection_id:, query_embeddings:, results_count:)
    payload = {
      query_embeddings: query_embeddings,
      n_results: results_count,
      include: %w[documents metadatas distances] # Include docs, metadata, and distances in the response
    }

    response = @http_client.post("#{@base_collection_path}/collections/#{collection_id}/query", payload.to_json)

    if response.success?
      body = JSON.parse(response.body)
      return body
    end

    raise "Failed to query collection. Status: #{response.status}, Body: #{response.body}"
  rescue Faraday::ConnectionFailed => e
    raise "Connection failed while querying collection: #{e.message}"
  rescue JSON::ParserError
    raise "Failed to parse JSON response from query."
  end
end
