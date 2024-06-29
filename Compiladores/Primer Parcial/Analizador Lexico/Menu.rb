require 'set'
require 'json'
require 'securerandom'

#FUNCIONES GENERALES

class Estado
  attr_reader :nombre
  attr_accessor :es_final

  def initialize(nombre, es_final = false)
    @nombre = nombre
    @es_final = es_final
  end

  # Método para marcar un estado como final
  def marcar_como_final
    @es_final = true
  end

  # Método para verificar si un estado es final
  def final?
    @es_final
  end
end

class Transicion
  attr_accessor :origen, :destino, :simbolo

  def initialize(origen, destino, simbolo)
    @origen = origen
    @destino = destino
    @simbolo = simbolo
  end
end
#FUNCIONES PARA LO QUE SEA DE AFN
class AFN
  attr_accessor :id_afn, :estados, :simbolos, :transiciones, :lim_inf, :lim_sup, :inicial, :final, :alfabeto, :estados_aceptacion
  attr_reader :id_afn, :estados, :simbolos, :transiciones, :lim_inf, :lim_sup, :inicial, :final, :alfabeto, :estados_aceptacion
  attr_accessor :simbolos

  @@contador_id_afn = 0

  def initialize(lim_inf, lim_sup)
    @id_afn = generar_id_afn
    @estados = []
    @simbolos = []
    @transiciones = []
    @lim_inf = lim_inf
    @lim_sup = lim_sup
    @alfabeto = [] # Inicializar el alfabeto como un array vacío
    @estados_aceptacion = []
    generar_afn
  end

  def agregar_simbolo(simbolo)
    @simbolos << simbolo
  end
  def estado_inicial_nombre
    @inicial.nombre
  end
  def estados_finales
    @estados.select { |estado| estado.final? }
  end
  def estado_final
    @final.nombre
  end
  def mostrar_afn
    puts "ID del AFN: #{@id_afn}"
    puts "Estados:"
    @estados.each { |estado| puts estado.nombre }

    puts "\nTransiciones:"
    @transiciones.each do |transicion|
      puts "#{transicion.origen.nombre} -> #{transicion.destino.nombre} con #{transicion.simbolo}"
    end
  end

  def marcar_estado_aceptacion(estado)
    estado.marcar_como_final
  end
  def guardar_afn_en_json(nombre_archivo)
    alfabeto = @estados.flat_map { |estado| estado.nombre.scan(/q(.)_\d+/) }.uniq

    afn_representation = {
      "estados": @estados.map(&:nombre),
      "transiciones": @transiciones.map do |transicion|
        if transicion.simbolo == "ε"
          {
            "estado_origen": transicion.origen.nombre,
            "simbolo": "ε",
            "estados_destino": transicion.destino.nombre
          }
        else
          {
            "estado_origen": transicion.origen.nombre,
            "simbolo": transicion.simbolo,
            "estados_destino": transicion.destino.nombre
          }
        end
      end,
      "alfabeto": alfabeto,
      "estado_inicial": @inicial.nombre,
      "estados_aceptacion": estados_finales.map(&:nombre)
    }

    File.open(nombre_archivo, "w") do |file|
      file.puts JSON.pretty_generate(afn_representation)
    end
  end
  def guardar_afn_perso(nombre_archivo)
    alfabeto = @estados.flat_map { |estado| estado.nombre.scan(/q(.)_\d+/) }.uniq

    # Reemplazar "aceptacion" con "concat_afn2_aceptacion" en el estado de aceptación
    @estados_aceptacion.reject! { |estado| estado.nombre == "aceptacion" }
    @estados_aceptacion << Estado.new("concat_afn2_aceptacion")

    afn_representation = {
      "estados": @estados.map(&:nombre),
      "transiciones": @transiciones.map do |transicion|
        if transicion.simbolo == "ε"
          {
            "estado_origen": transicion.origen.nombre,
            "simbolo": "ε",
            "estados_destino": transicion.destino.nombre
          }
        else
          {
            "estado_origen": transicion.origen.nombre,
            "simbolo": transicion.simbolo,
            "estados_destino": transicion.destino.nombre
          }
        end
      end,
      "alfabeto": alfabeto,
      "estado_inicial": @inicial.nombre,
      "estados_aceptacion": @estados_aceptacion.map(&:nombre)
    }

    File.open(nombre_archivo, "w") do |file|
      file.puts JSON.pretty_generate(afn_representation)
    end
  end









  #bloque privado
  private

  def generar_id_afn
    @@contador_id_afn += 1
  end

  def generar_afn
    lim_inf = @lim_inf
    lim_sup = @lim_sup

    # Crear estado inicial y final
    inicial_nombre = "q#{lim_inf}_#{@id_afn}"  # Nombre del estado inicial basado en lim_inf
    @inicial = Estado.new(inicial_nombre)
    @estados << @inicial

    @final = Estado.new("aceptacion")
    @estados << @final

    estado_anterior = @inicial

    # Generar transiciones para caracteres dentro del rango especificado
    if lim_inf.is_a?(String) && lim_inf.length == 1 && lim_sup.is_a?(String) && lim_sup.length == 1
      (lim_inf..lim_sup).each do |char|
        estado_actual = Estado.new("q#{char}_#{@id_afn}")
        @estados << estado_actual

        # Conectar el estado inicial con el estado actual
        if char.between?(lim_inf, lim_sup)
          # Si el caracter está dentro del rango, la transición va hacia el estado de aceptación
          transicion = Transicion.new(@inicial, @final, char)
        else
          # Si el caracter no está dentro del rango, la transición va hacia el próximo estado en la secuencia
          transicion = Transicion.new(@inicial, estado_actual, char)
        end

        @transiciones << transicion

        estado_anterior = estado_actual
      end
    end
  end









