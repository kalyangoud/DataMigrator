public class HandleBarsJsDemoCtrl {
    
    public ApexPages.StandardController stdCtrl {get;set;}
    
    public HandleBarsJsDemoCtrl(ApexPages.StandardController stdCtrl) {
        this.stdCtrl = stdCtrl;
    }
    
    @remoteAction
    public static List<Asset> doAssetSearch(Id accountId, String q) {
        return Database.query(
            'SELECT Name, Product2Id, Product2.ProductCode FROM Asset WHERE AccountId = \'' + accountId + '\' AND Name LIKE \'' + q + '%\''
        );
    }
}