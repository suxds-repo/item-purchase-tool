public with sharing class UnsplashService {
    @AuraEnabled
    public static String getImageUrl(String query) {
        if(String.isBlank(query)) return null;

        External_Config__mdt config = [SELECT Unsplash_Access_Key__c 
                                       FROM External_Config__mdt 
                                       WHERE DeveloperName='Unsplash' LIMIT 1];
        String accessKey = config.Unsplash_Access_Key__c;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.unsplash.com/search/photos?query=' + EncodingUtil.urlEncode(query,'UTF-8') + '&per_page=1');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Client-ID ' + accessKey);
        
        try {
            HttpResponse res = http.send(req);
            if(res.getStatusCode() == 200){
                Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                List<Object> results = (List<Object>)result.get('results');
                if(!results.isEmpty()){
                    Map<String,Object> first = (Map<String,Object>)results[0];
                    Map<String,Object> urls = (Map<String,Object>)first.get('urls');
                    if(urls.containsKey('small')) return (String)urls.get('small');
                }
            }
        } catch(Exception e){
            System.debug('Unsplash error: ' + e.getMessage());
        }
        return null;
    }
}
