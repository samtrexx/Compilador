# Método para cargar las expresiones regulares desde los archivos
def cargar_expresiones(num_exp)
  expresiones = {}
  num_exp.times do |i|
    file_name = "expression_#{i + 1}.txt"
    expresiones[i + 1] = File.readlines(file_name).map(&:chomp)
  end
  expresiones
end

# Método para determinar la expresión regular de aceptación para la cadena
def determinar_expresion_aceptacion(cadena, expresiones)
  expresion_aceptacion = nil
  expresiones.each do |key, value|
    value.each do |expresion|
      expresion_aceptacion = expresion if cadena.match?(Regexp.new(expresion))
    end
  end
  expresion_aceptacion
end

# Cargar expresiones regulares desde los archivos
num_expresiones = File.readlines("num_expressions.txt").first.to_i
expresiones = cargar_expresiones(num_expresiones)

# Solicitar al usuario una cadena de entrada
puts "Ingrese una cadena:"
cadena = gets.chomp

# Determinar la expresión regular de aceptación para la cadena
expresion_aceptacion = determinar_expresion_aceptacion(cadena, expresiones)

# Mostrar la expresión regular de aceptación junto con la cadena
if expresion_aceptacion
  puts "Cadena: #{cadena} | ER de Aceptación: #{expresion_aceptacion}"
else
  puts "No se encontró una expresión de aceptación para la cadena."
end
# se debe hacer como encontrar cada er para dar su token y asi pasarlo y encontrar cada  er.
#osease, Tengo una ER que tenga una
