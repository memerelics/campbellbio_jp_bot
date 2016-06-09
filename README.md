first, run following command to activate Node.js 4.3.x declared in .nvmrc. I'm just using this version because Lambda using it. Then `npm install`.

```
$ nvm use
$ npm install
```

prepare your twitter credentials and save them in KMS. Lambda function will decrypt them each time it invoked.

```sh
$ aws kms encrypt \
          --key-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
          --query CiphertextBlob \
          --output text \
          --plaintext "consumer_key:XXXXXXXXXXXXXXXXXXXXXXXXX,consumer_secret:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,access_token_key:111111111111111111-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,access_token_secret:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" \
| base64 -D > ./encrypted-credentials
```

deploy script whould come out something like this:

```sh
FUNC=lambda_function_name

zip -r index.zip index.js encrypted-credentials node_modules
aws lambda update-function-code --function-name $FUNC --zip-file fileb://`pwd`/index.zip
aws lambda invoke --function-name $FUNC out.log
```
