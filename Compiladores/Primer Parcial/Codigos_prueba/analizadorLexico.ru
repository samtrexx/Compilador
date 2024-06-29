ER = []  # Declarar la variable ER global como un array para almacenar varias ER

print "How many regular expressions do you want to enter? "
num_expressions = gets.chomp.to_i  # Obtener el número de ER que el usuario desea ingresar
File.write('num_expressions.txt', num_expressions.to_s)
num_expressions.times do |i|
  print "Enter regular expression #{i + 1}: "
  er_input = gets.chomp  # Obtener la ER del usuario
  ER << er_input  # Agregar la ER al array ER
  # Guardar la expresión regular en un archivo separado
  File.write("expression_#{i + 1}.txt", er_input)
end

system("ruby tokens.rb")

def display_menu
  puts "Welcome to the Interactive Menu"
  puts "1. Generar un AFN de una ER"
  puts "2. Union de AFN"
  puts "3. Concatenacion de AFN"
  puts "4. Cerradura de Kleene (+)"
  puts "5. Cerradura de Kleene (*)"
  puts "6. Union del analizador lexico"
  puts "7. Convertir AFD y guardar "
  puts "8. Test analizador lexico "
  puts "9. Exit"
end

def opciones_kleen
  puts "1. AFN_#"
  puts "2. Union de los AFN"
  puts "3. Concatenacion de AFN"
end

loop do
  display_menu
  print "Coloca tu opcion : "
  choice = gets.chomp.to_i

  case choice
#AFN
  when 1
    # Ejecutar afn.ru
    #system('ruby afn.ru')
    puts "Eligio AFN"

    num_expressions.times do |i|
      # ejecuta  afn.ru por archivo
      system("ruby afn.ru expression_#{i + 1}.txt")
    end
#unir afn
  when 2
    puts "Unir AFN"
    system("ruby UAFN.ru") #codigo de unir
#concatenar afn
  when 3
    puts "Concatenar AFN S"
    system("ruby CAFN.ru") #codigo de concatenar
#cerradura (+)
  when 4
    puts "Cerradura de Kleene (+)"
    opciones_kleen
    afn_choice = gets.chomp.to_i

    case afn_choice
    when 1
      puts "Aplicar cerradura Kleene (+) a  AFN_#"
     #system("ruby KMASAFN.ru AFN_#.txt")
      num_expressions.times do |i|
        system("ruby KMASAFN.ru AFN_#{i + 1}.txt")
      end
    when 2
      puts "Aplicar cerradura Kleene (+) a union de  AFN"
      system("ruby KMASAFN.ru AFN_union.txt")
    when 3
      puts "Aplicar cerradura Kleene (+) a concatenacion de  AFN"
      system("ruby KMASAFN.ru AFN_concatenado.txt")
    else
      puts "Invalido :c ."
    end

#cerradura (*)
  when 5
    puts "Cerradura de Kleene (*)"
    opciones_kleen
    cerradura_choice = gets.chomp.to_i

    case cerradura_choice
    when 1
      puts "Aplicar cerradura kleene (*) a  AFN_#"
     #system("ruby KMASAFN.ru AFN_#.txt")
      num_expressions.times do |i|
        system("ruby KPORAFN.ru AFN_#{i + 1}.txt")
      end
    when 2
      puts "Aplicar cerradura kleene (*) a union de  AFN"
      system("ruby KPORAFN.ru AFN_union.txt")
    when 3
      puts "Aplicar cerradura kleene (*) a concatenacion de AFN"
      system("ruby KPORAFN.ru AFN_concatenado.txt")
    else
      puts "Invalido :C"
    end

#yylex()
  when 6
    puts "Unión para analizador léxico"
puts "1. Aplicar yylex() a AFN_#"
puts "2. Aplicar yylex() a Unión de AFN"
puts "3. Aplicar yylex() a Concatenación de AFN"
puts "Ingrese su elección:"
yylex_choice = gets.chomp.to_i

case yylex_choice
when 1
  puts "Aplicar yylex() a AFN_#"
  num_expressions.times do |i|
    print "Ingrese la cadena a probar para AFN_#{i + 1}: "
    input_string = gets.chomp
    system("ruby lexer.ru AFN_#{i + 1}.txt \"#{input_string}\"")
  end
when 2
  puts "Aplicar yylex() a Unión de AFN"
  print "Ingrese la cadena a probar para la Unión de AFN: "
  input_string = gets.chomp
  system("ruby lexer.ru AFN_union.txt \"#{input_string}\"")
when 3
  puts "Aplicar yylex() a Concatenación de AFN"
  print "Ingrese la cadena a probar para la Concatenación de AFN: "
  input_string = gets.chomp
  system("ruby lexer.ru AFN_concatenado.txt \"#{input_string}\"")
else
  puts "Selección inválida."
end


#AFD
  when 7
    puts "Convertir AFD y guarda "
    opciones_kleen
    afd_choice = gets.chomp.to_i

    case afd_choice
    when 1
      puts "Hacer AFD a  AFN_#"
     #system("ruby KMASAFN.ru AFN_#.txt")
      num_expressions.times do |i|
        system("ruby AFD.ru AFN_#{i + 1}.txt")
      end
    when 2
      puts "Hacer AFD a union de AFN"
      system("ruby AFD.ru AFN_union.txt")
    when 3
      puts "Hacer AfD a concatenacion de AFN"
      system("ruby AFD.ru AFN_concatenado.txt")
    else
      puts "Invalid"
    end



    # Perform action for Option 7
  when 8
    puts "Probar analizador" #utilizar yylex()
    system("ruby probar.ru")


  when 9
    puts "Hasta la proxima jsjsjsjsj!"
    # Eliminar todos los archivos .txt en la carpeta actual
    Dir.glob("*.txt").each { |file| File.delete(file) }
    break
  else
    puts "Invalid choice. Please choose a valid option."
  end

  puts "Press Enter to continue..."
  gets.chomp
end
