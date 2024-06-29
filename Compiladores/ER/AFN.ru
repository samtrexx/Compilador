require 'json'
require 'set'

class State
  attr_accessor :transitions, :is_final, :name

  @@state_count = 0

  def initialize(is_final = false)
    @transitions = {}
    @is_final = is_final
    @name = "S#{@@state_count}"
    @@state_count += 1
  end

  def add_transition(symbol, state)
    @transitions[symbol] ||= []
    @transitions[symbol] << state
  end

  def to_s
    "State(#{@name}, final: #{@is_final}, transitions: #{@transitions.keys})"
  end
end

class NFA
  attr_accessor :start_state, :final_state

  def initialize(start_state, final_state)
    @start_state = start_state
    @final_state = final_state
  end

  def self.from_symbol(symbol)
    start_state = State.new
    final_state = State.new(true)
    start_state.add_transition(symbol, final_state)
    NFA.new(start_state, final_state)
  end

  def self.concatenate(nfa1, nfa2)
    nfa1.final_state.is_final = false
    nfa1.final_state.add_transition(nil, nfa2.start_state)
    NFA.new(nfa1.start_state, nfa2.final_state)
  end

  def self.union(nfa1, nfa2)
    start_state = State.new
    final_state = State.new(true)
    start_state.add_transition(nil, nfa1.start_state)
    start_state.add_transition(nil, nfa2.start_state)
    nfa1.final_state.is_final = false
    nfa2.final_state.is_final = false
    nfa1.final_state.add_transition(nil, final_state)
    nfa2.final_state.add_transition(nil, final_state)
    NFA.new(start_state, final_state)
  end

  def self.kleene_star(nfa)
    start_state = State.new
    final_state = State.new(true)
    start_state.add_transition(nil, nfa.start_state)
    start_state.add_transition(nil, final_state)
    nfa.final_state.is_final = false
    nfa.final_state.add_transition(nil, nfa.start_state)
    nfa.final_state.add_transition(nil, final_state)
    NFA.new(start_state, final_state)
  end

  def to_h
    states = {}
    collect_states(@start_state, states)
    states[@final_state.name] = { is_final: true, transitions: {} } # Agregar estado final

    # Agregar transiciones de estado inicial a sí mismo para todas las transiciones
    @start_state.transitions.each do |symbol, next_states|
      @start_state.transitions[symbol] = [@start_state.name]
    end

    {
      start_state: @start_state.name,
      final_state: @final_state.name,
      states: states
    }
  end

  def collect_states(state, states)
    return if states.key?(state.name)
    states[state.name] = {
      is_final: state.is_final,
      transitions: state.transitions.transform_values { |v| v.map(&:name) }
    }
    state.transitions.values.flatten.each { |next_state| collect_states(next_state, states) }
  end

  def epsilon_closure(states)
    closure = states.to_set
    stack = states.to_a

    until stack.empty?
      state = stack.pop
      (state.transitions[nil] || []).each do |next_state|
        unless closure.include?(next_state)
          closure.add(next_state)
          stack.push(next_state)
        end
      end
    end

    closure
  end

  def matches?(input)
    current_states = epsilon_closure([@start_state])
    input.chars.each do |char|
      next_states = []
      current_states.each do |state|
        next_states.concat(state.transitions[char] || [])
      end
      current_states = epsilon_closure(next_states)
    end
    current_states.any? { |state| state.is_final }
  end
end

def process_operator(stack, operator)
  case operator
  when '.'
    nfa2 = stack.pop
    nfa1 = stack.pop
    stack.push(NFA.concatenate(nfa1, nfa2))
  when '|'
    nfa2 = stack.pop
    nfa1 = stack.pop
    stack.push(NFA.union(nfa1, nfa2))
  end
end
def parse_regex_to_nfa(regex)
  stack = []
  operators = []

  i = 0
  while i < regex.length
    char = regex[i]
    case char
    when '*'
      nfa = stack.pop
      stack.push(NFA.kleene_star(nfa))
    when '+'
      nfa = stack.pop
      stack.push(NFA.concatenate(nfa, NFA.kleene_star(nfa)))
    when '|'
      while operators.any? && operators.last != '('
        process_operator(stack, operators.pop)
      end
      operators.push(char)
    when '('
      operators.push(char)
    when ')'
      while operators.any? && operators.last != '('
        process_operator(stack, operators.pop)
      end
      operators.pop
    when '.'
      operators.push(char)
    else
      stack.push(NFA.from_symbol(char))
      if i + 1 < regex.length && regex[i + 1] != '|' && regex[i + 1] != ')' && regex[i + 1] != '*' && regex[i + 1] != '+'
        process_operator(stack, '.')
      end
    end
    i += 1
  end

  while operators.any?
    process_operator(stack, operators.pop)
  end

  stack.pop
end
def save_nfa_to_json(nfa, filename)
  File.open(filename, 'w') do |file|
    file.write(JSON.pretty_generate(nfa.to_h))
  end
end
def load_nfa_from_json(filename)
  data = JSON.parse(File.read(filename))
  states = {}
  data['states'].each do |name, state_data|
    states[name] = State.new(state_data['is_final'])
    states[name].name = name
  end
  data['states'].each do |name, state_data|
    state_data['transitions'].each do |symbol, next_states|
      next_states.each do |next_state|
        states[name].add_transition(symbol == '' ? nil : symbol, states[next_state])
      end
    end
  end
  NFA.new(states[data['start_state']], states[data['final_state']])
end
def test_regex_with_string(regex, string)
  nfa = parse_regex_to_nfa(regex)
  save_nfa_to_json(nfa, 'nfa.json')
  loaded_nfa = load_nfa_from_json('nfa.json')
  result = loaded_nfa.matches?(string)
  puts "La cadena '#{string}' #{result ? 'es' : 'no es'} aceptada por la ER '#{regex}'"
end

regex = '(a|b)+.c'
string = 'aabc'
test_regex_with_string(regex, string)
