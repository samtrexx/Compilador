=begin
Codigo que convierte de afn a afd, usando Json y tabular en la terminal
=end
require 'json'
require 'tk'
require 'tkextlib/tile'

def epsilon_closure(states, transitions)
  closure = states.dup
  added = true
  while added
    added = false
    closure.dup.each do |state|
      transitions.each do |transition|
        if transition['origen'] == state && transition['simbolo'] == 'ε'
          dest_state = transition['destino']
          if !closure.include?(dest_state)
            closure << dest_state
            added = true
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
      if transition['origen'] == state && transition['simbolo'] == symbol
        result << transition['destino']
      end
    end
  end
  result.uniq
end

def afn_to_afd(afn)
  afn_states = afn['estados']
  afn_transitions = afn['transiciones']
  alphabet = afn['simbolos'].flatten.uniq
  initial_state = afn['inicial']
  accepting_states = afn['final']

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

  dfa_accepting_states = dfa_states.select { |state| state.any? { |substate| accepting_states.include?(substate) } }

  dfa = {
    'estados' => dfa_states,
    'transiciones' => dfa_transitions,
    'simbolos' => alphabet,
    'inicial' => dfa_initial_state,
    'final' => dfa_accepting_states
  }

  dfa
end


def save_to_txt(dfa, filename)
  File.open(filename, 'w') do |file|
    file.write(JSON.pretty_generate(dfa))
  end
end
=begin
def print_table(transitions, afn_alphabet, afn_accepting_states)
  # Crear la ventana emergente
  root = TkRoot.new { title "Tabla de Transiciones" }
  frame = TkFrame.new(root).pack(fill: 'both', expand: true)

  # Crear el encabezado
  header = ['Estado'] + afn_alphabet.flatten.uniq + ['Aceptación']
  header.each_with_index do |text, idx|
    TkLabel.new(frame) do
      text text
      grid(row: 0, column: idx, sticky: 'nsew')
    end
  end

  # Crear las filas de datos
  transitions.each_with_index do |transition, row_idx|
    state = transition['estado_origen']
    dest_states = Hash.new('-1')
    if transition['simbolo'].is_a?(Array)  # Verificar si simbolo es un arreglo
      transition['simbolo'].each_with_index do |symbol, col_idx|
        dest_states[symbol] = transition['estados_destino'][col_idx].join(',')
      end
    else
      dest_states[transition['simbolo']] = transition['estados_destino'].join(',')
    end

    # Verificar si el estado actual o algún subestado es un estado de aceptación
    estado_aceptacion = state.any? { |substate| afn_accepting_states.include?(substate) } ? state.join(',') : '-1'

    # Mostrar el estado y las transiciones para cada símbolo
    TkLabel.new(frame) do
      text state.join(',')
      grid(row: row_idx + 1, column: 0, sticky: 'nsew')
    end
    afn_alphabet.flatten.uniq.each_with_index do |symbol, idx|
      TkLabel.new(frame) do
        text dest_states[symbol]
        grid(row: row_idx + 1, column: idx + 1, sticky: 'nsew')
      end
    end
    TkLabel.new(frame) do
      text estado_aceptacion
      grid(row: row_idx + 1, column: afn_alphabet.flatten.uniq.length + 1, sticky: 'nsew')
    end
  end

  # Ajustar el tamaño de las celdas
  (afn_alphabet.flatten.uniq.length + 2).times do |col|
    TkGrid.columnconfigure(frame, col, weight: 1)
  end
  (transitions.length + 1).times do |row|
    TkGrid.rowconfigure(frame, row, weight: 1)
  end

  Tk.mainloop
end
=end
def print_table(transitions, afn_alphabet, afn_accepting_states)
  # Crear la ventana emergente
  root = TkRoot.new { title "Tabla de Transiciones" }
  frame = TkFrame.new(root).pack(fill: 'both', expand: true)

  # Crear el encabezado
  header = ['Estado'] + afn_alphabet.flatten.uniq + ['Aceptación']
  header.each_with_index do |text, idx|
    TkLabel.new(frame) do
      text text
      grid(row: 0, column: idx, sticky: 'nsew')
    end
  end

  # Agrupar transiciones por estado
  grouped_transitions = transitions.group_by { |transition| transition['estado_origen'] }

  # Crear las filas de datos agrupados por estado
  grouped_transitions.each_with_index do |(state, state_transitions), row_idx|
    dest_states = Hash.new('-1')
    state_transitions.each do |transition|
      if transition['simbolo'].is_a?(Array)  # Verificar si simbolo es un arreglo
        transition['simbolo'].each_with_index do |symbol, col_idx|
          dest_states[symbol] = transition['estados_destino'][col_idx].join(',')
        end
      else
        dest_states[transition['simbolo']] = transition['estados_destino'].join(',')
      end
    end

    # Verificar si el estado actual o algún subestado es un estado de aceptación
    estado_aceptacion = state.any? { |substate| afn_accepting_states.include?(substate) } ? state.join(',') : '-1'

    # Mostrar el estado y las transiciones para cada símbolo
    TkLabel.new(frame) do
      text state.join(',')
      grid(row: row_idx + 1, column: 0, sticky: 'nsew')
    end
    afn_alphabet.flatten.uniq.each_with_index do |symbol, idx|
      TkLabel.new(frame) do
        text dest_states[symbol]
        grid(row: row_idx + 1, column: idx + 1, sticky: 'nsew')
      end
    end
    TkLabel.new(frame) do
      text estado_aceptacion
      grid(row: row_idx + 1, column: afn_alphabet.flatten.uniq.length + 1, sticky: 'nsew')
    end
  end

  # Ajustar el tamaño de las celdas
  (afn_alphabet.flatten.uniq.length + 2).times do |col|
    TkGrid.columnconfigure(frame, col, weight: 1)
  end
  (grouped_transitions.length + 1).times do |row|
    TkGrid.rowconfigure(frame, row, weight: 1)
  end

  Tk.mainloop
end
def run_dfa(dfa, input_string)
  current_state = dfa['inicial']
  final_states = dfa['final']

  input_string.each_char do |symbol|
    transition_found = false
    dfa['transiciones'].each do |transition|
      if transition['estado_origen'] == current_state && transition['simbolo'] == symbol
        current_state = transition['estados_destino']
        transition_found = true
        break
      end
    end
    unless transition_found
      puts "Error: No se encontró una transición para el símbolo '#{symbol}' en el estado '#{current_state}'."
      return
    end
  end

  if final_states.include?(current_state)
    puts "Cadena aceptada. El AFD llegó al estado de aceptación '#{current_state}'."
  else
    puts "Cadena rechazada. El AFD terminó en el estado '#{current_state}', que no es un estado de aceptación."
  end
end




afn_filename = ARGV[0]

if afn_filename.nil?
  puts "Por favor, proporciona el nombre del archivo AFN como argumento."
  exit
end

afn_json = File.read(afn_filename)
afn = JSON.parse(afn_json)
afd = afn_to_afd(afn)

afd_filename = afn_filename.sub('.json', '_afd(1).json')
save_to_txt(afd, afd_filename)

afn_alphabet = afn['simbolos']

print_table(afd['transiciones'], afn_alphabet, afn['final'])
input_string = "43.12"
run_dfa(afd, input_string)
