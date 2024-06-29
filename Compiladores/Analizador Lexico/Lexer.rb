require 'tk'
require 'json'
require 'csv'

# Arreglos para almacenar los datos de la tabla
$indices = []
$items = []

# Archivo para almacenar la tabla de archivos
FILE_TABLE = 'Tabla_Lexica.csv'

# Método para actualizar ambos Listbox
def update_lists(listbox_indices, listbox_items)
  listbox_indices.delete(0, :end)
  listbox_items.delete(0, :end)

  $indices.each_with_index do |index, idx|
    listbox_indices.insert(:end, "#{index}")
    listbox_items.insert(:end, $items[idx])
  end
end

# Método para guardar la tabla de archivos en un archivo CSV
def save_file_table
  CSV.open(FILE_TABLE, 'w') do |csv|
    $indices.each_with_index do |index, idx|
      csv << ["#{index}", $items[idx]]
    end
  end
end

# Método para cargar la tabla de archivos desde un archivo CSV
def load_file_table
  if File.exist?(FILE_TABLE)
    CSV.foreach(FILE_TABLE) do |row|
      index = row[0].to_i
      item = row[1]
      $indices << index
      $items << item
    end
  end
end

# Método para agregar un archivo a la tabla
def add_file(file_path, listbox_indices, listbox_items)
  if File.exist?(file_path)
    new_index = $indices.empty? ? 1 : $indices.max + 1
    $indices << new_index
    $items << file_path
    update_lists(listbox_indices, listbox_items)
    save_file_table
  else
    puts "El archivo #{file_path} no existe."
  end
end

# Método para mostrar la ventana emergente y seleccionar un archivo
def select_file_to_add(listbox_indices, listbox_items)
  popup = TkToplevel.new { title "Seleccionar Archivo JSON" }

  files_frame = TkFrame.new(popup) { padx 10; pady 10 }.pack(fill: :both, expand: true)

  listbox_files = TkListbox.new(files_frame) { width 50; height 10 }.pack(side: :left, fill: :both, expand: true)
  scrollbar_files = TkScrollbar.new(files_frame) { orient :vertical }.pack(side: :right, fill: :y)
  listbox_files.yscrollcommand = proc { |first, last| scrollbar_files.set(first, last) }
  scrollbar_files.command = proc { |*args| listbox_files.yview(*args) }

  # Obtener archivos .json en la carpeta actual
  json_files = Dir.glob('*_afd.json')
  json_files.each { |file| listbox_files.insert(:end, file) }

  # Botón para seleccionar el archivo
  btn_select = TkButton.new(popup) {
    text "Seleccionar"
    command proc {
      selected_file = listbox_files.get(listbox_files.curselection)
      add_file(selected_file, listbox_indices, listbox_items)
      popup.destroy
    }
  }.pack(side: :bottom, padx: 5, pady: 10)
end

# Método para mostrar la ventana emergente y seleccionar un archivo para borrar
def select_file_to_delete(listbox_indices, listbox_items)
  popup = TkToplevel.new { title "Seleccionar Archivo para Borrar" }

  files_frame = TkFrame.new(popup) { padx 10; pady 10 }.pack(fill: :both, expand: true)

  listbox_files = TkListbox.new(files_frame) { width 50; height 10 }.pack(side: :left, fill: :both, expand: true)
  scrollbar_files = TkScrollbar.new(files_frame) { orient :vertical }.pack(side: :right, fill: :y)
  listbox_files.yscrollcommand = proc { |first, last| scrollbar_files.set(first, last) }
  scrollbar_files.command = proc { |*args| listbox_files.yview(*args) }

  # Llenar el Listbox con los archivos actuales en la tabla
  $items.each_with_index do |item, idx|
    listbox_files.insert(:end, "#{idx + 1}: #{item}")
  end

  # Botón para seleccionar el archivo a borrar
  btn_select = TkButton.new(popup) {
    text "Borrar"
    command proc {
      selected_index = listbox_files.curselection.first.to_i
      if selected_index >= 0
        $indices.delete_at(selected_index)
        $items.delete_at(selected_index)
        update_lists(listbox_indices, listbox_items)
        save_file_table
      end
      popup.destroy
    }
  }.pack(side: :bottom, padx: 5, pady: 10)
end



