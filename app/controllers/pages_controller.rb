class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_profile_created

  def terms; end

  def privacy; end
end
