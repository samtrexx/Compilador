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
# Función para unir dos AFN semánticamente
def unir_afn(afn1, afn2)
  # Obtener la unión de los alfabetos de los AFN
  nuevo_alfabeto = afn1.alfabeto | afn2.alfabeto

  # Calcular nuevos estados y transiciones
  nuevos_estados = afn1.estados + afn2.estados

  # Mapear los estados de aceptación de afn2 a nuevos estados de aceptación en el AFN unido
  nuevos_estados_aceptacion = afn2.estados_aceptacion.map { |estado| "q#{nuevos_estados.size + estado[1..-1].to_i}" }

  # Crear el nuevo AFN unido
  afn_unido = AFN.new(nuevos_estados, nuevo_alfabeto, afn1.transiciones + afn2.transiciones, afn1.estado_inicial, afn1.estados_aceptacion + nuevos_estados_aceptacion)
end


# Leer el número de AFN a unir
num_afn = File.read('num_expressions.txt').to_i

# Leer y cargar los AFN desde los archivos
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

# Unir los AFN semánticamente
afn_union = afns.reduce { |result, afn| unir_afn(result, afn) }

# Guardar el AFN unido en un archivo
File.write('AFN_union.txt', JSON.pretty_generate(afn_union.to_h))

puts "AFN union saved in AFN_union.txt."

# Leer y mostrar el contenido del archivo AFN_union.txt
=begin
file_name_union = 'AFN_union.txt'
if File.exist?(file_name_union)
  puts "Contenido de #{file_name_union}:"
  puts File.read(file_name_union)
else
  puts "Archivo #{file_name_union} no encontrado."
end
=end
system("ruby IMPAFN.ru AFN_union.txt")
