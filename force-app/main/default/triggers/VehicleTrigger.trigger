trigger VehicleTrigger on Vehicle__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        VehicleTriggerHandler.createInitialServiceHistory(Trigger.new);
    }
     VehicleTriggerHandler.afterInsert(Trigger.new);
}