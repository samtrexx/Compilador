require 'json'

# Clase para representar un AFN
class AFN
  attr_accessor :estados, :alfabeto, :transiciones, :estado_inicial, :estados_aceptacion

  def initialize(afn_data)
    @estados = afn_data['estados']
    @alfabeto = afn_data['alfabeto']
    @transiciones = afn_data['transiciones']
    @estado_inicial = afn_data['estado_inicial']
    @estados_aceptacion = afn_data['estados_aceptacion']
  end

  # Método para implementar la cerradura de Kleene (+)
  def cerradura_kleene_plus
    new_state = "q#{estados.size}"  # Nuevo estado para la cerradura de Kleene (+)
    @estados << new_state  # Agregar el nuevo estado a la lista de estados
    # Agregar transiciones para la cerradura de Kleene (+)
    @transiciones << { estado_origen: new_state, simbolo: '', estados_destino: [estado_inicial] }
    @estados_aceptacion << new_state  # Marcar el nuevo estado como estado de aceptación
  end

  # Método para convertir el AFN modificado a formato JSON
  def to_json
    {
      estados: @estados,
      alfabeto: @alfabeto,
      transiciones: @transiciones,
      estado_inicial: @estado_inicial,
      estados_aceptacion: @estados_aceptacion
    }
  end
end

# Método para cargar un AFN desde un archivo JSON
def cargar_afn_desde_archivo(archivo)
  json_afn = File.read(archivo)
  afn_data = JSON.parse(json_afn)
  AFN.new(afn_data)
end

# Obtener el nombre del archivo AFN desde la línea de comandos
archivo_afn = ARGV[0]

# Cargar el AFN desde el archivo dado
afn = cargar_afn_desde_archivo(archivo_afn)

# Aplicar la cerradura de Kleene (+)
afn.cerradura_kleene_plus

# Guardar el AFN modificado en un nuevo archivo AFN_con_cerradura.txt
archivo_afn_modificado = 'AFN_mas_cerradura.txt'
File.write(archivo_afn_modificado, JSON.pretty_generate(afn.to_json))

puts "AFN modificado con la cerradura de Kleene (+) guardado en #{archivo_afn_modificado}"

# Ejecutar el script IMPAFN.ru con el archivo modificado como argumento
system("ruby IMPAFN.ru #{archivo_afn_modificado}")