end


def unir_afn(afn1, afn2)
  # Crear un nuevo AFN
  nuevo_afn = AFN.new(nil, nil)

  # Crear un nuevo estado inicial y final para el nuevo AFN
  nuevo_estado_inicial = Estado.new("q#{afn1.inicial.nombre}_#{afn2.inicial.nombre}")
  nuevo_estado_final = Estado.new("q#{afn1.final.nombre}_#{afn2.final.nombre}")

  # Agregar los nuevos estados inicial y final al nuevo AFN
  nuevo_afn.inicial = nuevo_estado_inicial
  nuevo_afn.final = nuevo_estado_final
  nuevo_afn.estados << nuevo_estado_inicial
  nuevo_afn.estados << nuevo_estado_final

  # Unir las transiciones del primer AFN al nuevo AFN
  afn1.transiciones.each do |transicion|
    nuevo_afn.transiciones << Transicion.new(transicion.origen, transicion.destino, transicion.simbolo)
    nuevo_afn.simbolos << transicion.simbolo unless nuevo_afn.simbolos.include?(transicion.simbolo)
  end

  # Unir las transiciones del segundo AFN al nuevo AFN
  afn2.transiciones.each do |transicion|
    nuevo_afn.transiciones << Transicion.new(transicion.origen, transicion.destino, transicion.simbolo)
    nuevo_afn.simbolos << transicion.simbolo unless nuevo_afn.simbolos.include?(transicion.simbolo)
  end

  # Agregar transiciones ε desde el nuevo estado inicial a los estados iniciales de los AFN originales
  nuevo_afn.transiciones << Transicion.new(nuevo_estado_inicial, afn1.inicial, 'ε')
  nuevo_afn.transiciones << Transicion.new(nuevo_estado_inicial, afn2.inicial, 'ε')

  # Agregar transiciones ε desde los estados finales de los AFN originales al nuevo estado final
  nuevo_afn.transiciones << Transicion.new(afn1.final, nuevo_estado_final, 'ε')
  nuevo_afn.transiciones << Transicion.new(afn2.final, nuevo_estado_final, 'ε')

  # Añadir todos los estados únicos del primer AFN al nuevo AFN
  afn1.estados.each do |estado|
    nuevo_afn.estados << estado unless nuevo_afn.estados.include?(estado)
  end

  # Añadir todos los estados únicos del segundo AFN al nuevo AFN
  afn2.estados.each do |estado|
    nuevo_afn.estados << estado unless nuevo_afn.estados.include?(estado)
  end

  nuevo_afn
