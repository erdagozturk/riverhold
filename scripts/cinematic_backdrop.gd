extends Node3D
## A quiet distant matte. Gameplay, collision and village silhouettes stay fully 3D.

func setup() -> void:
	name = "CinematicHorizon"
	var panel := MeshInstance3D.new()
	panel.name = "LayeredValleyMatte"
	var quad := QuadMesh.new()
	quad.size = Vector2(176.0, 99.0)
	panel.mesh = quad
	panel.position = Vector3(0.0, 28.0, -112.0)
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	var texture: Texture2D=load("res://assets/environment/backdrops/valley_horizon_v1.png")
	material.albedo_texture=texture
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = -10
	panel.material_override = material
	add_child(panel)
	set_meta("role", "distant_atmosphere_only")
	set_meta("gameplay_geometry", false)
