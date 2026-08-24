# Despliegue de este fork de drawDB

Este documento cubre cómo se despliega esta instancia y, sobre todo, **dónde quedan guardados
los modelos**. Lo segundo importa más que lo primero.

## Cómo se guardan los diagramas hoy

No hay servidor de datos. Cada diagrama vive en el **IndexedDB del navegador** de quien lo
edita (base `drawDB`, tabla `diagrams`, ver [src/data/db.js](src/data/db.js)). El despliegue
sirve archivos estáticos y nada más.

Consecuencia directa: **nadie ve el trabajo del otro y no hay respaldo automático.** Toda la
integridad de los modelos depende de la disciplina de exportación descrita más abajo.

---

## Desplegar en Vercel

El repo ya viene preparado: [vercel.json](vercel.json) trae el rewrite de SPA que evita el 404
al recargar en rutas como `/editor/diagrams/:id`.

1. Conectar el repositorio en Vercel (privado sirve). Detecta Vite solo: build `npm run build`,
   salida `dist`.
2. Sin repositorio, desde el portátil: `npx vercel deploy --prod`.
3. Configurar el dominio **antes** de que alguien guarde el primer modelo (ver la advertencia
   siguiente).

La compilación corre en los builders de Vercel, así que no aplica el límite de memoria del
Dockerfile.

Dos límites del plan gratuito (Hobby):

- **Hobby es para uso no comercial** según los términos de Vercel. Un tablero interno de
  empresa es uso comercial; lo correcto sería el plan Pro. Es una restricción contractual, no
  técnica.
- **No hay protección con contraseña**: la URL de producción es pública. Como no hay datos en
  el servidor, lo que queda expuesto es el uso de la instancia, no los modelos.

## Desplegar en máquina propia (alternativa)

```bash
docker build -t drawdb .          # ← en tu portátil o en CI, NO en el servidor
docker run -d -p 80:80 --restart unless-stopped --name drawdb drawdb
```

[Dockerfile:7](Dockerfile#L7) fija `NODE_OPTIONS=--max-old-space-size=4096`: un servidor de
1 GB se queda sin memoria compilando. Construir fuera y hacer `docker pull` en el servidor
([.github/workflows/docker.yml](.github/workflows/docker.yml) ya publica a `ghcr.io` al
etiquetar).

Fuera de Vercel, quitar `@vercel/analytics` de [src/main.jsx](src/main.jsx), que hoy está
montado siempre y envía telemetría.

---

## ⚠️ La URL define dónde quedan los diagramas

El almacenamiento del navegador es **por origen**. Estos son tres almacenes distintos y
completamente aislados:

- `https://cashview-drawdb.vercel.app`
- `https://drawdb.tudominio.co`
- `http://192.168.1.50`

Si el equipo trabaja semanas contra el subdominio de Vercel y después se pone dominio propio,
**ningún diagrama viaja**: hay que exportar e importar uno por uno.

Lo mismo aplica a los *preview deployments*: cada rama genera una URL nueva, o sea un almacén
nuevo y vacío. **El equipo debe trabajar siempre contra la URL de producción.**

---

## Reglas para el equipo

Sin servidor, esto es lo que separa "tenemos los modelos" de "los perdimos":

1. **Exportar cada semana** y al cerrar cualquier trabajo importante: menú →
   *Export saved data*. Baja un `.zip` con todos tus diagramas y plantillas en JSON. Ese ZIP va
   a la carpeta compartida del equipo. Sin eso no existe respaldo de nada.
2. **Nunca en ventana de incógnito.** Al cerrarla se borra todo.
3. **No limpiar "datos del sitio"** del navegador. Es la forma número uno de perder trabajo.
4. **Un modelo, un dueño.** Para que otro lo revise: *File → Export as → JSON* y él lo importa.
   Desde ese momento son copias independientes: no existe forma de fusionar dos JSON que
   divergieron.
5. **Un navegador, una máquina.** Los diagramas no siguen a la persona entre equipos; para
   moverse, exportar e importar.
6. Los ajustes del editor, los tipos personalizados y el tema son locales del navegador
   (`localStorage`) y **no** viajan en el ZIP.

### Riesgos que se están aceptando conscientemente

- Limpiar caché, cambiar de navegador o de máquina ⇒ trabajo perdido, sin recuperación.
- El único respaldo es el ZIP que cada quien recuerde bajar.
- Dos personas sobre copias del mismo modelo ⇒ divergencia permanente.

### Cuándo dejar de aguantar esto

Migrar a guardado en servidor (fase 2) cuando aparezca cualquiera de estas señales: alguien
perdió trabajo; circulan dos copias del mismo modelo y nadie sabe cuál manda; se pregunta
seguido "¿dónde está la última versión?"; o entra la cuarta o quinta persona al equipo.

El diseño completo de esa fase está en el plan de trabajo: backend Node + SQLite conectado al
gancho de extensiones que el editor **ya trae y nadie tiene conectado**
([src/context/ExtensionsContext.jsx](src/context/ExtensionsContext.jsx)). Medio día a un día de
trabajo.

---

## Licencia

drawDB es **GNU AGPL v3** ([LICENSE](LICENSE)) y esta es una versión modificada. La sección 13
del AGPL pide que a quienes usan el programa por red se les ofrezca el código fuente
correspondiente, y aplica también en despliegues internos.

Cumplirlo es barato: mantener este fork en un repositorio al que el equipo tenga acceso y dejar
el enlace visible. Si el despliegue llegara a ser un producto para clientes, conviene revisarlo
con asesoría legal.

## Cambios de este fork sobre drawDB original

- Ancho ajustable por tabla (arrastrar el borde derecho, doble clic para ajustar al contenido).
- Relaciones con ruta editable: waypoints arrastrables y forma ortogonal / recta / curva.
- Etiqueta de categoría por tabla (core, stg, ref, erp, view…) con el color de la tabla.
