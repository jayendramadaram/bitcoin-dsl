# Copyright 2024 Kulpreet Singh
#
# This file is part of Bitcoin-DSL
#
# Bitcoin-DSL is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Bitcoin-DSL is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Bitcoin-DSL. If not, see <https://www.gnu.org/licenses/>.

# frozen_string_literal: false

require_relative '../../dsl/util'

# Script compiler module
module ScriptCompiler
  # script pub key compiler
  module ScriptPubKey
    include Util

    def interpolate_script(script, taproot: nil)
      program = Bitcoin::Script.new
      script.split.each do |element|
        obj = instance_eval(element)
        case obj
        when Bitcoin::Key
          program << obj.xonly_pubkey ? :taproot : obj.pubkey
        else
          program << obj || element
        end
      end
      program
    end

    def compile_script_pubkey(script)
      witness_program = interpolate_script(script)
      return [witness_program, nil] if witness_program.op_return?

      script_pubkey = Bitcoin::Script.to_p2wsh(witness_program)
      logger.debug "SCRIPT_PUBKEY: #{script_pubkey}"
      logger.debug "WITNESS: #{witness_program}"
      store_witness(script_pubkey.to_addr, witness_program)
      [script_pubkey, witness_program]
    end

    # Compile the taproot spec in components and return the script
    # pubkey to use in the transaction
    def compile_taproot(components)
      leaves = (components[:leaves] || []).map do |leaf|
        leaf_script = interpolate_script(leaf, :taproot)
        Bitcoin::Taproot::LeafNode.new(leaf_script)
      end
      builder = Bitcoin::Taproot::SimpleBuilder.new(components[:internal_key].xonly_pubkey, leaves)
      script_pubkey = builder.build
      address = script_pubkey.to_addr
      store_taproot(address, script_pubkey)
      script_pubkey
    end
  end
end
