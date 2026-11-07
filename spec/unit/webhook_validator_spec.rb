# frozen_string_literal: true

require 'spec_helper'
def generate_signature(payload, timestamp, key)
  digest = OpenSSL::HMAC.digest('SHA256', key, "#{payload}#{timestamp}")
  Base64.strict_encode64(digest)
end

# rake spec SPEC_OPTS="-e \"Boxr::WebhookValidator"\"
describe Boxr::WebhookValidator, :skip_reset do
  require 'spec_helper'
  describe '#verify_delivery_timestamp' do
    subject { described_class.new(headers, payload).verify_delivery_timestamp }

    let(:payload) { 'not relevant' }

    context 'maximum age is under 10 minutes' do
      let(:five_minutes_ago) { (Time.now.utc - 300).to_s } # 5 minutes (in seconds)
      let(:headers) { { 'BOX-DELIVERY-TIMESTAMP' => five_minutes_ago } }

      it 'returns true' do
        expect(subject).to be(true)
      end
    end

    context 'maximum age is over 10 minute' do
      let(:eleven_minutes_ago) { (Time.now.utc - 660).to_s } # 11 minutes (in seconds)
      let(:headers) { { 'BOX-DELIVERY-TIMESTAMP' => eleven_minutes_ago } }

      it 'returns false' do
        expect(subject).to be(false)
      end
    end

    context 'no delivery timestamp is supplied' do
      let(:headers) { { 'BOX-DELIVERY-TIMESTAMP' => nil } }

      it 'raises an error' do
        expect do
          subject
        end.to raise_error(Boxr::BoxrError,
                           'Webhook authenticity not verified: invalid timestamp')
      end
    end

    context 'bogus timestamp is supplied' do
      let(:headers) { { 'BOX-DELIVERY-TIMESTAMP' => 'foo' } }

      it 'raises an error' do
        expect do
          subject
        end.to raise_error(Boxr::BoxrError,
                           'Webhook authenticity not verified: invalid timestamp')
      end
    end
  end

  describe '#verify_signature' do
    subject do
      described_class.new(headers,
                          payload,
                          primary_signature_key: primary_key,
                          secondary_signature_key: secondary_key).verify_signature
    end

    let(:payload) { 'some data' }
    let(:timestamp) { (Time.now.utc - 300).to_s } # 5 minutes ago (in seconds)
    let(:primary_key) { 'primary key' }
    let(:secondary_key) { 'secondary key' }
    let(:signature_primary) do
      generate_signature(payload, timestamp, primary_key)
    end
    let(:signature_secondary) do
      generate_signature(payload, timestamp, secondary_key)
    end
    let(:forged_signature) { generate_signature(payload, timestamp, '') }

    context 'valid primary key' do
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => signature_primary }
      end

      it 'returns true' do
        expect(subject).to be(true)
      end
    end

    context 'invalid primary key, valid secondary key' do
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => 'invalid',
          'BOX-SIGNATURE-SECONDARY' => signature_secondary }
      end

      it 'returns true' do
        expect(subject).to be(true)
      end
    end

    context 'invalid primary key, invalid secondary key' do
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => 'invalid',
          'BOX-SIGNATURE-SECONDARY' => 'also invalid' }
      end

      it 'returns false' do
        expect(subject).to be(false)
      end
    end

    context 'no signatures were supplied' do
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => nil,
          'BOX-SIGNATURE-SECONDARY' => nil }
      end

      it 'returns false' do
        subject = described_class.new(headers, payload, primary_signature_key: nil,
                                                        secondary_signature_key: nil).verify_signature
        expect(subject).to be(false)
      end
    end

    context 'with a non-string primary signature and a valid secondary signature' do
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => [],
          'BOX-SIGNATURE-SECONDARY' => signature_secondary }
      end

      it { is_expected.to be(true) }
    end

    context 'with only a primary key and a valid primary signature' do
      let(:secondary_key) { nil }
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => signature_primary }
      end

      it { is_expected.to be(true) }
    end

    context 'with only a primary key and a primary signature forged from an empty key' do
      let(:secondary_key) { nil }
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => forged_signature }
      end

      it { is_expected.to be(false) }
    end

    context 'with only a primary key and a secondary signature forged from an empty key' do
      let(:secondary_key) { nil }
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-SECONDARY' => forged_signature }
      end

      it { is_expected.to be(false) }
    end

    context 'with only a secondary key and a valid secondary signature' do
      let(:primary_key) { nil }
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-SECONDARY' => signature_secondary }
      end

      it { is_expected.to be(true) }
    end

    context 'with only a secondary key and a primary signature forged from an empty key' do
      let(:primary_key) { nil }
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => forged_signature }
      end

      it { is_expected.to be(false) }
    end

    context 'when no keys are configured' do
      let(:primary_key) { nil }
      let(:secondary_key) { nil }
      let(:headers) do
        { 'BOX-DELIVERY-TIMESTAMP' => timestamp,
          'BOX-SIGNATURE-PRIMARY' => forged_signature,
          'BOX-SIGNATURE-SECONDARY' => forged_signature }
      end

      it { is_expected.to be(false) }
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
