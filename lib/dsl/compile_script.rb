# froze_string_literal: false

# DSL module for compiling miniscript and generating script sig
module CompileScript
  def compile_miniscript(script)
    policy = script.gsub!(/(\$)(\w+)/) { instance_eval("@#{Regexp.last_match(-1)}", __FILE__, __LINE__).pubkey }
    output = `miniscript-cli -m '#{policy}'`
    raise "Error parsing policy #{policy}" if output.empty?

    result = output.split("\n")
    logger.debug "Result: #{result}"
    logger.debug "Address: #{result[0]}"
    compiled_script = Bitcoin::Script.parse_from_payload(result[1].htb)
    # return the Wsh wrapped descriptor and the witness script
    [Bitcoin::Script.parse_from_addr(result[0]), compiled_script]
  end

  # Compile a scriptSig, replacing `sig:pk` with a signature by pk.
  # Return an array of components that will be concatenated into the witness stack
  def compile_script_sig(transaction, input, index, stack)
    components = get_components(input[:script_sig])
    components.each do |component|
      if component[:type] == :opcode
        stack << Bitcoin::Script.from_string(component[:expression]).to_payload
      else
        send("handle_#{component[:type]}", transaction, input, index, stack, component[:expression])
      end
    end
    append_witness_to_stack(input, index, stack)
  end

  def append_witness_to_stack(input, index, stack)
    input_tx = input[:tx].to_h.with_indifferent_access
    stack << @witness_scripts[input_tx[:txid]][index].to_payload if @witness_scripts[input_tx[:txid]][index]
  end

  def handle_p2wpkh(transaction, input, index, stack, key)
    key = instance_eval("@#{key}", __FILE__, __LINE__)
    stack << get_signature(transaction, input, index, key)
    stack << key.pubkey.htb
  end

  def handle_multisig(transaction, input, index, stack, keys)
    handle_nulldummy(transaction, input, index, stack, keys) # Empty byte for that infamous multisig validation bug
    keys.split(',').each do |key|
      key = instance_eval("@#{key}", __FILE__, __LINE__)
      stack << get_signature(transaction, input, index, key)
    end
  end

  def handle_sig(transaction, input, index, stack, key)
    instance_eval("@#{key}", __FILE__, __LINE__)
    stack << get_signature(transaction, input, index, key)
  end

  def handle_nulldummy(transaction, input, index, stack, key)
    stack << ''
  end

  def get_components(script)
    script.split.collect do |element|
      case element
      when /p2wpkh:\w+/
        { type: :p2wpkh, expression: element.split(':')[1] }
      when /multisig:\w+/
        { type: :multisig, expression: element.split(':')[1] }
      when /sig:\w+/
        { type: :sig, expression: element.split(':')[1] }
      when /nulldummy/
        { type: :nulldummy }
      else
        raise "Unknown term in script sig #{element}" unless opcode?(element)

        { type: :opcode, expression: element }
      end
    end
  end

  def as_opcode(name)
    Bitcoin::Opcodes.name_to_opcode(name)
  end

  def opcode?(name)
    !as_opcode(name).nil?
  end

  # Parses address s.t. if there is a p2wpkh tag, we generate a corresponding address for the key.
  # If there are no tags in the address, we return the received address as it is.
  def parse_address(address)
    address.gsub(/(p2wpkh:)(\w+)/) { instance_eval("@#{Regexp.last_match(-1)}", __FILE__, __LINE__).to_p2wpkh }
  end
end
