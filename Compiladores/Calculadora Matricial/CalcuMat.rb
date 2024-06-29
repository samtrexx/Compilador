require 'tk'
require 'matrix'

# Definición de la matriz para almacenar matrices
$matriz_madre = {}

# Definición de una clase para manejar operaciones matriciales
class Tokenizer
  TOKENS = {
    '+' => 30,
    '-' => 40,
    '*' => 50,
    '/' => 60,
    '[' => 70,    # Inicio de matriz
    ']' => 80,    # Fin de matriz
    ',' => 90,    # Separador de elementos de matriz
    ';' => 100,   # Separador de filas de matriz
    '(' => 110,   # Paréntesis izquierdo
    ')' => 120    # Paréntesis derecho
  }

  def initialize(input)
    @input = input.chars
    @position = 0
    @current_char = next_char
  end

  def next_token
    while @current_char == ' '
      @current_char = next_char
    end

    return nil if @current_char.nil?

    if @current_char =~ /\d/ || @current_char == '.'
      identifier = @current_char
      while peek_next_char =~ /\d/ || (peek_next_char == '.' && !identifier.include?('.'))
        @current_char = next_char
        identifier += @current_char
      end
      @current_char = next_char
      return 20, identifier.to_f
    elsif TOKENS.include?(@current_char)
      token = TOKENS[@current_char]
      @current_char = next_char
      return token, nil
    else
      raise "Error: Token inesperado '#{@current_char}' en la posición #{@position}"
    end
  end

  def current_position
    @position
  end

  private

  def next_char
    char = @input.shift
    @position += 1 unless char.nil?
    char
  end

  def peek_next_char
    @input.first
  end
end

# Definición de la clase RecursiveDescentParser para parsear operaciones matriciales
class RecursiveDescentParser
  def initialize(input)
    @input = input
    @tokenizer = Tokenizer.new(input)
    @current_token, @current_value = @tokenizer.next_token
  end

  def parse
    matrix_expression
  end

  private

  def matrix_expression
    result = matrix_term
    while @current_token == 30 || @current_token == 40 # + or -
      operador = @current_token
      next_token
      term_result = matrix_term
      if operador == 30
        result += term_result
      elsif operador == 40
        result -= term_result
      end
    end
    result
  end

  def matrix_term
    result = matrix_factor
    while @current_token == 50 || @current_token == 60 # * or /
      operador = @current_token
      next_token
      factor_result = matrix_factor
      if operador == 50
        result *= factor_result
      elsif operador == 60
        raise "No se puede dividir matrices"
      end
    end
    result
  end

  def matrix_factor
    if @current_token == 70 # '['
      next_token
      matrix = parse_matrix
      if @current_token == 80 # ']'
        next_token
        return matrix
      else
        raise "Se esperaba ']' después de la matriz."
      end
    elsif @current_token == 110 # '('
      next_token
      result = matrix_expression
      if @current_token == 120 # ')'
        next_token
        return result
      else
        raise "Se esperaba ')' después de la expresión."
      end
    elsif @current_token == 20 # Número literal
      value = @current_value
      next_token
      return Matrix[[value]]
    else
      raise "Token no esperado '#{@current_token}' en la posición #{@tokenizer.current_position}"
    end
  end

  def parse_matrix
    rows = []
    rows << parse_matrix_row
    while @current_token == 100 # ';'
      next_token
      rows << parse_matrix_row
    end
    Matrix.rows(rows)
  end

  def parse_matrix_row
    row = []
    while @current_token != 100 && @current_token != 80 # ';' or ']'
      row << @current_value if @current_token == 20
      next_token if @current_token == 20
      if @current_token == 90 # ','
        next_token
      end
    end
    row
  end

  def next_token
    @current_token, @current_value = @tokenizer.next_token
  end
end

# Crear la ventana principal
root = TkRoot.new { title "Calculadora Matricial" }
root.geometry("400x600")

# Variable para mostrar la entrada y el resultado
entrada = TkVariable.new

# Crear el cuadro de entrada
TkEntry.new(root, textvariable: entrada, font: 'arial 24 bold', justify: 'right').pack(pady: 10, padx: 10, fill: 'x')

# Función para actualizar la entrada
def actualizar_entrada(entrada, valor)
  entrada.value += valor
end

# Función para evaluar la expresión matricial
def evaluar_entrada(entrada)
  parser = RecursiveDescentParser.new(entrada.value)
  begin
    resultado = parser.parse
    entrada.value = resultado.to_s
    puts "Operación válida"
  rescue StandardError => e
    entrada.value = "Error: #{e.message}"
  end
end

# Función para almacenar una matriz con un nombre dado
def almacenar_matriz(nombre, matriz)
  $matriz_madre[nombre] = matriz
end

# Función para obtener una matriz almacenada por su nombre
def obtener_matriz(nombre)
  $matriz_madre[nombre]
end

# Función para borrar la entrada
def borrar_entrada(entrada)
  entrada.value = ""
end

# Crear los botones
botones = [
  ['[', ']', ',', ';'],
  ['+', '-', '*', '/'],
  ['Evaluar', 'Borrar', 'Almacenar', 'Recuperar', 'Salir']
]

# Crear un marco para los botones
boton_marco = TkFrame.new(root).pack

# Crear y colocar los botones en el marco
botones.each do |fila|
  boton_fila = TkFrame.new(boton_marco).pack(side: 'top', fill: 'x')
  fila.each do |btn_text|
    TkButton.new(boton_fila) do
      text btn_text
      font 'arial 10'
      pack(side: 'left', fill: 'both', expand: true)

      command do
        case btn_text
        when 'Evaluar'
          evaluar_entrada(entrada)
        when 'Borrar'
          borrar_entrada(entrada)
        when 'Almacenar'
          almacenar_matriz('MiMatriz', Matrix[[1, 2], [3, 4]])  # Ejemplo de almacenamiento de matriz con etiqueta 'MiMatriz'
        when 'Recuperar'
          matriz_recuperada = obtener_matriz('MiMatriz')  # Recuperar la matriz almacenada con etiqueta 'MiMatriz'
          entrada.value = matriz_recuperada.to_s if matriz_recuperada
        when 'Salir'
          exit
        else
          actualizar_entrada(entrada, btn_text)
        end
      end
    end
  end
end

# Iniciar la interfaz gráfica
Tk.mainloop
