class MunicipalitiesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_profile_created, only: %i[ index ]

  def index
    municipalities = Municipality.where(prefecture_id: params[:prefecture_id]).order(:name_kana)
    render json: municipalities.select(:id, :name_kanji)
  end
end
