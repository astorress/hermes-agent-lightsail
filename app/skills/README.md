# Skills del agente

Cada carpeta de aquí es una skill de Hermes y se despliega con cada release
(`npm run deploy-app:dev`): `docker-compose.yml` monta esta carpeta en `/opt/skills` (solo
lectura); `deploy` agrega esa ruta a `skills.external_dirs` en `config.yaml`, que es como Hermes
encuentra carpetas extra de skills. Como es de solo lectura, el agente no las edita: git es la
fuente de verdad.

```text
skills/
└── <nombre-de-la-skill>/        # el nombre de la carpeta = `name` del frontmatter
    ├── SKILL.md                 # obligatorio: frontmatter + instrucciones
    ├── references/              # opcional: documentos que la skill lee cuando los necesita
    ├── templates/               # opcional
    ├── scripts/                 # opcional: scripts que el agente puede ejecutar
    └── assets/                  # opcional
```

Para crear una: crea `skills/<nombre>/SKILL.md` con la plantilla de abajo, o usa la skill de
Claude `add-hermes-skill`. Dónde va cada cambio: `.claude/rules/objective.md`.

## Plantilla de `SKILL.md`

La plantilla vive aquí, dentro del README, y no como archivo, para que Hermes no la cargue como
una skill más.

````markdown
---
name: nombre-de-la-skill
description: Una frase que diga qué hace la skill y cuándo usarla. Es lo único que el agente lee antes de decidir si la carga, así que incluye las palabras con las que el usuario pediría la tarea.
---

# Título de la skill

## Cuándo usarla

- Situación 1 en la que el agente debe cargar esta skill.
- Situación 2.

## Pasos

1. Primer paso, concreto y verificable.
2. Segundo paso. Si hay un script: `scripts/nombre.sh <argumentos>`.
3. Cómo comprobar que quedó bien.

## Notas

- Límites, errores conocidos, cosas que nunca debe hacer.

## Referencias

- `references/detalle.md`: material largo que solo se lee si hace falta.
````

- Esta carpeta es la fuente de verdad **de lo que tú versionas**. Las skills que el agente
  escribe solo o instala desde el hub viven en `/opt/hermes/data/skills` (el volumen del
  servidor) y no pasan por git.
- No metas secretos aquí: viajan en el release y quedan en el servidor.
- Un cambio en una skill se publica con `npm run deploy-app:dev`; la conversación en curso puede
  necesitar `/reset` para verla.
