class_name StatModifier extends Resource

@export var target_stat: StatDefinition
@export_group("Modification")
@export var add_value: float = 0.0      # Flat +5
@export var multiplier: float = 0.0     # +0.1 is +10%
