# frozen_string_literal: false

run './lib/ark/setup.rb'

@spend_tx = spend inputs: [
                    { tx: @alice_boarding_tx, vout: 0, script_sig: 'p2wpkh:asp_timelock nulldummy nulldummy nulldummy' }
                  ],
                  outputs: [
                    {
                      address: 'p2wpkh:asp',
                      amount: 49.998 * SATS
                    }
                  ]

broadcast transaction: @spend_tx
extend_chain to: @alice
assert_confirmed transaction: @spend_tx