end
def concatenar_afn(afn1, afn2)
  # Crear un nuevo AFN
  nuevo_afn = AFN.new(nil, nil)

  # Copiar los estados y transiciones del primer AFN al nuevo AFN
  afn1.estados.each do |estado|
    nuevo_afn.estados << estado
  end

  afn1.transiciones.each do |transicion|
    nuevo_afn.transiciones << Transicion.new(transicion.origen, transicion.destino, transicion.simbolo)
    nuevo_afn.simbolos << transicion.simbolo unless nuevo_afn.simbolos.include?(transicion.simbolo)
  end

  # Copiar los estados y transiciones del segundo AFN al nuevo AFN, ajustando los nombres de los estados
  afn2.estados.each do |estado|
    nuevo_estado = Estado.new("concat_afn2_#{estado.nombre}")
    nuevo_afn.estados << nuevo_estado
  end

  # Establecer el estado inicial del nuevo AFN como el estado inicial de afn1
  nuevo_afn.inicial = afn1.inicial

  # Eliminar "aceptacion" de la lista de estados de aceptación
  nuevo_afn.estados_aceptacion.delete_if { |estado| estado.nombre == "aceptacion" }

  # Agregar "concat_afn2_aceptacion" a la lista de estados de aceptación
  nuevo_afn.estados_aceptacion << Estado.new("concat_afn2_aceptacion")

  afn2.transiciones.each do |transicion|
    nuevo_transicion = Transicion.new(Estado.new("concat_afn2_#{transicion.origen.nombre}"), Estado.new("concat_afn2_#{transicion.destino.nombre}"), transicion.simbolo)
    nuevo_afn.transiciones << nuevo_transicion
    nuevo_afn.simbolos << transicion.simbolo unless nuevo_afn.simbolos.include?(transicion.simbolo)
  end

  # Conectar estado final de AFN1 con estado inicial de AFN2 mediante una transición ε
  nuevo_afn.transiciones << Transicion.new(afn1.final, Estado.new("concat_afn2_#{afn2.inicial.nombre}"), 'ε')

  # Eliminar la transición del estado de aceptación al estado inicial de afn2
  nuevo_afn.transiciones.reject! { |transicion| transicion.origen.nombre == "aceptacion" && transicion.destino.nombre == afn2.inicial.nombre }

  nuevo_afn
end
def cerradura_opcional_afn(afn)
  nuevo_afn = AFN.new(nil, nil)

  # Crear un nuevo estado inicial y final para el nuevo AFN
  nuevo_estado_inicial = Estado.new("q0")
  nuevo_estado_final = Estado.new("qf")

  # Agregar los nuevos estados inicial y final al nuevo AFN
  nuevo_afn.inicial = nuevo_estado_inicial
  nuevo_afn.final = nuevo_estado_final
  nuevo_afn.estados << nuevo_estado_inicial
  nuevo_afn.estados << nuevo_estado_final

  # Copiar las transiciones del AFN original al nuevo AFN
  afn.transiciones.each do |transicion|
    nuevo_afn.transiciones << transicion.dup
  end

  # Agregar transiciones ε desde el nuevo estado inicial al estado inicial del AFN original
  nuevo_afn.transiciones << Transicion.new(nuevo_estado_inicial, afn.inicial, 'ε')

  # Agregar transiciones ε desde el estado final del AFN original al nuevo estado final
  nuevo_afn.transiciones << Transicion.new(afn.final, nuevo_estado_final, 'ε')

  nuevo_afn
end















def kleene_positiva_afn(afn)
  # Crear un nuevo AFN
  nuevo_afn = AFN.new(nil, nil)

  # Crear un nuevo estado inicial y final para el nuevo AFN
  nuevo_estado_inicial = Estado.new("q#{afn.inicial.nombre}_#{afn.final.nombre}_star")
  nuevo_estado_final = Estado.new("q#{afn.inicial.nombre}_#{afn.final.nombre}_star")

  # Agregar los nuevos estados inicial y final al nuevo AFN
  nuevo_afn.inicial = nuevo_estado_inicial
  nuevo_afn.final = nuevo_estado_final
  nuevo_afn.estados << nuevo_estado_inicial
  nuevo_afn.estados << nuevo_estado_final

  # Método para agregar una transición al nuevo AFN
  def agregar_transicion(origen, destino, simbolo, nuevo_afn)
    nuevo_afn.transiciones << Transicion.new(origen, destino, simbolo)
    nuevo_afn.simbolos << simbolo unless nuevo_afn.simbolos.include?(simbolo)
  end

  # Unir las transiciones del AFN original al nuevo AFN
  afn.transiciones.each do |transicion|
    agregar_transicion(transicion.origen, transicion.destino, transicion.simbolo, nuevo_afn)
  end

  # Agregar transiciones ε desde el nuevo estado inicial a los estados iniciales del AFN original
  agregar_transicion(nuevo_estado_inicial, afn.inicial, 'ε', nuevo_afn)

  # Agregar transiciones ε desde los estados finales del AFN original al nuevo estado final y al estado inicial
  agregar_transicion(afn.final, nuevo_estado_final, 'ε', nuevo_afn)
  agregar_transicion(afn.final, afn.inicial, 'ε', nuevo_afn)

  # Agregar los símbolos del alfabeto del AFN original al nuevo AFN
  nuevo_afn.simbolos.concat(afn.simbolos).uniq!

  # Agregar los estados del AFN original al nuevo AFN
  nuevo_afn.estados.concat(afn.estados).uniq!

  nuevo_afn
