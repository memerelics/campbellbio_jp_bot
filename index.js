'use strict';
console.log('--- Loading function ---');

let fs = require('fs');
let doc = require('dynamodb-doc');
let dynamo = new doc.DynamoDB();
let AWS = require("aws-sdk");
let kms = new AWS.KMS();
let Twitter = require('twitter');

var handle_error = (err, context) => {
  console.log(err, err.stack);
  context.fail('failed');
}

var getRandomInt = (min, max) => {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

var buildPayload = (items, prev) => {
  var payload = { status: '' };

  if (prev !== undefined) { // not first tweet
    payload.status = payload.status + '@campbellbio_jp ';
    payload.in_reply_to_status_id = prev.id_str;
  }

  payload.status = payload.status + items[0].text;

  if (items.length === 1) { // last tweet
    payload.status = payload.status +
      ' (ch.' + items[0].chapter.toString() +
          ', p.' + items[0].page.toString() + ')';
  }

  return payload;
}

var recursiveTweet = (items, context, client, prev) => {
  if (items.length !== 1) {
    client.post('statuses/update', buildPayload(items, prev), (err, tweet, resp) => {
      if (err) { handle_error(err, context); }
      console.log('tweet: ' + JSON.stringify(tweet));
      items.shift(); // remove the first item
      setTimeout(() => { recursiveTweet(items, context, client, tweet); }, 5000);
    });
  } else {
    client.post('statuses/update', buildPayload(items, prev), (err, tweet, resp) => {
      if (err) { handle_error(err, context); }
      context.succeed('lastTweet: ' + JSON.stringify(tweet));
    });
  }
}

exports.handler = (event, context, callback) => {
  console.log('Received event:', JSON.stringify(event, null, 2));
  var table = event.table;

  var encrypted = fs.readFileSync('./encrypted-credentials');
  kms.decrypt({CiphertextBlob: encrypted}, (err, data) => {
    if (err) { handle_error(err, context); }
    var decrypted = data['Plaintext'].toString();
    // console.log(decrypted);
    var obj = {};
    decrypted.split(',').forEach((item) => {
      var pair = item.split(':');
      obj[pair[0]] = pair[1];
    });

    var client = new Twitter({
      consumer_key: obj.consumer_key,
      consumer_secret: obj.consumer_secret,
      access_token_key: obj.access_token_key,
      access_token_secret: obj.access_token_secret
    });

    dynamo.getItem({
      TableName: table,
      Key: { text_id: 0, seq_id: 0 }
    }, (err, data) => {
      if (err) { handle_error(err, context); }
      // console.log(JSON.stringify(data));
      var randomId = getRandomInt(1, data.Item.count);
      console.log('selected text_id: ' + randomId.toString());

      dynamo.query({
        TableName: table,
        KeyConditionExpression: "#text_id = :i",
        ExpressionAttributeNames:{ "#text_id": "text_id" },
        ExpressionAttributeValues: { ":i": randomId }
      }, (err, data) => {
        if (err) { handle_error(err, context); }
        console.log('dynamo.query result: ' + JSON.stringify(data));
        recursiveTweet(data.Items, context, client);
      });
    });
  });
};
