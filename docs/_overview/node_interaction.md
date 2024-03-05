---
layout: page
title: Node Interaction
nav_order: 4
---

# Node Interaction

The DSL makes it easy to interact with bitcoin node with complete
contract state available.

---

The DSL supports all JSON-API commands supported by bitcoin. You don't
need to worry about (de)serialization of arguments. Just provide the
transaction object or any other parameter directly from the DSL. Here
are a few examples:

```ruby
@address = ...

# Mine blocks to the address
generatetoaddress num_blocks: 100, to: @address

@tx = ...

# Send raw transaction
sendrawtransaction tx: @tx
```

Apart from providing access to the raw JSON-API commands, the DSL also
provides commands that use the JSON-API to make life easier for a
contract developer. For example, there are commands to extend chain
and finding a spendable UTXO controlled by a key.

See details under [Node Interaction](/reference#node-interaction)
section of the reference for details.