end

def kleene_cerradura_afn(afn)
  # Crear un nuevo AFN
  nuevo_afn = AFN.new(nil, nil)

  # Crear un nuevo estado inicial y final para el nuevo AFN
  nuevo_estado_inicial = Estado.new("q#{afn.inicial.nombre}_#{afn.final.nombre}")
  nuevo_estado_final = Estado.new("q#{afn.inicial.nombre}_#{afn.final.nombre}_final")

  # Agregar los nuevos estados inicial y final al nuevo AFN
  nuevo_afn.inicial = nuevo_estado_inicial
  nuevo_afn.final = nuevo_estado_final
  nuevo_afn.estados << nuevo_estado_inicial
  nuevo_afn.estados << nuevo_estado_final

  # Método para agregar una transición al nuevo AFN
  def agregar_transicion(origen, destino, simbolo, nuevo_afn)
    nuevo_afn.transiciones << Transicion.new(origen, destino, simbolo)
    nuevo_afn.simbolos << simbolo unless nuevo_afn.simbolos.include?(simbolo)
  end

  # Unir las transiciones del AFN original al nuevo AFN
  afn.transiciones.each do |transicion|
    agregar_transicion(transicion.origen, transicion.destino, transicion.simbolo, nuevo_afn)
  end

  # Agregar transiciones ε desde el nuevo estado inicial a los estados iniciales del AFN original y al estado final
  agregar_transicion(nuevo_estado_inicial, afn.inicial, 'ε', nuevo_afn)
  agregar_transicion(nuevo_estado_inicial, nuevo_estado_final, 'ε', nuevo_afn)

  # Agregar transiciones ε desde el estado final del AFN original al nuevo estado final y al estado inicial
  agregar_transicion(afn.final, nuevo_estado_final, 'ε', nuevo_afn)
  agregar_transicion(afn.final, nuevo_estado_inicial, 'ε', nuevo_afn)

  # Agregar los símbolos del alfabeto del AFN original al nuevo AFN
  nuevo_afn.simbolos.concat(afn.simbolos).uniq!

  # Agregar los estados del AFN original al nuevo AFN
  nuevo_afn.estados.concat(afn.estados).uniq!

  nuevo_afn
end



#tabhla hash para AFN y AFD
class HashTable
  def initialize
    @afn_table = {}
    @next_id_afn = 1
  end

  def agregar_afn(afn)
    afn.id_afn = @next_id_afn
    @afn_table[@next_id_afn] = afn
    @next_id_afn += 1
  end

  def obtener_afn(id_afn)
    @afn_table[id_afn]
  end

end
#FUNCIONES PARA LO QUE ES AFD


def cerradura_epsilon(estado, transiciones)
  cerradura = []
  pila = [estado]

  until pila.empty?
    actual = pila.pop
    cerradura << actual

    transiciones.each do |transicion|
      if transicion.origen == actual && transicion.simbolo == 'ε' && !cerradura.include?(transicion.destino)
        pila.push(transicion.destino)
      end
    end
  end

  cerradura
end

def mover(estado, simbolo, transiciones)
  estados_destino = []

  transiciones.each do |transicion|
    if transicion.origen == estado && transicion.simbolo == simbolo
      estados_destino << transicion.destino
    end
  end

  estados_destino
end

def irA(estados, simbolo, transiciones)
  irA_resultado = []

  estados.each do |estado|
    irA_resultado.concat(mover(estado, simbolo, transiciones))
  end

  irA_resultado.uniq
end

