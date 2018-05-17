class MetadataController < ApplicationController
  layout false
  skip_before_action :preload_json, :check_xhr, :redirect_to_login_if_required

  def manifest
    render json: default_manifest.to_json
  end

  def opensearch
    render file: "#{Rails.root}/app/views/metadata/opensearch.xml"
  end

  private

  def default_manifest
    logo = SiteSetting.large_icon_url.presence || SiteSetting.logo_small_url.presence || SiteSetting.apple_touch_icon_url.presence

    manifest = {
      name: SiteSetting.title,
      short_name: SiteSetting.title,
      display: 'standalone',
      orientation: 'natural',
      start_url: "#{Discourse.base_uri}/",
      share_target: {
        url_template: 'new-topic?title={title}&body={text}%0A%0A{url}'
      },
      background_color: "##{ColorScheme.hex_for_name('secondary')}",
      theme_color: "##{ColorScheme.hex_for_name('header_background')}",
      icons: [
        {
          src: logo,
          sizes: "512x512",
          type: guess_mime(logo)
        }
      ]
    }

    if SiteSetting.native_app_install_banner
      manifest = manifest.merge(
        prefer_related_applications: true,
        related_applications: [
          {
            platform: "play",
            id: "com.discourse"
          }
        ]
      )
    end

    manifest
  end

  def guess_mime(filename)
    extension = filename.split(".").last
    valid_image_mimes = { png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", gif: "image/gif", ico: "image/x-icon" }
    valid_image_mimes[extension.to_sym] || "image/png"
  end

end
