@isTest
private class ChatterFeed_Test {
    
    private static String RAND = 'abcd' + System.now();
    
    
    @isTest
    private static void happyPath() {
     
        // Setup
        Account acc = new Account(Name='Acme');
        insert acc;
        
        FeedItem post = new FeedItem();
		post.ParentId = acc.Id; 
		post.Body = RAND;
    	insert post;
        
        FeedComment cmt = new FeedComment();
        cmt.FeedItemId = post.Id; 
		cmt.CommentBody = RAND;
    	insert cmt;
        
        Contact con = new Contact(LastName='Doe');
        insert con;
        
        
        // Exercise
        new ChatterFeed(acc.Id).copyTo(con.Id);
        
        
        // Verify
        FeedItem clone = [SELECT Body FROM FeedItem WHERE ParentId = :con.Id LIMIT 1];
        System.assertEquals(RAND, clone.Body); 
        
        FeedComment commentClone = [SELECT CommentBody FROM FeedComment WHERE FeedItemId = :clone.Id LIMIT 1];
        System.assertEquals(RAND, commentClone.CommentBody); 
    }
}