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
De forma que nuestra intención inicial como atacantes va a ser concseguir la ejecución de esta



