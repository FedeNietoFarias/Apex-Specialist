trigger MaintenanceRequest on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new MaintenanceRequestTriggerHandler().run();
}