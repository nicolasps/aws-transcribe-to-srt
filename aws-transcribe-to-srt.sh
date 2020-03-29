#!/bin/bash
set -e

#Check required applications
which jq | [ $(wc -l) = 0 ] && echo "Not possible to parse, 'jq' needs to be installed" && exit 1;

#Check parameters
[[ -z "$1" ]] && echo "Please provide the location of the Json file (AWS Transcribe output file) to convert to SRT" && exit 1;
[[ -z "$2" ]] && echo "Please provide the maximum number of words per line" && exit 1;

set -u;

AWS_TRANSCRIBE_JSON_FILE_LOCATION="${1}"
MAX_WORDS_PER_LINE=${2}; 
START_TIME=""
WORDS_IN_SENTENCE=0
SENTENCE=""
COUNTER=1
NEW_LINE="false"

while read -r TYPE CONTENT ITEM_START_TIME ITEM_END_TIME 
do
    if [ "${TYPE}" = "pronunciation" ]
    then
        [[ -z "$START_TIME" ]] && START_TIME=${ITEM_START_TIME} 
        [[ -z "$SENTENCE" ]] && SENTENCE=${CONTENT} || SENTENCE="${SENTENCE} ${CONTENT}"
        END_TIME=$ITEM_END_TIME
        WORDS_IN_SENTENCE=$((WORDS_IN_SENTENCE + 1))
        [[ ${WORDS_IN_SENTENCE} -ge ${MAX_WORDS_PER_LINE} ]] && NEW_LINE="true";
    elif [ "${TYPE}" = "punctuation" ]  && [ ${WORDS_IN_SENTENCE} -gt 0 ]; then
        [[ $CONTENT =~ \. ]] || SENTENCE="${SENTENCE}${CONTENT}"  && NEW_LINE="true"
    fi

    if [ $NEW_LINE = "true" ]; then
        printf "${COUNTER}\n$START_TIME --> $END_TIME\n${SENTENCE}\n\n" 
        START_TIME=""
        WORDS_IN_SENTENCE=0
        COUNTER=$((COUNTER + 1))
        SENTENCE=""
        NEW_LINE="false"
    fi
done <<< $(jq -r -e '.results.items[] | .type + " "  + .alternatives[0].content + " "  
+ try(
    (.start_time | split(".")[0] |tonumber | todateiso8601 | split("T")[1] | split("Z")[0]) + "," + (.start_time | split(".")[1]) + " " 
    + (.end_time | split(".")[0] |tonumber | todateiso8601 | split("T")[1] | split("Z")[0]) + "," + (.end_time | split(".")[1] )  
) 
catch ""' $AWS_TRANSCRIBE_JSON_FILE_LOCATION)

# Print missing words if needed
[[ $WORDS_IN_SENTENCE > 0 ]] && printf "${COUNTER}\n$START_TIME --> $END_TIME\n${SENTENCE}\n\n" 

