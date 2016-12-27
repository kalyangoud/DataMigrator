/*Comments
Another comment*/

public class DataMigratorClass {

    private static final String NS_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String NS_SF = 'urn:partner.soap.sforce.com';
    private static final Integer TIME_OUT = 60000;
    private static final String POST_REQ_METHOD = 'POST';
    public string userName {get; set;}
    public string password {get; set;}
    private string sessionId;
    private string serverUrl;
    public string jsonString {get; set;}
    public string queryString {get; set;}
    public String objFieldMapJSON {get; set;}
    public String objRelNameMapJSON {get; set;}
    public String parentObjectName {get; set;}
    public String responseBody {get; set;}
    public string selectedDomain {get; set;}


    public DataMigratorClass() {
    }

    @RemoteAction
    public static List<sObject> searchRecords(String queryStr) {
        return Database.query(queryStr);
    }

    public pageReference orgLogin() {
        HttpRequest request = new HttpRequest();
        request.setMethod(POST_REQ_METHOD);
        request.setTimeout(TIME_OUT);
        request.setEndpoint('https://' + selectedDomain + '.salesforce.com/services/Soap/u/29.0');
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setHeader('SOAPAction', '""');
        request.setBody('<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Header/><Body><login xmlns="urn:partner.soap.sforce.com"><username>' + userName + '</username><password>' + password + '</password></login></Body></Envelope>');
        try {
            HttpResponse response =  new Http().send(request);
            if (response.getStatusCode() == 200) {

                Dom.XmlNode resultElmt = response.getBodyDocument().getRootElement()
                                         .getChildElement('Body', NS_SOAP)
                                         .getChildElement('loginResponse', NS_SF)
                                         .getChildElement('result', NS_SF);

                serverUrl = resultElmt.getChildElement('serverUrl', NS_SF) .getText().split('/services')[0];
                sessionId = resultElmt.getChildElement('sessionId', NS_SF) .getText();

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Login Successfull'));

            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, response.getStatus() + ' ' + response.getStatusCode()));
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public pageReference schemaCheck() {
        Map<String, String> objRelNameMap = new Map<String, String>();
        Map<String, String> objFieldMap = new Map<String, String>();
        List<String> objectNames = new List<String>();
        Set<String> objectNameSet = new Set<String>();
        List<String> splitString = queryString.remove('(')
                                   .remove(')')
                                   .replaceAll(',', ' ')
                                   .trim()
                                   .replaceAll('\\s{2,}', ' ')
                                   .split(' ');

        for (integer i = 0, j = splitString.size(); i < j; i++) {
            if (splitString[i].equalsIgnoreCase('From')) {
                objectNames.add(splitString[i + 1]);
                objectNameSet.add(splitString[i + 1]);
            }
        }

        parentObjectName = objectNames[objectNames.size() - 1];
        for (Schema.ChildRelationship cr : Schema.getGlobalDescribe().get(parentObjectName).getdescribe().getChildRelationships()) {
            if (objectNameSet.contains(String.valueOf(cr.getRelationshipName()))) {
                objRelNameMap.put(String.valueOf(cr.getRelationshipName()), String.valueOf(cr.getChildSObject()));
                objFieldMap.put(String.valueOf(cr.getRelationshipName()), String.valueOf(cr.getField()));
            }
        }

        objRelNameMapJSON = JSON.serialize(objRelNameMap);
        objFieldMapJSON = JSON.serialize(objFieldMap);
        return null;
    }

    public pageReference moveRecords() {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        try {
            request.setMethod(POST_REQ_METHOD);
            request.setTimeout(TIME_OUT);
            request.setHeader('Authorization', 'Bearer ' + sessionId);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setBody(jsonString);
            request.setEndpoint(serverUrl + '/services/data/v37.0/composite/tree/' + parentObjectName + '/');
            response = new Http().send(request);
            responseBody = response.getBody();

        } catch (Exception e) {
            responseBody = response.getStatus() + ' ' + response.getStatusCode();
        }
        return null;
    }
}
