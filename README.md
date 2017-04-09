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

### upload media

```
$ bundle exec twurl -H upload.twitter.com -X POST "/1.1/media/upload.json" --file "/Users/hash/Desktop/183.png" --file-field "media"
{
    "media_id":747459862989180930,
    "media_id_string":"747459862989180930",
    "size":168537,
    "expires_after_secs":86400,
    "image": {
        "image_type":"image\/png",
        "w":281,
        "h":382
    }
}

$ ed local.js
client.post('statuses/update', {status: '真核生物の遺伝子発現は多数の段階で制御される (ch.18, p.453)', media_ids: '747463028430430211'},  (err, tweet, response) => {

$ nvm use stable
$ node local.js

$ data.txt
> "expanded_url": "http://twitter.com/campbellbio_jp/status/747463474133925888/photo/1",
```

### upload data

```
$ TABLE=source-table-name ruby seed.rb
```

#### check data

```
$ aws dynamodb scan --table-name $TABLE | \
  jrq -r '_.Items.map{|item| "ch.%2d (p.%4d): %4d, %2d" % [item.chapter.S, item.page.S, item.text_id.N, item.seq_id.N].map(&:to_i) rescue nil }'
```

total count

```
$ aws dynamodb query --table-name $TABLE \
  --key-condition-expression "text_id = :val" \
  --expression-attribute-values '{":val": {"N": "0"}}' \
  --query 'Items[0].count.N'
```
