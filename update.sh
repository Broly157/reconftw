#!/bin/bash

#@TODO:
    # - Update testssl.sh
    # - Update Go packages

bred='\033[1;31m'
bblue='\033[1;34m'
bgreen='\033[1;32m'
reset='\033[0m'

DEBUG_STD="&>/dev/null"
DEBUG_ERROR="2>/dev/null"

if grep -q "ARMv"  /proc/cpuinfo
then
   IS_ARM="True";
else
   IS_ARM="False";
fi

if [[ $(id -u | grep -o '^0$') == "0" ]]; then
    SUDO=" "
else
    SUDO="sudo"
fi

[ ! -d "~/.gf" ] && mkdir -p ~/.gf
[ ! -d "~/Tools" ] && mkdir -p ~/Tools
dir=~/Tools

if [ -f /etc/debian_version ]; then $SUDO apt install git wget;
elif [ -f /etc/redhat-release ]; then $SUDO yum install git wget;
elif [ -f /etc/arch-release ]; then $SUDO pacman -Sy install git wget;
#/etc/os-release fall in yum for some RedHat and Amazon Linux instances
elif [ -f /etc/os-release ]; then $SUDO yum install git wget;
fi

#Tools to be updated
repos="s0md3v/Arjun six2dez/degoogle_hunter 1ndianl33t/Gf-Patterns gwen001/github-search dark-warlord14/LinkFinder projectdiscovery/nuclei-templates devanshbatham/ParamSpider nsonaniya2010/SubDomainizer haccer/subjack s0md3v/Corsy pielco11/fav-up tomnomnom/gf codingo/Interlace blechschmidt/massdns m4ll0k/SecretFinder devanshbatham/OpenRedireX tillson/git-hound"

printf "\n${bgreen}--==[ ************************************************************************************ ]==--\n"
printf "${bred}                reconftw updater script (apt/rpm/pacman compatible)${reset}\n"
printf "\n${bgreen}--==[ ************************************************************************************ ]==--\n"

for repo in ${repos}; do
    printf "${bgreen}#######################################################################\n"
    printf "${bblue} Updating ${repo} ${reset}\n"
    if [ ! -d "$dir/$(basename $repo)" ]; then
        eval git clone https://github.com/$repo "$dir/$(basename $repo)" $DEBUG_STD
    else
        cd "$dir/$(basename $repo)"
        eval git pull origin master $DEBUG_STD
        if [ "massdns" = "$(basename $repo)" ]; then
            make && $SUDO cp bin/massdns /usr/bin/
        elif [ "Gf-Patterns" = "$(basename $repo)" ]; then
            cp *.json ~/.gf
        elif [ "gf" = "$(basename $repo)" ]; then
            cp -r examples ~/.gf
        elif [ "Interlace" = "$(basename $repo)" ] || [ "LinkFinder" = "$(basename $repo)" ]; then
            eval $SUDO python3 setup.py install $DEBUG_STD
        fi
        if [ "True" = "$IS_ARM" ] && [ "git-hound" = "$(basename $repo)" ]
            then
                go build && chmod 754 git-hound && $SUDO mv git-hound /usr/local/bin/
        fi
    fi
    printf "${bblue}\n Updating ${repo} is finished ${reset}\n"
    printf "${bgreen}#######################################################################\n"
done


printf "${bgreen}#######################################################################\n"
printf "${bblue} Updating Files \n"
if [ "True" = "$IS_ARM" ]
    then
        eval wget -N -c https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-rpi  $DEBUG_STD
        $SUDO mv findomain-rpi /usr/local/bin/findomain
    else
        eval wget -N -c https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux  $DEBUG_STD
        $SUDO mv findomain-linux /usr/local/bin/findomain
fi
$SUDO chmod 754 /usr/local/bin/findomain

