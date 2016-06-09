'use strict';
console.log('Loading function');

let doc = require('dynamodb-doc');
let dynamo = new doc.DynamoDB();
let AWS = require("aws-sdk");
let twitter = require('twitter');

exports.handler = (event, context, callback) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    var encrypted = fs.readFileSync('./encrypted-credentials');
    AWS.KMS.decrypt({CiphertextBlob: encrypted}, function(err, data) {
      if (err) {
        console.log(err, err.stack);
        context.fail('failed');
      } else {
         var decrypted = data['Plaintext'].toString();
         console.log(decrypted);
         obj = {};
         decrypted.split(',').forEach(function(item) {
           var pair = item.split(':');
           obj[pair[0]] = pair[1];
         });

         var client = new Twitter({
           consumer_key: obj.consumer_key,
           consumer_secret: obj.consumer_secret,
           access_token_key: obj.access_token_key,
           access_token_secret: obj.access_token_secret
         });
         console.log(client);

      }
    });
};
