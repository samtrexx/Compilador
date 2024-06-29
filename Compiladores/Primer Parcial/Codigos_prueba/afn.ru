require 'json'

# Clase para representar un AFN
class AFN
  attr_accessor :estados, :alfabeto, :transiciones, :estado_inicial, :estados_aceptacion

  def initialize(estados, alfabeto, transiciones, estado_inicial, estados_aceptacion)
    @estados = estados
    @alfabeto = alfabeto
    @transiciones = transiciones
    @estado_inicial = estado_inicial
    @estados_aceptacion = estados_aceptacion
  end

  # Método para obtener la representación del AFN como un hash
  def to_h
    {
      estados: @estados,
      alfabeto: @alfabeto,
      transiciones: @transiciones,
      estado_inicial: @estado_inicial,
      estados_aceptacion: @estados_aceptacion
    }
  end
end

# Función para generar el AFN a partir de una expresión regular
def generar_afn(expresion_regular)
  afn = AFN.new([], [], [], '', [])

  # Lógica para generar el AFN desde la expresión regular
  estados = (0..expresion_regular.length).map { |i| "q#{i}" }  # Generar estados q0, q1, ..., qn
  afn.estados = estados
  afn.alfabeto = expresion_regular.chars.uniq - ['(', ')', '|', '*', '+', '-', '.', '?']  # Obtener el alfabeto eliminando los operadores

  transiciones = []
  estado_actual = "q0"
  pila = []
  expresion_regular.each_char.with_index do |char, index|
    case char
    when '('
      pila << estado_actual
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: [estado_actual] }
    when ')'
      pila << estado_actual
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: [estado_actual] }
    when '|'
      pila << estado_actual
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    when '*'
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: [estado_actual, "q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    when '+'
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    when '-'
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    when '.'
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    when '?'
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    when '&'
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    when ' '
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    else
      transiciones << { estado_origen: estado_actual, simbolo: char, estados_destino: ["q#{index + 1}"] }
      estado_actual = "q#{index + 1}"
    end
  end

  afn.transiciones = transiciones

  afn.estado_inicial = 'q0'
  afn.estados_aceptacion = ["q#{expresion_regular.length}"]

  afn
end

# Generar el AFN para cada expresión regular en archivos separados
num_expressions = File.read('num_expressions.txt').to_i

num_expressions.times do |i|
  # Leer la expresión regular desde el archivo correspondiente
  expresion_regular = File.read("expression_#{i + 1}.txt").chomp

  # Generar el AFN
  afn = generar_afn(expresion_regular)

  # Agregar el operador utilizado al alfabeto
  afn.alfabeto += expresion_regular.scan(/[\(\)\|*+\-.?]/)

  # Guardar el JSON del AFN en un archivo de texto
  File.write("AFN_#{i + 1}.txt", JSON.pretty_generate(afn.to_h))
end

# Imprimir el contenido de los archivos AFN
=begin
puts "\nContenido de los archivos AFN:"
num_expressions.times do |i|
  file_name = "AFN_#{i + 1}.txt"
  if File.exist?(file_name)
    puts "Contenido de #{file_name}:"
    puts File.read(file_name)
    puts "\n"
  else
    puts "Archivo #{file_name} no encontrado."
  end
end
=end

# Ejecutar afn.ru para cada archivo AFN generado
num_expressions.times do |i|
  system("ruby IMPAFN.ru AFN_#{i + 1}.txt")
end