eval wget -N -c -O ~/.gf/potential.json https://raw.githubusercontent.com/devanshbatham/ParamSpider/master/gf_profiles/potential.json $DEBUG_STD
eval wget -N -c -O ~/.config/amass/config.ini https://raw.githubusercontent.com/OWASP/Amass/master/examples/config.ini $DEBUG_STD
eval wget -N -c -O $dir/github-endpoints.py https://gist.githubusercontent.com/six2dez/d1d516b606557526e9a78d7dd49cacd3/raw/8e7f1e1139ba3501d15dcd2ad82338d303f0b404/github-endpoints.py $DEBUG_STD
eval wget -N -c -O $dir/getjswords.py https://raw.githubusercontent.com/m4ll0k/Bug-Bounty-Toolz/master/getjswords.py $DEBUG_STD
eval wget -N -c -O $dir/subdomains.txt https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt $DEBUG_STD
eval wget -N -c -O $dir/resolvers.txt https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt $DEBUG_STD
eval wget -N -c -O $dir/permutations_list.txt https://gist.githubusercontent.com/six2dez/ffc2b14d283e8f8eff6ac83e20a3c4b4/raw/137bb6b60c616552c705e93a345c06cec3a2cb1f/permutations_list.txt $DEBUG_STD
eval wget -N -c -O $dir/ssrf.py https://gist.githubusercontent.com/h4ms1k/adcc340495d418fcd72ec727a116fea2/raw/ea0774de5e27f9bc855207b175249edae2e9ccef/asyncio_ssrf.py $DEBUG_STD
eval wget -N -c -O $dir/fuzz_wordlist.txt https://raw.githubusercontent.com/six2dez/OneListForAll/main/onelistforallmicro.txt $DEBUG_STD
printf "${bblue}\n Updating Files is finished ${reset}\n"
printf "${bgreen}#######################################################################\n"

#Updating Nuclei templates
printf "${bgreen}#######################################################################\n"
printf "${bblue} Updating Nuclei templates \n"
nuclei -update-templates $DEBUG_STD
printf "${bblue}\n Updating Nuclei templates is finished ${reset}\n"
printf "${bgreen}#######################################################################\n"

#Updating installed python packages
printf "${bgreen}#######################################################################\n"
printf "${bblue} Updating installed python packages \n"
cat $dir/*/requirements.txt | grep -v "=" | uniq | xargs pip3 install -U
printf "${bblue}\n Updating installed python packages is finished ${reset}\n"
printf "${bgreen}#######################################################################\n"

#Updating Golang
printf "${bgreen}#######################################################################\n"
printf "${bblue} Updating Golang \n"
if [ "True" = "$IS_ARM" ]; then
    LATEST_GO=$(wget -qO- https://golang.org/dl/ | grep -oP 'go([0-9\.]+)\.linux-armv6l\.tar\.gz' | head -n 1 | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2)
    if [ "go$LATEST_GO" =  $(go version | cut -d " " -f3) ]
        then
            printf "${bblue}\n Golang is up to date ${reset}\n"
        else
            wget https://dl.google.com/go/go$LATEST_GO.linux-armv6l.tar.gz
            $SUDO tar -C /usr/local -xzf go$LATEST_GO.linux-armv6l.tar.gz
            $SUDO cp /usr/local/go/bin/go /usr/bin
    fi
else
    LATEST_GO=$(wget -qO- https://golang.org/dl/ | grep -oP 'go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2)
    if [ "go$LATEST_GO" =  $(go version | cut -d " " -f3) ]
        then
            printf "${bblue}\n Golang is up to date ${reset}\n"
        else
            wget https://dl.google.com/go/go$LATEST_GO.linux-amd64.tar.gz
            $SUDO tar -C /usr/local -xzf go$LATEST_GO.linux-amd64.tar.gz
            $SUDO cp /usr/local/go/bin/go /usr/bin
    fi
fi
eval rm -rf go$LATEST_GO* $DEBUG_STD
printf "${bblue}\n Updating Golang is finished ${reset}\n"
printf "${bgreen}#######################################################################\n"


printf "\n${bgreen}--==[ ************************************************************************************ ]==--\n"
printf "${bred}                You are up to date, happy hacking${reset}\n"
printf "\n${bgreen}--==[ ************************************************************************************ ]==--\n"
