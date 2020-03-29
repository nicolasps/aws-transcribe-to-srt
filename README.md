# aws-transcribe-to-srt

This is a bash script to convert the Amazon Transcribe `.json` file into a `.srt`  file

## Use

The script expect two parameters:
- The locatlion of the `.json` file
- And the number of maximum words to show per line

```$./aws-transcribe-to-srt ~/myuser/transcribe.json 10```


## Output
The resulting `.srt` will be shown on the screen, but can be redirect to a file if required.

```$./aws-transcribe-to-srt ~/myuser/transcribe.json 10 > output.srt```



