# iw5-admin-script

# Requirements
* This script depends on [iw5-script](https://github.com/fedddddd/iw5-script/), download the latest release from [here](https://github.com/fedddddd/iw5-script/releases/) and copy the .dll to `Plutonium/storage/iw5/plugins/`
* This script also requires a sqlite webserver which you can find in `sqlite-server/`, to run it you must install `npm` and `nodejs` which you can find [here](https://nodejs.org/en/).
  To run the sqlite server simply run the `install.bat` (or .sh) script to install the dependencies then run the `run.bat` script.

# Configuration
* Create a password of your choice and set it in the sqlite server and admin script config file (`sqlite-server/config.json` and `scripts/admin-script/cfg/config.json`)
* Copy the `admin-script` folder into `Plutonium/storage/iw5/scripts/`
* Run the sqlite server
* Run the IW5 Server
