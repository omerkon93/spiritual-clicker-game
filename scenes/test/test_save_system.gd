extends Node

func _ready():
	print("\n========== STARTING SAVE/LOAD TEST ==========")
	
	# --- STEP 1: SETUP INITIAL STATE ---
	print("\n[Step 1] Setting up initial values...")
	
	# Reset for test
	CurrencyManager._currencies.clear()
	ItemManager.upgrade_levels.clear()
	
	# Add Test Values
	CurrencyManager.add_currency(GameEnums.CurrencyType.MONEY, 500.0)
	CurrencyManager.add_currency(GameEnums.CurrencyType.SPIRIT, 25.0)
	ItemManager.upgrade_levels["test_upgrade_1"] = 3
	GameStatsManager.set_flag("test_flag_visited_shop", true)
	
	print("   > Money Set To: ", CurrencyManager.get_currency_amount(GameEnums.CurrencyType.MONEY))
	print("   > Spirit Set To: ", CurrencyManager.get_currency_amount(GameEnums.CurrencyType.SPIRIT))
	print("   > Upgrade 'test_upgrade_1' Level: ", ItemManager.get_upgrade_level("test_upgrade_1"))
	print("   > Flag 'test_flag_visited_shop': ", GameStatsManager.has_flag("test_flag_visited_shop"))

	# --- STEP 2: SAVE THE GAME ---
	print("\n[Step 2] Saving Game...")
	SaveManager.save_game()
	
	# --- STEP 3: MODIFY (CORRUPT) STATE ---
	print("\n[Step 3] Modifying values (Simulating gameplay changes)...")
	
	CurrencyManager.add_currency(GameEnums.CurrencyType.MONEY, 99999.0) # Add a lot
	ItemManager.upgrade_levels["test_upgrade_1"] = 100
	GameStatsManager.set_flag("test_flag_visited_shop", false)
	
	print("   > Current Money (Modified): ", CurrencyManager.get_currency_amount(GameEnums.CurrencyType.MONEY))
	print("   > Current Upgrade Level (Modified): ", ItemManager.get_upgrade_level("test_upgrade_1"))
	print("   > Current Flag (Modified): ", GameStatsManager.has_flag("test_flag_visited_shop"))
	
	# --- STEP 4: LOAD THE GAME ---
	print("\n[Step 4] Loading Game...")
	SaveManager.load_game()
	
	# --- STEP 5: VERIFY RESULTS ---
	print("\n[Step 5] Verifying Restored Values...")
	
	var loaded_money = CurrencyManager.get_currency_amount(GameEnums.CurrencyType.MONEY)
	var loaded_spirit = CurrencyManager.get_currency_amount(GameEnums.CurrencyType.SPIRIT)
	var loaded_upgrade = ItemManager.get_upgrade_level("test_upgrade_1")
	var loaded_flag = GameStatsManager.has_flag("test_flag_visited_shop")
	
	var all_passed = true
	
	if loaded_money == 500.0:
		print("   [PASS] Money restored correctly (500).")
	else:
		printerr("   [FAIL] Money is ", loaded_money, " (Expected 500)")
		all_passed = false

	if loaded_spirit == 25.0:
		print("   [PASS] Spirit restored correctly (25).")
	else:
		printerr("   [FAIL] Spirit is ", loaded_spirit, " (Expected 25)")
		all_passed = false
		
	if loaded_upgrade == 3:
		print("   [PASS] Upgrade level restored correctly (3).")
	else:
		printerr("   [FAIL] Upgrade level is ", loaded_upgrade, " (Expected 3)")
		all_passed = false
		
	if loaded_flag == true:
		print("   [PASS] Story flag restored correctly (true).")
	else:
		printerr("   [FAIL] Story flag is ", loaded_flag, " (Expected true)")
		all_passed = false

	print("---------------------------------------------")
	if all_passed:
		print("TEST RESULT: SUCCESS! The Save System works.")
	else:
		printerr("TEST RESULT: FAILURE! Check errors above.")
	print("=============================================\n")