def load_dfa_from_file(file_name)
  file = File.read(file_name)
  JSON.parse(file)
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
      return false  # No se encontró una transición válida
    end
  end

  final_states.include?(current_state)  # Retorna true si la cadena es aceptada, false si no
end

def load_afd_number_mapping(csv_file)
  afd_number_map = {}
  CSV.foreach(csv_file) do |row|
    number = row[0].to_i
    filename = row[1]
    afd_number_map[filename] = number
  end
  afd_number_map
end

def analyze_string_incrementally(input_string, afd_number_map)
  require 'tk'

  dfas = {}
  Dir.glob('*_afd.json').each do |file_name|
    dfas[file_name] = load_dfa_from_file(file_name)
  end

  matches = []

  index = 0
  while index < input_string.length
    current_substring = ""
    matching_dfa = nil

    (index...input_string.length).each do |i|
      current_substring += input_string[i]

      # Verificar si la subcadena actual coincide con algún AFD
      dfas.each do |file_name, dfa|
        if run_dfa(dfa, current_substring)
          matching_dfa = file_name
          break
        end
      end

      # Si encontramos un AFD que coincide, y el siguiente carácter no es un punto, avanzamos el índice y continuamos
      if matching_dfa && (i + 1 >= input_string.length || input_string[i + 1] != '.')
        # Buscar el número correspondiente al nombre del AFD
        afd_number = afd_number_map[matching_dfa]
        #matches << "Se encontró un match con el AFD número '#{afd_number}' para la subcadena '#{current_substring}'."
        matches << "#{afd_number}"
        index = i + 1  # Avanzar el índice para continuar con el siguiente carácter
        break
      end
    end

    # Si no se encontró un AFD que coincida, imprimir mensaje de error
    unless matching_dfa
      if input_string[index] == '.'
        matches << "No se encontró un AFD que acepte el punto '.' como inicio de subcadena válida."
      else
        matches << "Ningún AFD pudo aceptar la subcadena comenzando desde '#{current_substring}'."
      end
      index += 1  # Avanzar el índice para pasar al siguiente carácter
    end
  end

  # Mostrar los resultados en una ventana emergente horizontal
  Tk.messageBox(
    type: :ok,
    icon: :info,
    title: "Resultados del Análisis",
    message: matches.join("  |  ")  # Usamos "  |  " como separador horizontal
  )
end



# Método para cargar la tabla desde el archivo CSV al inicio
load_file_table

# Crear la ventana principal
root = TkRoot.new { title "Tabla Lexica" }

# Marco para contener los Listbox y botones
frame = TkFrame.new(root) { padx 10; pady 10 }.pack(fill: :both, expand: true)

# Listbox para los números (índices)
listbox_indices = TkListbox.new(frame) { width 5; height 10 }.pack(side: :left, fill: :both, expand: true)

# Listbox para los elementos
listbox_items = TkListbox.new(frame) { width 50; height 10 }.pack(side: :left, fill: :both, expand: true)

# Mostrar la tabla inicial desde el archivo CSV
update_lists(listbox_indices, listbox_items)

# Botones para agregar y borrar archivos
btn_add_file = TkButton.new(frame) {
  text "Agregar Archivo"
  command -> { select_file_to_add(listbox_indices, listbox_items) }
}.pack(side: :bottom, padx: 5, pady: 10)

btn_delete_row = TkButton.new(frame) {
  text "Borrar Archivo"
  command -> { select_file_to_delete(listbox_indices, listbox_items) }
}.pack(side: :bottom, padx: 5, pady: 10)

# Etiqueta y caja de texto para ingresar la cadena
lbl_input = TkLabel.new(frame) {
  text "Ingrese la cadena:"
  pack(side: :top, padx: 5, pady: 5)
}

entry_input = TkEntry.new(frame) {
  width 50
  pack(side: :top, padx: 5, pady: 5)
}

# Botón para analizar la cadena ingresada
btn_analyze = TkButton.new(frame) {
  text "Analizar"
  command -> {
    afd_number_map = load_afd_number_mapping('Tabla_Lexica.csv')
    input_string = entry_input.get.strip
    analyze_string_incrementally(input_string, afd_number_map)
  }
  pack(side: :top, padx: 5, pady: 5)
}

# Ejecutar el bucle principal de la interfaz gráfica
Tk.mainloop
