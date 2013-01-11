#!/bin/sh

# Debug
#set -x

CKEY="ysJCh74mgNrzzQ0fZxXNw"
CSECRET="cvpHWJ3WSHLHeAX6WUOZjv5CR3qy7vwVvLf4WDuT0tY"
AKEY=""
ASECRET=""

#HTTP_POST="wget -q -O - --post-data" 
HTTP_POST="curl -s --data"
  
Encode()
{
string=$1; format=; set --
while
  literal=${string%%[!-._~0-9A-Za-z]*}
  if [ -n "$literal" ]; then
    format=$format%s
    set -- "$@" "$literal"
    string=${string#$literal}
  fi
  [ -n "$string" ]
do
  tail=${string#?}
  head=${string%$tail}
  format=$format%%%02X
  set -- "$@" "'$head"
  string=$tail
  done
printf "$format\\n" "$@"
}

GenerateHash()
{
EURL="`Encode $2`"
EPARAM="`Encode $3`"
QUERY="$1&$EURL&$EPARAM"
HASH="`echo -n \"$QUERY\" | openssl sha1 -hmac \"$CSECRET&$ASECRET\" -binary | openssl base64`"
Encode "$HASH"
} 

UpdateTimeLine()
{
TWEET="`Encode \"$@\"`"
if [ "$TWEET" == "" ]
then
 echo "Error: Text is missing" >&2
 exit 1
fi

URL="http://api.twitter.com/1.1/statuses/update.json"
NONCE="`dd if=/dev/urandom bs=1024 count=1 2>/dev/null | md5sum | cut -c1-32`"
PARAM="oauth_consumer_key=$CKEY&oauth_nonce=$NONCE&oauth_signature_method=HMAC-SHA1&oauth_timestamp=`date +%s`&oauth_token=$AKEY&oauth_version=1.0&status=$TWEET"
HASH="`GenerateHash "POST" "$URL" "$PARAM"`"

JSON="`$HTTP_POST "$PARAM&oauth_signature=$HASH" "$URL"`"
ERROR="`echo "$JSON" | grep "errors:"`"
if [ -n "$ERROR" ]
then
  echo -n "Error: "
  echo $JSON | sed -e 's/^.*"message":"\([^"]*\)".*$/\1/'
fi
}

UpdateTimeLine "$@"