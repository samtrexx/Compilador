require 'tk'

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
    afn.simbolos << simbolo
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

def afn_a_afd(afn)
  afd = AFD.new("AFD_#{afn.nombre}", afn.inicial)
  conjunto_inicial = afn.epsilon_cerradura([afn.inicial])

  conjunto_estados_afd = [conjunto_inicial]
  estados_afd_por_evaluar = [conjunto_inicial]

  while !estados_afd_por_evaluar.empty?
    conjunto_actual = estados_afd_por_evaluar.shift

    afn.simbolos.each do |simbolo|
      conjunto_siguiente = obtener_conjunto_siguiente(afn, conjunto_actual, simbolo)

      unless conjunto_estados_afd.include?(conjunto_siguiente)
        conjunto_estados_afd << conjunto_siguiente
        estados_afd_por_evaluar << conjunto_siguiente
      end

      afd.transiciones[conjunto_actual.map(&:to_s)] ||= {}
      afd.transiciones[conjunto_actual.map(&:to_s)][simbolo] = conjunto_siguiente.map(&:to_s)
    end

  # Asignar estado final al AFD si es el mismo que el del AFN
  afd.estados_finales << conjunto_actual.map(&:to_s) if conjunto_actual.include?(afn.final)

  end

  afd
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
#mostrar el AFD
def mostrar_afd(afd)
  popup = TkToplevel.new { title "Detalles del AFD" }

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
  content << "AFD resultante:\n"
  content << "Nombre: #{afd.nombre}\n"
  content << "Estado inicial: #{afd.inicial}\n"
  content << "Estados finales: #{afd.estados_finales}\n"
  content << "Estados: #{afd.estados}\n"
  content << "Transiciones:\n"

  afd.transiciones.each do |estado_origen, transiciones|
    transiciones.each do |simbolo, estado_destino|
      content << "  #{estado_origen} --#{simbolo}--> #{estado_destino}\n"
    end
  end

    # Insertar el contenido en el widget TkText
    text_widget.insert('end', content)
  # Habilitar que el widget TkText no sea editable
  text_widget.state('disabled')
end

# Función para seleccionar y mostrar un AFN y su AFD resultante
def seleccionar_y_mostrar_afn_a_afd
  popup = TkToplevel.new { title "Seleccionar AFN para Convertir a AFD" }

  TkLabel.new(popup) {
    text 'Seleccione el AFN que desea convertir a AFD:'
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
    text 'Convertir a AFD'
    command proc {
      selected_index = afn_listbox.curselection.first
      if selected_index
        afn = $afns_generados[selected_index]
        afd = afn_a_afd(afn) # Convertir AFN a AFD
        mostrar_afd(afd) # Mostrar AFD resultante
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
    { text: ' Generar AFN', command: proc { generar_afn } },
    { text: ' Mostrar Cualquier AFN', command: proc { seleccionar_y_mostrar_afn } },
    { text: ' AFN a AFD', command: proc { seleccionar_y_mostrar_afn_a_afd  } },
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
