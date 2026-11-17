Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setTargetObjectId(UserInfo.getUserId());
mail.setSaveAsActivity(false);
mail.setSubject('Internal User Email Test');
mail.setPlainTextBody('This email bypasses the single email external limit.');
Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
System.debug('Target Object ID Success: ' + results[0].isSuccess());