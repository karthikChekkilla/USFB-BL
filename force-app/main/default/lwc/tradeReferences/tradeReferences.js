import { LightningElement, api, track } from 'lwc';
export default class TradeReferences extends LightningElement {
    @api recordId;
    @track inputVariables = [];
    @track isFlowInvoked = false;

    handleClick(event) {
        this.isFlowInvoked = true;
        this.inputVariables = [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleClose(){
         this.isFlowInvoked = false;
    }

    handleStatusChange(event){
        console.log('event-> ', event.detail.status);
        if (event.detail.status === 'FINISHED') {
            this.isFlowInvoked = false;
            window.location.reload();
        }
    }

}