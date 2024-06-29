require 'tk'

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
  begin
    expr = entrada.value #guarda la expresiond e entrada en expr
    # Reemplazar las funciones por las funciones de Math y ^ por **
    expr.gsub!('sin', 'Math.sin')
    expr.gsub!('cos', 'Math.cos')
    expr.gsub!('tan', 'Math.tan')
    expr.gsub!('sqrt', 'Math.sqrt')
    expr.gsub!('ln', 'Math.log')
    expr.gsub!('^', '**')
    resultado = eval(expr)
    entrada.value = resultado
  rescue Exception => e
    entrada.value = "Error"
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
