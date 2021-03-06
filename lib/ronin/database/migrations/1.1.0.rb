#
# Copyright (c) 2006-2013 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# This file is part of Ronin.
#
# Ronin is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ronin is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ronin.  If not, see <http://www.gnu.org/licenses/>.
#

require 'ronin/database/migrations/1.0.0'
require 'ronin/campaign'
require 'ronin/target'

module Ronin
  module Database
    module Migrations
      migration :add_updated_at_column_to_campaigns_table,
                :needs => :create_campaigns_table do
        up do
          modify_table :ronin_campaigns do
            add_column :updated_at, Time
          end

          # set the updated_at column to created_at
          Campaign.each do |campaign|
            campaign.update(:updated_at => campaign.created_at)
          end
        end
      end

      migration :add_created_at_column_to_targets_table,
                :needs => :create_targets_table do
        up do
          modify_table :ronin_targets do
            add_column :created_at, Time
          end

          # set the updated_at column to the created_at of the Campaign
          Target.each do |target|
            target.update(:created_at => target.campaign.created_at)
          end
        end
      end

      migration :create_url_query_param_names_table,
                :needs => :create_url_query_params_table do
        up do
          create_table :ronin_url_query_param_names do
            column :id, Integer, :serial => true
            column :name, String, :length => 256, :not_null => true
          end

          create_index :ronin_url_query_param_names, :name, :unique => true

          # select any previous URLQueryParam entries before recreating the table
          query_params = adapter.select('SELECT id,name,value,url_id FROM ronin_url_query_params')

          # recreate the `ronin_url_query_params` table
          drop_table :ronin_url_query_params
          create_table :ronin_url_query_params do
            column :id, Integer, :serial => true
            column :name_id, Integer, :not_null => true
            column :value, Text
            column :url_id, Integer, :not_null => true
          end

          name_ids = {}

          query_params.each do |row|
            unless name_ids.has_key?(row.name)
              result = adapter.execute(
                'INSERT INTO ronin_url_query_param_names (name) VALUES (?)',
                row.name
              )

              name_ids[row.name] = result.insert_id
            end

            adapter.execute(
              'INSERT INTO ronin_url_query_params (id,name_id,value,url_id) VALUES (?,?,?,?)',
              row.id, name_ids[row.name], row.value, row.url_id
            )
          end
        end

        down do
          id_names = {}

          adapter.select('SELECT id,name FROM ronin_url_query_param_names').each do |row|
            id_names[row.id] = row.name
          end

          query_params = adapter.select('SELECT id,name_id,value,url_id FROM ronin_url_query_params')

          drop_table :ronin_url_query_params
          create_table :ronin_url_query_params do
            column :id, Integer, :serial => true
            column :name, String, :length => 256, :not_null => true
            column :value, Text
            column :url_id, Integer, :not_null => true
          end

          query_params.each do |row|
            adapter.execute(
              'INSERT INTO ronin_url_query_params (id,name,value,url_id) VALUES (?,?,?,?)',
              row.id, id_names[row.name_id], row.value, row.url_id
            )
          end

          drop_table :ronin_url_query_param_names
        end
      end
    end
  end
end
