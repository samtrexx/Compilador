=begin
CODIGO DE ANALIZADOR LEXICO CON TODO
Este codigo Necesita el Uso de 1 solo codigo extra, llamado Lexer.rb, el cual es el analizar lexico.
=end
require 'tk'
require 'json'

# Definir clases básicas para AFN, Estado, y Transición
class Estado
  attr_accessor :nombre

  def initialize(nombre)
    @nombre = nombre
  end

  def eql?(other)
    self.class == other.class && @nombre == other.nombre
  end

  def hash
    @nombre.hash
  end

  def to_s
    @nombre
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
class AFN
    attr_accessor :nombre, :inicial, :final, :estados, :transiciones, :simbolos

    def initialize(nombre, inicial = nil, final = nil)
      @nombre = nombre
      @inicial = inicial
      @final = [final].compact # Asegúrate de que final sea un array
      @estados = []
      @transiciones = []
      @simbolos = []
    end

    def acepta_cadena?(cadena)
      estados_actuales = epsilon_cerradura([inicial])
      cadena.each_char do |simbolo|
        nuevos_estados = []
        estados_actuales.each do |estado|
          transiciones.each do |transicion|
            if transicion.origen == estado && (transicion.simbolo.include?(simbolo) || transicion.simbolo == simbolo)
              nuevos_estados << transicion.destino
            end
          end
        end
        estados_actuales = epsilon_cerradura(nuevos_estados)
      end
      estados_actuales.any? { |estado| estado == final }
    end

    def epsilon_cerradura(estados)
      estados_cerradura = estados.dup
      nuevos_estados = estados.dup
      while nuevos_estados.any?
        estado_actual = nuevos_estados.shift
        transiciones.each do |transicion|
          if transicion.origen == estado_actual && transicion.simbolo == 'ε'
            destino = transicion.destino
            unless estados_cerradura.include?(destino)
              estados_cerradura << destino
              nuevos_estados << destino
            end
          end
        end
      end
      estados_cerradura
    end
end
def epsilon_closure(states, transitions)
  closure = states.dup
  added = true
  while added
    added = false
    closure.dup.each do |state|
      transitions.each do |transition|
        if transition['origen'] == state && transition['simbolo'] == 'ε'
          dest_state = transition['destino']
          if !closure.include?(dest_state)
            closure << dest_state
            added = true
          end
        end
      end
    end
  end
  closure
end
def move(states, symbol, transitions)
  result = []
  states.each do |state|
    transitions.each do |transition|
      if transition['origen'] == state && transition['simbolo'] == symbol
        result << transition['destino']
      end
    end
  end
  result.uniq
