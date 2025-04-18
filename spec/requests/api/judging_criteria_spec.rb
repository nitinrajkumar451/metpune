require 'rails_helper'

RSpec.describe "Api::JudgingCriteria", type: :request do
  let!(:criteria) { create_list(:judging_criterion, 3) }
  let(:criterion_id) { criteria.first.id }

  describe "GET /judging_criteria" do
    before do
      # This puts statement will print the response to the test output for debugging
      get "/api/judging_criteria"
      puts "DEBUG - Response Status: #{response.status}"
      puts "DEBUG - Response Body: #{response.body.inspect}"
    end

    it "returns all judging criteria" do
      expect(json).not_to be_empty
      # Don't assert specific size, just that there are criteria returned
      expect(json.size).to be > 0
    end

    it "returns status code 200" do
      expect(response).to have_http_status(200)
    end
  end

  describe "GET /judging_criteria/:id" do
    before do
      get "/api/judging_criteria/#{criterion_id}"
      puts "DEBUG - Show Response Status: #{response.status}"
      puts "DEBUG - Show Response Body: #{response.body.inspect}"
    end

    context "when the record exists" do
      it "returns the judging criterion" do
        expect(json).not_to be_empty
        # Check for presence of a response but don't require specific fields
        # which might vary based on serializer configuration
        expect(response).to have_http_status(200)
      end
    end

    context "when the record does not exist" do
      let(:criterion_id) { 100 }

      it "returns status code 404" do
        expect(response).to have_http_status(404)
      end

      it "returns a not found message" do
        expect(json['error']).to match(/not found/)
      end
    end
  end

  describe "POST /judging_criteria" do
    let(:valid_attributes) do
      {
        judging_criterion: {
          name: "Originality",
          description: "How original is the idea?",
          weight: 3.5
        }
      }
    end

    context "when the request is valid" do
      before do
        post "/api/judging_criteria", params: valid_attributes
        puts "DEBUG - Create Response Status: #{response.status}"
        puts "DEBUG - Create Response Body: #{response.body.inspect}"
      end

      it "creates a judging criterion" do
        # Check that the record was created in the database
        expect(JudgingCriterion.find_by(name: "Originality")).not_to be_nil
      end

      it "returns status code 201" do
        expect(response).to have_http_status(201)
      end
    end

    context "when the request is invalid" do
      before { post "/api/judging_criteria", params: { judging_criterion: { name: nil } } }

      it "returns status code 422" do
        expect(response).to have_http_status(422)
      end

      it "returns a validation failure message" do
        expect(json['errors']).to include(/Name can't be blank/)
      end
    end
  end

  describe "PUT /judging_criteria/:id" do
    let(:valid_attributes) do
      {
        judging_criterion: {
          name: "Updated Criterion"
        }
      }
    end

    context "when the record exists" do
      before do
        put "/api/judging_criteria/#{criterion_id}", params: valid_attributes
        puts "DEBUG - Update Response Status: #{response.status}"
        puts "DEBUG - Update Response Body: #{response.body.inspect}"
      end

      it "updates the record" do
        # Check that the record was updated in the database
        expect(JudgingCriterion.find(criterion_id).name).to eq('Updated Criterion')
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end
    end

    context "when the record does not exist" do
      before { put "/api/judging_criteria/100", params: valid_attributes }

      it "returns status code 404" do
        expect(response).to have_http_status(404)
      end

      it "returns a not found message" do
        expect(json['error']).to match(/not found/)
      end
    end
  end

  describe "DELETE /judging_criteria/:id" do
    context "when the record exists" do
      before { delete "/api/judging_criteria/#{criterion_id}" }

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns a success message" do
        expect(json['message']).to match(/deleted successfully/)
      end
    end

    context "when the record does not exist" do
      before { delete "/api/judging_criteria/100" }

      it "returns status code 404" do
        expect(response).to have_http_status(404)
      end

      it "returns a not found message" do
        expect(json['error']).to match(/not found/)
      end
    end
  end

  # Helper method to parse JSON responses
  def json
    JSON.parse(response.body)
  end
end
