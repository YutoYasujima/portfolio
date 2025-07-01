namespace :chats do
  desc "Update image dimensions (width, height) from S3 or local for existing Chat images"
  task update_image_dimensions: :environment do
    require "mini_magick"
    require "open-uri"

    puts "🖼️  画像サイズ更新を開始..."

    updated = 0
    skipped = 0
    failed  = 0

    Chat.where.not(image: [nil, ""]).find_each do |chat|
      if chat.image_width.present? && chat.image_height.present?
        skipped += 1
        next
      end

      begin
        if Rails.env.production?
          # S3などURLから取得
          URI.open(chat.image.url) do |file|
            img = MiniMagick::Image.read(file)
            chat.update_columns(image_width: img.width, image_height: img.height)
            puts "✅ Chat ##{chat.id} updated: #{img.width}x#{img.height}"
            updated += 1
          end
        else
          # ローカルファイルから取得
          local_path = File.join(Rails.root, "public", chat.image.url)
          if File.exist?(local_path)
            img = MiniMagick::Image.open(local_path)
            chat.update_columns(image_width: img.width, image_height: img.height)
            puts "✅ Chat ##{chat.id} updated: #{img.width}x#{img.height}"
            updated += 1
          else
            puts "❌ Chat ##{chat.id} failed: local file not found"
            failed += 1
          end
        end
      rescue => e
        puts "❌ Chat ##{chat.id} failed: #{e.message}"
        failed += 1
      end
    end

    puts "\n✅ 完了: 更新 #{updated} 件 / スキップ #{skipped} 件 / 失敗 #{failed} 件"
  end
end
