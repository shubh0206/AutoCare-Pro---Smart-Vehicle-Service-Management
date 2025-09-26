public class WorkOrderTriggerHandler {
    
    public static void processCompletedWorkOrders(List<WorkOrder> completedOrders) {
        if (completedOrders == null || completedOrders.isEmpty()) return;
        
        sendCompletionNotifications(completedOrders);
        createFollowUpTasks(completedOrders);
        ServiceEventPublisher.publishServiceCompletion(completedOrders);
    }
    
    public static void sendCompletionNotifications(List<WorkOrder> completedOrders) {
        if (completedOrders == null || completedOrders.isEmpty()) return;
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (WorkOrder wo : completedOrders) {
            if (wo.ContactId != null || wo.AccountId != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setSubject('Work Order Completed: ' + wo.WorkOrderNumber);
                email.setPlainTextBody('Your work order has been completed. Thank you for your business!');
                
                if (wo.Contact?.Email != null) {
                    email.setToAddresses(new String[]{wo.Contact.Email});
                    emails.add(email);
                }
            }
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Error sending email notifications: ' + e.getMessage());
            }
        }
    }
    
    public static void createFollowUpTasks(List<WorkOrder> completedOrders) {
        if (completedOrders == null || completedOrders.isEmpty()) return;
        
        List<Task> followUpTasks = new List<Task>();
        
        for (WorkOrder wo : completedOrders) {
            Task followUpTask = new Task();
            followUpTask.WhatId = wo.Id;
            followUpTask.Subject = 'Follow-up for completed work order: ' + wo.WorkOrderNumber;
            followUpTask.Status = 'Not Started';
            followUpTask.Priority = 'Normal';
            followUpTask.ActivityDate = Date.today().addDays(7);
            followUpTasks.add(followUpTask);
        }
        
        if (!followUpTasks.isEmpty()) {
            try {
                insert followUpTasks;
            } catch (Exception e) {
                System.debug('Error creating follow-up tasks: ' + e.getMessage());
            }
        }
    }
}