class MachiReposController < ApplicationController
  def index
    @profile = current_user.profile
  end

  def new
    @address = current_user.profile.prefecture.name_kanji + current_user.profile.municipality.name_kanji
    geocoding = Geocoder.search(@address).first.coordinates
    @machi_repo = MachiRepo.new(latitude: geocoding[0], longitude: geocoding[1])
  end

  def create
  end
end
