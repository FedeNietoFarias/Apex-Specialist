trigger MaintenanceRequest on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(Trigger.isUpdate && Trigger.isAfter){
        MaintenanceRequestHelper.updateWorkOrders(Trigger.New, Trigger.OldMap);
    }
}