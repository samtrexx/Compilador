require 'json'

class AFNAnalyzer
  def initialize(afn_filename)
    @afn = cargar_afn_desde_archivo(afn_filename)
  end

  def analizar_cadena(cadena)
    estados_actuales = obtener_estados_epsilon([@afn["estado_inicial"]])
    cadena.each_char do |simbolo|
      estados_actuales = obtener_siguientes_estados(estados_actuales, simbolo)
      estados_actuales = obtener_estados_epsilon(estados_actuales)
    end
    estados_aceptacion = @afn["estados_aceptacion"]
    estados_actuales.any? { |estado| estados_aceptacion.include?(estado) }
  end

  private

  def cargar_afn_desde_archivo(archivo_afn)
    JSON.parse(File.read(archivo_afn))
  end

  def obtener_siguientes_estados(estados_actuales, simbolo)
    siguientes_estados = []
    estados_actuales.each do |estado_actual|
      # Manejar el caso especial del símbolo "."
      if simbolo == "."
        transiciones_punto = obtener_transiciones_epsilon(estado_actual)
        siguientes_estados.concat(transiciones_punto)
      else
        transiciones = obtener_transiciones(estado_actual, simbolo)
        siguientes_estados.concat(transiciones)
      end
    end
    siguientes_estados
  end


  def obtener_transiciones(estado, simbolo)
    transiciones = @afn["transiciones"].select do |transicion|
      transicion["estado_origen"] == estado && (transicion["simbolo"] == simbolo || transicion["simbolo"] == ".")
    end
    transiciones.map { |transicion| transicion["estados_destino"] }
  end

  def obtener_estados_epsilon(estados_actuales)
    nuevos_estados = estados_actuales.dup
    estados_actuales.each do |estado_actual|
      transiciones_epsilon = obtener_transiciones_epsilon(estado_actual)
      nuevos_estados.concat(transiciones_epsilon)
    end
    nuevos_estados.uniq
  end

  def obtener_transiciones_epsilon(estado)
    transiciones_epsilon = @afn["transiciones"].select do |transicion|
      transicion["estado_origen"] == estado && transicion["simbolo"] == "ε"
    end
    transiciones_epsilon.map { |transicion| transicion["estados_destino"] }
  end


end

# Ejemplo de uso
afn_analyzer = AFNAnalyzer.new('AFN_5.txt')

print "Ingrese una cadena a analizar: "
cadena = gets.chomp

if afn_analyzer.analizar_cadena(cadena)
  puts "La cadena '#{cadena}' es aceptada por el AFN."
else
  puts "La cadena '#{cadena}' no es aceptada por el AFN."
end
