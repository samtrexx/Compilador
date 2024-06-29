require 'json'

# Método para obtener la expresión regular a partir de un AFN en formato JSON
def obtener_expresion_regular(afn_txt)
  afn_data = JSON.parse(afn_txt)

  expresion_regular = ""
  transiciones = afn_data['transiciones']

  transiciones.each do |transicion|
    simbolo = transicion['simbolo']
    estados_destino = transicion['estados_destino'].join(',')

    expresion_regular += simbolo unless simbolo.empty?
  end

  expresion_regular
end

# Verifica si se proporcionó el nombre del archivo como argumento
filename = ARGV[0]
if filename.nil?
  puts "Error: Debes proporcionar un nombre de archivo como argumento."
  exit
end

# Intenta leer el archivo y obtener la expresión regular del AFN en formato JSON
begin
  afn_txt = File.read(filename)
  expresion_regular_afn = obtener_expresion_regular(afn_txt)

  puts "Expresión Regular es:"
  puts expresion_regular_afn
rescue Errno::ENOENT
  puts "Error: El archivo '#{filename}' no existe."
end
