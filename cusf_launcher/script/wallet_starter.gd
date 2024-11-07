extends Node

@onready var rpc_client = preload("res://script/rpc_client.gd").new()

var starters_dir

func _ready():
	# Set starters directory path next to downloads
	var downloads_dir = OS.get_user_data_dir().path_join("downloads")
	starters_dir = OS.get_user_data_dir().path_join("starters")
	print("Ensuring directory:", starters_dir)

	var dir = DirAccess.open(starters_dir)
	if not dir:
		dir = DirAccess.open(OS.get_user_data_dir())
		if dir and not dir.dir_exists("starters"):
			var result = dir.make_dir("starters")
			if result == OK:
				print("Directory 'starters' successfully created next to downloads at", starters_dir)
			else:
				print("Failed to create 'starters' directory. Error code:", result)
	else:
		print("'starters' directory already exists at", starters_dir)

	# Automatically create wallet on launch
	create_wallet()

func create_wallet():
	print("Starting wallet creation process...")

	# Call gRPC to generate master wallet and sidechain information
	var wallet_data = request_wallet_data()
	if wallet_data:
		print("Wallet data retrieved successfully.")
		
		# Write master wallet file
		if write_wallet_data(wallet_data["master_wallet"], "wallet_master_seed.txt"):
			print("Master wallet data saved.")
		
		# Write sidechain starters
		for sidechain_key in wallet_data["sidechains"].keys():
			var sidechain_data = wallet_data["sidechains"][sidechain_key]
			if write_wallet_data(sidechain_data, sidechain_key + "_starter.txt"):
				print("Sidechain data for ", sidechain_key, " saved.")
	else:
		print("Error: Wallet data retrieval failed.")

func request_wallet_data() -> Dictionary:
	# Mocked data for wallet and sidechain starters
	var wallet_data = {}
	
	# Example master wallet data
	wallet_data["master_wallet"] = {
		"mnemonic": "example twelve word mnemonic phrase for wallet",
		"seed_hex": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
		"bip39_bin": "binarystring",
		"bip39_csum": "csumstring",
		"bip39_csum_hex": "a1b2c3",
		"hd_key_data": "hdkeydataexample",
		"master_key": "masterkeyexample",
		"chain_code": "chaincodeexample"
	}
	
	# Example sidechain starters
	wallet_data["sidechains"] = {}
	var sidechain_slots = [0, 1, 2] # Adjust based on actual sidechains in your project
	for slot in sidechain_slots:
		wallet_data["sidechains"]["sidechain_" + str(slot)] = {
			"mnemonic": "sidechain mnemonic for slot " + str(slot),
			"seed_hex": "hexstringforsidechain" + str(slot),
			"seed_binary": "binarystringforsidechain" + str(slot),
			"derivation_path": "m/44'/0'/" + str(slot) + "'"
		}
	
	return wallet_data

func write_wallet_data(data: Dictionary, file_name: String) -> bool:
	var file_path = starters_dir.path_join(file_name)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
		return true
	print("Error: Unable to write to file:", file_name)
	return false
