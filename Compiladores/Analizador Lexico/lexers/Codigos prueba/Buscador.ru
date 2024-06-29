require 'json'
require 'find'

def load_dfa_from_file(file_name)
  file = File.read(file_name)
  JSON.parse(file)
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
      return false  # No se encontró una transición válida
    end
  end

  final_states.include?(current_state)  # Retorna true si la cadena es aceptada, false si no
end

def analyze_string_in_all_dfas(input_string)
  accepted_afds = []

  Dir.glob('*_afd.json').each do |file_name|
    dfa = load_dfa_from_file(file_name)
    result = run_dfa(dfa, input_string)
    if result
      accepted_afds << file_name
    end
  end

  if accepted_afds.empty?
    puts "Ningún AFD aceptó la cadena."
  else
    puts "Los siguientes AFD aceptaron la cadena:"
    accepted_afds.each { |file_name| puts file_name }
  end
end

# Ejemplo de uso:
input_string = '8 +'  # Cambia esto por la cadena que quieres probar
analyze_string_in_all_dfas(input_string)
