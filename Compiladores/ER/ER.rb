class GrammarRule
  attr_accessor :non_terminal, :productions

  def initialize(non_terminal, *productions)
    @non_terminal = non_terminal
    @productions = productions.flatten
  end

  def to_s
    "#{non_terminal} -> #{productions.join(' ')}"
  end
end

class ERtoGrammarConverter
  def initialize(expression)
    @expression = expression
    @current_non_terminal = 'E'
    @rules = []
    @valid = true  # Variable para indicar si la expresión es válida o no
  end

  def convert
    process_expression(@expression)
    @rules
  end

  private

  def process_expression(expression)
    case expression.length
    when 1
      new_non_terminal = next_non_terminal
      @rules << GrammarRule.new(@current_non_terminal, [expression])
    when 3
      case expression[1]
      when '|'
        left_expr = expression[0]
        right_expr = expression[2]
        new_non_terminal_left = next_non_terminal
        new_non_terminal_right = next_non_terminal
        process_expression(left_expr)
        process_expression(right_expr)
        @rules << GrammarRule.new(@current_non_terminal, [new_non_terminal_left])
        @rules << GrammarRule.new(@current_non_terminal, [new_non_terminal_right])
      when '.'
        left_expr = expression[0]
        right_expr = expression[2]
        process_expression(left_expr)
        process_expression(right_expr)
        new_non_terminal = next_non_terminal
        @rules << GrammarRule.new(@current_non_terminal, [left_expr, right_expr])
        @current_non_terminal = new_non_terminal
      else
        @valid = false  # Marcar la expresión como no válida
      end
    else
      @valid = false  # Marcar la expresión como no válida
    end
  end

  def next_non_terminal
    @current_non_terminal = @current_non_terminal.succ
    @current_non_terminal
  end
end

# Ejemplo de uso:
er = "a|b.c"
converter = ERtoGrammarConverter.new(er)
rules = converter.convert

if converter.instance_variable_get(:@valid)
  puts "Gramática resultante:"
  rules.each do |rule|
    puts rule
  end
else
  puts "La expresión regular no tiene un formato válido."
end
