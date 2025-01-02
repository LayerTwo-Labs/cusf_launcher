extends Control

@onready var seed_input = $Panel/VBoxContainer/SeedInput
@onready var passphrase_input = $Panel/VBoxContainer/PassphraseContainer/PassphraseInput
@onready var passphrase_container = $Panel/VBoxContainer/PassphraseContainer
@onready var generate_random = $Panel/VBoxContainer/HBoxContainer/GenerateRandom
@onready var create_wallet = $Panel/VBoxContainer/HBoxContainer/CreateWallet
@onready var status_label = $Panel/VBoxContainer/StatusLabel
@onready var mnemonic_button = $Panel/VBoxContainer/InputTypeContainer/MnemonicButton
@onready var hex_button = $Panel/VBoxContainer/InputTypeContainer/HexButton

var crypto = Crypto.new()
var ripemd160
var hmac_sha512
var bip39_words = []

# BIP39 constants
const ENT_128 = 16  # 128 bits = 12 words

func sha256(data: PackedByteArray) -> PackedByteArray:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish()

func _ready():
	# Initialize crypto classes
	if ClassDB.class_exists("Ripemd160") and ClassDB.class_exists("HmacSha512"):
		ripemd160 = Ripemd160.new()
		hmac_sha512 = HmacSha512.new()
	else:
		push_error("Crypto extension classes not found. Make sure the extension is loaded.")
		return

	generate_random.connect("pressed", Callable(self, "_on_generate_random_pressed"))
	create_wallet.connect("pressed", Callable(self, "_on_create_wallet_pressed"))
	seed_input.connect("text_changed", Callable(self, "_on_seed_input_changed"))
	mnemonic_button.connect("pressed", Callable(self, "_on_input_type_changed"))
	hex_button.connect("pressed", Callable(self, "_on_input_type_changed"))
	$Panel/CloseButton.connect("pressed", Callable(self, "_on_close_button_pressed"))
	$Panel/CloseWarningDialog.connect("confirmed", Callable(self, "_on_close_warning_confirmed"))
	ensure_starters_directory()
	load_bip39_words()
	
	# Show the window if no wallet exists
	visible = !check_existing_wallet()
	_on_input_type_changed()  # Set initial visibility

func _on_input_type_changed():
	var button = mnemonic_button if mnemonic_button.button_pressed else hex_button
	if button == mnemonic_button:
		hex_button.button_pressed = false
		seed_input.placeholder_text = "Enter BIP39 mnemonic (12 words) or generate random"
		passphrase_container.visible = true
	else:
		mnemonic_button.button_pressed = false
		seed_input.placeholder_text = "Enter 64 hex characters or generate random"
		passphrase_container.visible = false
	_on_seed_input_changed(seed_input.text)

func load_bip39_words():
	var file = FileAccess.open("res://addons/cusf_launcher_crypto/bip39_word_list.json", FileAccess.READ)
	if file:
		bip39_words = JSON.parse_string(file.get_as_text())
		file.close()

func _on_generate_random_pressed():
	# Generate random bytes using current time
	var time_bytes = str(Time.get_unix_time_from_system()).to_utf8_buffer()
	var random_hex = sha256(sha256(time_bytes)).hex_encode()
	
	if mnemonic_button.button_pressed:
		# Convert the hex to mnemonic (use first 16 bytes for 12 words)
		var all_bytes = random_hex.hex_decode()
		var entropy = all_bytes.slice(0, ENT_128)  # Take first 16 bytes for 12 words
		var mnemonic = generate_mnemonic(entropy)
		seed_input.text = mnemonic
	else:
		# Display the hex directly
		seed_input.text = random_hex

func _on_create_wallet_pressed():
	var input_text = seed_input.text.strip_edges()
	var seed_bytes: PackedByteArray
	var mnemonic: String = ""
	
	if mnemonic_button.button_pressed:
		if !is_valid_mnemonic(input_text):
			status_label.text = "Invalid mnemonic. Please enter 12 valid BIP39 words."
			return
		mnemonic = input_text
		var passphrase = passphrase_input.text  # Get optional passphrase
		seed_bytes = mnemonic_to_seed(mnemonic, passphrase)
	else:
		if !is_valid_hex(input_text):
			status_label.text = "Invalid hex format. Must be 64 hex characters."
			return
		# Double SHA256 of hex input
		var initial_bytes = input_text.hex_decode()
		var first_hash = sha256(initial_bytes)
		seed_bytes = sha256(first_hash)
	
	# Generate wallet data
	var wallet_data = generate_wallet_data(seed_bytes, mnemonic)
	save_wallet_data(wallet_data)
	status_label.text = "Wallet created successfully!"
	
	# Hide after a short delay
	await get_tree().create_timer(1.0).timeout
	visible = false

