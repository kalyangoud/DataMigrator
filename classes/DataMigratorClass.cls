/*Comments
Another comment*/

public class DataMigratorClass {
    
    private static final String NS_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String NS_SF = 'urn:partner.soap.sforce.com';
    private static final Integer TIME_OUT = 60000;
    private static final String POST_REQ_METHOD = 'POST'; 
    public string userName {get;set;} //'balu.nalgonda@gmail.com';
    public string password {get;set;} //'Aadhya123#4wuHFKr2vbMNXr9XLRchkRf2m';
    private string sessionId;
    private string serverUrl;
    public string jsonString {get;set;}
    public string queryString {get;set;}
    public Map<String, String> objRelNameMap;
    public Map<String, String> objFieldMap;
    public String objFieldMapJSON {get;set;}
    public String objRelNameMapJSON {get;set;}
    public String parentObjectName {get;set;}
    public String responseBody {get;set;}
    public string selectedDomain {get;set;}
    
    
    public DataMigratorClass(){
    }
    
    @RemoteAction
    public static List<sObject> searchRecords(String queryStr) {
        return Database.query(queryStr);
    }
    
    public pageReference orgLogin(){
        HttpRequest req = new HttpRequest();
        req.setMethod(POST_REQ_METHOD);   
        req.setTimeout(TIME_OUT);
        req.setEndpoint('https://'+selectedDomain+'.salesforce.com/services/Soap/u/29.0');
        req.setHeader('Content-Type', 'text/xml;charset=UTF-8');        
        req.setHeader('SOAPAction', '""');
        req.setBody('<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Header/><Body><login xmlns="urn:partner.soap.sforce.com"><username>' +userName+ '</username><password>' + password + '</password></login></Body></Envelope>'); 
        try{
            HttpResponse res =  new Http().send(req);
            if(res.getStatusCode() == 200){
                Dom.Document responseDocument = res.getBodyDocument();
                Dom.Xmlnode rootElm = responseDocument.getRootElement(); // soapenv:Envelope
                Dom.Xmlnode bodyElm = rootElm.getChildElement('Body', NS_SOAP); // soapenv:Body 
                Dom.Xmlnode loginResponseElm = bodyElm.getChildElement('loginResponse', NS_SF); // loginResponse
                Dom.Xmlnode resultElm = loginResponseElm.getChildElement('result', NS_SF); // result
                Dom.Xmlnode sessionIdElm = resultElm.getChildElement('sessionId', NS_SF); // sessionId
                Dom.Xmlnode serverURLElm = resultElm.getChildElement('serverUrl', NS_SF); // server URL
                sessionId = sessionIdElm.getText();
                serverUrl = serverURLElm.getText().split('/services')[0];
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Login Successfull'));
            }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, res.getStatus()+' '+res.getStatusCode()));
            }
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }               
        return null;        
    } 
    
    public pageReference schemaCheck(){
        objRelNameMap = new Map<String, String>();
        objFieldMap = new Map<String, String>();
        List<String> objectNames = new List<String>();
        Set<String> objectNameSet = new Set<String>();
        String queryStr = queryString.remove('(').remove(')');
        queryStr = queryStr.replaceAll(',', ' ');
        queryStr = queryStr.trim().replaceAll('\\s{2,}', ' ');
        List<String> splitString = queryStr.split(' ');        
        for(integer i = 0, j = splitString.size(); i<j; i++){
            if(splitString[i].equalsIgnoreCase('From')){
                objectNames.add(splitString[i+1]);
                objectNameSet.add(splitString[i+1]);
            }    
        }
        
        parentObjectName = objectNames[objectNames.size()-1];
        for(Schema.ChildRelationship cr: Schema.getGlobalDescribe().get(parentObjectName).getdescribe().getChildRelationships()){
            if(objectNameSet.contains(String.valueOf(cr.getRelationshipName()))){
                objRelNameMap.put(String.valueOf(cr.getRelationshipName()), String.valueOf(cr.getChildSObject()));
                objFieldMap.put(String.valueOf(cr.getRelationshipName()), String.valueOf(cr.getField()));
            }            
        }
        
        objRelNameMapJSON = JSON.serialize(objRelNameMap);
        objFieldMapJSON = JSON.serialize(objFieldMap);
        return null;
    }
    
    public pageReference moveRecords(){
        Http hSobject = new Http();
        HttpRequest reqSobject = new HttpRequest();
        HttpResponse resSobject = new HttpResponse();
        reqSobject.setMethod(POST_REQ_METHOD);
        reqSobject.setTimeout(TIME_OUT);
        reqSobject.setHeader('Authorization', 'Bearer '+sessionId);
        reqSobject.setHeader('Content-Type','application/json');
        reqSobject.setHeader('Accept','application/json');
        reqSobject.setBody(jsonString);
        reqSobject.setEndpoint(serverUrl+'/services/data/v37.0/composite/tree/'+parentObjectName+'/');
        resSobject = hSobject.send(reqSobject);
        responseBody = resSobject.getBody();     
        return null;        
    }
}
