public class MaintenanceRequestTriggerHandler extends TriggerHandler{

    public override void beforeUpdate(){
         MaintenanceRequestService.createNewMaintenanceRequest(Trigger.new);
    }
}