public class ChatterFeed {
    
    private static Set<String> IGNORE_TYPES = new Set<String>{ 'TrackedChange' };
    private static Set<Id> STANDARD_USERS = new Map<Id, User>([SELECT Id FROM User Where UserType = 'Standard' OR Profile.UserType = 'Standard']).keySet();
    
    private Id parentId;
    

    // CONSTRUCTOR
    
    public ChatterFeed(Id parentId) {
        this.parentId = parentId;
    }
    
    
    // PUBLIC
    
    public void copyTo(Id newParent) {
	// Workaround due to untraceable error messages: https://success.salesforce.com/ideaView?id=08730000000XkUBAA0
	// TODO: fix this when Idea is implemented.
	insertContentFakes(parentId);
	
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{ FeedItem.SObjectType, FeedComment.SObjectType });
        
        for(FeedItem original : [SELECT BestCommentId, Body, CommentCount, CreatedById, CreatedDate, CreatedBy.IsActive, CreatedBy.Name, 
                                        HasContent, HasLink, Id, IsDeleted, LastEditById, LastEditDate, LastModifiedDate, LikeCount, 
                                        LinkUrl, ParentId, RelatedRecordId, Revision, SystemModstamp, Title, Type,
                                        (SELECT CommentBody, CommentType, CreatedById, CreatedDate, FeedItemId,
                                                IsDeleted, LastEditById, LastEditDate, ParentId, RelatedRecordId, Revision 
                                         FROM FeedComments)
                                 FROM FeedItem
                                 WHERE ParentId = :parentId
                                 AND (NOT Type IN :IGNORE_TYPES)]) {
                                     
            FeedItem clone = original.clone(false, false, true, true);
            clone.ParentId = newParent;
            uow.registerNew(clone);
            
            if(isFileByCommunityUser(original) || createdByInactiveUser(original)) {
                clone.CreatedById = UserInfo.getUserId();
            }
            
            for(FeedComment comment : original.FeedComments) {
               FeedComment commentClone = comment.clone(false, false, true, true);
               uow.registerNew(commentClone, FeedComment.FeedItemId, clone);
            }  
        }
        
        uow.commitWork();
	deleteContentFakes();
    }


	// PRIVATE
    
    private void insertContentFakes(Id parentId) {
        List<FeedItem> fakeposts = new List<FeedItem>();
        
        for(FeedItem contentPost : [SELECT ParentId, RelatedRecordId
                                    FROM FeedItem
                                    WHERE ParentId = :parentId
                                    AND Type = 'ContentPost']) {
            FeedItem fakePost = contentPost.clone(false, false, true, true);
            fakePost.CreatedById = UserInfo.getUserId();
            fakepost.Body = 'delete me';
            
            fakeposts.add(fakePost);
        }
        
        insert fakeposts;
    }
    
    private void deleteContentFakes() {
        List<FeedItem> fakeposts = new List<FeedItem>();
        
        for (FeedItem post : [SELECT Body FROM FeedItem WHERE CreatedById = :UserInfo.getUserId() AND Type = 'ContentPost']) {
            if(post.Body == 'delete me') {
                fakeposts.add(post);
            }
        }
        
        delete fakePosts;
    }
    
    private Boolean isFileByCommunityUser(FeedItem item) {
        return (item.RelatedRecordId != null && !STANDARD_USERS.contains(item.CreatedById));
    }
    
    private Boolean createdByInactiveUser(FeedItem item) {
        return !item.CreatedBy.IsActive;
    }
}
