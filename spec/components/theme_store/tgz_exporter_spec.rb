require 'rails_helper'
require 'theme_store/tgz_exporter'

describe ThemeStore::TgzExporter do
  let(:theme) do
    Fabricate(:theme, name: "Header Icons").tap do |theme|
      theme.set_field(target: :common, name: :body_tag, value: "<b>testtheme1</b>")
      theme.set_field(target: :settings, name: :yaml, value: "somesetting: test")
      theme.set_field(target: :mobile, name: :scss, value: 'body {background-color: $background_color; font-size: $font-size}')
      theme.set_field(target: :translations, name: :en, value: { en: { key: "value" } }.deep_stringify_keys.to_yaml)
      image = file_from_fixtures("logo.png")
      upload = UploadCreator.new(image, "logo.png").create_for(-1)
      theme.set_field(target: :common, name: :logo, upload_id: upload.id, type: :theme_upload_var)
      theme.build_remote_theme(remote_url: "", about_url: "abouturl", license_url: "licenseurl")

      cs1 = Fabricate(:color_scheme, name: 'Orphan Color Scheme', color_scheme_colors: [
        Fabricate(:color_scheme_color, name: 'header_primary',  hex: 'F0F0F0'),
        Fabricate(:color_scheme_color, name: 'header_background', hex: '1E1E1E'),
        Fabricate(:color_scheme_color, name: 'tertiary', hex: '858585')
      ])

      cs2 = Fabricate(:color_scheme, name: 'Theme Color Scheme', color_scheme_colors: [
        Fabricate(:color_scheme_color, name: 'header_primary',  hex: 'F0F0F0'),
        Fabricate(:color_scheme_color, name: 'header_background', hex: '1E1E1E'),
        Fabricate(:color_scheme_color, name: 'tertiary', hex: '858585')
      ])

      theme.color_scheme = cs1
      cs2.update(theme_id: theme.id)

      theme.save!
    end
  end

  let(:dir) do
    tmpdir = Dir.tmpdir
    dir = "#{tmpdir}/#{SecureRandom.hex}"
    FileUtils.mkdir(dir)
    dir
  end

  after do
    FileUtils.rm_rf(dir)
  end

  let(:package) do
    exporter = ThemeStore::TgzExporter.new(theme)
    filename = exporter.package_filename
    FileUtils.cp(filename, dir)
    exporter.cleanup!
    "#{dir}/discourse-header-icons-theme.tar.gz"
  end

  it "exports the theme correctly" do
    package
    Dir.chdir("#{dir}") do
      `tar -xzf discourse-header-icons-theme.tar.gz`
    end
    Dir.chdir("#{dir}/discourse-header-icons-theme") do
      folders = Dir.glob("**/*").reject { |f| File.file?(f) }
      expect(folders).to contain_exactly("assets", "common", "locales", "mobile")

      files = Dir.glob("**/*").reject { |f| File.directory?(f) }
      expect(files).to contain_exactly("about.json", "assets/logo.png", "common/body_tag.html", "locales/en.yml", "mobile/mobile.scss", "settings.yml")

      expect(JSON.parse(File.read('about.json')).deep_symbolize_keys).to eq(
        "name": "Header Icons",
        "about_url": "abouturl",
        "license_url": "licenseurl",
        "component": false,
        "assets": {
          "logo": "assets/logo.png"
        },
        "color_schemes": {
          "Orphan Color Scheme": {
            "header_primary": "F0F0F0",
            "header_background": "1E1E1E",
            "tertiary": "858585"
          },
          "Theme Color Scheme": {
            "header_primary": "F0F0F0",
            "header_background": "1E1E1E",
            "tertiary": "858585"
          }
        }
      )

      expect(File.read("common/body_tag.html")).to eq("<b>testtheme1</b>")
      expect(File.read("mobile/mobile.scss")).to eq("body {background-color: $background_color; font-size: $font-size}")
      expect(File.read("settings.yml")).to eq("somesetting: test")
      expect(File.read("locales/en.yml")).to eq({ en: { key: "value" } }.deep_stringify_keys.to_yaml)
    end
  end

  it "has safeguards to prevent writing outside the temp directory" do
    # Theme field names should be sanitized before writing to the database,
    # but protection is in place 'just in case'
    expect do
      theme.set_field(target: :translations, name: "en", value: "hacked")
      theme.theme_fields[0].stubs(:file_path).returns("../../malicious")
      theme.save!
      package
    end.to raise_error(RuntimeError)
  end

end
