# frozen_string_literal: true

require 'securerandom'

# This class orchestrates the ChromaDB client and the Gemini service.
class VectorDBConnector
  def initialize(chroma_client:, gemini_service:, collection_name:)
    @chroma_client = chroma_client
    @gemini_service = gemini_service
    @collection_name = collection_name
    @collection_id = nil
  end

  def ensure_collection_exists!
    response = @chroma_client.get_or_create_collection(name: @collection_name)
    @collection_id = response['id']
    unless @collection_id
      raise "Failed to get or create collection ID. Response: #{response}"
    end
  end

  # Deletes the collection to ensure a fresh start.
  def delete_collection!
    puts "  - Sending delete request for '#{@collection_name}'..."
    @chroma_client.delete_collection(name: @collection_name)
    @collection_id = nil
    puts "  - Delete request sent."
  rescue => e
    puts "  - Collection didn't exist or couldn't be deleted (ignored): #{e.message}"
  end

  # Seeds the ChromaDB collection with an array of text documents.
  # @param documents [Array<String>] An array of text strings to embed and add.
  def seed_data(documents)
    raise "Collection ID not set. Call ensure_collection_exists! first." unless @collection_id

    ids = []
    embeddings = []
    docs_to_add = []
    metadatas = []

    documents.each_with_index do |doc, i|
      puts "  - Embedding document #{i + 1}..."
      ids << "doc_#{SecureRandom.uuid}"
      embeddings << @gemini_service.get_embedding(text: doc)
      docs_to_add << doc
      metadatas << { source: "seed_data_#{i + 1}" }
    end

    puts "Adding documents to ChromaDB..."
    payload = {
      ids: ids,
      embeddings: embeddings,
      documents: docs_to_add,
      metadatas: metadatas
    }

    @chroma_client.add(
      collection_id: @collection_id,
      payload: payload
    )
  end

  # Asks a question, retrieves relevant documents, and generates an answer.
  # @param question [String] The user's question.
  # @return [String] The generated answer.
  def ask(question:)
    raise "Collection ID not set. Call ensure_collection_exists! first." unless @collection_id

    puts "Embedding question..."
    query_embedding = @gemini_service.get_embedding(text: question)

    puts "Querying ChromaDB for relevant documents..."
    query_response = @chroma_client.query(
      collection_id: @collection_id,
      query_embeddings: [ query_embedding ],
      results_count: 3
    )
    relevant_docs = query_response['documents']&.first || []
    context = relevant_docs.join("\n\n---\n\n")

    if context.empty?
      puts "No relevant documents found."
      return "I'm sorry, I couldn't find any relevant information to answer that question."
    end

    puts "Generating answer based on context..."
    @gemini_service.generate_answer(question: question, context: context)
  end

end
