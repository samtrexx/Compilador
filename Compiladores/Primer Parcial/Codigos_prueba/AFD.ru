require 'tk'
require 'tkextlib/tile'

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
    transition['simbolo'].each_with_index do |symbol, col_idx|
      dest_states[symbol] = transition['estados_destino'][col_idx].join(',')
    end

    # Verificar si el estado actual o algún subestado es un estado de aceptación
    estado_aceptacion = state.any? { |substate| afn_accepting_states.include?(substate) } ? state.join(',') : '-1'

    # Mostrar el estado y las transiciones
    TkLabel.new(frame) do
      text state.join(',')
      grid(row: row_idx + 1, column: 0, sticky: 'nsew')
    end
    dest_states.each_with_index do |(symbol, dest_state), idx|
      TkLabel.new(frame) do
        text dest_state
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

# Ejemplo de uso
transitions = [
  { 'estado_origen' => ['q0'], 'simbolo' => ['a', 'b'], 'estados_destino' => [['q1'], ['q2']] },
  { 'estado_origen' => ['q1'], 'simbolo' => ['a'], 'estados_destino' => [['q2']] },
  { 'estado_origen' => ['q2'], 'simbolo' => ['b'], 'estados_destino' => [['q0']] }
]
afn_alphabet = [['a', 'b']]
afn_accepting_states = ['q2']

print_table(transitions, afn_alphabet, afn_accepting_states)
