@isTest
private class PartsInventoryTriggerHandlerTest {
    
    @isTest
    static void testPartsValidation() {
        Parts_Inventory__c invalidPart = new Parts_Inventory__c(
            Name = 'INVALID001',
            Part_Name__c = 'Invalid Part',
            Current_Stock__c = -5, // Negative stock
            Minimum_Stock__c = -2, // Negative minimum
            Unit_Cost__c = -10.99  // Negative cost
        );
        
        Test.startTest();
        
        try {
            insert invalidPart;
            System.assert(false, 'Should have thrown validation error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('cannot be negative'));
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testLowStockAlert() {
        Test.startTest();
        
        Parts_Inventory__c part = new Parts_Inventory__c(
            Name = 'ALERT001',
            Part_Name__c = 'Alert Part',
            Current_Stock__c = 20,
            Minimum_Stock__c = 10,
            Unit_Cost__c = 25.99
        );
        insert part;
        
        // Update to trigger low stock alert
        part.Current_Stock__c = 8;
        update part;
        
        Test.stopTest();
        
        // Verify alert task was created
        List<Task> alertTasks = [
            SELECT Subject
            FROM Task
            WHERE Subject LIKE 'LOW STOCK:%'
        ];
        
        System.assertEquals(1, alertTasks.size());
        System.assert(alertTasks[0].Subject.contains('Alert Part'));
    }
}