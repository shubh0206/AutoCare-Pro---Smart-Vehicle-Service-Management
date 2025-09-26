public class VehicleTriggerHandler {
    
    // After Insert Trigger Method
    public static void afterInsert(List<Vehicle__c> newVehicles) {
        createInitialServiceHistory(newVehicles);
        VINDecoderService.triggerVINDecode(newVehicles);
    }
    
    public static void createInitialServiceHistory(List<Vehicle__c> newVehicles) {
        if (newVehicles == null || newVehicles.isEmpty()) return;

        // Pehle check karenge ki kya in vehicles ke liye already service history hai
        Set<Id> vehicleIds = new Set<Id>();
        for (Vehicle__c v : newVehicles) {
            vehicleIds.add(v.Id);
        }
        
        // Query existing service histories for these vehicles
        Map<Id, Service_History__c> existingHistories = new Map<Id, Service_History__c>();
        for (Service_History__c sh : [
            SELECT Id, Vehicle__c 
            FROM Service_History__c 
            WHERE Vehicle__c IN :vehicleIds
        ]) {
            existingHistories.put(sh.Vehicle__c, sh);
        }
        
        // Sirf unhi vehicles ke liye banayenge jinke liye nahi hai
        List<Vehicle__c> vehiclesToProcess = new List<Vehicle__c>();
        for (Vehicle__c v : newVehicles) {
            if (!existingHistories.containsKey(v.Id)) {
                vehiclesToProcess.add(v);
            }
        }
        
        if (vehiclesToProcess.isEmpty()) return;

        // Rest of your existing code...
        Set<String> allowedServiceTypes = new Set<String>();
        try {
            for (Schema.PicklistEntry pe : Service_History__c.Service_Type__c.getDescribe().getPicklistValues()) {
                allowedServiceTypes.add(pe.getLabel());
            }
        } catch (Exception ex) {
            System.debug('Describe failure: ' + ex.getMessage());
        }

        String desiredLabel = 'Initial Registration';
        String picklistToUse = null;
        if (allowedServiceTypes.contains(desiredLabel)) {
            picklistToUse = desiredLabel;
        } else if (!allowedServiceTypes.isEmpty()) {
            picklistToUse = allowedServiceTypes.iterator().next();
        }

        List<Service_History__c> histories = new List<Service_History__c>();
        Set<Id> processedVehicleIds = new Set<Id>();

        for (Vehicle__c v : vehiclesToProcess) {
            Service_History__c sh = new Service_History__c();
            sh.Vehicle__c = v.Id;
            sh.Service_Date__c = Date.today();
            if (v.Mileage__c != null) sh.Mileage_at_Service__c = v.Mileage__c;
            if (picklistToUse != null) sh.Service_Type__c = picklistToUse;
            // Notes__c field remove kardia agar nahi hai to
            // sh.Notes__c = 'Created automatically by trigger';
            histories.add(sh);
            processedVehicleIds.add(v.Id);
        }

        if (!histories.isEmpty()) {
            try {
                insert histories;
            } catch (DmlException ex) {
                System.debug('Error inserting Service History records: ' + ex.getMessage());
                throw ex;
            }
        }

        // Notifications only for newly created histories
        try {
            VehicleNotificationService.sendInitialServiceEmails(processedVehicleIds);
        } catch (Exception ex) {
            System.debug('Error sending initial service emails: ' + ex.getMessage());
        }
    }
}