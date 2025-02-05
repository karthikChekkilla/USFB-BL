import { LightningElement, track, wire, api  } from 'lwc';
export default class ManualDeviation extends LightningElement {
    @track showSpinner = false;
    @track isNewButtonVisible = true;
    @track isFlowInvoked = false;
    @track inputVariables = [];
    @api recordId;
    @api objectApiName;

    connectedCallback() {
        console.log('recordId-> ', this.recordId);
        console.log('objectApiName-> ', this.objectApiName); 
    }

    handleClick(event) {
        this.inputVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: this.recordId
                }
           ];
        this.isFlowInvoked = true;
    }

    handleStatusChange(event){

    }
    
    handleClose(event){
        this.isFlowInvoked = false;
    }

}