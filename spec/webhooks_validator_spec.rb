require 'spec_helper'

describe Boxr::WebhookValidator do
  describe '#verify_delivery_timestamp' do
    let(:payload) { 'not relevant' }
    subject { described_class.new(headers, payload).verify_delivery_timestamp }
    context 'maximum age is under 10 minutes' do
      let(:headers) { { 'Box-Delivery-Timestamp' => 5.minutes.ago.to_s } }
      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'maximum age is over 10 minute' do
      let(:headers) { { 'Box-Delivery-Timestamp' => 11.minutes.ago.to_s } }
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'no delivery timestamp is supplied' do
      let(:headers) { { 'Box-Delivery-Timestamp' => nil } }
      it 'raises an error' do
        expect do
          subject
        end.to raise_error(RuntimeError, 'Webhook authenticity not verified: invalid timestamp')
      end
    end

    context 'bogus timestamp is supplied' do
      let(:headers) { { 'Box-Delivery-Timestamp' => 'foo' } }
      it 'raises an error' do
        expect do
          subject
        end.to raise_error(RuntimeError, 'Webhook authenticity not verified: invalid timestamp')
      end
    end
  end

  describe '#verify_signature' do
    let(:payload) { 'some data' }
    subject { described_class.new(headers, payload).verify_signature }

    context 'valid primary key' do
      let(:headers) do
        { 'Box-Delivery-Timestamp' => 9.minutes.ago.to_s,
          'Box-Signature-Primary' => "MDM5N2NkMmZkYWVmYzMyODE3Yjc0OTIyNjNiYTQwM2E3OTE2ZTk1MTYzNDZm\nZWQyYTM4YTA3MmIwNjBlMjBlNA==\n"

        }
      end

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'invalid primary key, valid secondary key' do
      let(:headers) do
        { 'Box-Delivery-Timestamp' => 9.minutes.ago.to_s,
          'Box-Signature-Primary' => 'bogus',
          'Box-Signature-Secondary' => "MjhlNjRkZWRjYTg3NDQzODFjMTViNDU4MDJjY2E4Mzk5OTM5NmY2NzU3YjBm\nNTVmOTEzM2Q4MjIxZTQ3YjM1Mg==\n"
        }
      end

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'invalid primary key, invalid secondary key' do
      let(:headers) do
        { 'Box-Delivery-Timestamp'  => 9.minutes.ago.to_s,
          'Box-Signature-Primary'   => 'bogus',
          'Box-Signature-Secondary' => 'also bogus'
        }
      end

      it 'returns false' do
        expect(subject).to eq(false)
      end
  end

    context 'no signatures were supplied' do
      let(:headers) do
        { 'Box-Delivery-Timestamp'  => 9.minutes.ago.to_s,
          'Box-Signature-Primary'   => nil,
          'Box-Signature-Secondary' => nil
        }
      end

      it 'returns false' do
        subject = described_class.new(headers, payload, primary_signature_key: nil, secondary_signature_key: nil).verify_signature
        expect(subject).to eq(false)
      end
    end

  end

  describe '#valid_message?' do
    let(:headers) { { 'doesnt' => 'matter' } }
    let(:payload) { 'not relevant' }

    it 'delegates to timestamp and signature verification' do
      validator = described_class.new(headers, payload)
      expect(validator).to receive(:verify_delivery_timestamp).and_return(true)
      expect(validator).to receive(:verify_signature)
      validator.valid_message?
    end
  end
end
