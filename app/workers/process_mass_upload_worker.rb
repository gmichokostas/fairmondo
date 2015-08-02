# encoding: UTF-8
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
class ProcessMassUploadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mass_upload,
                  retry: 20,
                  backtrace: true


  # new cool stuff with smarter_csv
  def perform mass_upload_id
    mass_upload = MassUpload.find(mass_upload_id)

    # do we need this?
    mass_upload.start

    # for what do we need this?
    row_count = 0

    total_chunks = SmarterCSV.process(mass_upload.file.path,
                                      col_sep: ';',
                                      quote_char: '"',
                                      headers_in_file: true,
                                      chunk_size: 200) do |chunk|
      chunk.each do |row|
        row_count += 1
        row.delete '€' # delete encoding column

        mass_upload_article = MassUploadArticle.find_or_create_from_row_index row_count, mass_upload
        if mass_upload_article.done?
          return
        else
          mass_upload_article.process row
        end
      end
    end

    mass_upload.update_attribute(:row_count, row_count)
    mass_upload.finish
  end

end
