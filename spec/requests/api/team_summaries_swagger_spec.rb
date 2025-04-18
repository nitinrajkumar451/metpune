require 'swagger_helper'

RSpec.describe 'Team Summaries API', type: :request do
  path '/api/team_summaries' do
    get 'Lists all team summaries' do
      tags 'Team Summaries'
      produces 'application/json'
      parameter name: :status, in: :query, schema: { type: :string, enum: [ 'pending', 'processing', 'success', 'failed' ] }, required: false,
                description: 'Filter team summaries by status'

      response '200', 'team summaries found' do
        schema type: :object,
               properties: {
                 team_summaries: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/TeamSummary' }
                 }
               },
               required: [ 'team_summaries' ]

        let(:status) { 'success' }
        run_test!
      end
    end
  end

  path '/api/team_summaries/{team_name}' do
    get 'Retrieves a team summary' do
      tags 'Team Summaries'
      produces 'application/json'
      parameter name: :team_name, in: :path, type: :string, required: true,
                description: 'Team name'

      response '200', 'team summary found' do
        schema type: :object,
               properties: {
                 team_summary: { '$ref' => '#/components/schemas/TeamSummary' }
               },
               required: [ 'team_summary' ]

        let(:team_name) { create(:team_summary).team_name }
        run_test!
      end

      response '404', 'team summary not found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: [ 'error' ]

        let(:team_name) { 'nonexistent' }
        run_test!
      end
    end
  end

  path '/api/team_summaries/generate' do
    post 'Generates a comprehensive summary for a team' do
      tags 'Team Summaries'
      produces 'application/json'
      parameter name: :team_name, in: :query, schema: { type: :string }, required: true,
                description: 'The team name to generate a summary for'

      response '200', 'team summary generation started' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               },
               required: [ 'message' ]

        let(:team_name) { create(:submission, :success).team_name }
        run_test!
      end

      response '400', 'invalid request' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: [ 'error' ]

        let(:team_name) { 'nonexistent' }
        run_test!
      end
    end
  end
end
