#!/bin/bash

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

if ! hash tidy
then
	error "tidy is not installed"
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

if [ -f "${DIR}/settings" ]
then
	source "${DIR}/settings"
fi



# Use out script home for work if needs be.
WORKDIR="${WORKDIR:-$DIR}"

cd "${WORKDIR}"

if [ -f "${WORKDIR}/xpath_error" ]
then
	echo "Last request returned 0 results, check your URL and XPATH"
	echo "Delete the xpath_error file to resume normal operation"
	exit 1
fi

if [ -f "${WORKDIR}/email_error" ]
then
	echo "Last email send failed"
	echo "Delete the email_error file to resume normal operation"
	exit 1
fi

if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]
then
	echo "No AWS creds"
	exit 1
fi


if [ -z "${URL:-}" ] || [ -z "${XPATH:-}" ]
then
	echo "No URL or XPATH set"
	exit 1
fi

if [ -z "${EMAIL:-}" ] || [ -z "${FROM:-}" ]
then
	echo "No email to send to or from"
	exit 1
fi


if ! [ -e "${WORKDIR}/last.txt" ]
then
	touch "${WORKDIR}/last.txt"
fi

LAST=$(<"${WORKDIR}/last.txt")

NOW=$(curl -s -L "${URL}" | tidy -config "${DIR}/tidy.conf" 2>/dev/null | xmllint -xpath "${XPATH}" - | sed '/^$/d' )

LINES=$(echo "${NOW}" | sed '/^$/d' | wc -l | tr -d '[:space:]')

if [ "${1}" = 'test' ]
then
	echo "URL: ${URL}"
	echo "XPATH: ${XPATH}"
	echo "Lines: ${LINES}"
	echo "Results: "
	echo "${NOW}"
	exit 0
fi


if [ "${LINES}" -eq 0 ]
then
	touch "${WORKDIR}/xpath_error"
	echo "xpath error"
	exit 1
fi

function send_mail {
	BODY=$(cat <<-EOF
		Update to your classified checker! New items:

		${1}
	EOF
	)

	export AWS_ACCESS_KEY_ID
	export AWS_SECRET_ACCESS_KEY
	export AWS_DEFAULT_REGION=us-east-1

	STATUS=$(aws ses send-email \
		--from "${FROM}" \
		--to "${EMAIL}" \
		--subject "Armslist classifieds update" \
		--text "${BODY}" 2>&1 )

	if [ $? -ne 0 ]
	then
		echo "No email sent"
		echo "${STATUS}" > "${WORKDIR}/email_failure"
		exit 1
	fi

}

if [[ "${LAST}" != "${NOW}" ]]
then
	DIFF=$(echo "${NOW}" | diff --changed-group-format='%>' --unchanged-group-format='' "${WORKDIR}/last.txt" -)
	echo "${DIFF}" > "${WORKDIR}/last_diff.txt"
	send_mail "${DIFF}"
fi

echo "${NOW}" > "${WORKDIR}/last.txt"



# Random jiggery-pokery

# xmlstarlet sel -T -t -m "/orders/orderCompleteRequestType"
# xmlstarlet sel -t -m '/html/body/div[@id="wrapper"]/main/div/div//div[@class="row"]' -
# xmllint --xpath '/html/body/div[@id="wrapper"]/main/div/div//div[@class="row"]'
# curl -s -L -o - 'https://www.armslist.com/classifieds/search\?location\=new-hampshire\&category\=all\&page\=1\&posttype\=7\&sellertype\=1\&ships\=False' | /usr/local/bin/tidy -config tidy.conf 2>/dev/null  | xmllint --xpath "//div[@class='row']" -
# curl -s -L 'https://www.armslist.com/classifieds/search?location=new-hampshire&category=all&page=1&posttype=7&sellertype=1&ships=False'
