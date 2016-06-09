'use strict';
console.log('--- Loading function ---');

let fs = require('fs');
let doc = require('dynamodb-doc');
let dynamo = new doc.DynamoDB();
let AWS = require("aws-sdk");
let kms = new AWS.KMS();
let Twitter = require('twitter');

var getRandomInt = (min, max) => {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

exports.handler = (event, context, callback) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var table = event.table;

    var encrypted = fs.readFileSync('./encrypted-credentials');
    kms.decrypt({CiphertextBlob: encrypted}, (err, data) => {
      if (err) {
        console.log(err, err.stack);
        context.fail('failed');
      } else {
         var decrypted = data['Plaintext'].toString();
         console.log(decrypted);
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

         dynamo.getItem({TableName: table,
                         Key: { text_id: 0, seq_id: 1 }
         }, (err, data) => {
           if (err) {
             console.log(err, err.stack);
             context.fail('failed');
           } else {
             console.log(data);
             var randomId = getRandomInt(1, data.Item.count);
             console.log(randomId);

             dynamo.query({TableName: table,
               KeyConditionExpression: "#text_id = :iii",
               ExpressionAttributeNames:{ "#text_id": "text_id" },
               ExpressionAttributeValues: { ":iii": randomId }
             }, (err, data) => {
               if (err) {
                 console.log(err, err.stack);
                 context.fail('failed');
               } else {
                 console.log(data);
                 var page = data.Items[0].page;
                 var _text = data.Items[0].text;
                 var text = _text + ' (p.' + page.toString() + ')'
                 client.post('statuses/update', {status: text},  (err, tweet, resp) => {
                   if (err) {
                     console.log(err, err.stack);
                     context.fail('failed');
                   } else {
                     console.log(tweet);
                     console.log(resp);
                     context.succeed('succeed');
                   }
                 });
               }
             });
           }
         });
      }
    });
};
