class MunicipalitiesController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    municipalities = Municipality.where(prefecture_id: params[:prefecture_id]).order(:name_kana)
    render json: municipalities.select(:id, :name_kanji)
  end
end
