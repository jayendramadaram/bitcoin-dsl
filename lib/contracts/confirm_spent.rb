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

# Generate new keys
@alice = key :new
@bob = key :new

# Seed alice with some coins
extend_chain to: @alice

# Seed bob with some coins and make coinbase spendable
extend_chain num_blocks: 101, to: @alice

@alice_coinbase = spendable_coinbase_for @alice

@simple_tx = transaction inputs: [
                           { tx: @alice_coinbase, vout: 0, script_sig: 'sig:@alice @alice' }
                         ],
                         outputs: [
                           {
                             descriptor: 'wpkh(@alice)',
                             amount: 49.999.sats
                           }
                         ]

assert_output_is_not_spent transaction: @alice_coinbase, vout: 0

broadcast @simple_tx
confirm transaction: @simple_tx, to: @alice

assert_output_is_spent transaction: @alice_coinbase, vout: 0
assert_output_is_not_spent transaction: @simple_tx, vout: 0
