require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_file) { Hashie::Mash.new(id: '67890', name: 'test.txt') }
  let(:test_folder) { Hashie::Mash.new(id: '12345', name: 'test_folder') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_metadata) do
    BoxrMash.new(
      id: 'metadata123',
      type: 'metadata',
      scope: 'global',
      template: 'properties',
      data: { 'key' => 'value' }
    )
  end
  let(:mock_template) do
    BoxrMash.new(
      id: 'template123',
      type: 'metadata_template',
      scope: 'enterprise',
      templateKey: 'test_template',
      displayName: 'Test Template'
    )
  end

  describe '#create_metadata' do
    before do
      allow(client).to receive_messages(
        post: [mock_metadata, mock_response]
      )
    end

    it 'creates metadata with default scope and template' do
      metadata = { 'key' => 'value' }
      result = client.create_metadata(test_file, metadata)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/global/properties",
        metadata,
        content_type: "application/json"
      )
    end

    it 'creates metadata with custom scope and template' do
      metadata = { 'key' => 'value' }
      result = client.create_metadata(test_file, metadata, scope: :enterprise, template: :custom)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/enterprise/custom",
        metadata,
        content_type: "application/json"
      )
    end

    it 'handles file ID string' do
      metadata = { 'key' => 'value' }
      result = client.create_metadata('67890', metadata)

      expect(result).to eq(mock_metadata)
    end
  end

  describe '#create_folder_metadata' do
    before do
      allow(client).to receive_messages(
        post: [mock_metadata, mock_response]
      )
    end

    it 'creates folder metadata' do
      metadata = { 'key' => 'value' }
      result = client.create_folder_metadata(test_folder, metadata, :enterprise, :custom)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::FOLDER_METADATA_URI}/12345/metadata/enterprise/custom",
        metadata,
        content_type: "application/json"
      )
    end

    it 'handles folder ID string' do
      metadata = { 'key' => 'value' }
      result = client.create_folder_metadata('12345', metadata, :enterprise, :custom)

      expect(result).to eq(mock_metadata)
    end
  end

  describe '#metadata' do
    before do
      allow(client).to receive_messages(
        get: [mock_metadata, mock_response]
      )
    end

    it 'retrieves metadata with default scope and template' do
      result = client.metadata(test_file)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/global/properties"
      )
    end

    it 'retrieves metadata with custom scope and template' do
      result = client.metadata(test_file, scope: :enterprise, template: :custom)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/enterprise/custom"
      )
    end

    it 'handles file ID string' do
      result = client.metadata('67890')

      expect(result).to eq(mock_metadata)
    end
  end

  describe '#folder_metadata' do
    before do
      allow(client).to receive_messages(
        get: [mock_metadata, mock_response]
      )
    end

    it 'retrieves folder metadata' do
      result = client.folder_metadata(test_folder, :enterprise, :custom)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::FOLDER_METADATA_URI}/12345/metadata/enterprise/custom"
      )
    end

    it 'handles folder ID string' do
      result = client.folder_metadata('12345', :enterprise, :custom)

      expect(result).to eq(mock_metadata)
    end
  end

  describe '#all_folder_metadata' do
    let(:mock_all_metadata) { BoxrMash.new(entries: [mock_metadata], total_count: 1) }

    before do
      allow(client).to receive_messages(
        get: [mock_all_metadata, mock_response]
      )
    end

    it 'retrieves all folder metadata' do
      result = client.all_folder_metadata(test_folder)

      expect(result).to eq(mock_all_metadata)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::FOLDER_METADATA_URI}/12345/metadata"
      )
    end

    it 'handles folder ID string' do
      result = client.all_folder_metadata('12345')

      expect(result).to eq(mock_all_metadata)
    end
  end

  describe '#all_metadata' do
    let(:mock_all_metadata) { BoxrMash.new(entries: [mock_metadata], total_count: 1) }

    before do
      allow(client).to receive_messages(
        get: [mock_all_metadata, mock_response]
      )
    end

    it 'retrieves all file metadata' do
      result = client.all_metadata(test_file)

      expect(result).to eq(mock_all_metadata)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata"
      )
    end

    it 'handles file ID string' do
      result = client.all_metadata('67890')

      expect(result).to eq(mock_all_metadata)
    end
  end

  describe '#update_metadata' do
    before do
      allow(client).to receive_messages(
        put: [mock_metadata, mock_response]
      )
    end

    it 'updates metadata with single update' do
      update = { op: 'replace', path: '/key', value: 'new_value' }
      result = client.update_metadata(test_file, update)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/global/properties",
        [update],
        content_type: "application/json-patch+json"
      )
    end

    it 'updates metadata with array of updates' do
      updates = [
        { op: 'replace', path: '/key1', value: 'value1' },
        { op: 'add', path: '/key2', value: 'value2' }
      ]
      result = client.update_metadata(test_file, updates)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/global/properties",
        updates,
        content_type: "application/json-patch+json"
      )
    end

    it 'updates metadata with custom scope and template' do
      update = { op: 'replace', path: '/key', value: 'new_value' }
      result = client.update_metadata(test_file, update, scope: :enterprise, template: :custom)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/enterprise/custom",
        [update],
        content_type: "application/json-patch+json"
      )
    end

    it 'handles file ID string' do
      update = { op: 'replace', path: '/key', value: 'new_value' }
      result = client.update_metadata('67890', update)

      expect(result).to eq(mock_metadata)
    end
  end

  describe '#update_folder_metadata' do
    before do
      allow(client).to receive_messages(
        put: [mock_metadata, mock_response]
      )
    end

    it 'updates folder metadata with single update' do
      update = { op: 'replace', path: '/key', value: 'new_value' }
      result = client.update_folder_metadata(test_folder, update, :enterprise, :custom)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::FOLDER_METADATA_URI}/12345/metadata/enterprise/custom",
        [update],
        content_type: "application/json-patch+json"
      )
    end

    it 'updates folder metadata with array of updates' do
      updates = [
        { op: 'replace', path: '/key1', value: 'value1' },
        { op: 'add', path: '/key2', value: 'value2' }
      ]
      result = client.update_folder_metadata(test_folder, updates, :enterprise, :custom)

      expect(result).to eq(mock_metadata)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::FOLDER_METADATA_URI}/12345/metadata/enterprise/custom",
        updates,
        content_type: "application/json-patch+json"
      )
    end

    it 'handles folder ID string' do
      update = { op: 'replace', path: '/key', value: 'new_value' }
      result = client.update_folder_metadata('12345', update, :enterprise, :custom)

      expect(result).to eq(mock_metadata)
    end
  end

  describe '#delete_metadata' do
    before do
      allow(client).to receive_messages(
        delete: [true, mock_response]
      )
    end

    it 'deletes metadata with default scope and template' do
      result = client.delete_metadata(test_file)

      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/global/properties"
      )
    end

    it 'deletes metadata with custom scope and template' do
      result = client.delete_metadata(test_file, scope: :enterprise, template: :custom)

      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::FILE_METADATA_URI}/67890/metadata/enterprise/custom"
      )
    end

    it 'handles file ID string' do
      result = client.delete_metadata('67890')

      expect(result).to be true
    end
  end

  describe '#delete_folder_metadata' do
    before do
      allow(client).to receive_messages(
        delete: [true, mock_response]
      )
    end

    it 'deletes folder metadata' do
      result = client.delete_folder_metadata(test_folder, :enterprise, :custom)

      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::FOLDER_METADATA_URI}/12345/metadata/enterprise/custom"
      )
    end

    it 'handles folder ID string' do
      result = client.delete_folder_metadata('12345', :enterprise, :custom)

      expect(result).to be true
    end
  end

  describe '#enterprise_metadata' do
    let(:mock_enterprise_metadata) { BoxrMash.new(entries: [mock_template], total_count: 1) }

    before do
      allow(client).to receive(:get).and_return([mock_enterprise_metadata, mock_response])
    end

    it 'retrieves enterprise metadata templates' do
      result = client.enterprise_metadata

      expect(result).to eq(mock_enterprise_metadata)
      expect(client).to have_received(:get).with(Boxr::Client::METADATA_TEMPLATES_URI + '/enterprise')
    end

    it 'aliases to get_enterprise_templates' do
      result = client.get_enterprise_templates

      expect(result).to eq(mock_enterprise_metadata)
      expect(client).to have_received(:get).with(Boxr::Client::METADATA_TEMPLATES_URI + '/enterprise')
    end
  end

  describe '#metadata_schema' do
    before do
      allow(client).to receive(:get).and_return([mock_template, mock_response])
    end

    it 'retrieves metadata schema' do
      result = client.metadata_schema(:enterprise, :test_template)

      expect(result).to eq(mock_template)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::METADATA_TEMPLATES_URI}/enterprise/test_template/schema"
      )
    end

    it 'aliases to get_metadata_template_by_name' do
      result = client.get_metadata_template_by_name(:enterprise, :test_template)

      expect(result).to eq(mock_template)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::METADATA_TEMPLATES_URI}/enterprise/test_template/schema"
      )
    end
  end

  describe '#get_metadata_template_by_id' do
    before do
      allow(client).to receive_messages(
        get: [mock_template, mock_response]
      )
    end

    it 'retrieves metadata template by ID' do
      result = client.get_metadata_template_by_id('template123')

      expect(result).to eq(mock_template)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::METADATA_TEMPLATES_URI}/template123"
      )
    end

    it 'handles template ID object' do
      template_obj = Hashie::Mash.new(id: 'template123')
      result = client.get_metadata_template_by_id(template_obj)

      expect(result).to eq(mock_template)
    end
  end

  describe '#create_metadata_template' do
    before do
      allow(client).to receive(:post).and_return([mock_template, mock_response])
    end

    it 'creates metadata template with required parameters' do
      result = client.create_metadata_template('Test Template')

      expect(result).to eq(mock_template)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::METADATA_TEMPLATES_URI}/schema",
        {
          scope: "enterprise",
          displayName: "Test Template"
        },
        content_type: "application/json"
      )
    end

    it 'creates metadata template with all parameters' do
      fields = [{ key: 'field1', displayName: 'Field 1', type: 'string' }]
      result = client.create_metadata_template(
        'Test Template',
        template_key: :test_template,
        fields: fields,
        hidden: false
      )

      expect(result).to eq(mock_template)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::METADATA_TEMPLATES_URI}/schema",
        {
          scope: "enterprise",
          displayName: "Test Template",
          templateKey: :test_template,
          hidden: false,
          fields: fields
        },
        content_type: "application/json"
      )
    end

    it 'creates metadata template with empty fields array' do
      result = client.create_metadata_template('Test Template', fields: [])

      expect(result).to eq(mock_template)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::METADATA_TEMPLATES_URI}/schema",
        {
          scope: "enterprise",
          displayName: "Test Template"
        },
        content_type: "application/json"
      )
    end
  end

  describe '#delete_metadata_template' do
    before do
      allow(client).to receive(:delete).and_return([true, mock_response])
    end

    it 'deletes metadata template' do
      result = client.delete_metadata_template(:enterprise, :test_template)

      expect(result).to be true
      expect(client).to have_received(:delete).with(
        "#{Boxr::Client::METADATA_TEMPLATES_URI}/enterprise/test_template/schema"
      )
    end
  end
end
