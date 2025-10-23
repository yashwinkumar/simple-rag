# RAG Simple

A simple implementation of a Retrieval-Augmented Generation (RAG) system using Ruby.

## Overview

This project demonstrates a basic RAG system. It retrieves relevant information from a ChromaDB vector database based on a user's question and then uses the Gemini API to generate an answer based on the retrieved context.

## Features

*   Connects to a ChromaDB instance to store and retrieve document embeddings.
*   Uses the Gemini API for generating embeddings and answering questions.
*   Includes sample data seeding for initial setup.
*   Provides a command-line interface for asking questions and receiving answers.

## Dependencies

*   Ruby (version 3.2.2 or higher)

    *   `chromadb` (version X.X.X) -  ChromaDB is used as the vector database to store and retrieve document embeddings efficiently. This allows for semantic search and retrieval of relevant context for question answering.
    *   `google-generative-ai` (version X.X.X) - The Gemini API is used for generating embeddings and generating answers.

## Setup

1.  **Install Ruby:** Make sure you have Ruby installed (version X.X.X or higher). You can download it from [https://www.ruby-lang.org/en/downloads/](https://www.ruby-lang.org/en/downloads/).

2.  **Install Dependencies:**

    ```bash
    bundle install
    ```

3.  **Set up Environment Variables:**

    *   Create a `.env` file in the project root.
    *   Add your Gemini API key:

        ```
        GEMINI_API_KEY=YOUR_GEMINI_API_KEY
        ```

4.  **Start ChromaDB:**
    *   Make sure you have a ChromaDB instance running. By default, the application connects to `http://localhost:8000`.  Refer to ChromaDB documentation on how to setup the DB.

## Usage

1.  **Run the RAG System:**

    ```bash
    ruby run_rag.rb
    ```

2.  **Ask Questions:**

    *   The script will prompt you to enter your question.
    *   Type your question and press Enter.
    *   The system will retrieve relevant documents and generate an answer using the Gemini API.
    *   Type `exit` to quit.

## Code Structure

*   `chroma_api_client.rb`: Handles communication with the ChromaDB API.
*   `gemini_service.rb`: Handles communication with the Gemini API.
*   `vector_db_connector.rb`: Orchestrates the ChromaDB client and Gemini service to perform RAG.
*   `run_rag.rb`:  Main script to run the RAG system.
*   `Gemfile`: Lists the project dependencies.
*   `.env`: Stores environment-specific variables (like API keys).

## Customization

*   **Adjusting the Context:**  Modify the prompt in `gemini_service.rb` to change how the context is presented to the Gemini API.
*   **Changing the Collection Name:**  Modify the `COLLECTION_NAME` constant in `run_rag.rb` to use a different ChromaDB collection.
*   **Seeding Data:** Modify the `sample_documents` array in `run_rag.rb` to seed the database with your own data.

## Contributing

Feel free to contribute to this project by submitting pull requests, reporting issues, or suggesting new features.

## License

This project is licensed under the [MIT License](LICENSE) - see the `LICENSE` file for details.
