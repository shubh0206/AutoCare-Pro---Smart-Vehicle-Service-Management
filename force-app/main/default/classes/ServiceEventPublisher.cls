public class ServiceEventPublisher {
    
    // Publish service completion event - CORRECTED EVENT NAME
    public static void publishServiceCompletion(List<WorkOrder> completedOrders) {
        List<Service_Completion_Event__e> events = new List<Service_Completion_Event__e>();
        
        for (WorkOrder wo : completedOrders) {
            Service_Completion_Event__e event = new Service_Completion_Event__e();
            event.Work_Order_Id__c = wo.Id;
            event.Customer_Name__c = wo.Account?.Name;
            events.add(event);
        }
        
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
    
    // Simple method to test event publishing - CORRECTED EVENT NAME
    public static void testPublishEvent(String workOrderId, String customerName) {
        Service_Completion_Event__e testEvent = new Service_Completion_Event__e();
        testEvent.Work_Order_Id__c = workOrderId;
        testEvent.Customer_Name__c = customerName;
        
        EventBus.publish(testEvent);
    }
}