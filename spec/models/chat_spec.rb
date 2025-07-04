require "rails_helper"

RSpec.describe Chat, type: :model do
  describe "アソシエーション" do
    it "belongs_to :user" do
      assoc = Chat.reflect_on_association(:user)
      expect(assoc.macro).to eq :belongs_to
    end

    it "belongs_to :chatable(polymorphic: true)" do
      assoc = Chat.reflect_on_association(:chatable)
      expect(assoc.macro).to eq :belongs_to
      expect(assoc.options[:polymorphic]).to be true
    end
  end

  describe "バリデーション" do
    let(:chat) { build(:chat) }
    it "正常な入力の場合" do
      expect(chat).to be_valid
    end

    context "message" do
      it "messageが500文字以内なら有効" do
        chat = build(:chat, message: "あ" * 500)
        expect(chat).to be_valid
      end

      it "messageが501文字以上なら無効" do
        chat = build(:chat, message: "あ" * 501)
        expect(chat).to be_invalid
        expect(chat.errors[:message]).to be_present
      end
    end
  end

  describe "画像アップロード機能" do
    it "imageカラムにChatImageUploaderがマウントされていること" do
      expect(Chat.uploaders[:image]).to eq ChatImageUploader
    end

    it "画像を添付するとimage_widthとimage_heightが設定される" do
      image_file = generate_temp_image(width: 640, height: 480)
      chat = build(:chat, image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"))

      expect(chat.save).to be true
      expect(chat.image).to be_present
      expect(chat.image_width).to be_present
      expect(chat.image_height).to be_present
      expect(chat.image_width).to be <= 1280  # アップローダーでリサイズ処理される
      expect(chat.image_height).to be <= 720
    ensure
      image_file.close
      image_file.unlink
    end

    context "拡張子の許可" do
      %w[jpg jpeg png gif].each do |ext|
        it "#{ext}ファイルは有効" do
          file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.#{ext}"), "image/#{ext}")
          chat = build(:chat, image: file)
          expect(chat).to be_valid
        end
      end

      it "txtファイルは無効" do
        file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.txt"), "text/plain")
        chat = build(:chat, image: file)
        expect(chat).to be_invalid
        expect(chat.errors[:image]).to be_present
      end
    end

    context "ファイルサイズの検証" do
      it "10MBを超えるファイルは無効" do
        large_file = Tempfile.new([ "large_test", ".jpeg" ])
        large_file.binmode
        large_file.write("0" * (10.megabytes + 1))
        large_file.rewind

        chat = build(:chat, image: Rack::Test::UploadedFile.new(large_file.path, "image/jpeg"))

        expect(chat).to be_invalid
        expect(chat.errors[:image]).to be_present
      ensure
        large_file.close
        large_file.unlink
      end

      it "10MB以下のファイルは有効" do
        valid_file = Tempfile.new([ "valid_test", ".jpeg" ])
        valid_file.binmode
        valid_file.write("0" * 10.megabytes)
        valid_file.rewind

        chat = build(:chat, image: Rack::Test::UploadedFile.new(valid_file.path, "image/jpeg"))

        expect(chat).to be_valid
      ensure
        valid_file.close
        valid_file.unlink
      end
    end
  end
end
