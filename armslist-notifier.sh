#!/bin/bash

URL='https://www.armslist.com/classifieds/search?location=new-hampshire&category=all&page=1&posttype=7&sellertype=1&ships=False'
XPATH='/html/body/div[@id="wrapper"]/main/div/div//div[@class="row c50"]//h4[@class="c47"]/a/text()'

if ! hash curl
then
	error "curl is not installed"
	exit 1
fi

if ! hash xmllint
then
	error "xmllint is not installed"
	exit 1
fi

# Get directory of this file, no matter where it's being invoked from (cron!)
# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself

SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"

cd "${DIR}"

if ! [ -e "${DIR}/last.txt" ]
then
	touch "${DIR}/last.txt"
fi

LAST=$(<"${DIR}/last.txt")

NOW=$(curl -s -L "${URL}" | /usr/local/bin/tidy -config tidy.conf 2>/dev/null | xmllint -xpath "${XPATH}" -)

if [[ "${LAST}" != "${NOW}" ]]
then
	echo "Different!"

else
	echo "Same!"
fi

echo "${NOW}" > "${DIR}/last.txt"


# Random jiggery-pokery

# xmlstarlet sel -T -t -m "/orders/orderCompleteRequestType"
# xmlstarlet sel -t -m '/html/body/div[@id="wrapper"]/main/div/div//div[@class="row"]' -
# xmllint --xpath '/html/body/div[@id="wrapper"]/main/div/div//div[@class="row"]'
# curl -s -L -o - 'https://www.armslist.com/classifieds/search\?location\=new-hampshire\&category\=all\&page\=1\&posttype\=7\&sellertype\=1\&ships\=False' | /usr/local/bin/tidy -config tidy.conf 2>/dev/null  | xmllint --xpath "//div[@class='row']" -
# curl -s -L 'https://www.armslist.com/classifieds/search?location=new-hampshire&category=all&page=1&posttype=7&sellertype=1&ships=False'
