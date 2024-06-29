require 'tk'

# Definimos la clase Tokenizer
class Tokenizer
  TOKENS = {
    '+' => 30,
    '-' => 40,
    '*' => 50,
    '/' => 60,
    '(' => 70,
    ')' => 80,
    '^' => 90,
    'sin' => 100,
    'cos' => 110,
    'tan' => 120,
    'ln' => 130,
    'sqrt' => 140,
    'root' => 150
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

    if @current_char =~ /[a-zA-Z]/
      identifier = @current_char
      while peek_next_char =~ /[a-zA-Z0-9]/
        @current_char = next_char
        identifier += @current_char
      end
      if TOKENS.include?(identifier)
        token = TOKENS[identifier]
        @current_char = next_char
      else
        token = 10 # Identificador genérico (por ejemplo, nombre de variable o función)
      end
    elsif @current_char =~ /\d/
      token = 20
      identifier = @current_char
      while peek_next_char =~ /\d/ || (peek_next_char == '.' && !identifier.include?('.'))
        @current_char = next_char
        identifier += @current_char
      end
      @current_char = next_char
    elsif TOKENS.include?(@current_char)
      token = TOKENS[@current_char]
      @current_char = next_char
    else
      raise "Error: Token inesperado '#{@current_char}' en la posición #{@position}"
    end

    token
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

# Definimos la clase RecursiveDescentParser
class RecursiveDescentParser
  def initialize(input)
    @input = input
    @tokenizer = Tokenizer.new(input)
    @current_token = @tokenizer.next_token
    @variables = {} # Diccionario para almacenar variables
  end

  def parse
    begin
      result = expression
      if @current_token.nil?
        return result
      else
        error_message("Token inesperado '#{@current_token}' al final de la expresión.")
      end
    rescue => e
      return e.message
    end
  end

  private

  def next_token
    @current_token = @tokenizer.next_token
  end

  def error_message(message)
    position = @tokenizer.current_position
    indicator = " " * (position - 1) + "^"
    raise "#{message}\n#{@input}\n#{indicator}"
  end

  def expression
    result = term
    while @current_token == 30 || @current_token == 40 # + or -
      operador = @current_token
      next_token
      term_result = term
      if operador == 30
        result += term_result
      elsif operador == 40
        result -= term_result
      end
    end
    result
  end

  def term
    result = factor
    while @current_token == 50 || @current_token == 60 # * or /
      operador = @current_token
      next_token
      factor_result = factor
      if operador == 50
        result *= factor_result
      elsif operador == 60
        result /= factor_result
      end
    end
    result
  end

  def factor
    result = potencia
    result
  end

  def potencia
    result = primario
    while @current_token == 90 # ^
      operador = '^'
      next_token
      result **= primario
    end
    result
  end

  def primario
    result = nil
    if @current_token == 20 # NUM
      start_position = @tokenizer.current_position - 1
      number_str = ''
      while @current_token == 20
        number_str += @input[start_position]
        start_position += 1
        next_token
      end
      result = number_str.to_f
    elsif @current_token == 10 # IDENT or function
      identifier = @input[@tokenizer.current_position - 1]
      next_token
      if @current_token == 70 # '(' para funciones
        next_token
        result = expression
        if @current_token == 80 # ')'
          next_token
        else
          error_message("Se esperaba ')' después de la función.")
        end
      else
        error_message("Token inesperado '#{@current_token}' en primario.")
      end
    elsif @current_token == 70 # '('
      next_token
      result = expression
      if @current_token == 80 # ')'
        next_token
      else
        error_message("Se esperaba ')'.")
      end
    elsif [100, 110, 120, 130, 140, 150].include?(@current_token) # sin, cos, tan, ln, sqrt, root
      case @current_token
      when 100
        next_token
        if @current_token == 70 # '('
          next_token
          result = Math.sin(expression)
          if @current_token == 80 # ')'
            next_token
          else
            error_message("Se esperaba ')' después de la función 'sin'.")
          end
        else
          error_message("Se esperaba '(' después de 'sin'.")
        end
      when 110
        next_token
        if @current_token == 70 # '('
          next_token
          result = Math.cos(expression)
          if @current_token == 80 # ')'
            next_token
          else
            error_message("Se esperaba ')' después de la función 'cos'.")
          end
        else
          error_message("Se esperaba '(' después de 'cos'.")
        end
      when 120
        next_token
        if @current_token == 70 # '('
          next_token
          result = Math.tan(expression)
          if @current_token == 80 # ')'
            next_token
          else
            error_message("Se esperaba ')' después de la función 'tan'.")
          end
        else
          error_message("Se esperaba '(' después de 'tan'.")
        end
      when 130
        next_token
        if @current_token == 70 # '('
          next_token
          result = Math.log(expression)
          if @current_token == 80 # ')'
            next_token
          else
            error_message("Se esperaba ')' después de la función 'ln'.")
          end
        else
          error_message("Se esperaba '(' después de 'ln'.")
        end
      when 140
        next_token
        if @current_token == 70 # '('
          next_token
          result = Math.sqrt(expression)
          if @current_token == 80 # ')'
            next_token
          else
            error_message("Se esperaba ')' después de la función 'sqrt'.")
          end
        else
          error_message("Se esperaba '(' después de 'sqrt'.")
        end
      when 150
        next_token
        if @current_token == 70 # '('
          next_token
          result = Math.cbrt(expression) # Usamos cbrt para root (raíz cúbica)
          if @current_token == 80 # ')'
            next_token
          else
            error_message("Se esperaba ')' después de la función 'root'.")
          end
        else
          error_message("Se esperaba '(' después de 'root'.")
        end
      end
    else
      error_message("Token inesperado '#{@current_token}' en primario.")
    end
    result
  end
end

# Crear la ventana principal
root = TkRoot.new { title "Calculadora Científica" }
root.geometry("400x600")

# Variable para mostrar la entrada y el resultado
entrada = TkVariable.new

# Crear el cuadro de entrada
TkEntry.new(root, textvariable: entrada, font: 'arial 24 bold', justify: 'right').pack(pady: 10, padx: 10, fill: 'x')

# Función para actualizar la entrada
def actualizar_entrada(entrada, valor)
  entrada.value += valor
end

# Función para evaluar la expresión
def evaluar_entrada(entrada)
  parser = RecursiveDescentParser.new(entrada.value)
  resultado = parser.parse
  if resultado.is_a?(Numeric) || resultado.is_a?(Float)
    #entrada.value = "Operación válida"
    expr = entrada.value
    expr.gsub!('sin', 'Math.sin')
    expr.gsub!('cos', 'Math.cos')
    expr.gsub!('tan', 'Math.tan')
    expr.gsub!('sqrt', 'Math.sqrt')
    expr.gsub!('ln', 'Math.log')
    expr.gsub!('^', '**')
    resultado = eval(expr)
    entrada.value = resultado
  else
    #entrada.value = "Error"
    entrada.value = resultado
  end
end


# Función para borrar la entrada
def borrar_entrada(entrada)
  entrada.value = ""
end

# Crear los botones
botones = [
  ['7', '8', '9', '/'],
  ['4', '5', '6', '*'],
  ['1', '2', '3', '-'],
  ['0', '.', '=', '+'],
  ['sin', 'cos', 'tan', 'sqrt'],
  ['^', 'ln', '(', ')'],
  ['C', 'Salir']
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
        if btn_text == '='
          evaluar_entrada(entrada)
        elsif btn_text == 'C'
          borrar_entrada(entrada)
        elsif btn_text == 'Salir'
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
