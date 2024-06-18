@import CoreFoundation;
@import UIKit;

// SECTION YOUTUBE SCROLLVIEW ADS

@interface YTAsyncCollectionView : UICollectionView
@end 

@interface _ASCollectionViewCell : NSObject
@property (nonatomic, strong, readonly) NSObject* node;
@end

@interface ELMComponent : NSObject
- (NSString*) templateURI;
@end

@interface ELMNodeController : NSObject
@property (nonatomic, strong, readonly) ELMComponent* owningComponent;
@end

@interface ELMCellNode : NSObject
@property (nonatomic, strong, readonly) ELMNodeController* controller;
@end

@interface YTAdCellNode : NSObject
@property (nonatomic, strong, readonly) NSObject* parentResponder;
@end


// SECTION IN VIDEO ADS

@class YTAdsInnerTubeContextDecorator; 
