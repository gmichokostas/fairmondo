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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#
class Library < ActiveRecord::Base
  extend Sanitization, Enumerize

  auto_sanitize :name

  delegate :nickname, to: :user, prefix: true

  validates :name, :user, presence: true
  validates :name, uniqueness: {scope: :user_id}, length: {maximum: 70}

  enumerize :exhibition_name, in: [:donation_articles, :old, :queue1, :queue2,
    :queue3, :queue4, :book1, :book2, :book3, :book4, :book5, :book6, :book7,
    :book8]
  before_update :uniquify_exhibition_name

  #Relations

  belongs_to :user

  has_many :library_elements, dependent: :destroy
  has_many :articles, through: :library_elements

  scope :published, -> { where(public: true) }
  default_scope -> { order('updated_at DESC') }

  private
    # when an exhibition name is set to a library, remove the same exhibition
    # name from all other libraries.
    def uniquify_exhibition_name
      if self.exhibition_name
        Library.where(exhibition_name: self.exhibition_name).where("id != ?", self.id).each do |library|
          library.update_attribute(:exhibition_name, nil)
        end
      end
      true
    end
end