end
# Almacenar los AFNs generados
$afns_generados = []
# Función para abrir una ventana emergente para generar un AFN
def generar_afn
  popup = TkToplevel.new { title "Generar AFN" }

  # Verificar si la altura de la ventana es mayor que 30 y la anchura mayor que 20
  if popup.winfo_height > 30 || popup.winfo_width > 20
    TkScrollbar.new(popup) {
      pack('side' => 'right', 'fill' => 'y')
    }
  end

  TkLabel.new(popup) {
    text 'Ingrese los detalles del AFN'
    pack { padx 15; pady 15; side 'top' }
  }

  TkLabel.new(popup) {
    text 'Nombre del AFN:'
    pack { padx 5; pady 5; side 'left' }
  }
  nombre_afn = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'left' }
  }

  TkLabel.new(popup) {
    text 'Límite inferior:'
    pack { padx 5; pady 5; side 'left' }
  }
  limite_inferior = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'left' }
  }

  TkLabel.new(popup) {
    text 'Límite superior:'
    pack { padx 5; pady 5; side 'left' }
  }
  limite_superior = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Generar'
    command proc {
      nombre = nombre_afn.value
      inferior = limite_inferior.value
      superior = limite_superior.value
      puts "Generando AFN con nombre: #{nombre}, límite inferior: #{inferior}, límite superior: #{superior}"

      afn = crear_afn_basico(nombre, inferior, superior)
      $afns_generados << afn

      mostrar_afn(afn)
      guardar_afn_en_json(afn)  # Llama a la función para guardar el AFN en JSON
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end
# Función para crear un AFN básico con transiciones desde el límite inferior hasta el superior
def crear_afn_basico(nombre, inferior, superior)
  afn = AFN.new(nombre)

  # Crear un estado inicial con un nombre único que incluya el nombre del AFN
  estado_inicial = Estado.new("q_Estado##{nombre}")
  afn.estados << estado_inicial
  afn.inicial = estado_inicial

  estado_final = Estado.new("q_FEstado##{nombre}")
  afn.estados << estado_final
  afn.final = estado_final

  # Añadir transiciones que cubran el rango de símbolos
  rango = (inferior..superior).to_a
  rango.each do |simbolo|
    afn.transiciones << Transicion.new(estado_inicial, estado_final, simbolo)
    afn.simbolos << simbolo #colocar esto en las operaciones
  end

  afn
end
# Función para mostrar los detalles de un AFN en una ventana emergente
def mostrar_afn(afn)
  popup = TkToplevel.new { title "Detalles del AFN" }

  # Crear un widget TkText para mostrar el contenido con una barra de desplazamiento vertical
  text_widget = TkText.new(popup) {
    wrap 'none' # Evitar que el texto se ajuste automáticamente
    pack('side' => 'left', 'fill' => 'both', 'expand' => 'yes')
  }

  # Agregar barra de desplazamiento vertical
  scrollbar_y = TkScrollbar.new(popup) {
    command(proc { |*args| text_widget.yview(*args) })
    pack('side' => 'right', 'fill' => 'y')
  }

  # Configurar el widget TkText para trabajar con la barra de desplazamiento vertical
  text_widget.yscrollbar(scrollbar_y)

  # Construir el contenido a mostrar
  content = ""
  content << "AFN: #{afn.nombre}\n"
  content << "Estado inicial: #{afn.inicial.nombre}\n"
  content << "Estados:\n"
  afn.estados.each { |estado| content << "#{estado.nombre}\n" }
  content << "Transiciones:\n"
  afn.transiciones.each { |transicion| content << "#{transicion.origen.nombre} --#{transicion.simbolo}--> #{transicion.destino.nombre}\n" }
  content << "Estado final: #{afn.final.nombre}\n"

  # Insertar el contenido en el widget TkText
  text_widget.insert('end', content)

  # Habilitar que el widget TkText no sea editable
  text_widget.state('disabled')

  # Crear un widget TkEntry para ingresar la cadena a probar
  cadena_entry = TkEntry.new(popup).pack('side' => 'top', 'fill' => 'x')

  # Crear un botón "Probar AFN" y definir la funcionalidad
  TkButton.new(popup) {
    text 'Probar AFN'
    command proc {
      cadena = cadena_entry.get # Obtener la cadena ingresada
      aceptada = afn.acepta_cadena?(cadena) # Verificar si el AFN acepta la cadena
      resultado = aceptada ? "La cadena '#{cadena}' es aceptada por el AFN." : "La cadena '#{cadena}' NO es aceptada por el AFN."
      Tk.messageBox('type' => 'ok', 'icon' => 'info', 'title' => 'Resultado de la prueba', 'message' => resultado)
    }
    pack('side' => 'top', 'padx' => 5, 'pady' => 5)
  }
end
# Función para seleccionar y mostrar un AFN
def seleccionar_y_mostrar_afn
  popup = TkToplevel.new { title "Seleccionar AFN" }

  TkLabel.new(popup) {
    text 'Seleccione el AFN que desea mostrar:'
    pack { padx 15; pady 15; side 'top' }
  }

  afn_listbox = TkListbox.new(popup) {
    height 10
    pack { padx 15; pady 15; side 'top' }
  }

  $afns_generados.each_with_index do |afn, index|
    afn_listbox.insert(index, afn.nombre)
  end

  TkButton.new(popup) {
    text 'Mostrar'
    command proc {
      selected_index = afn_listbox.curselection
      if selected_index && !selected_index.empty?
        mostrar_afn($afns_generados[selected_index.first])
      end
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end
# Función para guardar un AFN en formato JSON en un archivo
def guardar_afn_en_json(afn)
  # Convierte el AFN a un hash compatible con JSON
  afn_hash = {
    nombre: afn.nombre,
    inicial: afn.inicial.nombre,
    final: afn.final.nombre,
    estados: afn.estados.map { |estado| estado.nombre },
    transiciones: afn.transiciones.map { |transicion| { origen: transicion.origen.nombre, destino: transicion.destino.nombre, simbolo: transicion.simbolo } },
    simbolos: afn.simbolos
  }

  # Convierte el hash a formato JSON
  afn_json = JSON.pretty_generate(afn_hash)

  # Guarda el JSON en un archivo
  File.open("#{afn.nombre}.json", "w") do |file|
    file.write(afn_json)
  end

  puts "AFN guardado en #{afn.nombre}.json"
end
# Función para seleccionar dos AFNs para la unión
def seleccionar_afns_para_unir
  popup = TkToplevel.new { title "Seleccionar AFNs para Unir" }

  TkLabel.new(popup) {
    text 'Seleccione los dos AFNs que desea unir:'
    pack { padx 15; pady 15; side 'top' }
  }

  afn_listbox = TkListbox.new(popup) {
    height 10
    selectmode 'multiple'
    pack { padx 15; pady 15; side 'top' }
  }

  $afns_generados.each_with_index do |afn, index|
    afn_listbox.insert(index, afn.nombre)
  end

  TkButton.new(popup) {
    text 'Unir'
    command proc {
      selected_indices = afn_listbox.curselection
      if selected_indices && selected_indices.size == 2
        afn1 = $afns_generados[selected_indices.first]
        afn2 = $afns_generados[selected_indices.last]
        unir_afn(afn1, afn2)
      end
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end
def agregar_transiciones_epsilon(afn_unido, estado_origen, estado_destino)
  afn_unido.transiciones << Transicion.new(estado_origen, estado_destino, 'ε')
  #afn_unido.simbolos << 'ε' #colocar esto en las operaciones
end
=begin
def agregar_transiciones_simbolo(afn_unido, estado_origen, estado_destino, simbolo)
  afn_unido.transiciones << Transicion.new(estado_origen, estado_destino, simbolo)
  afn_unido.simbolos << simbolo #colocar esto en las operaciones
end
=end
def agregar_transiciones_simbolo(afn_unido, estado_origen, estado_destino, simbolo)
  afn_unido.transiciones << Transicion.new(estado_origen, estado_destino, simbolo)
  afn_unido.simbolos << simbolo unless afn_unido.simbolos.include?(simbolo)
end
def copiar_estados_y_transiciones(afn_unido, afn)
  afn.estados.each do |estado|
    afn_unido.estados << estado unless afn_unido.estados.include?(estado)
  end

  afn.transiciones.each do |transicion|
    agregar_transiciones_simbolo(afn_unido, transicion.origen, transicion.destino, transicion.simbolo)
  end
end

#unir
def unir_afn(afn1, afn2)
  popup = TkToplevel.new { title "Unir AFNs" }

  TkLabel.new(popup) {
    text 'Ingrese el nombre del nuevo AFN unido'
    pack { padx 15; pady 15; side 'top' }
  }

  nombre_afn_unido = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Unir'
    command proc {
      nombre = nombre_afn_unido.value

      # Crear un nuevo AFN para la unión
      afn_unido = AFN.new(nombre)

      # Crear un nuevo estado inicial con el nombre deseado
      estado_inicial_unido = Estado.new("q_Estado##{nombre}")
      afn_unido.estados << estado_inicial_unido
      afn_unido.inicial = estado_inicial_unido

      # Agregar la transición epsilon desde el nuevo estado inicial a los estados iniciales de afn1 y afn2
      agregar_transiciones_simbolo(afn_unido, estado_inicial_unido, afn1.inicial, 'ε')
      agregar_transiciones_simbolo(afn_unido, estado_inicial_unido, afn2.inicial, 'ε')

      # Copiar estados y transiciones de afn1
      copiar_estados_y_transiciones(afn_unido, afn1)

      # Copiar estados y transiciones de afn2
      copiar_estados_y_transiciones(afn_unido, afn2)

      # Fusionar los estados finales en un solo estado final
      estado_final_unido = Estado.new("q_F#{nombre}")
      afn_unido.estados << estado_final_unido

      # Agregar transiciones epsilon desde todos los estados finales de los AFNs al nuevo estado final
      agregar_transiciones_simbolo(afn_unido, afn1.final, estado_final_unido, 'ε')
      agregar_transiciones_simbolo(afn_unido, afn2.final, estado_final_unido, 'ε')

      afn_unido.final = estado_final_unido

      $afns_generados << afn_unido

      mostrar_afn(afn_unido)
      guardar_afn_en_json(afn_unido)  # Llama a la función para guardar el AFN en JSON
      popup.destroy
    }
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'top' }
  }
end

#concatenar
def seleccionar_afns_para_concatenar
  popup = TkToplevel.new { title "Seleccionar AFNs para Concatenar" }

  TkLabel.new(popup) {
    text 'Seleccione los dos AFNs que desea concatenar:'
    pack { padx 15; pady 15; side 'top' }
  }

  afn_listbox = TkListbox.new(popup) {
    height 10
    selectmode 'multiple'
    pack { padx 15; pady 15; side 'top' }
  }

  $afns_generados.each_with_index do |afn, index|
    afn_listbox.insert(index, afn.nombre)
  end

  TkButton.new(popup) {
    text 'Concatenar'
    command proc {
      selected_indices = afn_listbox.curselection
      if selected_indices && selected_indices.size == 2
        afn1 = $afns_generados[selected_indices.first]
        afn2 = $afns_generados[selected_indices.last]
        concatenar_afn(afn1, afn2)
      end
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end
def concatenar_afn(afn1, afn2)
  popup = TkToplevel.new { title "Concatenar AFNs" }

  TkLabel.new(popup) {
    text 'Ingrese el nombre del nuevo AFN concatenado'
    pack { padx 15; pady 15; side 'top' }
  }

  nombre_afn_concatenado = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Concatenar'
    command proc {
      nombre = nombre_afn_concatenado.value

      # Crear un nuevo AFN para la concatenación
      afn_concatenado = AFN.new(nombre)

      # Copiar estados y transiciones de afn1
      copiar_estados_y_transiciones(afn_concatenado, afn1)

      # Copiar estados y transiciones de afn2, excepto el estado inicial
      copiar_estados_y_transiciones(afn_concatenado, afn2)
      afn_concatenado.estados.delete(afn2.inicial)

      # Conectar el estado final de afn1 con el estado inicial de afn2
      afn_concatenado.transiciones << Transicion.new(afn1.final, afn2.inicial, 'ε')

      # Actualizar el estado inicial y final del AFN concatenado
      afn_concatenado.inicial = afn1.inicial
      afn_concatenado.final = afn2.final

      $afns_generados << afn_concatenado

      mostrar_afn(afn_concatenado)
      guardar_afn_en_json(afn_concatenado)  # Llama a la función para guardar el AFN en JSON

      popup.destroy
    }
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'top' }
  }
end
#cerradura (+)
def seleccionar_afn_para_cerradura_positiva
  popup = TkToplevel.new { title "Seleccionar AFN para Cerradura Positiva" }

  TkLabel.new(popup) {
    text 'Seleccione el AFN que desea aplicar la cerradura positiva:'
    pack { padx 15; pady 15; side 'top' }
  }

  afn_listbox = TkListbox.new(popup) {
    height 10
    selectmode 'single'
    pack { padx 15; pady 15; side 'top' }
  }

  $afns_generados.each_with_index do |afn, index|
    afn_listbox.insert(index, afn.nombre)
  end

  TkButton.new(popup) {
    text 'Aplicar Cerradura Positiva'
    command proc {
      selected_index = afn_listbox.curselection.first
      if selected_index
        afn = $afns_generados[selected_index]
        aplicar_cerradura_positiva(afn)
      end
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end
def aplicar_cerradura_positiva(afn)
  popup = TkToplevel.new { title "Cerradura Positiva" }

  TkLabel.new(popup) {
    text 'Ingrese el nombre del nuevo AFN con cerradura positiva'
    pack { padx 15; pady 15; side 'top' }
  }

  nombre_afn_positiva = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Aplicar'
    command proc {
      nombre = nombre_afn_positiva.value

      # Crear un nuevo AFN para la cerradura positiva
      afn_positiva = AFN.new(nombre)

      # Crear un nuevo estado inicial y un nuevo estado final
      estado_inicial_positiva = Estado.new("q_Estado##{nombre}")
      estado_final_positiva = Estado.new("q_F#{nombre}")
      afn_positiva.estados << estado_inicial_positiva
      afn_positiva.estados << estado_final_positiva

      # Agregar transiciones epsilon
      afn_positiva.transiciones << Transicion.new(estado_inicial_positiva, afn.inicial, 'ε')
      afn_positiva.transiciones << Transicion.new(afn.final, estado_final_positiva, 'ε')
      afn_positiva.transiciones << Transicion.new(afn.final, afn.inicial, 'ε')

      # Copiar estados y transiciones del AFN original
      copiar_estados_y_transiciones(afn_positiva, afn)

      afn_positiva.inicial = estado_inicial_positiva
      afn_positiva.final = estado_final_positiva

      $afns_generados << afn_positiva

      mostrar_afn(afn_positiva)
      guardar_afn_en_json(afn_positiva)  # Llama a la función para guardar el AFN en JSON

      popup.destroy
    }
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'top' }
  }
end
#cerraudura (*)
def seleccionar_afn_para_cerradura_kleene_por
  popup = TkToplevel.new { title "Seleccionar AFN para Cerradura de Kleene (*)" }

  TkLabel.new(popup) {
    text 'Seleccione el AFN que desea aplicar la cerradura de Kleene (*):'
    pack { padx 15; pady 15; side 'top' }
  }

  afn_listbox = TkListbox.new(popup) {
    height 10
    selectmode 'single'
    pack { padx 15; pady 15; side 'top' }
  }

  $afns_generados.each_with_index do |afn, index|
    afn_listbox.insert(index, afn.nombre)
  end

  TkButton.new(popup) {
    text 'Aplicar Cerradura de Kleene (*)'
    command proc {
      selected_index = afn_listbox.curselection.first
      if selected_index
        afn = $afns_generados[selected_index]
        aplicar_cerradura_kleene_por(afn)
      end
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end
def aplicar_cerradura_kleene_por(afn)
  popup = TkToplevel.new { title "Cerradura de Kleene (*)" }

  TkLabel.new(popup) {
    text 'Ingrese el nombre del nuevo AFN con cerradura de Kleene (*)'
    pack { padx 15; pady 15; side 'top' }
  }

  nombre_afn_kleene_por = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Aplicar'
    command proc {
      nombre = nombre_afn_kleene_por.value

      # Crear un nuevo AFN para la cerradura de Kleene (*)
      afn_kleene_por = AFN.new(nombre)

      # Crear un nuevo estado inicial y un nuevo estado final
      estado_inicial_kleene_por = Estado.new("q_Estado##{nombre}")
      estado_final_kleene_por = Estado.new("q_F#{nombre}")
      afn_kleene_por.estados << estado_inicial_kleene_por
      afn_kleene_por.estados << estado_final_kleene_por

      # Agregar transiciones epsilon
      afn_kleene_por.transiciones << Transicion.new(estado_inicial_kleene_por, afn.inicial, 'ε')
      afn_kleene_por.transiciones << Transicion.new(estado_inicial_kleene_por, estado_final_kleene_por, 'ε')
      afn_kleene_por.transiciones << Transicion.new(afn.final, estado_final_kleene_por, 'ε')
      afn_kleene_por.transiciones << Transicion.new(afn.final, afn.inicial, 'ε')

      # Copiar estados y transiciones del AFN original
      copiar_estados_y_transiciones(afn_kleene_por, afn)

      afn_kleene_por.inicial = estado_inicial_kleene_por
      afn_kleene_por.final = estado_final_kleene_por

      $afns_generados << afn_kleene_por

      mostrar_afn(afn_kleene_por)
      guardar_afn_en_json(afn_kleene_por)  # Llama a la función para guardar el AFN en JSON

      popup.destroy
    }
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'top' }
  }
end
#cerradura (?)
def seleccionar_afn_para_cerradura_opcional
  popup = TkToplevel.new { title "Seleccionar AFN para Cerradura Opcional" }

  TkLabel.new(popup) {
    text 'Seleccione el AFN que desea aplicar la cerradura opcional:'
    pack { padx 15; pady 15; side 'top' }
  }

  afn_listbox = TkListbox.new(popup) {
    height 10
    selectmode 'single'
    pack { padx 15; pady 15; side 'top' }
  }

  $afns_generados.each_with_index do |afn, index|
    afn_listbox.insert(index, afn.nombre)
  end

  TkButton.new(popup) {
    text 'Aplicar Cerradura Opcional'
    command proc {
      selected_index = afn_listbox.curselection.first
      if selected_index
        afn = $afns_generados[selected_index]
        aplicar_cerradura_opcional(afn)
      end
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end
def aplicar_cerradura_opcional(afn)
  popup = TkToplevel.new { title "Cerradura Opcional" }

  TkLabel.new(popup) {
    text 'Ingrese el nombre del nuevo AFN con cerradura opcional'
    pack { padx 15; pady 15; side 'top' }
  }

  nombre_afn_opcional = TkEntry.new(popup) {
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Aplicar'
    command proc {
      nombre = nombre_afn_opcional.value

      # Crear un nuevo AFN para la cerradura opcional
      afn_opcional = AFN.new(nombre)

      # Crear un nuevo estado inicial y un nuevo estado final
      estado_inicial_opcional = Estado.new("q_Estado##{nombre}")
      estado_final_opcional = Estado.new("q_F#{nombre}")
      afn_opcional.estados << estado_inicial_opcional
      afn_opcional.estados << estado_final_opcional

      # Agregar transiciones epsilon
      afn_opcional.transiciones << Transicion.new(estado_inicial_opcional, afn.inicial, 'ε')
      afn_opcional.transiciones << Transicion.new(estado_inicial_opcional, estado_final_opcional, 'ε')
      afn_opcional.transiciones << Transicion.new(afn.final, estado_final_opcional, 'ε')

      # Copiar estados y transiciones del AFN original
      copiar_estados_y_transiciones(afn_opcional, afn)

      afn_opcional.inicial = estado_inicial_opcional
      afn_opcional.final = estado_final_opcional

      $afns_generados << afn_opcional

      mostrar_afn(afn_opcional)
      guardar_afn_en_json(afn_opcional)  # Llama a la función para guardar el AFN en JSON

      popup.destroy
    }
    pack { padx 5; pady 5; side 'top' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'top' }
  }
end



#AFD
class AFD
  attr_accessor :nombre, :inicial, :estados_finales, :estados, :transiciones

  def initialize(nombre, inicial)
    @nombre = nombre
    @inicial = inicial
    @estados_finales = []
    @estados = [inicial]
    @transiciones = {}
  end

  def acepta_cadena?(cadena)
    estado_actual = inicial
    cadena.each_char do |simbolo|
      estado_actual = transiciones[estado_actual][simbolo]
      return false unless estado_actual
    end
    estados_finales.include?(estado_actual)
  end
end
def obtener_conjunto_siguiente(afn, conjunto_actual, simbolo)
  conjunto_siguiente = []
  conjunto_actual.each do |estado|
    afn.transiciones.each do |transicion|
      if transicion.origen == estado && transicion.simbolo == simbolo
        conjunto_siguiente.concat(afn.epsilon_cerradura([transicion.destino]))
      end
    end
  end
  conjunto_siguiente.uniq
end
def afn_to_afd(afn)
  afn_states = afn['estados']
  afn_transitions = afn['transiciones']
  alphabet = afn['simbolos'].flatten.uniq
  initial_state = afn['inicial']
  accepting_states = afn['final']

  dfa_states = []
  dfa_transitions = []
  dfa_initial_state = epsilon_closure([initial_state], afn_transitions)
  dfa_states << dfa_initial_state
  unprocessed_states = [dfa_initial_state]

  while !unprocessed_states.empty?
    current_state = unprocessed_states.pop
    alphabet.each do |symbol|
      next_states = epsilon_closure(move(current_state, symbol, afn_transitions), afn_transitions)
      if !dfa_states.include?(next_states)
        dfa_states << next_states
        unprocessed_states << next_states
      end
      dfa_transitions << {
        'estado_origen' => current_state,
        'simbolo' => symbol,
        'estados_destino' => next_states
      }
    end
  end

  dfa_accepting_states = dfa_states.select { |state| state.any? { |substate| accepting_states.include?(substate) } }

  dfa = {
    'estados' => dfa_states,
    'transiciones' => dfa_transitions,
    'simbolos' => alphabet,
    'inicial' => dfa_initial_state,
    'final' => dfa_accepting_states
  }

  dfa
end
def save_to_txt(dfa, filename)
  File.open(filename, 'w') do |file|
    file.write(JSON.pretty_generate(dfa))
  end
end
=begin
def print_table(transitions, afn_alphabet, afn_accepting_states)
  # Crear la ventana emergente
  popup = TkToplevel.new { title "#table AFD" }

  # Crear el contenedor para la tabla con scrollbars
  frame = TkFrame.new(popup) { pack(fill: 'both', expand: true) }
  canvas = TkCanvas.new(frame) { pack(side: 'left', fill: 'both', expand: true) }
  scrollbar_y = TkScrollbar.new(frame) { pack(side: 'right', fill: 'y') }
  scrollbar_x = TkScrollbar.new(popup, orient: 'horizontal') { pack(side: 'bottom', fill: 'x') }

  # Asociar scrollbars al canvas
  canvas.yscrollbar(scrollbar_y)
  canvas.xscrollbar(scrollbar_x)

  # Crear el encabezado
  header = ['Estado'] + afn_alphabet.flatten.uniq + ['Aceptación']
  header.each_with_index do |text, idx|
    TkLabel.new(canvas) do
      text text
      grid(row: 0, column: idx, sticky: 'nsew')
    end
  end

  # Agrupar transiciones por estado
  grouped_transitions = transitions.group_by { |transition| transition['estado_origen'] }

  # Crear las filas de datos agrupados por estado
  grouped_transitions.each_with_index do |(state, state_transitions), row_idx|
    dest_states = Hash.new('-1')
    state_transitions.each do |transition|
      if transition['simbolo'].is_a?(Array)  # Verificar si simbolo es un arreglo
        transition['simbolo'].each_with_index do |symbol, col_idx|
          dest_states[symbol] = transition['estados_destino'][col_idx].join(',')
        end
      else
        dest_states[transition['simbolo']] = transition['estados_destino'].join(',')
      end
    end

    # Verificar si el estado actual o algún subestado es un estado de aceptación
    estado_aceptacion = state.any? { |substate| afn_accepting_states.include?(substate) } ? state.join(',') : '-1'

    # Mostrar el estado y las transiciones para cada símbolo
    TkLabel.new(canvas) do
      text state.join(',')
      grid(row: row_idx + 1, column: 0, sticky: 'nsew')
    end
    afn_alphabet.flatten.uniq.each_with_index do |symbol, idx|
      TkLabel.new(canvas) do
        text dest_states[symbol]
        grid(row: row_idx + 1, column: idx + 1, sticky: 'nsew')
      end
    end
    TkLabel.new(canvas) do
      text estado_aceptacion
      grid(row: row_idx + 1, column: afn_alphabet.flatten.uniq.length + 1, sticky: 'nsew')
    end
  end

  # Ajustar el tamaño de las celdas
  (afn_alphabet.flatten.uniq.length + 2).times do |col|
    TkGrid.columnconfigure(canvas, col, weight: 1)
  end
  (grouped_transitions.length + 1).times do |row|
    TkGrid.rowconfigure(canvas, row, weight: 1)
  end

  Tk.mainloop
end
=end
#falta impelemtnar un buen scrollbar para que se vea la info bien
def print_table(transitions, afn_alphabet, afn_accepting_states)
  # Crear la ventana emergente
  popup = TkToplevel.new { title "#table AFD" }

  # Crear el contenedor para la tabla con scrollbars
  frame = TkFrame.new(popup) { pack(fill: 'both', expand: true) }
  canvas = TkCanvas.new(frame) { pack(side: 'left', fill: 'both', expand: true) }
  scrollbar_y = TkScrollbar.new(frame) { pack(side: 'right', fill: 'y') }
  scrollbar_x = TkScrollbar.new(popup, orient: 'horizontal') { pack(side: 'bottom', fill: 'x') }

  # Asociar scrollbars al canvas
  canvas.yscrollbar(scrollbar_y)
  canvas.xscrollbar(scrollbar_x)

  # Crear el encabezado
  header = ['Estado'] + afn_alphabet.flatten.uniq + ['Aceptación']
  header.each_with_index do |text, idx|
    TkLabel.new(canvas) do
      text text
      grid(row: 0, column: idx, sticky: 'nsew')
    end
  end

  # Agrupar transiciones por estado
  grouped_transitions = transitions.group_by { |transition| transition['estado_origen'] }

  # Crear las filas de datos agrupados por estado
  grouped_transitions.each_with_index do |(state, state_transitions), row_idx|
    dest_states = Hash.new('-1')
    state_transitions.each do |transition|
      if transition['simbolo'].is_a?(Array)  # Verificar si simbolo es un arreglo
        transition['simbolo'].each_with_index do |symbol, col_idx|
          dest_states[symbol] = transition['estados_destino'][col_idx].join(',')
        end
      else
        dest_states[transition['simbolo']] = transition['estados_destino'].join(',')
      end
    end

    # Verificar si el estado actual o algún subestado es un estado de aceptación
    estado_aceptacion = state.any? { |substate| afn_accepting_states.include?(substate) } ? state.join(',') : '-1'

    # Mostrar el estado y las transiciones para cada símbolo
    TkLabel.new(canvas) do
      text state.join(',')
      grid(row: row_idx + 1, column: 0, sticky: 'nsew')
    end
    afn_alphabet.flatten.uniq.each_with_index do |symbol, idx|
      TkLabel.new(canvas) do
        text dest_states[symbol]
        grid(row: row_idx + 1, column: idx + 1, sticky: 'nsew')
      end
    end
    TkLabel.new(canvas) do
      text estado_aceptacion
      grid(row: row_idx + 1, column: afn_alphabet.flatten.uniq.length + 1, sticky: 'nsew')
    end
  end

  # Ajustar el tamaño de las celdas
  (afn_alphabet.flatten.uniq.length + 2).times do |col|
    TkGrid.columnconfigure(canvas, col, weight: 1)
  end
  (grouped_transitions.length + 1).times do |row|
    TkGrid.rowconfigure(canvas, row, weight: 1)
  end

  Tk.mainloop
end
def run_dfa(dfa, input_string)
  current_state = dfa['inicial']
  final_states = dfa['final']

  input_string.each_char do |symbol|
    transition_found = false
    dfa['transiciones'].each do |transition|
      if transition['estado_origen'] == current_state && transition['simbolo'] == symbol
        current_state = transition['estados_destino']
        transition_found = true
        break
      end
    end
    unless transition_found
      puts "Error: No se encontró una transición para el símbolo '#{symbol}' en el estado '#{current_state}'."
      return
    end
  end

  if final_states.include?(current_state)
    puts "Cadena aceptada. El AFD llegó al estado de aceptación '#{current_state}'."
  else
    puts "Cadena rechazada. El AFD terminó en el estado '#{current_state}', que no es un estado de aceptación."
  end
end
def seleccionar_y_mostrar_afn_a_afd
  popup = TkToplevel.new { title "Seleccionar AFN para AFD" }

  TkLabel.new(popup) {
    text 'Seleccione el AFN para convertir a AFD:'
    pack { padx 15; pady 15; side 'top' }
  }

  afn_listbox = TkListbox.new(popup) {
    height 10
    pack { padx 15; pady 15; side 'top' }
  }

  # Obtener la lista de archivos JSON en el directorio actual
  afn_files = Dir.glob("*.json")

  afn_files.each_with_index do |afn_file, index|
    afn_name = File.basename(afn_file, ".json")
    afn_listbox.insert(index, afn_name)
  end

  TkButton.new(popup) {
    text 'Convertir a AFD'
    command proc {
      selected_index = afn_listbox.curselection
      if selected_index && !selected_index.empty?
        afn_name = afn_listbox.get(selected_index.first)
        afn_filename = "#{afn_name}.json"

        # Verificar si el archivo JSON existe
        if File.exist?(afn_filename)
          afn_json = File.read(afn_filename)
          afn = JSON.parse(afn_json)
          afd = afn_to_afd(afn)

          afd_filename = afn_filename.sub('.json', '_afd.json')
          save_to_txt(afd, afd_filename)

          afn_alphabet = afn['simbolos']

          print_table(afd['transiciones'], afn_alphabet, afn['final'])


        else
          Tk.messageBox('type' => 'ok', 'icon' => 'error', 'title' => 'Error', 'message' => "No se encontró el archivo #{afn_json_file}.")
        end
      else
        Tk.messageBox('type' => 'ok', 'icon' => 'warning', 'title' => 'Advertencia', 'message' => 'Seleccione un AFN.')
      end
      popup.destroy
    }
    pack { padx 5; pady 5; side 'left' }
  }

  TkButton.new(popup) {
    text 'Cancelar'
    command proc { popup.destroy }
    pack { padx 5; pady 5; side 'left' }
  }
end


def display_menu
  root = TkRoot.new { title "Generador de AFN" }

  TkLabel.new(root) {
    text 'Bienvenido al programa de generación de AFN'
    pack { padx 15; pady 15; side 'top' }
  }

  buttons_frame = TkFrame.new(root) {
    pack { padx 15; pady 15; side 'top' }
  }

  menu_options = [
    { text: '1. Generar AFN', command: proc { generar_afn } },
    { text: '2. Unión (|)', command: proc { seleccionar_afns_para_unir } },
    { text: '3. Concatenación  ', command: proc { seleccionar_afns_para_concatenar} },
    { text: '4. Kleene +', command: proc { seleccionar_afn_para_cerradura_positiva } },
    { text: '5. Kleene *', command: proc { seleccionar_afn_para_cerradura_kleene_por } },
    { text: '6. Cerradura opcional', command: proc { seleccionar_afn_para_cerradura_opcional} },
    { text: '7. Mostrar Cualquier AFN', command: proc { seleccionar_y_mostrar_afn } },
    { text: '8. AFN a AFD', command: proc { seleccionar_y_mostrar_afn_a_afd  } },
    { text: '9. Analizador Léxico', command: proc { system("ruby Lexer.rb")    } },
    { text: '0. Salir', command: proc { exit } }
  ]

  menu_options.each do |option|
    TkButton.new(buttons_frame) {
      text option[:text]
      command option[:command]
      pack { padx 5; pady 5; side 'top' }
    }
  end

  Tk.mainloop
end

def main_menu
  display_menu
end

main_menu
