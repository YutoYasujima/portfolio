require "mini_magick"

module ImageHelper
  # 指定サイズの画像を一時ファイルとして作成して返す
  def generate_temp_image(width:, height:)
    file = Tempfile.new([ "test_image", ".jpeg" ])
    MiniMagick::Tool::Convert.new do |convert|
      convert.size "#{width}x#{height}"
      convert.xc "white"
      convert << file.path
    end
    file.rewind
    file
  end
end
