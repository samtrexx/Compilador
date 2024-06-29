require 'csv'
require 'json'

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

def load_afd_number_mapping(csv_file)
  afd_number_map = {}
  CSV.foreach(csv_file) do |row|
    number = row[0].to_i
    filename = row[1]
    afd_number_map[filename] = number
  end
  afd_number_map
end

def analyze_string_incrementally(input_string, afd_number_map)
  dfas = {}
  Dir.glob('*_afd.json').each do |file_name|
    dfas[file_name] = load_dfa_from_file(file_name)
  end

  index = 0
  while index < input_string.length
    current_substring = ""
    matching_dfa = nil

    (index...input_string.length).each do |i|
      current_substring += input_string[i]

      # Verificar si la subcadena actual coincide con algún AFD
      dfas.each do |file_name, dfa|
        if run_dfa(dfa, current_substring)
          matching_dfa = file_name
          break
        end
      end

      # Si encontramos un AFD que coincide, y el siguiente carácter no es un punto, avanzamos el índice y continuamos
      if matching_dfa && (i + 1 >= input_string.length || input_string[i + 1] != '.')
        # Buscar el número correspondiente al nombre del AFD
        afd_number = afd_number_map[matching_dfa]
        puts "Se encontró un match con el AFD número '#{afd_number}' para la subcadena '#{current_substring}'."
        index = i + 1  # Avanzar el índice para continuar con el siguiente carácter
        break
      end
    end

    # Si no se encontró un AFD que coincida, imprimir mensaje de error
    unless matching_dfa
      if input_string[index] == '.'
        puts "No se encontró un AFD que acepte el punto '.' como inicio de subcadena válida."
      else
        puts "Ningún AFD pudo aceptar la subcadena comenzando desde '#{current_substring}'."
      end
      index += 1  # Avanzar el índice para pasar al siguiente carácter
    end
  end
end

# Cargar el mapeo de número de AFD desde el archivo CSV
afd_number_map = load_afd_number_mapping('Tabla_Lexica.csv')

# Ejemplo de uso:
input_string = '2.8+((37+L21-43.1   )/12.8*var1)'  # Cambia esto por la cadena que quieres probar
puts "\nAnalizando con analyze_string_incrementally:"
analyze_string_incrementally(input_string, afd_number_map)
