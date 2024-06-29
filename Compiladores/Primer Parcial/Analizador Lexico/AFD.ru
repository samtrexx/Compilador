require 'json'

def epsilon_closure(states, transitions)
  closure = states.dup
  added = true
  while added
    added = false
    closure.dup.each do |state|
      transitions.each do |transition|
        if transition['estado_origen'] == state && transition['simbolo'] == 'ε'
          dest_states = transition['estados_destino']
          dest_states = [dest_states] if dest_states.is_a?(String)
          dest_states.each do |dest_state|
            if !closure.include?(dest_state)
              closure << dest_state
              added = true
            end
          end
        end
      end
    end
  end
  closure
end

def move(states, symbol, transitions)
  result = []
  states.each do |state|
    transitions.each do |transition|
      if transition['estado_origen'] == state && transition['simbolo'] == symbol
        dest_states = transition['estados_destino']
        dest_states = [dest_states] if dest_states.is_a?(String)
        result.concat(dest_states)
      end
    end
  end
  result.uniq
end

def afn_to_afd(afn)
  afn_states = afn['estados']
  afn_transitions = afn['transiciones']
  alphabet = afn['alfabeto'].flatten.uniq
  initial_state = afn['estado_inicial']
  accepting_states = afn['estados_aceptacion']

  dfa_states = []
  dfa_transitions = []
  dfa_initial_state = epsilon_closure([initial_state], afn_transitions)
  dfa_states << dfa_initial_state
  unprocessed_states = [dfa_initial_state]

  while !unprocessed_states.empty?
    current_state = unprocessed_states.pop
    alphabet.each do |symbol|
      next_states = epsilon_closure(move(current_state, symbol, afn_transitions), afn_transitions)
      if !dfa_states.include?(next_states)
        dfa_states << next_states
        unprocessed_states << next_states
      end
      dfa_transitions << {
        'estado_origen' => current_state,
        'simbolo' => symbol,
        'estados_destino' => next_states
      }
    end
  end

  dfa_accepting_states = dfa_states.select { |state| (state & accepting_states).any? }

  dfa = {
    'estados' => dfa_states,
    'transiciones' => dfa_transitions,
    'alfabeto' => alphabet,
    'estado_inicial' => dfa_initial_state,
    'estados_aceptacion' => dfa_accepting_states
  }

  dfa
end

def save_to_txt(dfa, filename)
  File.open(filename, 'w') do |file|
    file.write(JSON.pretty_generate(dfa))
  end
end

def print_table(transitions, afn_alphabet, afn_accepting_states)
  # Crear un hash para almacenar las transiciones por cada estado de origen
  transitions_hash = {}

  transitions.each do |transition|
    state = transition['estado_origen']
    transitions_hash[state] ||= {}
    transitions_hash[state][transition['simbolo']] ||= []
    transitions_hash[state][transition['simbolo']] += transition['estados_destino']
  end

  # Obtener el alfabeto del AFN
  afn_alphabet.flatten.uniq.each do |symbol|
    print symbol.ljust(4) + "| "
  end
  puts "Aceptación"

  puts "-" * (afn_alphabet.flatten.uniq.length * 4 + 10)

  # Imprimir las transiciones para cada estado de origen
  transitions_hash.each do |state, state_transitions|
    # Convertir estado a cadena de texto si es un array
    state_str = state.is_a?(Array) ? state.join(',') : state

    # Imprimir el estado
    print state_str.ljust(15) + "| "

    # Obtener los estados destino para cada símbolo del alfabeto
    afn_alphabet.flatten.uniq.each do |symbol|
      # Obtener los estados destino para el símbolo actual
      dest_states = state_transitions[symbol] || []

      # Imprimir los estados destino
      print (dest_states.empty? ? "-1" : dest_states.sort.join(',')).ljust(4) + "| "
    end

    # Imprimir el estado de aceptación
    estado_aceptacion = afn_accepting_states.include?(state) ? afn_accepting_states.join(',') : '-1'
    puts estado_aceptacion
  end
end

# Obtener el nombre del archivo AFN desde la línea de comandos
afn_filename = ARGV[0]

# Verificar si se proporcionó un nombre de archivo
if afn_filename.nil?
  puts "Por favor, proporciona el nombre del archivo AFN como argumento."
  exit
end

# Leer el contenido del archivo AFN
afn_json = File.read(afn_filename)

# Convertir AFN a AFD
afn = JSON.parse(afn_json)
afd = afn_to_afd(afn)

# Guardar AFD como .txt
afd_filename = afn_filename.sub('.txt', '_afd.txt')
save_to_txt(afd, afd_filename)

# Obtener el alfabeto del AFN
afn_alphabet = afn['alfabeto']

# Imprimir las transiciones del AFD en formato tabular
print_table(afd['transiciones'], afn_alphabet, afn['estados_aceptacion'])
