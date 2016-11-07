#!/bin/bash
#
# phantom.js
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# config
KIBANA_URL="http://kibana.your.domain.com"
PHANTOM_BINARY="/opt/phantomjs/bin/phantomjs"
PHANTOM_OPTIONS="--ignore-ssl-errors=yes"
PHANTOM_TEMPLATE="/opt/phantomjs/kibana-template.js"
PHANTOM_SITES="/opt/phantomjs/urls.conf"
PHANTOM_OUT="/opt/phantomjs/output"
PHANTOM_FORMAT="jpg"
PHANTOM_ZOOM=""
MAIL_SEND="yes"
MAIL_FROM="you@mail.com"
MAIL_TO="you@mail.com"
MAIL_BCC="you@mail.com"

# functions
function actionstart (){
    echo -e "\n$(date '+%d.%m.%G %H:%M:%S') - ${1}"
}

function exitcode (){
    if [ "$?" = 0 ]; then
	echo "$(date '+%d.%m.%G %H:%M:%S') - ${1} - ok "
    else
	echo "$(date '+%d.%m.%G %H:%M:%S') - ${1} - not ok "
        let ERROR_COUNT=ERROR_COUNT+1
    fi
}

function sendreport () {
    REPORT_MAIL_BCC="${1}"
    MAIL_DATE="$(date '+%d.%m.%G %H:%M:%S')"
    MIMETYPE="$(mimetype -b ${FILE_NAME})"
    BOUNDARY="$(uuidgen)"
    BASE64_FILE="$(base64 ${FILE_NAME})"

    /usr/sbin/sendmail -oi -t ${MAIL_TO} <<EOF
From: Your Name | Your Company <${MAIL_FROM}>
To: ${MAIL_TO}
BCC: ${REPORT_MAIL_BCC}
Subject: Kibana Report ${DATE} $(echo ${KIBANA_SEARCH} | sed 's/\"//g')
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=${BOUNDARY}

--${BOUNDARY}
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

Hi,

this is you Kibana report with search term: '${KIBANA_SEARCH}', of $(echo ${LINE} | awk '{split($0,a,";;;"); print a[6]}'), executet @ ${MAIL_DATE}.

--
Regards
Your Name

--${BOUNDARY}
Content-Type: ${MIMETYPE}
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=${DATE}_${KIBANA_SEARCH_NAME}.${PHANTOM_FORMAT}

${BASE64_FILE}

--${BOUNDARY}--

EOF
}

# script
DATE="$(date '+%Y%m%d')"
LINE_NUMBER="1"
LINE_NUMBERS="$(grep "@" < ${PHANTOM_SITES} | wc -l)"
IFS="ö"

test -d ${PHANTOM_OUT} || mkdir -p ${PHANTOM_OUT}

while [ ${LINE_NUMBER} -le ${LINE_NUMBERS} ]; do
    LINE=$(sed "${LINE_NUMBER}!d" < ${PHANTOM_SITES})
    MAIL_BCC="$(echo ${LINE} | awk '{split($0,a,";;;"); print a[1]}')"
    KIBANA_DASHBOARD="$(echo ${LINE} | awk '{split($0,a,";;;"); print a[2]}')"
    KIBANA_TIME="$(echo ${LINE} | awk '{split($0,a,";;;"); print a[3]}')"
    KIBANA_SEARCH="$(echo ${LINE} | awk '{split($0,a,";;;"); print a[4]}')"
    KIBANA_LINK="${KIBANA_URL}/app/kibana#/dashboard/${KIBANA_DASHBOARD}?embed&_g=(time:(from:now-${KIBANA_TIME},mode:quick,to:now))&_a=(query:(query_string:(analyze_wildcard:!t,query:'${KIBANA_SEARCH}')))"
    KIBANA_SEARCH_NAME="$(echo ${LINE} | awk '{split($0,a,";;;"); print a[4]}' | sed -e 's/://g' -e 's/ //g' -e 's/!/No/g' -e 's/\"//g')"
    PHANTOM_RES="$(echo ${LINE} | awk '{split($0,a,";;;"); print a[5]}')"
    FILE_NAME="${PHANTOM_OUT}/${DATE}_${KIBANA_DASHBOARD}_${KIBANA_SEARCH_NAME}.${PHANTOM_FORMAT}"

    actionstart "create ${FILE_NAME}"
    ${PHANTOM_BINARY} ${PHANTOM_OPTIONS} ${PHANTOM_TEMPLATE} "${KIBANA_LINK}" ${FILE_NAME} ${PHANTOM_RES} ${PHANTOM_ZOOM}
    exitcode "create ${FILE_NAME}"

    if [ ${MAIL_SEND} == "yes" ];then
	actionstart "send report"
	sendreport ${MAIL_BCC}
	exitcode "send report"
    fi

    LINE_NUMBER=$[${LINE_NUMBER}+1]
done

unset IFS
