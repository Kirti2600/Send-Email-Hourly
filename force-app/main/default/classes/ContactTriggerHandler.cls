public class ContactTriggerHandler {
  public static void handleNewContacts(List<Contact> newContacts)
  {
                  Set<Id> accountIds = new Set<Id>();
           
            for (Contact con : newContacts) {
                if (con.AccountId != null) {
                    accountIds.add(con.AccountId);
                }
            }
    
            // Query Accounts based on the Account IDs collected
            List<Account> accountsToUpdate = [
                SELECT Id, isMailSend__c 
                FROM Account 
                WHERE Id IN :accountIds
            ];
          
            for (Account acc : accountsToUpdate) {
                acc.isMailSend__c = false; // Set to false when a new Contact is created
            }
    
            // Update the Accounts to reflect the change
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }
    
    
}