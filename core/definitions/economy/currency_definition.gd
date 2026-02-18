class_name CurrencyDefinition extends Resource

enum CurrencyType {
	NONE = 0,
	MONEY = 1,
	SPIRIT = 2
}

@export var type: CurrencyType = CurrencyType.NONE
@export var display_name: String = "Currency Name"
@export var icon: Texture2D
@export var display_color: Color = Color.WHITE
@export var initial_amount: float = 0.0
@export var max_amount: float = 999999.0
@export var prefix: String = ""
