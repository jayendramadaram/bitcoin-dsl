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

@alice = key wif: 'L4bEFrQrfXH9mZBbq2SoTEx8FkyrG4aP2TZerN8DwSTaGoUcohJd'
@bob = key wif: 'KyWBUpCZF5n9WifoBcDDtCGYmX13SkubfQp3zCiDA4r2vozL5jE8'

# Seed alice with some coins
extend_chain to: @alice

# Seed bob with some coins and make coinbase spendable
extend_chain num_blocks: 101, to: @alice

@alice_coinbase = spendable_coinbase_for @alice

@opcodes_tx = transaction inputs: [
                            { tx: @alice_coinbase, vout: 0, script_sig: 'sig:@alice @alice' }
                          ],
                          outputs: [
                            {
                              descriptor: wsh('OP_DUP OP_HASH160 OP_EQUALVERIFY hash160(@bob) OP_CHECKSIG'),
                              amount: 49.999.sats
                            }
                          ]

verify_signature for_transaction: @opcodes_tx,
                 at_index: 0,
                 with_prevout: [@alice_coinbase, 0]

broadcast @opcodes_tx

confirm transaction: @opcodes_tx, to: @alice

log 'Opcodes transaction confirmed'