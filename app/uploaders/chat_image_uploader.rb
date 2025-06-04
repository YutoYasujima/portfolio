class ChatImageUploader < CarrierWave::Uploader::Base
  # Include RMagick, MiniMagick, or Vips support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  # include CarrierWave::Vips

  # Choose what kind of storage to use for this uploader:
  # storage :file
  # storage :fog
  if Rails.env.production?
    storage :fog
  else
    storage :file
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url(*args)
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # アップロード時に軽量化処理を実行
  # アップロード時に画像の解像度を下げる
  process :optimize_image

  def optimize_image
    manipulate! do |img|
      img.auto_orient        # 回転情報の自動補正（スマホ対応）
      img.strip              # EXIFなど不要なメタデータを除去
      img.resize "1280x720>" # スマホ向けに設定
      img.quality("80")      # 画質（70〜85が推奨）
      img
    end
  end

  # Add an allowlist of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # アップロード可能な拡張子のリスト
  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  # アップロード可能なファイルサイズの制限
  def size_range
    1.byte..5.megabytes
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg"
  # end

  # ファイル名のカスタマイズ
  def filename
      "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  # ファイル名を一意にする
  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
end
