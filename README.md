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






