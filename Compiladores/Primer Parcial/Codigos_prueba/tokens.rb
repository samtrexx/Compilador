# Método para obtener el número de expresiones desde un archivo
def obtener_numero_expresiones(filename)
  File.read(filename).to_i
end

# Método para leer expresiones regulares desde archivos
def leer_expresiones_regulares(num_expresiones)
  expresiones_regulares = []

  num_expresiones.times do |i|
    file = "expression_#{i + 1}.txt"
    expresion = File.read(file).strip
    expresiones_regulares << expresion
  end

  expresiones_regulares
end

# Método para generar tokens por cada caracter de una ER
def generar_tokens(er)
  tokens = {}
  token_value = 10 # Valor inicial del token

  er.each_char do |char|
    tokens[char] ||= token_value
    token_value += 10
  end

  tokens
end

# Método para obtener tokens de múltiples ER
def obtener_tokens(ers)
  tokens_totales = {}

  ers.each_with_index do |er, index|
    tokens_er = generar_tokens(er)
    tokens_er.each do |char, token|
      tokens_totales[char] ||= token
    end

    tokens_totales["ER_#{index + 1}"] = 1000 + index # Token para identificar la ER
  end

  tokens_totales
end

# Método para guardar los tokens en un archivo de texto
def guardar_tokens(tokens, filename)
  File.open(filename, "w") do |file|
    tokens.each { |char, token| file.puts "#{char}: #{token}" }
  end
end

# Obtener el número de expresiones desde el archivo
num_expresiones = obtener_numero_expresiones("num_expressions.txt")

# Leer expresiones regulares desde archivos
expresiones_regulares = leer_expresiones_regulares(num_expresiones)

# Generar tokens
tokens = obtener_tokens(expresiones_regulares)
guardar_tokens(tokens, "tokens.txt")

# Guardar tokens en un archivo de texto
# Mostrar tokens resultantes en la terminal con el formato "Simbolo | Numero"
=begin
puts "Tokens generados:"
puts "Simbolo | Numero"
tokens.sort_by { |char, token| token }.reverse_each do |char, token|
  puts "#{char} | #{token}"
end
=end