func _on_seed_input_changed(new_text: String):
	if new_text.is_empty():
		status_label.text = ""
		return

	if mnemonic_button.button_pressed:
		if is_valid_mnemonic(new_text):
			status_label.text = "Valid mnemonic format"
		else:
			status_label.text = "Invalid mnemonic. Please enter 12 valid BIP39 words."
	else:
		if is_valid_hex(new_text):
			status_label.text = "Valid hex format"
		else:
			status_label.text = "Invalid hex format. Must be 64 hex characters."

func is_valid_hex(hex_string: String) -> bool:
	if hex_string.length() != 64:
		return false
	var hex_regex = RegEx.new()
	hex_regex.compile("^[0-9a-fA-F]+$")
	return hex_regex.search(hex_string) != null

func format_binary(num: int, width: int) -> String:
	var result = ""
	for i in range(width):
		result = ("1" if num & (1 << i) else "0") + result
	return result

func is_valid_mnemonic(mnemonic: String) -> bool:
	var words = mnemonic.split(" ", false)
	
	# Check word count is valid (12 words only)
	if words.size() != 12:
		return false
	
	# Check if all words are in the BIP39 word list
	for word in words:
		if !bip39_words.has(word):
			return false
	
	# Calculate entropy length (128 bits for 12 words)
	var entropy_bits = 128  # (12 words * 11 bits) - (12/3) checksum bits
	var entropy_bytes = 16  # 128 bits = 16 bytes
	
	# Validate checksum
	var indices = []
	for word in words:
		indices.append(bip39_words.find(word))
	
	# Convert indices to binary
	var binary = ""
	for index in indices:
		binary += format_binary(index, 11)
	
	# Split entropy and checksum
	var entropy_bits_str = binary.substr(0, entropy_bits)
	var checksum_bits = binary.substr(entropy_bits)
	
	# Convert entropy bits back to bytes
	var entropy = PackedByteArray()
	for i in range(0, entropy_bits_str.length(), 8):
		var byte_bits = entropy_bits_str.substr(i, 8)
		var byte_value = 0
		for j in range(8):
			if byte_bits[j] == "1":
				byte_value |= 1 << (7 - j)
		entropy.append(byte_value)
	
	# Calculate expected checksum
	var checksum = sha256(entropy)
	var expected_checksum = ""
	var checksum_length = entropy_bytes / 4  # BIP39 spec: CS = ENT / 32
	for i in range(checksum_length):
		expected_checksum += "1" if checksum[i/8] & (1 << (7 - (i % 8))) else "0"
	
	return checksum_bits == expected_checksum

func generate_mnemonic(entropy: PackedByteArray) -> String:
	if entropy.size() != ENT_128:
		push_error("Invalid entropy length")
		return ""
		
	# Convert entropy to binary string
	var binary = ""
	for byte in entropy:
		var bin_str = ""
		var val = byte
		for _i in range(8):
			bin_str = ("1" if val & 1 else "0") + bin_str
			val = val >> 1
		binary += bin_str
	
	# Calculate SHA256 checksum
	var checksum = sha256(entropy)
	var checksum_length = entropy.size() / 4  # BIP39 spec: CS = ENT / 32
	var checksum_binary = ""
	for i in range(checksum_length):
		checksum_binary += "1" if checksum[i/8] & (1 << (7 - (i % 8))) else "0"
	
	# Combine entropy and checksum
	binary += checksum_binary
	
	# Split into 11-bit segments and convert to words
	var words = []
	for i in range(0, binary.length(), 11):
		var segment = binary.substr(i, 11)
		if segment.length() == 11:  # Ensure complete segment
			var index = 0
			for j in range(11):
				if segment[j] == "1":
					index |= 1 << (10 - j)
			if index < bip39_words.size():
				words.append(bip39_words[index])
	
	return " ".join(words)

func mnemonic_to_seed(mnemonic: String, passphrase: String = "") -> PackedByteArray:
	# Convert mnemonic and passphrase to UTF-8
	var password = mnemonic.to_utf8_buffer()
	var salt = ("mnemonic" + passphrase).to_utf8_buffer()
	
	# PBKDF2-HMAC-SHA512 implementation
	var result = PackedByteArray()
	var block_number = 1
	
	# We need 64 bytes (512 bits) of output
	while result.size() < 64:
		# Calculate U1 = HMAC-SHA512(password, salt || INT_32_BE(i))
		var u = hmac_sha512.hmac(password, salt + int_to_4bytes(block_number))
		var block = u
		
		# Calculate U2 through U2048
		for i in range(2047):  # Already did first iteration
			u = hmac_sha512.hmac(password, u)
			# XOR the new value with the previous block
			for j in range(block.size()):
				block[j] ^= u[j]
		
		result.append_array(block)
		block_number += 1
	
	return result.slice(0, 64)  # Ensure exactly 64 bytes

