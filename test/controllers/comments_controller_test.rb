#
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly. If not, see <http://www.gnu.org/licenses/>.
#
#

require_relative "../test_helper"

describe CommentsController do
  describe "GET comments on library" do
    before :each do
      @library = FactoryGirl.create(:library)
      @user = FactoryGirl.create(:user)
      @comment = FactoryGirl.create(:comment,
                                 text: "Test comment",
                                 commentable: @library,
                                 library: @library,
                                 user: @user)
      sign_in @user
    end
  end

  describe "POST comment on library" do
    before :each do
      @library = FactoryGirl.create(:library)
      @user = FactoryGirl.create(:user)
      sign_in @user
    end

    it "should allow posting using ajax" do
      post :create, user: @user,
                    comment: {text: "test"},
                    library_id: @library.id,
                    format: :js
      assert_response :success
    end
  end

  describe "DELETE comment on library" do
    before :each do
      @library = FactoryGirl.create(:library)
      @user = FactoryGirl.create(:user)
      sign_in @user
      @comment = FactoryGirl.create(:comment,
                                 text: "Test comment",
                                 commentable: @library,
                                 library: @library,
                                 user: @user)

      it "it should remove the comment" do
        delete :destroy, user: @user,
                          id: @comment.id,
                          library_id: @library.id

        assert_response :success
      end
    end
  end
end