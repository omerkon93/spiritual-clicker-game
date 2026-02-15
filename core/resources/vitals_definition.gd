extends Resource
class_name VitalDefinition

enum VitalType {
	NONE = 100,
	ENERGY,
	FULLNESS,
	FOCUS,
	SANITY
}

@export var type: VitalType = VitalType.NONE
@export var display_name: String
@export var icon: Texture2D
@export var display_color: Color = Color.WHITE

# Stats specific to Vitals
@export var default_max_value: float = 100.0
@export var gradient: Gradient
