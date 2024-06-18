#import <substrate.h>
#import "Interfaces.h"

#ifdef DEBUG
#define DEBUG_LOG(fmt, ...) NSLog(@"iHateYTAds: " fmt, ##__VA_ARGS__)
#else
#define DEBUG_LOG(fmt, ...) 
#endif

static void noop(NSObject* self, SEL _cmd) {
    DEBUG_LOG(@"[NO-OP] %@::%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

static BOOL returnFalse(NSObject* self, SEL _cmd) {
    DEBUG_LOG(@"[FALSE] %@::%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return NO;
}

static BOOL returnTrue(NSObject* self, SEL _cmd) {
    DEBUG_LOG(@"[TRUE] %@::%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return YES;
}
static UICollectionViewCell* (*originalGetCollectionView)(YTAsyncCollectionView*, SEL, UICollectionView *, NSIndexPath *);
static UICollectionViewCell* filterAdPanels(YTAsyncCollectionView* __unused self, SEL __unused _cmd, UICollectionView * cv, NSIndexPath * indexPath) {
	
	UICollectionViewCell* original = originalGetCollectionView(self, _cmd, cv, indexPath);

	if(![original isKindOfClass:[NSClassFromString(@"_ASCollectionViewCell") class]]) return original;

	_ASCollectionViewCell* viewcell = (_ASCollectionViewCell*)original;

	BOOL isAd = FALSE;
	NSString* description = @"(generic)";

	if (![[viewcell node] isKindOfClass:[NSClassFromString(@"ELMCellNode") class]]) return original;

	// only special YTAdCell instances have a parent responder
	if([[viewcell node] respondsToSelector:@selector(parentResponder)]) {
		NSObject* parentResponder = ((YTAdCellNode*)viewcell.node).parentResponder;
		description = parentResponder.description;
		isAd = [parentResponder isKindOfClass:[NSClassFromString(@"YTAdVideoElementsCellController") class]];

	} else {
		
		description = ((ELMCellNode*)viewcell.node).controller.owningComponent.templateURI; 

		// these are "generic" cells with advertisement embeds
		isAd = [description containsString:@"product_carousel"] ||
			[description containsString:@"product_engagement_panel"] ||
			[description containsString:@"product_item"] ||
			[description containsString:@"text_search_ad"] ||
			[description containsString:@"text_image_button_layout"] ||
			[description containsString:@"carousel_headered_layout"] ||
			[description containsString:@"full_width_portrait_image"] ||
			[description containsString:@"square_image_layout"] ||
			[description containsString:@"carousel_footered_layout"] ||
			[description containsString:@"landscape_image_wide_button_layout"] ||
			[description containsString:@"feed_ad_metadata"];
	}

	if (isAd) {
		[self deleteItemsAtIndexPaths: @[indexPath]];

		DEBUG_LOG(@"removed scroll-view ad %@", description);
		// we nee to call the original method again since we changed
		// the order of cells in the view
		return originalGetCollectionView(self, _cmd, cv, indexPath);
	}

    return original;
}

static __attribute__((constructor)) void initTweak(int __unused argc, char __unused **argv, char __unused **envp) {
	
	DEBUG_LOG("Setting up Hooks!");

	MSHookMessageEx(objc_getClass("YTAdsInnerTubeContextDecorator"), @selector(decorateContext:), (IMP)&noop, NULL);

	MSHookMessageEx(
		objc_getClass("YTAsyncCollectionView"),
		@selector(collectionView:cellForItemAtIndexPath:),
		(IMP)&filterAdPanels,
		(IMP*)&originalGetCollectionView
	);

	Class clazz = objc_getClass("YTAdsControlFlowManagerImpl");
	MSHookMessageEx(clazz, @selector(slotAdapter:didEnterSlot:), (IMP)&noop,NULL);
	MSHookMessageEx(clazz, @selector(slotAdapter:didExitSlot:), (IMP)&noop, NULL);
	MSHookMessageEx(clazz, @selector(slotAdapter:didFailForSlot:error:), (IMP)&noop, NULL);
	MSHookMessageEx(clazz, @selector(slotOpportunityAdapter:didProvideSlot:), (IMP)&noop, NULL);

	MSHookMessageEx(objc_getClass("YTAdsWebViewCell"), @selector(layoutSubviews), (IMP)&noop, NULL);

	MSHookMessageEx(objc_getClass("YTIPlayerResponse"), @selector(isMonetized), (IMP)&returnFalse, NULL);

	clazz = objc_getClass("YTTimingPlayerResponderEventVideoData");
	MSHookMessageEx(clazz, @selector(monetizable), (IMP)&returnFalse, NULL);
	MSHookMessageEx(clazz, @selector(initWithVideoID:CPN:monetizable:autoplay:), (IMP)&returnFalse, NULL);

	clazz = objc_getClass("YTSettings");
	MSHookMessageEx(clazz, @selector(watchBreakWaitAfterVideoEnds), (IMP)&returnFalse, NULL);
	MSHookMessageEx(clazz, @selector(watchBreakEnabled), (IMP)&returnFalse, NULL);
	MSHookMessageEx(clazz, @selector(enableMDXFijiSkippableAd), (IMP)&returnTrue, NULL);

	// privacy stuff

	MSHookMessageEx(objc_getClass("YTPersonalizedSuggestionsCache"), @selector(isValidIndexPath:), (IMP)&returnTrue, NULL);

	clazz = objc_getClass("YTDataUtils");
	MSHookMessageEx(clazz, @selector(isAdvertisingTrackingEnabled), (IMP)&returnFalse, NULL);
	MSHookMessageEx(clazz, @selector(isAdvertisingTrackingEnabledForEssentialUse), (IMP)&returnFalse, NULL);

	MSHookMessageEx(objc_getClass("TOKOverlayEditorView"), @selector(isTrackingEnabled), (IMP)&returnFalse, NULL);

	MSHookMessageEx(objc_getClass("ASIdentifierManager"), @selector(isAdvertisingTrackingEnabled), (IMP)&returnFalse, NULL);

	MSHookMessageEx(objc_getClass("APMRemoteConfig"), @selector(personalizedAdsFeatureEnabled), (IMP)&returnFalse, NULL);

	MSHookMessageEx(objc_getClass("APMPersistedConfig"), @selector(allowPersonalizedAds), (IMP)&returnFalse, NULL);

	MSHookMessageEx(objc_getClass("MDXPlaybackController"), @selector(isPlayingAdSurvey), (IMP)&returnFalse, NULL);

	MSHookMessageEx(objc_getClass("YTHotConfig"), @selector(disableAfmaIdfaCollection), (IMP)&returnFalse, NULL);

	DEBUG_LOG("Tweak Loaded!");

}