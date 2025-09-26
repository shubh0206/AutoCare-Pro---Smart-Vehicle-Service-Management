public class VINDecoderService {
    
    // Simple VIN decoder callout
    @future(callout=true)
    public static void decodeVIN(Set<Id> vehicleIds) {
        
        List<Vehicle__c> vehicles = [
            SELECT Id, Vehicle_Identification_Number__c, Make__c, Model__c
            FROM Vehicle__c 
            WHERE Id IN :vehicleIds 
            AND Vehicle_Identification_Number__c != null
        ];
        
        List<Vehicle__c> vehiclesToUpdate = new List<Vehicle__c>();
        
        for (Vehicle__c vehicle : vehicles) {
            try {
                // Make API call
                HttpRequest req = new HttpRequest();
                String vin = vehicle.Vehicle_Identification_Number__c;
                req.setEndpoint('callout:VIN_Decoder_Service/vehicles/DecodeVinValues/' + vin + '?format=json');
                req.setMethod('GET');
                req.setTimeout(10000); // 10 second timeout
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    // Parse response (simplified)
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    
                    if (jsonResponse.containsKey('Results')) {
                        List<Object> results = (List<Object>) jsonResponse.get('Results');
                        if (!results.isEmpty()) {
                            Map<String, Object> vehicleData = (Map<String, Object>) results[0];
                            
                            // Update vehicle with decoded information
                            if (String.isBlank(vehicle.Make__c)) {
                                String make = (String) vehicleData.get('Make');
                                if (!String.isBlank(make)) {
                                    vehicle.Make__c = make;
                                }
                            }
                            
                            if (String.isBlank(vehicle.Model__c)) {
                                String model = (String) vehicleData.get('Model');
                                if (!String.isBlank(model)) {
                                    vehicle.Model__c = model;
                                }
                            }
                            
                            vehiclesToUpdate.add(vehicle);
                        }
                    }
                }
                
            } catch (Exception e) {
                System.debug('VIN decode error for ' + vehicle.Id + ': ' + e.getMessage());
                // Continue with other vehicles even if one fails
            }
        }
        
        // Update vehicles with decoded information
        if (!vehiclesToUpdate.isEmpty()) {
            try {
                update vehiclesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating vehicles: ' + e.getMessage());
            }
        }
    }
    
    // Helper method to trigger VIN decoding
    public static void triggerVINDecode(List<Vehicle__c> newVehicles) {
        Set<Id> vehicleIds = new Set<Id>();
        
        for (Vehicle__c vehicle : newVehicles) {
            if (!String.isBlank(vehicle.Vehicle_Identification_Number__c)) {
                vehicleIds.add(vehicle.Id);
            }
        }
        
        if (!vehicleIds.isEmpty()) {
            decodeVIN(vehicleIds);
        }
    }
}