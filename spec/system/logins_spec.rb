require 'rails_helper'

RSpec.describe "Logins", type: :system do
  describe "ログイン前" do
    context "入力値が正常" do
      it "ログイン成功" do
        visit new_user_session_path
        expect(page).to have_content("ログイン")
      end
    end
  end
end
