# frozen_string_literal: true

require 'dotenv/load'
require 'json'
require_relative './chroma_api_client'
require_relative './gemini_service'
require_relative './vector_db_connector'

CHROMA_URL = 'http://localhost:8000'
COLLECTION_NAME = 'resume_data'
API_KEY = ENV['GEMINI_API_KEY']
# A simple wrapper to run the script and print friendly errors.
def run_rag_system
  puts "RAG system starting..."

  # 1. Initialize services
  chroma_client = ChromaApiClient.new(url: CHROMA_URL)
  gemini_service = GeminiService.new(api_key: API_KEY)

  # 2. Initialize the main connector
  rag_connector = VectorDBConnector.new(
    chroma_client: chroma_client,
    gemini_service: gemini_service,
    collection_name: COLLECTION_NAME
  )

  puts "Attempting to delete collection '#{COLLECTION_NAME}' (if it exists)..."
  rag_connector.delete_collection!

  # 3. Ensure the collection exists
  puts "Ensuring collection '#{COLLECTION_NAME}' exists..."
  rag_connector.ensure_collection_exists!

  # 4. Define sample data to seed
  sample_documents = [
    "Ashwin Kumar is a Ruby on Rails developer with 8 years of experience.",
    "He specializes in backend systems and API development.",
    "His recent project involved building a high-availability e-commerce platform.",
    "Gajalakshmi Sasidharan is a student at the Frankfurt University of Applied Sciences.",
    "Ashwin is actively looking for a new software engineer role in Berlin."
  ]

  # 5. Seed the data
  puts "Seeding #{sample_documents.length} documents..."
  rag_connector.seed_data(sample_documents)

  puts "\n✅ Data seeding complete."

  puts "\n--- Ready to answer questions ---"
  puts "Type your question and press Enter. Type 'exit' to quit."

  loop do
    print "\nQuestion: "
    question = gets.chomp

    break if question.downcase == 'exit'
    next if question.empty?

    puts "\nWorking..."
    answer = rag_connector.ask(question: question)

    puts "\n--- Generated Answer ---"
    puts answer
    puts "------------------------"
  end

  puts "Exiting RAG system. Goodbye!"

rescue => e
  puts "\n❌ FAILURE: An unexpected error occurred."
  puts "    Error details: #{e.message}"
  # Print the first line of the backtrace to show where the error happened
  puts e.backtrace.first.prepend('    ')
end

# --- Script execution ---
if __FILE__ == $0
  unless API_KEY
    puts "Error: GEMINI_API_KEY not found. Please create a .env file with this key."
    exit 1
  end

  run_rag_system
end
