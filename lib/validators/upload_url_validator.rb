class UploadUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present?
      uri =
        begin
          URI.parse(value)
        rescue URI::Error
        end

      unless uri && Upload.exists?(url: value)
        record.errors.add(attribute, options[:message] || I18n.t('errors.messages.invalid'))
      end
    end
  end
end
