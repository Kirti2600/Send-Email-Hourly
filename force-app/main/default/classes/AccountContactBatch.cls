global class AccountContactBatch implements Database.Batchable<SObject>
{
     global Database.QueryLocator start(Database.BatchableContext BC) 
     {
        return Database.getQueryLocator([
            SELECT Id, Name, mailSendUser__c, isMailSend__c,
                   (SELECT Id, FirstName, LastName, Email FROM Contacts WHERE CreatedDate >= :System.now().addHours(-1))
            FROM Account 
            WHERE isMailSend__c = false
        ]);
    }

      
   
    global void execute(Database.BatchableContext BC, List<Account> accountList) {
        if (!accountList.isEmpty()) {
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            String contactRows = ''; // Initialize the contact rows for the email body
            Set<Id> emailRecipients = new Set<Id>(); // To keep track of unique recipients

            // Iterate through the account list
            for (Account acc : accountList) {
                // Check if the account has contacts
                if (acc.Contacts != null && !acc.Contacts.isEmpty()) {
                    // Iterate through each contact and build the HTML rows
                    for (Contact con : acc.Contacts) {
                        contactRows += '<tr>';
                        contactRows += '<td>' + acc.Name + '</td>'; // Add Account Name to the row
                        contactRows += '<td>' + con.FirstName + ' ' + con.LastName + '</td>';
                        contactRows += '<td>' + (con.Email != null ? con.Email : 'No Email') + '</td>'; // Handle null email case
                        contactRows += '</tr>';
                    }
                }
                // Collect unique mailSendUser__c to send a single email to each unique user
                if (acc.mailSendUser__c != null) {
                    emailRecipients.add(acc.mailSendUser__c);
                }
                
                // Mark the account to avoid duplicate emails
                acc.isMailSend__c = true;
            }

            // If there are contact rows, send an email
            if (contactRows.length() > 0 && !emailRecipients.isEmpty()) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                // Set the template
                emailTemplate et = [SELECT Id,Body FROM EmailTemplate WHERE DeveloperName = 'ContactInformationtemplate'];
                mail.setTemplateId(et.Id);
                mail.setTargetObjectId(emailRecipients.iterator().next()); // Set the first recipient
                mail.setWhatId(accountList[0].Id); // Related Account (can be any from the list)
                mail.setSaveAsActivity(false);
                mail.setUseSignature(false);
                
                // Prepare the HTML body using the contact rows
               String emailBody = et.Body + '<br/><br/>' + 
                    '<html><body>' +
                    '<h1>New Contacts Created</h1>' +
                    '<table border="1" cellpadding="5" cellspacing="0">' +
                    '<tr><th>Account Name</th><th>Contact Name</th><th>Email</th></tr>' +
                    contactRows +
                    '</table>' +
                    '</body></html>';
                    
                mail.setHtmlBody(emailBody);

                // Add the email to the list
                emailsToSend.add(mail);
               
            }

            // Send all emails in a single call
            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }

            // Update accounts after processing
            update accountList;

            // For demonstration: Log account contact details to debug
            System.debug('Emails sent for accounts: ' + accountList);
        }
    }

    
    
    global void finish(Database.BatchableContext BC) {
        // Optional: Add any post-processing logic here if needed
        System.debug('Batch job completed.');
    }
    
}