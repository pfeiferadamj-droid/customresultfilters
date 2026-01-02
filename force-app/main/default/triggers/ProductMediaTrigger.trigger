trigger ProductMediaTrigger on ProductMedia (before insert, before update) {
    ProductMediaTriggerHandler.syncContentKeys(Trigger.new);
}
