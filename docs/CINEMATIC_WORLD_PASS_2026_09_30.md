# Cinematic world pass — 2026-09-30

This pass replaces the scattered prototype composition with an authored two-village layout while preserving symmetric combat travel distances.

## Implemented

- 20 planned buildings per faction, including castle, town center, guild hall, inn, barracks, blacksmith, warehouse, windmill, market and residential groups.
- Roads and door approaches are generated from the shared village plan. Cosmetic offsets on the red side do not change the combat route or terrain height.
- Craft, market and residential props are grouped by function instead of randomly scattered.
- A distant cinematic valley matte is used only beyond the playable 3D terrain. The villages, bridge, river, units and collision remain 3D.
- Camera orbit is limited to the authored vista. Manual input immediately exits the cinematic follow mode.
- The “Savaşı izle” camera follows the center of active combat and adds restrained drift.
- Hit feedback combines the installed Binbun effects, brighter impact light, target compression/recoil, spatial audio and distance-scaled camera impulse.
- Water has directional current lines, obstacle/shore foam, angle tint and moving sun glints.
- Village paving is darker, dirtier and includes broken grime and wheel-wear variation.

## Generated background asset

- Mode: built-in ImageGen, image-to-image mood reference.
- Project asset: `res://assets/environment/backdrops/valley_horizon_v1.png`
- Role: distant atmospheric background only.
- Prompt:

> Use case: stylized-concept. Asset type: distant panoramic background matte for a fully 3D isometric medieval fantasy strategy game. Create a wide layered fantasy valley horizon with distant blue mountains, pine forest silhouettes, soft clouds, atmospheric mist and a bright open sky. This will sit behind a fully 3D foreground containing two rival villages and a central bridge, so keep the backdrop distant and visually quiet. Use the input image only for its cinematic depth, visual hierarchy, mist layering, and polished game-environment atmosphere. Do not reproduce its cathedral or exact layout. Style: polished cohesive stylized 3D game environment, premium colorful medieval high fantasy, painterly low-poly forms, believable scale, no photorealism. Composition: 16:9 panoramic, low-detail distant shapes, clear central valley opening, layered mountain silhouettes, tree-covered ridges toward the sides, no close structures, no bridge, no characters. Lighting: warm late-afternoon golden light with cool blue-green atmospheric depth, soft volumetric sun rays, restrained saturation. Constraints: seamless-feeling side edges, no text, no logo, no watermark, no UI, no foreground terrain, no foreground buildings.

## Validation

- `validate_planned_village.gd`: both objectives, symmetric terrain, 40-unit deployment, combat contact, doors/roads and turret sockets pass.
- `validate_combat_feedback.gd`: one-time reward, concurrent VFX material isolation and cleanup pass.
- `validate_redesign.gd`: mouse card flow, battle camera, two-file formation and narrow bridge pass.
- `validate_cinematic_pass.gd`: 20 districts per side, landmark hierarchy, backdrop role and camera feedback connection pass.

The next visual pass should focus on per-building facade variation, close-camera character animation polish and authored ambient NPC schedules. These require direct play review at close zoom rather than more random prop density.

## Hybrid village plate revision

The authored 3D village is retained as a fallback and as the gameplay layout source, but the default presentation now uses a full ImageGen environment plate:

- `res://assets/environment/plates/fetih_valley_cinematic_v1.png`
- Both villages, river, bridge, farms, markets, fortifications and distant scenery share one rendered visual language.
- Units, projectiles, damage feedback, health UI and combat effects remain live 3D.
- The plate follows camera zoom and pan while staying locked to the world-space bridge center.
- Far depth of field is disabled in this mode because the generated plate already contains authored atmospheric depth.
- Close battle watch uses a 20-unit camera zoom to avoid magnifying the plate beyond useful resolution.
- Press `V` to compare the hybrid presentation with the original full-3D environment.

ImageGen mode: built-in image-to-image generation using the target atmosphere reference and the previous playable map capture. The prompt requested a complete 16:9 two-village battlefield, centered vertical river, long narrow horizontal bridge, mirrored strategic distances, functional village districts, unobstructed combat route, golden-hour lighting, volumetric depth, and no characters or UI.
