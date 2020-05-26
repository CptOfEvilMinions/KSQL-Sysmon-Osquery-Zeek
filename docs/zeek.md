# Zeek

## Install/Setup Zeek on Ubuntu 20.04
1. `sudo sh -c "echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_20.04/ /' > /etc/apt/sources.list.d/security:zeek.list"`
1. `wget -nv https://download.opensuse.org/repositories/security:zeek/xUbuntu_20.04/Release.key -O Release.key`
1. `sudo apt-key add - < Release.key`
1. `sudo apt-get update -y`
1. `sudo apt-get install zeek -y`
1. `/opt/zeek/bin/zeek -v`


## References
* [Get Zeek](https://zeek.org/get-zeek/)
* [Zeek ReadTheDocs](https://docs.zeek.org/en/current/quickstart/)
* [zeek from security:zeek project](https://software.opensuse.org//download.html?project=security%3Azeek&package=zeek)
* [How do I set PATH variables for all users on a server?](https://askubuntu.com/questions/24937/how-do-i-set-path-variables-for-all-users-on-a-server)
* [StackOverFlow - Echo newline in Bash prints literal \n](https://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n)
* [Zkg Quickstart Guide](https://docs.zeek.org/projects/package-manager/en/stable/quickstart.html#installation)
* [corelight/zeek-community-id](https://github.com/corelight/zeek-community-id)
* []()
* []()
