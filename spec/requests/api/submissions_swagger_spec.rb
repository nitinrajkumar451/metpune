require 'swagger_helper'

RSpec.describe 'Submissions API', type: :request do
  path '/api/submissions' do
    get 'Lists all submissions' do
      tags 'Submissions'
      produces 'application/json'
      parameter name: :status, in: :query, schema: { type: :string, enum: [ 'pending', 'processing', 'success', 'failed' ] }, required: false,
                description: 'Filter submissions by status'
      parameter name: :team_name, in: :query, schema: { type: :string }, required: false,
                description: 'Filter submissions by team name'
      parameter name: :project, in: :query, schema: { type: :string }, required: false,
                description: 'Filter submissions by project'

      response '200', 'submissions found' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/Submission' }

        let(:status) { 'success' }
        run_test!
      end
    end
  end

  path '/api/submissions/{id}' do
    get 'Retrieves a submission' do
      tags 'Submissions'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true,
                description: 'Submission ID'

      response '200', 'submission found' do
        schema '$ref' => '#/components/schemas/Submission'

        let(:id) { create(:submission).id }
        run_test!
      end

      response '404', 'submission not found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: [ 'error' ]

        let(:id) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/start_ingestion' do
    post 'Starts the document ingestion process' do
      tags 'Ingestion'
      produces 'application/json'

      response '200', 'ingestion process started' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               },
               required: [ 'message' ]

        run_test!
      end
    end
  end
end
