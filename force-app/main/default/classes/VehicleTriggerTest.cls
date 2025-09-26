@isTest
private class VehicleTriggerTest {
    @isTest static void testCreateInitialServiceHistory() {
        // Prepare test vehicle (use fields present in your schema)
        Vehicle__c v = new Vehicle__c();
        v.Vehicle_Identification_Number__c = 'TESTVIN12345678901';
        v.License_Plate__c = 'UNIT-TEST-01';
        v.Mileage__c = 1500;

        Test.startTest();
            insert v;
        Test.stopTest();

        // Assert Service History got created
        List<Service_History__c> shList = [
            SELECT Id, Vehicle__c, Mileage_at_Service__c, Service_Type__c
            FROM Service_History__c
            WHERE Vehicle__c = :v.Id
        ];
        System.assert(shList.size() > 0, 'Service History should be created by trigger');
        // If mileage was set, it should be copied
        if (v.Mileage__c != null) {
            System.assertEquals(v.Mileage__c, shList[0].Mileage_at_Service__c, 'Mileage must be copied to Service History');
        }
    }
}