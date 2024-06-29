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
      while peek_next_char =~ /\d/ || (peek_next_char == '.' && !@current_char.include?('.'))
        @current_char = next_char
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

class RecursiveDescentParser
  def initialize(input)
    @input = input
    @tokenizer = Tokenizer.new(input)
    @current_token = @tokenizer.next_token
  end

  def parse
    begin
      expression
      if @current_token.nil?
        puts "La expresión está bien escrita."
      else
        error_message("Token inesperado '#{@current_token}' al final de la expresión.")
      end
    rescue => e
      puts e.message
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
    term
    while @current_token == 30 || @current_token == 40 # + or -
      operador = @current_token
      next_token
      term
      puts "Procesado operador '#{operador.chr}' en expresión."
    end
  end

  def term
    factor
    while @current_token == 50 || @current_token == 60 # * or /
      operador = @current_token
      next_token
      factor
      puts "Procesado operador '#{operador.chr}' en término."
    end
  end

  def factor
    potencia
  end

  def potencia
    primario
    while [90, 130, 140, 150].include?(@current_token) # ^, ln, sqrt, root
      case @current_token
      when 90
        operador = '^'
        next_token
        primario
        puts "Procesado operador '#{operador}' en potencia."
      when 130
        operador = 'ln'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'ln'."
          else
            error_message("Se esperaba ')' después de la función 'ln'.")
          end
        else
          error_message("Se esperaba '(' después de 'ln'.")
        end
      when 140
        operador = 'sqrt'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'sqrt'."
          else
            error_message("Se esperaba ')' después de la función 'sqrt'.")
          end
        else
          error_message("Se esperaba '(' después de 'sqrt'.")
        end
      when 150
        operador = 'root'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'root'."
          else
            error_message("Se esperaba ')' después de la función 'root'.")
          end
        else
          error_message("Se esperaba '(' después de 'root'.")
        end
      end
    end
  end

  def primario
    if @current_token == 20 # NUM
      puts "Encontrado número."
      next_token
    elsif [100, 110, 120, 130, 140, 150].include?(@current_token) # sin, cos, tan, ln, sqrt, root
      case @current_token
      when 100
        operador = 'sin'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'sin'."
          else
            error_message("Se esperaba ')' después de la función 'sin'.")
          end
        else
          error_message("Se esperaba '(' después de 'sin'.")
        end
      when 110
        operador = 'cos'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'cos'."
          else
            error_message("Se esperaba ')' después de la función 'cos'.")
          end
        else
          error_message("Se esperaba '(' después de 'cos'.")
        end
      when 120
        operador = 'tan'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'tan'."
          else
            error_message("Se esperaba ')' después de la función 'tan'.")
          end
        else
          error_message("Se esperaba '(' después de 'tan'.")
        end
      when 130
        operador = 'ln'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'ln'."
          else
            error_message("Se esperaba ')' después de la función 'ln'.")
          end
        else
          error_message("Se esperaba '(' después de 'ln'.")
        end
      when 140
        operador = 'sqrt'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'sqrt'."
          else
            error_message("Se esperaba ')' después de la función 'sqrt'.")
          end
        else
          error_message("Se esperaba '(' después de 'sqrt'.")
        end
      when 150
        operador = 'root'
        next_token
        if @current_token == 70 # (
          next_token
          expression
          if @current_token == 80 # )
            next_token
            puts "Procesada función 'root'."
          else
            error_message("Se esperaba ')' después de la función 'root'.")
          end
        else
          error_message("Se esperaba '(' después de 'root'.")
        end
      end
    elsif @current_token == 10 # IDENT or function
      identificador = @current_token
      next_token
      if @current_token == 70 # (
        next_token
        expression
        if @current_token == 80 # )
          next_token
          puts "Procesada función '#{identificador.chr}'."
        else
          error_message("Se esperaba ')' después de la función.")
        end
      else
        puts "Encontrado identificador o variable."
      end
    elsif @current_token == 70 # (
      next_token
      expression
      if @current_token == 80 # )
        next_token
        puts "Procesado grupo de paréntesis."
      else
        error_message("Se esperaba ')'.")
      end
    else
      error_message("Token inesperado '#{@current_token}' en primario.")
    end
  end
end

# Ejemplo de uso:
input = "3 ^ (2.5 + 2) - cos(2) + sqrt(4) + ln(100) * ln(2) / root(16) + 6 * tan(8)"
parser = RecursiveDescentParser.new(input)
parser.parse
