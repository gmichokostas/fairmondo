#
#
# == License:
# Fairmondo - Fairmondo is an open-source online marketplace.
# Copyright (C) 2013 Fairmondo eG
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

describe Content do
  describe 'friendly_id' do
    # see https://github.com/norman/friendly_id/issues/332
    it 'find by slug should work' do
      content = FactoryGirl.create :content
      assert_equal content, Content.find(content.key)
    end
  end

  describe 'validations' do
    it 'key and body are required attributes' do
      content = Content.new
      assert_not content.valid?
      assert_equal [:key, :body], content.errors.keys
    end
  end
end
