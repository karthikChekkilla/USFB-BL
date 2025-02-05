import { LightningElement,api,wire,track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import getVehicleDetails from '@salesforce/apex/UB_RepaymentSchedule.getVehicleDetails';
import repaymentScheduleData from '@salesforce/apex/UB_RepaymentSchedule.repaymentScheduleData';


export default class Ub_RepaymentSchedule extends LightningElement {

    @api recordId;
    @track showSpinner ;
    vehiclesData = [];
    vehicleOptions = [] ;
    @track repaymentScheduleData = [];
    @track isRepaymentTableShow = false
     
    @track selectedVehicle = {
        'vehicleName' : undefined,
        'tenure' : undefined,
        'roi' : undefined,
        'vehicleCost' : undefined,
        'emi' : undefined
    };



    @wire(CurrentPageReference)
    getLAFId(currentPageReference) {
        console.log('currentPageReference  ',currentPageReference);
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            console.log('LOAN ID  ',this.recordId);
            this.getVehicles();
        }
    }

    getVehicles(){
        console.log('1111111111');
        getVehicleDetails({'loanApplicationId' :this.recordId})
        .then((data => {
            if (data) {
                this.vehiclesData = data;
                console.log('DATAAAAAAAA  ',this.vehiclesData);
                console.log('this.financialData ', JSON.stringify(data));
                for (var key in this.vehiclesData) {
                    console.log('keykeykey ',key);
                    console.log('this.vehiclesData ',this.vehiclesData[key]);
                    var item = {
                        label: this.vehiclesData[key].Name,
                        value: this.vehiclesData[key].Id + ':' + this.vehiclesData[key].Name
                    };
                    this.vehicleOptions = [...this.vehicleOptions, item];
                }
                console.log('this.vehicleOptions ', JSON.stringify(this.vehicleOptions));
            }
        })).catch((err) => {
            console.log('Error in returnRelatedRecords = ', err.message);
        });
    }
    handleInputChange(event) {
        console.log('NAMEEE  ',event.target.name);
        console.log('VALUE  ',event.target.value);
        if(event.target.name == 'ROI') {
            this.selectedVehicle.roi = event.target.value;
        } else if(event.target.name == 'Tenure') {
            this.selectedVehicle.tenure = event.target.value;
        } else if (event.target.name == 'VehicleCost') {
            this.selectedVehicle.vehicleCost = event.target.value;
        } 
        console.log('this.selectedVehicle  ',    JSON.stringify(this.selectedVehicle) );

    }

    handleOptionChange(event) {
        this.selectedVehicle = (event.target.value).split(':')[1] ;
        console.log('this.selectedVehicle 000000000000 ',    JSON.stringify(this.selectedVehicle) );
        for (var key in this.vehiclesData) {
            if(this.vehiclesData[key].Id == (event.target.value).split(':')[0]) {
                this.selectedVehicle = {
                    'tenure' : this.vehiclesData[key].Tenure__c,
                    'roi' : this.vehiclesData[key].ROI__c,
                    'vehicleCost' : this.vehiclesData[key].Vehicle_Cost__c,
                   
                }
            }
        }
       
        console.log('this.selectedVehicle  ',    JSON.stringify(this.selectedVehicle) );
        /*
        */

    }

    handleSave() {
        this.showSpinner = true;
        this.isRepaymentTableShow = true;
        repaymentScheduleData({tenure: this.selectedVehicle.tenure, roi: this.selectedVehicle.roi, vehicleCost: this.selectedVehicle.vehicleCost })
            .then(result => {
                this.repaymentScheduleData = JSON.parse(result);
              
                console.log(' this.isRepaymentTableShow  ',this.isRepaymentTableShow);
                this.showSpinner = false;
            })
            .catch(e => {
                console.log('Exception is >>>>', e.message);
            }); 
    }

    closeQuickAction() {
        this.showSpinner = true;
        this.dispatchEvent(new CloseActionScreenEvent());
        this.showSpinner = false;
    }

}