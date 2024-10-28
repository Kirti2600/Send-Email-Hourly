trigger ContactTrigger on Contact (after insert) {
  // Call the handler class to process the new Contacts
    if (Trigger.isAfter && Trigger.isInsert) 
    {
        ContactTriggerHandler.handleNewContacts(Trigger.new);
    }
}