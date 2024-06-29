require_relative 'AFNAnalyzer'  # Asegúrate de que el archivo AFNAnalyzer.rb esté en el mismo directorio
require 'json'

class AutomataManager
  attr_accessor :afns, :next_afn_token

  def initialize
    @afns = {}  # Cambiado de :afds a :afns
    @next_afn_token = 10  # Cambiado de :next_afd_token a :next_afn_token
    cargar_afns_desde_json("afns.json")
  end

  def menu_principal
    loop do
      puts "\n--- Menú Principal ---"
      puts "1. Agregar AFN"
      puts "2. Eliminar AFN"
      puts "3. Ver AFNs y Tokens"
      puts "4. Escanear entrada"
      puts "5. Salir"

      print "\nIngrese su elección: "
      opcion = gets.chomp.to_i

      case opcion
      when 1
        agregar_afn
        guardar_afns_en_json("afns.json")
      when 2
        eliminar_afn
        guardar_afns_en_json("afns.json")
      when 3
        ver_afns_y_tokens
      when 4
        escanear_entrada
      when 5
        puts "¡Hasta luego!"
        guardar_afns_en_json("afns.json")  # Guardar al salir del programa
        break
      else
        puts "Opción no válida. Por favor, elija una opción del menú."
      end
    end
  end

  private

  def cargar_afns_desde_json(archivo)
    if File.exist?(archivo)
      json_data = File.read(archivo)
      @afns = JSON.parse(json_data)
    end
  end

  def guardar_afns_en_json(archivo)
    File.open(archivo, "w") do |f|
      f.write(JSON.pretty_generate(@afns))
    end
  end

  def agregar_afn
    print "\nIngrese un identificador para el AFN: "
    identificador_afn = gets.chomp

    archivo_afn = "AFN_#{identificador_afn}.txt"
    if File.exist?(archivo_afn)
      @afns[archivo_afn] = @next_afn_token
      @next_afn_token += 10
      puts "AFN agregado con éxito. Token asignado: #{@afns[archivo_afn]}"
    else
      puts "¡El archivo AFN '#{archivo_afn}' no existe!"
    end
  end

  def eliminar_afn
    if @afns.empty?
      puts "No hay AFNs para eliminar."
    else
      puts "\n--- Lista de AFNs ---"
      @afns.each { |archivo_afn, token| puts "#{token}. #{archivo_afn}" }

      print "\nIngrese el número del AFN a eliminar: "
      numero_afn = gets.chomp.to_i

      archivo_afn_a_eliminar = @afns.key(numero_afn)
      if archivo_afn_a_eliminar
        @afns.delete(archivo_afn_a_eliminar)
        puts "AFN eliminado con éxito."
      else
        puts "¡El número de AFN ingresado no es válido!"
      end
    end
  end

  def ver_afns_y_tokens
    if @afns.empty?
      puts "No hay AFNs para mostrar."
    else
      puts "\n--- Lista de AFNs y Tokens ---"
      @afns.each { |archivo_afn, token| puts "#{archivo_afn}: #{token}" }
    end
  end

  def escanear_entrada
    if @afns.empty?
      puts "No hay AFNs disponibles para escanear la entrada."
    else
      print "\nIngrese la cadena a escanear: "
      cadena = gets.chomp.strip  # Eliminar espacios en blanco al inicio y al final

      tokens_cadena = ""
      cadena.each_char do |simbolo|
        encontrado = false

        # Iterar sobre todos los AFNs para el símbolo actual
        @afns.each do |archivo_afn, token|
          afn_analyzer = AFNAnalyzer.new(archivo_afn)
          if afn_analyzer.analizar_cadena(simbolo)
            tokens_cadena += "#{simbolo} pertenece al AFN_#{token}\n"
            encontrado = true
            break
          end
        end

        unless encontrado
          tokens_cadena += "#{simbolo} no pertenece a ningún AFN conocido\n"
        end
      end

      puts "Resultados de la búsqueda por símbolo:\n#{tokens_cadena}"
    end
  end





end

# Ejemplo de uso
automata_manager = AutomataManager.new
automata_manager.menu_principal
