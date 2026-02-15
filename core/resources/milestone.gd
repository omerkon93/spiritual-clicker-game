extends Resource
class_name Milestone

enum UnlockCondition {
	CURRENCY_THRESHOLD,
	VITAL_THRESHOLD,
	UPGRADE_LEVEL,
	TIME_PLAYED, # Future proofing
	TOTAL_CLICKS # Future proofing
}

@export_group("Reward")
@export var target_flag: StoryFlag # The flag to set to TRUE when unlocked
@export var notification_text: String = "Milestone Reached!"

@export_group("Condition")
@export var condition_type: UnlockCondition = UnlockCondition.CURRENCY_THRESHOLD
@export var is_less_than: bool = false

@export_group("Currency Checks")
# For Currency Checks
@export var target_currency: CurrencyDefinition.CurrencyType = CurrencyDefinition.CurrencyType.MONEY
@export var currency_amount: float = 0.0

@export_group("Vital Checks")
# For Currency Checks
@export var target_vital: VitalDefinition.VitalType = VitalDefinition.VitalType.NONE
@export var vital_amount: float = 0.0

@export_group("Upgrade Checks")
# For Upgrade Checks
@export var target_upgrade_id: String = ""
@export var upgrade_level: int = 0