func int_to_4bytes(n: int) -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(4)
	bytes[0] = (n >> 24) & 0xFF
	bytes[1] = (n >> 16) & 0xFF
	bytes[2] = (n >> 8) & 0xFF
	bytes[3] = n & 0xFF
	return bytes

func generate_wallet_data(seed_bytes: PackedByteArray, mnemonic: String) -> Dictionary:
	# Generate HMAC-SHA512 of seed with "Bitcoin seed" as key
	var key = "Bitcoin seed".to_utf8_buffer()
	var hmac = hmac_sha512.hmac(key, seed_bytes)
	
	# Split the HMAC output into master key (first 32 bytes) and chain code (last 32 bytes)
	var master_key = hmac.slice(0, 32)
	var chain_code = hmac.slice(32, 64)
	
	# Calculate BIP39 binary and checksum if mnemonic is provided
	var bip39_bin = ""
	var bip39_csum = ""
	var bip39_csum_hex = ""
	
	if !mnemonic.is_empty():
		# Convert mnemonic words to indices
		var indices = []
		for word in mnemonic.split(" ", false):
			indices.append(bip39_words.find(word))
		
		# Convert indices to binary
		for index in indices:
			bip39_bin += format_binary(index, 11)
		
		# Calculate entropy length from word count
		var word_count = mnemonic.split(" ", false).size()
		var entropy_bits = (word_count * 11) - (word_count / 3)
		
		# Extract entropy and checksum
		var entropy_bits_str = bip39_bin.substr(0, entropy_bits)
		bip39_csum = bip39_bin.substr(entropy_bits)
		
		# Calculate checksum hex
		var csum_value = 0
		for i in range(bip39_csum.length()):
			if bip39_csum[i] == "1":
				csum_value |= 1 << (bip39_csum.length() - 1 - i)
		
		# Convert to hex without using format string
		var hex_chars = "0123456789abcdef"
		bip39_csum_hex = hex_chars[(csum_value >> 4) & 0xF] + hex_chars[csum_value & 0xF]
		
		# Store complete binary (including checksum)
		bip39_bin = entropy_bits_str + bip39_csum
	
	return {
		"bip39_bin": bip39_bin,
		"bip39_csum": bip39_csum,
		"bip39_csum_hex": bip39_csum_hex,
		"chain_code": chain_code.hex_encode(),
		"hd_key_data": master_key.hex_encode() + chain_code.hex_encode(),
		"master_key": master_key.hex_encode(),
		"mnemonic": mnemonic,
		"seed_hex": seed_bytes.hex_encode()
	}

func save_wallet_data(wallet_data: Dictionary):
	ensure_starters_directory()
	
	var user_data_dir = OS.get_user_data_dir()
	var starters_dir = user_data_dir.path_join("wallet_starters")
	
	# Save master wallet data
	var master_file = FileAccess.open(starters_dir.path_join("wallet_master_seed.txt"), FileAccess.WRITE)
	if master_file:
		master_file.store_string(JSON.stringify(wallet_data))
		master_file.close()

func ensure_starters_directory():
	var user_data_dir = OS.get_user_data_dir()
	var starters_dir = user_data_dir.path_join("wallet_starters")
	var dir = DirAccess.open(user_data_dir)
	if not dir.dir_exists("wallet_starters"):
		dir.make_dir("wallet_starters")

func check_existing_wallet() -> bool:
	var user_data_dir = OS.get_user_data_dir()
	var wallet_file = user_data_dir.path_join("wallet_starters/wallet_master_seed.txt")
	return FileAccess.file_exists(wallet_file)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if click is outside the panel
			var panel_rect = $Panel.get_global_rect()
			if !panel_rect.has_point(event.position):
				_on_close_requested()

func _on_close_requested():
	if check_existing_wallet():
		visible = false
	else:
		status_label.text = "Please create a wallet first"

func _on_close_button_pressed():
	if !check_existing_wallet():
		$Panel/CloseWarningDialog.popup_centered()
	else:
		visible = false

func _on_close_warning_confirmed():
	visible = false