class AFD
  attr_accessor :estado_inicial, :estados_aceptacion, :transiciones, :alfabeto

  def initialize(alfabeto)
    @estado_inicial = nil
    @estados_aceptacion = []
    @transiciones = {}
    @alfabeto = alfabeto
  end

  def agregar_transicion(estado_origen, simbolo, estado_destino)
    @transiciones[estado_origen] ||= {}
    @transiciones[estado_origen][simbolo] = estado_destino
  end

  def marcar_estado_aceptacion(estado)
    @estados_aceptacion << estado
  end

  def establecer_estado_inicial(estado)
    @estado_inicial = estado
  end

  def guardar_en_archivo(nombre_archivo)
    File.open(nombre_archivo, "w") do |file|
      file.puts "Estado inicial: #{@estado_inicial ? @estado_inicial : 'No definido'}"
      file.puts "Estados de aceptación: #{@estados_aceptacion}"
      file.puts "Transiciones:"
      @transiciones.each do |estado_origen, transiciones|
        transiciones.each do |simbolo, estado_destino|
          file.puts "#{estado_origen} --#{simbolo}--> #{estado_destino}"
        end
      end
    end
  end
end


class ConvertidorAFNtoAFD
  def initialize(afn)
    @afn = afn
    @afd = AFD.new(afn.simbolos)
  end

  def convertir
    estado_inicial_afn = @afn.estados.find { |estado| estado.nombre == @afn.lim_inf }
    conjuntos_estados = [cerradura_epsilon([estado_inicial_afn], @afn.transiciones)]

    conjuntos_estados.each do |conjunto|
      @afn.simbolos.each do |simbolo|
        siguiente_conjunto = cerradura_epsilon(mover(conjunto, simbolo, @afn.transiciones), @afn.transiciones)
        @afd.agregar_transicion(conjunto, simbolo, siguiente_conjunto)
        conjuntos_estados << siguiente_conjunto unless conjuntos_estados.include?(siguiente_conjunto)
      end
    end

    conjuntos_estados.each do |conjunto|
      if (conjunto & [@afn.final]).any?
        @afd.marcar_estado_aceptacion(conjunto)
      end
    end

    estado_inicial_afd = conjuntos_estados.find { |conjunto| conjunto.include?(estado_inicial_afn) }
    @afd.establecer_estado_inicial(estado_inicial_afd)
  end

  def guardar_afd_en_archivo(nombre_archivo)
    @afd.guardar_en_archivo(nombre_archivo)
  end

  private

  def cerradura_epsilon(estados, transiciones)
    cerradura = []
    pila = estados.dup

    until pila.empty?
      actual = pila.pop
      cerradura << actual

      transiciones.each do |transicion|
        if transicion.origen == actual && transicion.simbolo == 'ε' && !cerradura.include?(transicion.destino)
          pila.push(transicion.destino)
        end
      end
    end

    cerradura
  end

  def mover(estados, simbolo, transiciones)
    estados_destino = []

    transiciones.each do |transicion|
      if estados.include?(transicion.origen) && transicion.simbolo == simbolo
        estados_destino << transicion.destino
      end
    end

    estados_destino
  end
end


# FUNCIONES PARA MENU Y OPCIONES
# Función para solicitar límites al usuario
def solicitar_limites
  print "Ingrese el límite inferior: "
  lim_inf = gets.chomp
  print "Ingrese el límite superior: "
  lim_sup = gets.chomp
  [lim_inf, lim_sup]
end
# Función para limpiar la pantalla y mostrar el menú
def display_menu
  print "Presiona Enter para limpiar la pantalla..."
  gets
  system("clear") || system("cls") # Intenta limpiar la pantalla en sistemas Unix/Linux y Windows
  puts "Bienvenido al programa de generación de AFN"
  puts "Menú:"
  puts "1. Generar AFN"
  puts "2. Unión (|)"
  puts "3. Concatenación"
  puts "4. Kleene +"
  puts "5. Kleene *"
  puts "6. Mostrar Cualquier AFN"
  puts "7. AFN a AFD "
  puts "8. Analizador Lexico"
  puts "9. Pronar Analizador lexico"
  puts "0. Salir"
  puts "Ingrese el número de la opción que desea:"
end
def aceptar?
  print "Presiona 'S' para aceptar, 'N' para cancelar: "
  respuesta = gets.chomp.downcase
  respuesta == 's'
