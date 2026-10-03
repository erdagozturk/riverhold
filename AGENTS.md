# Fetih Game — Visual Implementation Rules

These project rules apply to every visual change, including work done with Astra.

## Target

The game uses a premium stylized cartoon fantasy city-builder look. Preserve readable chibi silhouettes, warm sunlight against cool sky fill, coherent village composition, material separation, atmospheric depth, and restrained high-value VFX. Do not solve visual quality by raising saturation or scattering unrelated lights and props.

## Renderer-aware environment

- Query `RenderingServer.get_current_rendering_method()` before enabling renderer-specific effects.
- Forward+ may use SSR, SSIL, SDFGI and volumetric fog.
- Compatibility may use SSAO, standard fog, tonemapping, glow, adjustments and fullscreen post-processing.
- Mobile must not enable unsupported Forward+ features. Use standard fog, sky ambient light, controlled directional shadows, reflection probes and lightweight shaders as fallbacks.
- Build the image through `WorldEnvironment`, sky ambient/reflected light, DirectionalLight3D, shadow quality, material roughness/specular balance, ambient occlusion where supported, tonemapping and atmospheric depth.
- Prefer AgX for this bright stylized palette. Keep color correction restrained.
- Bloom/glow is reserved for fire, lightning, magic and deliberately emissive accents.

## Materials

- Character and architecture `StandardMaterial3D` instances use Toon diffuse and Toon specular when compatible with the material.
- Keep metalness at zero for wood, plaster, vegetation, skin and ordinary stone.
- Preserve texture and normal detail, but reduce excessive normal strength and glossy highlights.
- Tune roughness by material family. Do not apply one shiny or one matte value to the entire scene.
- Sky contribution must be controlled because excessive ambient light flattens Toon light separation.

## Water

Never create the river as a flat blue `StandardMaterial3D`.

The water must be a depth-aware Godot 4 spatial shader with:

- shallow turquoise/green-blue and deeper darker saturated color;
- scene depth driven transition and proximity/contact treatment;
- two independently scrolling normal textures;
- Fresnel reflection response;
- mild screen-space refraction;
- broken shoreline foam at geometry intersections;
- restrained current streaks and wakes around obstacles;
- controlled roughness/specular highlights;
- subtle caustics restricted to visible shallow water.

The result is premium cartoon city-builder water, not a photoreal ocean and not an emissive blue floor.

## Lighting and shadows

- Use one coherent sun direction for the world. Avoid random fill lights.
- Use warm directional sunlight and cooler sky ambient light.
- Configure shadow splits and maximum distance for the gameplay camera. Blend splits only when the renderer and performance target allow it.
- Use soft shadows without erasing contact definition.
- Local lights belong to motivated sources such as torches, windows, magic and altar attacks.

## Composition and validation

- Every building, road, field, wall, market and military zone needs a functional reason and a connected route.
- Mirrored sides must remain competitively equivalent while small cosmetic variation avoids sterile duplication.
- Validate shader parsing, project parsing, renderer feature gating, bow/weapon orientation, material assignment and combat mechanics after changes.
- The user performs final play feel and visual judgment; provide a playable build rather than spending time recording a verification video.

## Primary references

- https://docs.godotengine.org/en/4.6/tutorials/3d/environment_and_post_processing.html
- https://docs.godotengine.org/en/4.6/tutorials/3d/standard_material_3d.html
- https://docs.godotengine.org/en/4.6/tutorials/rendering/renderers.html
- https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html
- https://github.com/godot-extended-libraries/godot-realistic-water/blob/4/realistic_water_shader/art/water/Water.gdshader
- https://godotshaders.com/shader/stylized-water-shader/
- https://github.com/jkulawik/godot-water-shader

