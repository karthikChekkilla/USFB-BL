import { LightningElement,api,wire,track } from 'lwc';
import IS_READONNLY from "@salesforce/schema/Loan_Application__c.IsReadOnly__c";
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import getFinancialData from '@salesforce/apex/UB_FinancialCalcutionHelper.getFinancialData';
import createFinancials from '@salesforce/apex/UB_FinancialCalcutionHelper.createFinancials';
import { CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
const fields = [IS_READONNLY];


export default class Ub_Financials extends LightningElement {

 @api recordId;
 financialData = [];
 @track showSpinner ;
 @track readonlyField = false

 get FinancialTypeOptions() {
    return [
        { label: 'Provisional', value: 'Provisional' },
        { label: 'Audited', value: 'Audited' }
        
    ];
}

 @wire(getRecord, { recordId: "$recordId", fields })
   loadFields({error, data}){
    if(data){
            this.readonlyField = getFieldValue(data, IS_READONNLY);
            console.log('readonlyField   ',this.readonlyField);
        }
    }

 @wire(CurrentPageReference)
 getLAFId(currentPageReference) {
     if (currentPageReference) {
         this.recordId = currentPageReference.attributes.recordId;
         this.getFinancialRecords();
     }
 }


 getFinancialRecords(){
    this.showSpinner = true;
    console.log('lOANNN111111111111111  ',this.recordId);
    getFinancialData({'loanId' :this.recordId})
        .then((data => {
            if (data) {
                this.financialData = JSON.parse(data);
                this.showSpinner = false;
                console.log('this.financialData ', JSON.stringify(this.financialData ));
            }
        })).catch((err) => {
            console.log('Error in returnRelatedRecords = ', err.message);
        });
  }

  inputOnchange(event){
    console.log('LOANID   ',this.recordId);
    const matrixFinancial = ["NW42", "Turnover43", "Cash Profit %44","Net Profit %45"];
    var outerIndex = event.target.dataset.sequence;
    var isMatrixHorizonal = false;
    var InnerIndex = event.target.dataset.code -1  ;
    console.log('VALUEEEEEE  ',event.target.value);
    console.log('ROWWWWWWWW  ',outerIndex);
    console.log('LINE INDEXXXXXXXx  ',event.target.dataset.code);
    var InnerIndex = event.target.dataset.code -1  ;
    console.log('InnerIndex   ',InnerIndex) ;
    console.log('LABELLLLL111  ',  this.financialData[event.target.dataset.sequence]);
    console.log('LABELLLLL  ',  this.financialData[event.target.dataset.sequence].label);
    console.log('FIELD API NAMEEEEE  ', event.target.dataset.id);
    let financialDataTemp = [...this.financialData];
    financialDataTemp[outerIndex].labelwrapperList[InnerIndex].answer = event.target.value;
    this.financialData =  [...financialDataTemp];
    // code to calculate formula and update it in formula field which is returning wrapper.
    try {
        // loop on parent
        for (let fIndex = 1; fIndex < this.financialData.length; fIndex++) {
            let matrixWrapperObj =  { ...this.financialData[fIndex].labelwrapperList[InnerIndex]} ;
            if(matrixWrapperObj.formula != null){
                matrixWrapperObj.DecodedFormula = matrixWrapperObj.formula;
                let financialDataTemp = [...this.financialData];
                financialDataTemp[fIndex].labelwrapperList[InnerIndex].DecodedFormula = financialDataTemp[fIndex].labelwrapperList[InnerIndex].formula;
                this.financialData =  [...financialDataTemp];
               // code to evaluate horizontal formula
                if(matrixFinancial.includes(this.financialData[fIndex].label + fIndex)) {
                    console.log('ROW INDEX ', fIndex);
                    console.log('ROW Label ',this.financialData[fIndex].label);
                    console.log('ARRAY MATRIX INDEXXXXXXX  ',matrixFinancial.includes(this.financialData[fIndex].label + fIndex));
                    for (let i = 1; i < this.financialData.length; i++) {
                        let answer = (this.financialData[i].labelwrapperList[InnerIndex].answer) ? this.financialData[i].labelwrapperList[InnerIndex].answer : 0;
                        
                        console.log('checkkk   ',answer, 'ROWWWW   ','{!' + (i) + '}');
                        console.log('DECODE FORMULA   ',matrixWrapperObj.DecodedFormula );
                        console.log('INCLUDEEEEE  ', matrixWrapperObj.DecodedFormula.includes('{!' + (i) + '}'));
                        if(matrixWrapperObj.DecodedFormula != null && matrixWrapperObj.DecodedFormula.includes('{!' + (i) + '}')) {
                            var flag;
                            console.log('FLAGGGGGGG   ');
                            // code to check first colom index or provisional then don't execute formula.
                            if(InnerIndex == 0 || this.financialData[0].labelwrapperList[InnerIndex].answer == 'Provisional') {
                                console.log('11111111111');
                                isMatrixHorizonal = true;
                                matrixWrapperObj.DecodedFormula = 0; 
                                break;
                            } else {
                                console.log('DECODE FORMULAAAA FLAG1111 ', JSON.stringify(matrixWrapperObj) );
                                console.log('Financial VALUE on horizontal formula ', this.financialData[0].labelwrapperList[InnerIndex].answer );
                                flag = this.financialData[i].labelwrapperList[InnerIndex-1].answer;
                                console.log('222222222222222',flag);
                                matrixWrapperObj.DecodedFormula = matrixWrapperObj.DecodedFormula.replaceAll('{!' + (i) + '}', answer);
                            }
                            console.log('DECODE FORMULAAAA FLAG ', JSON.stringify(matrixWrapperObj) );
                        }
                    }
                 }
                // code to evaluate vertical formula.
                 else {
                    for (let i = 1; i < this.financialData.length; i++) {
                        let answer = (this.financialData[i].labelwrapperList[InnerIndex].answer) ? this.financialData[i].labelwrapperList[InnerIndex].answer : 0;
                        if(matrixWrapperObj.DecodedFormula != null && matrixWrapperObj.DecodedFormula.includes('{!' + (i) + '}')) {
                            console.log('ROWWWWWW    ',fIndex);
                            matrixWrapperObj.DecodedFormula = matrixWrapperObj.DecodedFormula.replaceAll('{!' + (i) + '}', answer);
                            console.log('DECODE FORMULAAAA  NORMAL ', JSON.stringify(matrixWrapperObj) );
                        }
                    }
                }
            console.log('FINAL Decode Formula VALYEEEEE  ',matrixWrapperObj.DecodedFormula);
            // code to evaluate on vertical  decode formula .
            if (!isMatrixHorizonal && !matrixWrapperObj.DecodedFormula.includes('{!')) {
                matrixWrapperObj.answer = (eval(matrixWrapperObj.DecodedFormula)).toFixed(2);
                console.log('ANSWERRRRRRRRRR  0000000', matrixWrapperObj.answer);
                console.log('FINAL VALYEEEEE  without flag',matrixWrapperObj.answer);
                if(matrixWrapperObj.answer != 0 && matrixWrapperObj.answer != Infinity) {
                    let financialDataTemp = [...this.financialData];
                    financialDataTemp[fIndex].labelwrapperList[InnerIndex].answer = matrixWrapperObj.answer ;
                    this.financialData =  [...financialDataTemp];
                }
            } 
            // code to evaluate on Horizontal  decode formula .
            else {
                matrixWrapperObj.answer = (eval(matrixWrapperObj.DecodedFormula)).toFixed(2);
                console.log('ANSWERRRRRRRRRR  1111111', matrixWrapperObj.answer);
                console.log('FINAL VALYEEEEE  with flag',matrixWrapperObj.answer);
                if(matrixWrapperObj.answer != 0 && matrixWrapperObj.answer != Infinity) {
                    console.log('matrixWrapperObj.answer  AAAAAAAAA  ',matrixWrapperObj.answer)
                    let financialDataTemp = [...this.financialData];
                    financialDataTemp[fIndex].labelwrapperList[InnerIndex].answer = matrixWrapperObj.answer ;
                    this.financialData =  [...financialDataTemp];
                } 
                // code to handle condition when user change financial type then old value will change.
                else if(matrixWrapperObj.answer == 0 && this.financialData[0].labelwrapperList[InnerIndex].answer == 'Provisional') {
                    let financialDataTemp = [...this.financialData];
                    console.log('matrixWrapperObj.answer  BBBBBBBBBBBB  ',matrixWrapperObj.answer)

                    financialDataTemp[fIndex].labelwrapperList[InnerIndex].answer = undefined ;
                    this.financialData =  [...financialDataTemp];
                 }

            }
        }
    }
    console.log('this.financialData  ',JSON.stringify(this.financialData));
    } catch (err) {
        console.error('ERROOOOOOOORRRRRRRR=', err);
        console.error('MESSSAGEEEE=', err.message);
    }

  }



  clickHandler(){
    this.showSpinner = true;
    console.log('qqqq');
    console.log('this.matrixData', JSON.stringify(this.financialData) );
     createFinancials({ 'loanId' :this.recordId, financialData: JSON.stringify(this.financialData) })
      .then((result => {
        console.log('result  ',result);
          if (result) {
            this.showSpinner = false;
              console.log('result :', result);
              if(result.includes('success')) {
                this.showToastMsg('success', 'Financials are submitted successfully' , 'success');

              } else if(result.includes('failure')) {
                this.showToastMsg('error', 'Error , please check' , 'error');

              } else {
                this.showToastMsg('error', result , 'error');

              }
              
          }
      })).catch((er) => {
          console.log('Error  = ', er);
          console.log('Error  = ', er.message);
      });
  
}

showToastMsg(title, message, variant){
    this.dispatchEvent(
        new ShowToastEvent({
            title   : title,
            message : message,
            variant : variant,
            mode : "pester"
        })
    )
}

}