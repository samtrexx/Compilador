require 'json'
# Función para obtener el conjunto de estados alcanzables a partir de un conjunto de estados y un símbolo
def get_reachable_states(states, symbol, data)
  reachable_states = []
  states.each do |state|
    transitions = data['states'][state]['transitions'][symbol] || []
    reachable_states.concat(transitions)
  end
  reachable_states.uniq
end
# Función para convertir el AFN a AFD
def convert_automaton(data)
  start_state = data['start_state']
  final_state = data['final_state']
  states = data['states'].keys
  data['states'].each do |state, info|
    info['transitions'] = replace_epsilon_transitions(info['transitions'])
  end
  # Inicialización del automata
  automaton_states = {}
  automaton_transitions = {}
  automaton_final_states = []

  # Calcula el conjunto de estados alcanzables a partir del estado inicial
  initial_states = [start_state]
  automaton_states[start_state] = { 'is_final' => (start_state == final_state), 'transitions' => data['states'][start_state]['transitions'] }
  queue = [start_state]

  while !queue.empty?
    current_state = queue.shift
    automaton_states[current_state]['transitions'].each do |symbol, _|
      reachable_states = get_reachable_states([current_state], symbol, data)
      automaton_transitions[current_state] ||= {}
      automaton_transitions[current_state][symbol] = reachable_states
      reachable_states.each do |state|
        if !automaton_states[state]
          automaton_states[state] = { 'is_final' => (state == final_state), 'transitions' => data['states'][state]['transitions'] }
          queue << state
        end
      end
    end
  end

  # Marca los estados finales del automata
  automaton_states.each do |state, info|
    automaton_final_states << state if info['is_final']
  end

  # Genera la definición del automata en formato JSON
  automaton_data = {
    'start_state' => start_state,
    'final_state' => final_state,
    'states' => automaton_states
  }

  automaton_data
end
def replace_epsilon_transitions(transitions)
  transitions.each_with_object({}) do |(symbol, states), new_transitions|
    new_symbol = symbol == "" ? "ε" : symbol
    new_transitions[new_symbol] = states
  end
end
def evaluate_afd(afd, input_string)
  current_state = afd["start_state"]
  transitions = afd["states"]

  input_string.each_char do |symbol|
    if transitions[current_state]["transitions"].key?(symbol)
      current_state = transitions[current_state]["transitions"][symbol][0]
    else
      return false  # No hay transición para el símbolo actual
    end
  end

  transitions[current_state]["is_final"]
end



afn_json_file = File.read('nfa.json')
afn_data = JSON.parse(afn_json_file)

afd_data = convert_automaton(afn_data)
File.open('afd.json', 'w') { |file| file.write(JSON.pretty_generate(afd_data)) }

input_string = 'aabc'
result = evaluate_afd(afn_data, input_string)
puts result
