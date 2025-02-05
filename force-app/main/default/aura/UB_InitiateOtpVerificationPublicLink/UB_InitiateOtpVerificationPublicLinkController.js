({
    // This Method is used to fetch the Aadhaar OTP status whether the OTP has been sent
    // for the particular Applicant/CO-Applicant or not.
    doInit: function(cmp,event,helper) {
        // Spinner Started        
        cmp.set('v.spinner',true);
        // Calling fetchOtpStatus Method
        console.log('Loan Application Id ',cmp.get('v.recordId'));
        var action = cmp.get("c.fetchOtpStatus");
        action.setParams({
            "verificationId" : cmp.get('v.recordId')
        });  
        // Call back method
        action.setCallback(this, function(response) {
            var state = response.getState();
            var responseValue = response.getReturnValue(); 
            console.log('init result',responseValue);
            if(responseValue == 'Success'){                
                cmp.set('v.showUI',true);
                $A.util.addClass(cmp.find('formBackground'), 'changeformBackgroundStyle');
                cmp.set('v.spinner',false);
                return;
            }
            else {
                helper.showPageMessage(cmp,'utility:error',responseValue,'error');
                helper.postProcessingMessage(cmp,event);             
            }            
        });        
        // Enqueue Action
        $A.enqueueAction(action);
    },
    
    // OnRender method is used to handle all the change activities on the Otp Input Fields
    onRender : function(component, event, helper) {
        const inputs = document.querySelectorAll("input"),
            button = component.find("button");
        
        // iterate over all inputs
        inputs.forEach((input, index1) => {
            
            input.addEventListener("keyup", (e) => {
            console.log('input->',index1 );
            
            const currentInput = input,
            nextInput = input.nextElementSibling,
            prevInput = input.previousElementSibling;
            
            // if the value has more than one character then clear it
            if (currentInput.value.length > 1) {
            currentInput.value = "";
            return;
        }
            // if the next input is disabled and the current value is not empty
            //  enable the next input and focus on it
            console.log('nextInput',nextInput);
            debugger;
            
            if (nextInput != null && nextInput.hasAttribute("disabled") && currentInput.value !== "") {
            console.log('inside if');
            nextInput.removeAttribute("disabled");
            console.log('after disabled');
            nextInput.focus();
        }
            
            // if the backspace key is pressed
            if (e.key === "Backspace") {
            // iterate over all inputs again
            inputs.forEach((input, index2) => {
            // if the index1 of the current input is less than or equal to the index2 of the input in the outer loop
            // and the previous element exists, set the disabled attribute on the input and focus on the previous element
            if (index1 <= index2 && prevInput) {
            input.setAttribute("disabled", true);
            input.value = "";
            prevInput.focus();
        }
        });
        }
            //if the six input( which index number is 5) is not empty and has not disable attribute then
            //add active class if not then remove the active class.
            console.log('inputs[6].disabled',inputs[5].disabled);
            if (!inputs[5].disabled && inputs[5].value !== "" && component.get('v.consent')) {
            $A.util.addClass(button, "active");
            return;
        }
            $A.util.removeClass(button,"active");
        });
            
        });                     
            //focus the first input which index is 0 on window load
            window.addEventListener("load", () => inputs[0].focus());        
        },
            
            // This method is used to handle the OTP Submission and Invocation of the Aadhaar XML File
            // API for the given LAF.
            handleSubmit : function(component, event, helper) { 
                let consent = component.get('v.consent');
                if( consent == false )
                {
                    alert('Please given Consent before submit the OTP')
                    return;
                }
                else if( consent == true )
                {
                    component.set('v.spinner',true);
                    let otpString = '';
                    const inputs = document.querySelectorAll("input");
                    inputs.forEach(input => { 
                        otpString +=input.value; 
                    });
                        console.log('OTP STRING ###',otpString);
                        console.log('Record Id inside ##',component.get('v.recordId'));
                        //if(otpString.length > 0)
                        //otpString = otpString.substring((otpString.length - 6), otpString.length);                                         
                        // call the Aadhaar XML File API ....
                        var action = component.get("c.validateVerification");
                        // Call back method
                        action.setParams({
                        "verificationId" : component.get('v.recordId'),
                        "otp" : otpString
                    });          
                    
                    action.setCallback(this, function(response) {   
                        console.log('API RESPONSE ##', JSON.parse(response.getReturnValue()));
                        var state = response.getState(); // get the response state
                        let apiResponse = JSON.parse(response.getReturnValue());
                        if(apiResponse != null || apiResponse != undefined)
                        {
                            if(state == 'SUCCESS') {                     
                                if(apiResponse.statusCode == '200')
                                {
                                    
                                    if(apiResponse.ResponseMap['statusCode'] == 101  && apiResponse.ResponseMap['result'] && apiResponse.ResponseMap['result']['message']){
                                        helper.showPageMessage(component,'action:approval',apiResponse.ResponseMap['result']['message'],'success');
                                        helper.postProcessingMessage(component,event);
                                        window.location.replace("https://www.utkarsh.bank/");
                                        
                                    }
                                    else if(apiResponse.ResponseMap['statusCode']  != 101)
                                    {
                                        console.log('inside here not 101');
                                        let toastMessage;
                                        if(apiResponse.ResponseMap['statusCode'] == 102){
                                            toastMessage = 'OTP mismatch/OTP expired';
                                        }
                                        else if(apiResponse.ResponseMap['statusCode'] == 104){
                                            toastMessage = 'File Already downloaded/Max retries exceeded';
                                        }
                                        else if(apiResponse.ResponseMap['statusCode'] == 105){
                                            toastMessage = 'Access Key is expired/Missing Consent';
                                        }
                                        else{
                                            toastMessage = 'Aadhaar Authentication Failed';   
                                        }
                                        helper.showPageMessage(component,'utility:error',toastMessage,'error');
                                        helper.postProcessingMessage(component,event);
                                    }
                                    
                                }
                                else if(apiResponse.statusCode != '200' && apiResponse.ResponseMap['error'])
                                {                                   
                                    console.log('inside here not 200');  
                                    helper.showPageMessage(component,'utility:error',apiResponse.ResponseMap['error'],'error');
                                    helper.postProcessingMessage(component,event);
                                }
                            }
                            else if (state === 'ERROR') {
                                console.log('inside here ERROR');
                                var errors = response.getError();
                                if (errors) {
                                    if (errors[0] && errors[0].message) {
                                        helper.showPageMessage(component,'utility:error',errors[0].message,'error');
                                        helper.postProcessingMessage(component,event);                                                                             
                                    }
                                } else {
                                    helper.showPageMessage(component,'utility:error','Unknown error','error');
                                    helper.postProcessingMessage(component,event); 
                                    console.log("Unknown error");
                                }
                            }
                        }                
                        else
                        {
                            console.log('inside null');  
                            helper.showPageMessage(component,'utility:error','An Error while fetching Response','error');
                            helper.postProcessingMessage(component,event);                             
                        }                       
                    });
                    
                    // Enqueue Action
                    $A.enqueueAction(action);
                }    
                
            },
            
            // on change method for Consent Checkbox
            checkboxSelect: function(cmp, event, helper) {
                console.log(event.getSource().get('v.checked'));
                cmp.set("v.consent",event.getSource().get('v.checked'));
                console.log('checkbox value ',event.getSource().get('v.checked'));
                let otpString = '';
                const inputs = document.querySelectorAll("input");
                inputs.forEach(input => { 
                    otpString +=input.value; 
                });
                    console.log('OTP STRING ###',otpString);
                    if(otpString.length > 0)
                    otpString = otpString.substring((otpString.length - 6), otpString.length);   
                    // if otp is being entered and consent checkbox is checked then the button will be active otherwise button will be disabled                                      
                    if(otpString.length == 6 && event.getSource().get('v.checked'))
                    {  
                    console.log('inside if');
                    let button = cmp.find('button');
                    $A.util.addClass(button, "active");
                }
                    else
                    {
                    console.log('inside else');
                    let button = cmp.find('button');
                    $A.util.removeClass(button, "active");
                }
                },
             /* 
                Author : Zafaruddin
                Description :  method for only number enter for otp
                Date : 30/04/2024
             */
            inputOTPSelect: function(cmp, event, helper) {
                const inputs = document.querySelectorAll("input");
                inputs.forEach(input => { 
                    console.log('input.value  ',input.value);
                    if (isNaN(input.value)) 
                      {
                        helper.showPageMessage(cmp,'utility:error','Only Number can be enter.','error');
                		helper.postProcessingMessage(cmp,event);
                      }
                });

                },
                    
})