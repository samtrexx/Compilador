require 'json'

# Obtener el nombre del archivo como argumento de la línea de comandos
archivo_afn = ARGV[0]

# Verificar si se proporcionó el nombre del archivo como argumento
if archivo_afn.nil?
  puts "Por favor, proporciona el nombre del archivo AFN."
  exit
end

# Leer el contenido del archivo JSON
afn_json = File.read(archivo_afn)

# Convertir el JSON a un objeto Ruby
afn = JSON.parse(afn_json)

# Método para obtener la representación de un símbolo
def obtener_simbolo(simbolo)
  case simbolo
  when 'epsilon'
    'ε'
  when 'OR'
    '|'
  else
    simbolo
  end
end

# Imprimir el AFN en el formato especificado
puts "+---------------------------+"
puts "|         AFN               |"
puts "+---------------------------+"
puts "| Estado | simb | estado    | aceptacion |"
afn['transiciones'].each do |transicion|
  origen = transicion['estado_origen']
  simbolo = obtener_simbolo(transicion['simbolo'])
  destino = transicion['estados_destino'].join(', ')
  aceptacion = afn['estados_aceptacion'].include?(destino) ? 'Sí' : 'No'
  puts "| #{origen.ljust(6)} | #{simbolo.ljust(4)} | #{destino.ljust(9)} | #{aceptacion.ljust(10)} |"
end
puts "+---------------------------+"
