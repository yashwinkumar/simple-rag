# frozen_string_literal: true

require 'faraday'
require 'json'

# Communicates with the Google Gemini API for embeddings and text generation.
# Uses Faraday for HTTP requests and JSON for payload handling.
class GeminiService
  API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'
  attr_reader :api_key, :http_client

  def initialize(api_key:)
    @api_key = api_key
    @http_client = Faraday.new(url: API_URL) do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/json'
    end
  end

  EMBEDDING_MODEL = 'gemini-embedding-001'
  # @return [Array<Float>] The embedding vector.
  def get_embedding(text:)
    payload = {
      model: "models/#{EMBEDDING_MODEL}", # Model name is required in the body
      content: {
        parts: [ { text: text } ]
      }
    }
    response = @http_client.post("#{EMBEDDING_MODEL}:embedContent?key=#{api_key}") do |req|
      req.body = payload.to_json
    end

    unless response.success?
      raise "Gemini embedding request failed. Status: #{response.status}, Body: #{response.body}"
    end

    body = JSON.parse(response.body)
    body.dig('embedding', 'values') ||
      raise("Failed to parse embedding from Gemini response: #{body}")
  end

  GENERATION_MODEL = 'gemini-2.5-flash-preview-09-2025'
  # @return [String] The generated answer.
  def generate_answer(question:, context:)
    prompt = <<~PROMPT
      You are a helpful assistant. Answer the following question based *only*
      on the provided context. If the answer is not in the context, say
      "I do not have that information."

      Context:
      ---
      #{context}
      ---

      Question:
      #{question}
    PROMPT

    payload = {
      contents: [
        {
          parts: [ { text: prompt } ]
        }
      ]
    }
    
    response = @http_client.post("#{GENERATION_MODEL}:generateContent?key=#{api_key}") do |req|
      req.body = payload.to_json
    end

    unless response.success?
      raise "Gemini generation request failed. Status: #{response.status}, Body: #{response.body}"
    end

    body = JSON.parse(response.body)
    body.dig('candidates', 0, 'content', 'parts', 0, 'text') ||
      raise("Failed to parse answer from Gemini response: #{body}")
  end

  def delete_collection(name:)
    response = @http_client.delete("#{@base_collection_path}/collections/#{name}")
    
    if response.success? || response.status == 404
      return true
    end
    
    raise "Failed to delete collection. Status: #{response.status}, Body: #{response.body}"
  rescue Faraday::ConnectionFailed => e
    raise "Connection failed while trying to delete collection: #{e.message}"
  end
end
