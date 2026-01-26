extends Resource
class_name VitalDefinition

@export var type: GameEnums.VitalType = GameEnums.VitalType.NONE
@export var display_name: String
@export var icon: Texture2D

# Link to the Enum so code knows what logic to run

# Stats specific to Vitals
@export var default_max_value: float = 100.0
@export var gradient: GradientTexture1D # Cool feature: Color changes from Empty -> Full
