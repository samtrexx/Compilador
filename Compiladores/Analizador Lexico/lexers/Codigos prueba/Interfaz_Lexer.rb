require 'tk'
require 'json'
require 'csv' #Valores separados por comas

# Arreglos para almacenar los datos de la tabla
$indices = []
$items = []

# Archivo para almacenar la tabla de archivos
FILE_TABLE = 'file_table.csv'

# Método para actualizar ambos Listbox
def update_lists(listbox_indices, listbox_items)
  listbox_indices.delete(0, :end)
  listbox_items.delete(0, :end)

  $indices.each_with_index do |index, idx|
    listbox_indices.insert(:end, "#{(idx + 1) * 10}")
    listbox_items.insert(:end, $items[idx])
  end
end

# Método para guardar la tabla de archivos en un archivo CSV
def save_file_table
  CSV.open(FILE_TABLE, 'w') do |csv|
    $indices.each_with_index do |index, idx|
      csv << ["#{(idx + 1) * 10}", $items[idx]]
    end
  end
end

# Método para agregar un archivo a la tabla
def add_file(file_path, listbox_indices, listbox_items)
  if File.exist?(file_path)
    new_index = $indices.size + 1
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
  json_files = Dir.glob('*.json')
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
    listbox_files.insert(:end, "#{(idx + 1) * 10}: #{item}")
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

# Crear la ventana principal
root = TkRoot.new { title "Tabla con dos partes separadas" }

# Marco para contener los Listbox y botones
frame = TkFrame.new(root) { padx 10; pady 10 }.pack(fill: :both, expand: true)

# Listbox para los números (índices)
listbox_indices = TkListbox.new(frame) { width 5; height 10 }.pack(side: :left, fill: :both, expand: true)

# Listbox para los elementos
listbox_items = TkListbox.new(frame) { width 50; height 10 }.pack(side: :left, fill: :both, expand: true)

# Botones para agregar y borrar archivos
btn_add_file = TkButton.new(frame) {
  text "Agregar Archivo"
  command -> { select_file_to_add(listbox_indices, listbox_items) }
}.pack(side: :bottom, padx: 5, pady: 10)

btn_delete_row = TkButton.new(frame) {
  text "Borrar Archivo"
  command -> { select_file_to_delete(listbox_indices, listbox_items) }
}.pack(side: :bottom, padx: 5, pady: 10)

# Mostrar la tabla inicial
update_lists(listbox_indices, listbox_items)

# Ejecutar el bucle principal de la interfaz gráfica
Tk.mainloop
