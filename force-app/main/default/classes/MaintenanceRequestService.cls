public class MaintenanceRequestService {
    public static void createNewMaintenanceRequest(List<Case> sfMRs) {
        List<Case> newRequests = new List<Case>();
        Map<Id, Case> oldToNewRequestMap = new Map<Id, Case>();

        // Obtener todos los Equipment_Maintenance_Item__c relacionados con los Maintenance Requests entrantes
        Map<Id, List<Equipment_Maintenance_Item__c>> equipmentByRequestId = new Map<Id, List<Equipment_Maintenance_Item__c>>();
        for (Equipment_Maintenance_Item__c item : [
            SELECT Equipment__c, Equipment__r.Maintenance_Cycle__c, Maintenance_Request__c
            FROM Equipment_Maintenance_Item__c
            WHERE Maintenance_Request__c IN :sfMRs
        ]) {
            if (!equipmentByRequestId.containsKey(item.Maintenance_Request__c)) {
                equipmentByRequestId.put(item.Maintenance_Request__c, new List<Equipment_Maintenance_Item__c>());
            }
            equipmentByRequestId.get(item.Maintenance_Request__c).add(item);
        }

        // Crear los nuevos Maintenance Requests
        for (Case sfMR : sfMRs) {
            if (sfMR.Status == 'Closed' && (sfMR.Type == 'Repair' || sfMR.Type == 'Routine Maintenance')) {
                List<Equipment_Maintenance_Item__c> relatedItems = equipmentByRequestId.get(sfMR.Id);
                Integer shortestCycle = 99999;

                if (relatedItems != null) {
                    for (Equipment_Maintenance_Item__c item : relatedItems) {
                        if (item.Equipment__r.Maintenance_Cycle__c != null) {
                            Integer cycle = item.Equipment__r.Maintenance_Cycle__c.setScale(0, RoundingMode.HALF_UP).intValue();
                            if (cycle < shortestCycle) {
                                shortestCycle = cycle;
                            }
                        }
                    }
                }

                if (shortestCycle == 99999) {
                    shortestCycle = 0;
                }

                Case newMR = new Case();
                newMR.Subject = sfMR.Subject;
                newMR.Type = 'Routine Maintenance';
                newMR.Vehicle__c = sfMR.Vehicle__c;
                newMR.ProductId = sfMR.ProductId;
                newMR.Date_Reported__c = Date.today();
                newMR.Date_Due__c = Date.today().addDays(shortestCycle);
                newRequests.add(newMR);
                oldToNewRequestMap.put(sfMR.Id, newMR);
            }
        }

        // Insertar los nuevos Maintenance Requests
        if (!newRequests.isEmpty()) {
            insert newRequests;

            // Mapear old → new ID
            Map<Id, Id> oldToNewIdMap = new Map<Id, Id>();
            Integer index = 0;
            for (Case sfMR : sfMRs) {
                if (oldToNewRequestMap.containsKey(sfMR.Id)) {
                    oldToNewIdMap.put(sfMR.Id, newRequests[index].Id);
                    index++;
                }
            }

            // Clonar Equipment_Maintenance_Item__c
            List<Equipment_Maintenance_Item__c> itemsToInsert = new List<Equipment_Maintenance_Item__c>();
            for (Id oldMRId : oldToNewIdMap.keySet()) {
                List<Equipment_Maintenance_Item__c> oldItems = equipmentByRequestId.get(oldMRId);
                if (oldItems != null) {
                    for (Equipment_Maintenance_Item__c item : oldItems) {
                        Equipment_Maintenance_Item__c newItem = new Equipment_Maintenance_Item__c();
                        newItem.Equipment__c = item.Equipment__c;
                        newItem.Maintenance_Request__c = oldToNewIdMap.get(oldMRId);
                        itemsToInsert.add(newItem);
                    }
                }
            }

            if (!itemsToInsert.isEmpty()) {
                insert itemsToInsert;
            }
        }
    }
}
