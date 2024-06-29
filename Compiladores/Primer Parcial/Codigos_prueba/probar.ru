require 'json'

# Cargar el AFD desde 'prueba.txt' en formato JSON
def cargar_afd_desde_json(archivo)
  json_data = File.read(archivo)
  JSON.parse(json_data)
end

# Función para probar el AFD
def probar_afd(afd, cadena)
  estado_actual = 'q0'  # Estado inicial
  cadena.each_char do |simbolo|
    return false unless afd[estado_actual] && afd[estado_actual][simbolo]
    estado_actual = afd[estado_actual][simbolo]
  end
  afd[estado_actual]['aceptador']  # Comprobar si se llega a un estado aceptador
end

# Cargar el AFD desde el archivo 'prueba.txt' en formato JSON
archivo_afd_json = 'prueba.txt'
afd_json = cargar_afd_desde_json(archivo_afd_json)

# Cadena a probar
puts "Ingresa una cadena para probar el AFD:"
cadena = gets.chomp

# Probar el AFD con la cadena
resultado = probar_afd(afd_json, cadena)
if resultado
  puts "La cadena es válida según el AFD."
else
  puts "La cadena no es válida según el AFD."
end
