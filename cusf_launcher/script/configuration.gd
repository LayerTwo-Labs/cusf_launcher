extends Control

const DEFAULT_BITCOIN_RPC_PORT : int = 18443
const DEFAULT_WALLET_RPC_PORT : int = 18443
const DEFAULT_CUSF_CAT_RPC_PORT : int = -1 # TODO currently unknown
const DEFAULT_CUSF_DRIVECHAIN_RPC_PORT : int = 50051 
const DEFAULT_BITCOIN_DATA_DIR : String = ".bitcoin" 
const DEFAULT_BITCOIN_CONFIG_DIR : String = ".bitcoin/bitcoin.conf" 

const DEFAULT_CONFIG_BITCOIN : String = '''
rpcuser=user
rpcpassword=password
signetblocktime=60
signetchallenge=00141f61d57873d70d28bd28b3c9f9d6bf818b5a0d6a
zmqpubsequence=tcp://0.0.0.0:29000
txindex=1
server=1
'''

signal configuration_complete

func write_bitcoin_configuration() -> void:
	var user : String = ""
	if OS.has_environment("USERNAME"):
		# Windows
		user = OS.get_environment("USERNAME")
	elif OS.has_environment("USER"):
		# Everything else
		user = OS.get_environment("USER")
	
	DirAccess.make_dir_absolute(str("/home/", user, "/", DEFAULT_BITCOIN_DATA_DIR))
	
	var file = FileAccess.open(str("/home/", user, "/", DEFAULT_BITCOIN_CONFIG_DIR), FileAccess.WRITE_READ)
	file.store_string(DEFAULT_CONFIG_BITCOIN)
	
	configuration_complete.emit()
