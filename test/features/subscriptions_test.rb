#
# == License:
# Fairmondo - Fairmondo is an open-source online marketplace.
# Copyright (C) 2015 Fairmondo eG
#
# This file is part of Fairmondo.
#
# Fairmondo is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairmondo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairmondo.  If not, see <http://www.gnu.org/licenses/>.
#

require_relative '../test_helper'

include Warden::Test::Helpers

feature 'Subscriptions page' do
  setup do
    @user = FactoryGirl.create :user
  end

  scenario 'User visits subscriptions page' do
    login_as @user
    visit user_subscriptions_path(@user)
  end

  scenario 'Guest cannot reach subscriptions page' do
    visit user_subscriptions_path(@user)
    page.status_code.should be 500
  end
end
