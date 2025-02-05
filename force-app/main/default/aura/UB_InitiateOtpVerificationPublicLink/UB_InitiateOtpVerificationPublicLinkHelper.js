({
    // this is a helper method used to set the Page Message..
    showPageMessage : function(component,iconName,pageMessage,variant) {
        component.set('v.showUI',false);
        component.set('v.iconName',iconName);
        component.set('v.pageMessage',pageMessage);
        component.set('v.variantType',variant);        
    },
    // this method is used to set the visibility of Page Message Error/Success
    postProcessingMessage : function(component,event) {
        $A.util.addClass(component.find('pageMessageBackground'), 'changepageMessageBackgroundStyle');
        component.set('v.showUI',false);
        component.set('v.spinner',false); 
    }
})