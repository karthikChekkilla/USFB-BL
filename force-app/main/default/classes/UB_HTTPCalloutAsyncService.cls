/*
* Application Name:- UB_HTTPCalloutAsyncService
* License:- 
* Created:- 21-03-2024
* Last Updated:- 
* Description:- This is the service class for performing HTTP Callouts
* Contributors:-
*    1. Lakshya Verma 
*/
public class UB_HTTPCalloutAsyncService {

    List<String> requestLabels;
    Transient List<HTTPRequest> httpRequests;
    Transient Map<String, HTTPRequest> requestMap;
    Integer requestTimeout;
    public static final Integer CONTINUATION_LIMIT = 3;
    public static final String CONTINUATION_STATE = 'Continuation State';
    String continuationState;
    
    /*
* Getter and Setters - Begin
*/
    public List<String> getRequestLabels() {
        return requestLabels;
    }
    
    public Integer getRequestTimeout() {
        return requestTimeout;
    }
    
    public void setRequestTimeout(Integer requestTimeout) {
        this.requestTimeout = requestTimeout;
    }
    
    public String getContinuationState() {
        return continuationState;
    } 
    
    public void setContinuationState(String continuationState) {
        this.continuationState = continuationState;
    }
    
    public Map<String, HTTPRequest> getRequestMap() {
        return requestMap;
    }
    
    public void setRequestMap(Map<String, HTTPRequest> requestMap) {
        this.requestMap = requestMap;
    }
    /*
* Getter and Setters - End
*/
    
    /*
* Method to initialize data members
*/
    void initialize(Integer timeout) {
        requestLabels = new List<String>();
        requestTimeout = timeout;
        continuationState = CONTINUATION_STATE;
        if(requestTimeout == null) {
            requestTimeout = 120;
        }
    }
    
    /*
    * Constructor
    */
    public UB_HTTPCalloutAsyncService(Integer requestTimeout, List<HTTPRequest> httpRequests) {
        this.httpRequests = new List<HTTPRequest>();
        initialize(requestTimeout);
        if((httpRequests != null) && (!httpRequests.isEmpty())) {
            if(httpRequests.size() > CONTINUATION_LIMIT) {
                throw new UB_LogException(UB_ConstantsUtil.CONTINUATION_LIMIT_EXCEEDED);
            }
            this.httpRequests = httpRequests;
        }
    }
    
    /*
    * Constructor with custom metadata
    */
    public UB_HTTPCalloutAsyncService(Integer requestTimeout, List<String> customMetadataList) {
        requestMap = new Map<String, HTTPRequest>();
        initialize(requestTimeout);
        if((customMetadataList != null) && (!customMetadataList.isEmpty())) {
            if(customMetadataList.size() > CONTINUATION_LIMIT) {
                throw new UB_LogException(UB_ConstantsUtil.CONTINUATION_LIMIT_EXCEEDED);
            }
            for(String customMetadata : customMetadataList) {
                UB_HTTPCalloutService service = new UB_HTTPCalloutService(customMetadata);
                if(service != null) {
                    requestMap.put(customMetadata, service.getRequest());
                }
            }
        }
    }
    
    /*
    * This method is used to send continuation request
    */
    public Continuation sendRequest(String responseMethodName) {
        Continuation con = new Continuation(requestTimeout);
        con.continuationMethod = responseMethodName;
        con.state = continuationState;
        String requestLabel;
        if(requestMap != null) {
            for(String customMetadata : requestMap.keySet()) {
                requestLabel = con.addHTTPRequest(requestMap.get(customMetadata));
                requestLabels.add(requestLabel);
            }
        } else {
            for(HTTPRequest request : httpRequests) {
                requestLabel = con.addHTTPRequest(request);
                requestLabels.add(requestLabel);
            }
        }
        return con;
    }
    
    /*
    * This method is used to parse the continuation response
    */
    public List<HTTPResponse> getResponse(List<String> requestLabels) {
        List<HTTPResponse> responses = new List<HTTPResponse>();
        for(String requestLabel : requestLabels) {
            responses.add(Continuation.getResponse(requestLabel));
        }
        return responses;
    }
}