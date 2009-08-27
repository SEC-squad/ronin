#
# Ronin - A ruby development platform designed for information security
# and data exploration tasks.
#
# Copyright (c) 2006-2009 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'ronin/network/helpers/helper'
require 'ronin/network/esmtp'

module Ronin
  module Network
    module Helpers
      module ESMTP
        include Helper

        protected

        #
        # @since 0.3.0
        #
        def esmtp_message(options={},&block)
          Network::SMTP.message(options,&block)
        end

        #
        # @since 0.3.0
        #
        def esmtp_connect(options={},&block)
          require_variable :host

          options[:port] ||= @port
          options[:login] ||= @esmtp_login
          options[:user] ||= @esmtp_user
          options[:password] ||= @esmtp_password

          if @port
            print_info "Connecting to #{@host}:#{@port} ..."
          else
            print_info "Connecting to #{@host} ..."
          end

          return ::Net.esmtp_connect(@host,options,&block)
        end

        #
        # @since 0.3.0
        #
        def esmtp_session(options={},&block)
          esmtp_connect(options) do |sess|
            block.call(sess) if block

            sess.close

            if @port
              print_info "Disconnecting from #{@host}:#{@port}"
            else
              print_info "Disconnecting from #{@host}"
            end
          end
        end
      end
    end
  end
end