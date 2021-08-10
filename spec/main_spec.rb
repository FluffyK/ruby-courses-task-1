# frozen_string_literal: true
require 'spec_helper'
require 'json'
require_relative '../main'
RSpec.describe PlaylistGetter do
  it"return playlist json" do
    access_token = response[1]['access_token']
    playlist_id = create_new_playlist[1]['id']
  end
end