end

def cambiar_estado_aceptacion_en_archivo(nombre_archivo, nuevo_estado_aceptacion)
  # Leer el contenido del archivo JSON
  afn_json = File.read(nombre_archivo)

  # Parsear el contenido JSON
  afn_representation = JSON.parse(afn_json)

  # Cambiar el estado de aceptación
  afn_representation["estados_aceptacion"] = [nuevo_estado_aceptacion]

  # Escribir de vuelta en el archivo
  File.open(nombre_archivo, "w") do |file|
    file.puts JSON.pretty_generate(afn_representation)
  end
end


# Función principal que muestra el menú y maneja las opciones
def main_menu
  tabla_afn = HashTable.new
  tabla_afd = HashTable.new

  loop do
    display_menu

    option = gets.chomp.to_i

    case option
    when 1 # Generar AFN
      lim_inf, lim_sup = solicitar_limites
      nuevo_afn = AFN.new(lim_inf, lim_sup)
      nuevo_afn.marcar_estado_aceptacion(nuevo_afn.final) # Marcando el estado final como estado de aceptación
      tabla_afn.agregar_afn(nuevo_afn)
      puts "AFN generado correctamente. ID del AFN: #{nuevo_afn.id_afn}"
      # Luego, llamas al método guardar_afn_en_json para guardar el AFN en formato JSON
      filename = "AFN_#{nuevo_afn.id_afn}.txt" # Nombre del archivo con el formato AFN_#id.json
      nuevo_afn.guardar_afn_en_json(filename)
      puts "AFN guardado en #{filename}"
     # nuevo_afn.mostrar_afn
    when 2 # operacion de union
      puts "Operación de Unión"
      print "Ingrese el ID del primer AFN que desea unir: "
      id_afn1 = gets.chomp.to_i
      afn1 = tabla_afn.obtener_afn(id_afn1)
      unless afn1
        puts "No se encontró un AFN con ese ID."
        next
      end

      print "Ingrese el ID del segundo AFN que desea unir: "
      id_afn2 = gets.chomp.to_i
      afn2 = tabla_afn.obtener_afn(id_afn2)
      unless afn2
        puts "No se encontró un AFN con ese ID."
        next
      end
      if aceptar?#condicional para unir
      # Lógica de unión de AFN
      nuevo_afn = unir_afn(afn1, afn2)
      tabla_afn.agregar_afn(nuevo_afn)
      puts "AFN unidos correctamente. ID del nuevo AFN: #{nuevo_afn.id_afn}"
      nuevo_afn.mostrar_afn
      filename = "AFN_#{nuevo_afn.id_afn}.txt" # Nombre del archivo con el formato AFN_#id.json
      nuevo_afn.guardar_afn_perso(filename)
      puts "AFN guardado en #{filename}"
      cambiar_estado_aceptacion_en_archivo(filename, "concat_afn2_aceptacion")

      else
        puts "Operación cancelada."
      end


    when 3 # Concatenar
      puts "Operación de Concatenación"
      print "Ingrese el ID del primer AFN: "
      id_afn1 = gets.chomp.to_i
      afn1 = tabla_afn.obtener_afn(id_afn1)
      if afn1.nil?
        puts "No se encontró un AFN con el ID proporcionado."
        next
      end

      print "Ingrese el ID del segundo AFN: "
      id_afn2 = gets.chomp.to_i
      afn2 = tabla_afn.obtener_afn(id_afn2)
      if afn2.nil?
        puts "No se encontró un AFN con el ID proporcionado."
        next
      end


      if aceptar?
      # Concatenar los dos AFN
      nuevo_afn = concatenar_afn(afn1, afn2)
      # Agregar el nuevo AFN a la tabla de hash
      tabla_afn.agregar_afn(nuevo_afn)
      puts "Operación de Concatenación realizada con éxito. ID del nuevo AFN: #{nuevo_afn.id_afn}"
      filename = "AFN_#{nuevo_afn.id_afn}.txt" # Nombre del archivo con el formato AFN_#id.json
      nuevo_afn.guardar_afn_en_json(filename)
      puts "AFN guardado en #{filename}"
      puts "Estado final del nuevo AFN: #{nuevo_afn.estados_aceptacion.first.nombre}"

      else
        puts "Operación cancelada."
      end

    when 4 # Kleene +
      puts "Operación de Kleene +"
      print "Ingrese el ID del AFN al que desea aplicar Kleene +: "
      id_afn = gets.chomp.to_i
      afn = tabla_afn.obtener_afn(id_afn)
      if aceptar?
        if afn
          nuevo_afn = kleene_positiva_afn(afn)
          tabla_afn.agregar_afn(nuevo_afn)
          puts "Se aplicó Kleene + al AFN con ID #{afn.id_afn}. Nuevo ID del AFN resultante: #{nuevo_afn.id_afn}"
          nuevo_afn.mostrar_afn
          filename = "AFN_#{nuevo_afn.id_afn}.txt" # Nombre del archivo con el formato AFN_#id.json
          nuevo_afn.guardar_afn_en_json(filename)
          puts "AFN guardado en #{filename}"
        else
          puts "No se encontró un AFN con ese ID."
        end
      else
        puts "Operación cancelada."
      end
    when 5 # kleene *
      puts "Operación de Kleene *"
      print "Ingrese el ID del AFN al que desea aplicar Kleene *: "
      id_afn = gets.chomp.to_i
      afn = tabla_afn.obtener_afn(id_afn)
      if aceptar?
        if afn
          nuevo_afn = kleene_cerradura_afn(afn)
          tabla_afn.agregar_afn(nuevo_afn)
          puts "Se aplicó Kleene * al AFN con ID #{afn.id_afn}. Nuevo ID del AFN resultante: #{nuevo_afn.id_afn}"
          nuevo_afn.mostrar_afn
          filename = "AFN_#{nuevo_afn.id_afn}.txt" # Nombre del archivo con el formato AFN_#id.json
          nuevo_afn.guardar_afn_en_json(filename)
          puts "AFN guardado en #{filename}"
        else
          puts "No se encontró un AFN con ese ID."
        end
      else
        puts "Operación cancelada."
      end


    when 6 # muestrar los AFN
      print "Ingrese el ID del AFN que desea mostrar: "
      id_afn = gets.chomp.to_i
      afn = tabla_afn.obtener_afn(id_afn)
      if afn
        afn.mostrar_afn
      else
        puts "No se encontró un AFN con ese ID."
      end
    when 7 # Crear AFD
      puts "Crear AFD"
      # Interfaz de usuario para seleccionar el AFN
      print "Ingrese el ID del AFN para convertirlo en AFD : "
      id_afn = gets.chomp.to_i
      afn_filename = "AFN_#{id_afn}.txt"  # Nombre del archivo AFN basado en el ID ingresado

        if aceptar?
            if File.exist?(afn_filename)
              system("ruby AFD.ru #{afn_filename}")
            else
              puts "No se encontró el archivo AFN con el ID especificado."
            end
        else
          puts "Operación cancelada."
        end


    when 8 #analizador lexico

    when 9 # Cerradura opcional
      puts "Operación de Cerradura opcional"
      print "Ingrese el ID del AFN al que desea aplicar la cerradura opcional: "
      id_afn = gets.chomp.to_i
      afn = tabla_afn.obtener_afn(id_afn)
      if afn
        nuevo_afn = cerradura_opcional_afn(afn)
        tabla_afn.agregar_afn(nuevo_afn)
        puts "Se aplicó la cerradura opcional al AFN con ID #{afn.id_afn}. Nuevo ID del AFN resultante: #{nuevo_afn.id_afn}"
        nuevo_afn.mostrar_afn
        filename = "AFN_#{nuevo_afn.id_afn}.txt" # Nombre del archivo con el formato AFN_#id.json
        nuevo_afn.guardar_afn_en_json(filename)
        puts "AFN guardado en #{filename}"
      else
        puts "No se encontró un AFN con ese ID."
      end



    when 0
      puts "Saliendo del programa..."
      break
    else
      puts "Opción no válida. Inténtelo de nuevo."
    end
  end
end

# Llamada a la función principal
main_menu

#muestra cada estado
  #  if afn.nil?
  #   puts "No se encontró un AFN con el ID proporcionado."
  #  else
  #    puts "AFN ID: #{idAFN}"
  #    puts "Estados: #{afn[:estados].estados}"
  #    puts "Transiciones: #{afn[:transiciones].transiciones}"
  #    puts "Estado inicial: #{afn[:estado_inicial]}"
  #    puts "Estado final: #{afn[:estado_final]}"
  #  end
