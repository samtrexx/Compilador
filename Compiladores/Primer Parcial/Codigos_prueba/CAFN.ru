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

# Función para concatenar N AFN desde archivos
def concatenar_afn(num_afn)
  afns = []
  num_afn.times do |i|
    file_name = "AFN_#{i + 1}.txt"
    if File.exist?(file_name)
      json_data = File.read(file_name)
      afn_data = JSON.parse(json_data)
      afn = AFN.new(afn_data['estados'], afn_data['alfabeto'], afn_data['transiciones'], afn_data['estado_inicial'], afn_data['estados_aceptacion'])
      afns << afn
    else
      puts "Archivo #{file_name} no encontrado."
    end
  end

  if afns.empty?
    puts "Se necesita al menos un AFN para concatenar."
    return nil
  end

  nuevo_alfabeto = afns.map(&:alfabeto).reduce(:|)
  nuevos_estados = afns.map(&:estados).reduce(:+)

  # Mapear los estados de aceptación de los AFN anteriores al estado inicial del siguiente AFN
  nuevos_estados_aceptacion = []
  estado_inicial_siguiente = afns[0].estados.size
  afns.each_with_index do |afn, index|
    nuevos_estados_aceptacion.concat(afn.estados_aceptacion.map { |estado| "q#{index == 0 ? '' : estado_inicial_siguiente + estado[1..-1].to_i}" })
    estado_inicial_siguiente += afn.estados.size
  end

  # Construir las transiciones concatenadas
  nuevas_transiciones = []
  estado_inicial_siguiente = 0
  afns.each_with_index do |afn, index|
    if index > 0
      nuevas_transiciones << { estado_origen: "q#{estado_inicial_siguiente - 1}", simbolo: '', estados_destino: ["q#{estado_inicial_siguiente}"] }
    end
    nuevas_transiciones.concat(afn.transiciones.map do |transicion|
      {
        estado_origen: "q#{estado_inicial_siguiente + transicion['estado_origen'][1..-1].to_i}",
        simbolo: transicion['simbolo'],
        estados_destino: transicion['estados_destino'].map { |estado| "q#{estado_inicial_siguiente + estado[1..-1].to_i}" }
      }
    end)
    estado_inicial_siguiente += afn.estados.size
  end

  AFN.new(nuevos_estados, nuevo_alfabeto, nuevas_transiciones, "q0", nuevos_estados_aceptacion)
end

# Leer el número de AFN a concatenar
num_afn = File.read('num_expressions.txt').to_i

# Concatenar los AFN
afn_concatenado = concatenar_afn(num_afn)
if afn_concatenado
  # Guardar el AFN concatenado en un archivo
  File.write('AFN_concatenado.txt', JSON.pretty_generate(afn_concatenado.to_h))
  puts "AFN concatenado guardado en AFN_concatenado.txt."
else
  puts "No se pudo concatenar los AFN."
end
# Leer y mostrar el contenido del archivo AFN_concatenado.txt
=begin file_name_concatenado = 'AFN_concatenado.txt'
if File.exist?(file_name_concatenado)
  puts "Contenido de #{file_name_concatenado}:"
  puts File.read(file_name_concatenado)
else
  puts "Archivo #{file_name_concatenado} no encontrado."
=end
system("ruby IMPAFN.ru AFN_concatenado.txt")
