require 'spec_helper'

describe Boxr::BoxrError do
  let(:status) { 400 }
  let(:response_body) do
    '{"type":"error","status":400,"code":"bad_request","message":"Bad Request","request_id":"abc123"}'
  end
  let(:header) { { 'WWW-Authenticate' => ['Bearer realm="Service"'] } }
  let(:boxr_message) { 'Custom Boxr error message' }

  describe '#initialize' do
    context 'with all parameters' do
      let(:error) do
        described_class.new(status: status, body: response_body, header: header,
                            boxr_message: boxr_message)
      end

      it 'sets status' do
        expect(error.status).to eq(status)
      end

      it 'sets response_body' do
        expect(error.response_body).to eq(response_body)
      end

      it 'sets boxr_message' do
        expect(error.boxr_message).to eq(boxr_message)
      end

      it 'parses JSON body and sets attributes' do
        expect(error.type).to eq('error')
        expect(error.code).to eq('bad_request')
        expect(error.box_message).to eq('Bad Request')
        expect(error.request_id).to eq('abc123')
      end
    end

    context 'with minimal parameters' do
      let(:error) { described_class.new(status: 500) }

      it 'sets only status' do
        expect(error.status).to eq(500)
        expect(error.response_body).to be_nil
        expect(error.boxr_message).to be_nil
      end
    end

    context 'with invalid JSON body' do
      let(:error) { described_class.new(status: status, body: 'invalid json') }

      it 'handles JSON parsing gracefully' do
        expect(error.type).to be_nil
        expect(error.code).to be_nil
        expect(error.box_message).to be_nil
      end
    end

    context 'with nil body' do
      let(:error) { described_class.new(status: status, body: nil) }

      it 'handles nil body gracefully' do
        expect(error.type).to be_nil
        expect(error.code).to be_nil
        expect(error.box_message).to be_nil
      end
    end

    context 'with empty body' do
      let(:error) { described_class.new(status: status, body: '') }

      it 'handles empty body gracefully' do
        expect(error.type).to be_nil
        expect(error.code).to be_nil
        expect(error.box_message).to be_nil
      end
    end
  end

  describe '#message' do
    context 'with WWW-Authenticate header' do
      let(:error) { described_class.new(status: status, header: header) }

      it 'returns status and auth header' do
        expect(error.message).to eq('400: Bearer realm="Service"')
      end
    end

    context 'with empty WWW-Authenticate header' do
      let(:header) { { 'WWW-Authenticate' => [] } }
      let(:error) { described_class.new(status: status, header: header, body: response_body) }

      it 'falls back to box_message' do
        expect(error.message).to eq('400: Bad Request')
      end
    end

    context 'with nil WWW-Authenticate header' do
      let(:header) { { 'WWW-Authenticate' => nil } }
      let(:error) { described_class.new(status: status, header: header, body: response_body) }

      it 'falls back to box_message' do
        expect(error.message).to eq('400: Bad Request')
      end
    end

    context 'with missing WWW-Authenticate header' do
      let(:header) { {} }
      let(:error) { described_class.new(status: status, header: header, body: response_body) }

      it 'falls back to box_message' do
        expect(error.message).to eq('400: Bad Request')
      end
    end

    context 'with box_message' do
      let(:error) { described_class.new(status: status, body: response_body) }

      it 'returns status and box_message' do
        expect(error.message).to eq('400: Bad Request')
      end
    end

    context 'with boxr_message' do
      let(:error) { described_class.new(status: status, boxr_message: boxr_message) }

      it 'returns boxr_message' do
        expect(error.message).to eq(boxr_message)
      end
    end

    context 'with only status and response_body' do
      let(:error) { described_class.new(status: status, body: 'plain text error') }

      it 'returns status and response_body' do
        expect(error.message).to eq('400: plain text error')
      end
    end

    context 'with only status' do
      let(:error) { described_class.new(status: status) }

      it 'returns status and nil response_body' do
        expect(error.message).to eq('400: ')
      end
    end
  end

  describe '#to_s' do
    let(:error) { described_class.new(status: status, body: response_body) }

    it 'returns the same as message' do
      expect(error.to_s).to eq(error.message)
    end
  end

  describe 'attribute readers' do
    let(:error) do
      described_class.new(status: status, body: response_body, header: header,
                          boxr_message: boxr_message)
    end

    it 'provides read access to all attributes' do
      expect(error.status).to eq(status)
      expect(error.response_body).to eq(response_body)
      expect(error.type).to eq('error')
      expect(error.code).to eq('bad_request')
      expect(error.help_uri).to be_nil
      expect(error.box_message).to eq('Bad Request')
      expect(error.boxr_message).to eq(boxr_message)
      expect(error.request_id).to eq('abc123')
    end
  end

  describe 'JSON parsing edge cases' do
    context 'with malformed JSON' do
      let(:error) { described_class.new(status: status, body: '{"incomplete":') }

      it 'handles malformed JSON gracefully' do
        expect(error.type).to be_nil
        expect(error.code).to be_nil
        expect(error.box_message).to be_nil
      end
    end

    context 'with empty JSON object' do
      let(:error) { described_class.new(status: status, body: '{}') }

      it 'handles empty JSON gracefully' do
        expect(error.type).to be_nil
        expect(error.code).to be_nil
        expect(error.box_message).to be_nil
      end
    end

    context 'with JSON containing only some fields' do
      let(:response_body) { '{"type":"error","message":"Partial error"}' }
      let(:error) { described_class.new(status: status, body: response_body) }

      it 'sets only available fields' do
        expect(error.type).to eq('error')
        expect(error.box_message).to eq('Partial error')
        expect(error.code).to be_nil
        expect(error.request_id).to be_nil
      end
    end
  end

  describe 'message priority' do
    context 'when all message types are present' do
      let(:header) { { 'WWW-Authenticate' => ['Bearer realm="Service"'] } }
      let(:error) do
        described_class.new(status: status, body: response_body, header: header,
                            boxr_message: boxr_message)
      end

      it 'prioritizes WWW-Authenticate header' do
        expect(error.message).to eq('400: Bearer realm="Service"')
      end
    end

    context 'when box_message and boxr_message are present' do
      let(:error) do
        described_class.new(status: status, body: response_body, boxr_message: boxr_message)
      end

      it 'prioritizes box_message over boxr_message' do
        expect(error.message).to eq('400: Bad Request')
      end
    end
  end
end
