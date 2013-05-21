
//   							 AtoZCodeFactory   main.m             

@interface 							 PlistNode : NSObject	@property id value, key, expanded; @property (nonatomic) NSMutableArray * children;	@end
@implementation 					 PlistNode - (NSMutableArray*)children	{ return _children = _children ?: NSMutableArray.new; }																			@end

@interface 			  DefinitionController : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate, NSApplicationDelegate, NSTextViewDelegate>
@property 				      NSOutlineView * nodeView;	
@property 				      NSSearchField * searchField;
@property 				         NSUInteger   matched;
@property  (readonly) 		 NSDictionary * expansions;
@property  (readonly) 			  NSString * generatedHeader;
@property  (readonly) 				NSArray * allKeywords,*allReplacements;
@property (nonatomic) 			  NSString * plistPath,  *generatedHeaderPath;
@property (nonatomic)           NSWindow * window;
@property (nonatomic) 		    PlistNode * root;

@end
@implementation DefinitionController
-             (id) outlineView:(NSOutlineView*)v 
	  objectValueForTableColumn:(NSTableColumn*)c 							 byItem:(id)x	{	
	  
	return [c.identifier isEqualToString:@"value"] ? ((PlistNode*)x).children.count ? nil : ((PlistNode*)x).value:((PlistNode*)x).key;
}
- 				(BOOL) outlineView:(NSOutlineView*)v 			 		  isGroupItem:(id)x 	{ return [(PlistNode*)x value] == nil; }
-           (BOOL) outlineView:(NSOutlineView*)v 		      isItemExpandable:(id)x	{ return !x ?   : [[x children]count];	}
-      (NSInteger) outlineView:(NSOutlineView*)v      numberOfChildrenOfItem:(id)x	{ NSInteger ct = !x ? 1 : [[x children]count];	
																																				  return NSLog(@"Item: %@ children ct: %ld", x, ct),ct;
}
- 			     (id) outlineView:(NSOutlineView*)v child:(NSInteger)idx ofItem:(id)x	{	return !x ? self.root : [x children][idx];	
}  
//-  			(BOOL) outlineView:(NSOutlineView*)v shouldExpandItem:			  (id)x  {  return  ([((PlistNode*)x).children count]);}//expanded boolValue] ?: x == _root; }
//
//	if (![_searchField.stringValue isEqualToString:@""]) return  YES; 
//	NSString *key = [(PlistNode*)x key];
//	NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
//	return  [d objectForKey:key]  ? [d boolForKey:key] : YES; 

-           (void) applicationWillFinishLaunching:	(NSNotification*)n	{ [self.window makeKeyAndOrderFront:self];	}
-				(void) outlineViewItemDidCollapse:		(NSNotification*)n 	{	if (![n.object isKindOfClass:PlistNode.class]) return;
	[NSUserDefaults.standardUserDefaults setBool:YES forKey:[(PlistNode*)n.object key]];	
}
-           (void) controlTextDidChange:				(NSNotification*)n 	{ 	

	static BOOL isCompleting; NSLog(@"%@", n.userInfo);
	static NSString *last = nil; 
	if (!isCompleting && [[(NSTextView*)n.userInfo[@"NSFieldEditor"]  string]length] > last.length) { 
		isCompleting = YES;
		[n.userInfo[@"NSFieldEditor"] complete:nil];	
		isCompleting = NO;
	}
	last = _searchField.stringValue;
}
- 		  (NSArray*) allKeywords 						{  NSMutableArray *keys = NSMutableArray.new; 
	[[self.expansions allValues] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
		[obj  enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[keys addObject:key];
		}];
	}];
	return keys;
}
- 		  (NSArray*) allReplacements 					{  NSMutableArray *keys = NSMutableArray.new; 
	[[self.expansions allValues] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
		[obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[keys addObject:obj];
		}];
	}];
	return keys;
}
-      (NSWindow*) window								{

	NSInteger wMask 	= NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask;
	NSRect 	 wRect 	= (NSRect){  0,  0,200,500};
	NSRect 	 fRect 	= (NSRect){ 60,450,130, 50}; 
	NSRect 	 oRect 	= (NSRect){  0,  0,200,450};
	NSRect 	 mRect 	= (NSRect){  0,450, 50, 50}; 
	_window 				= [NSWindow.alloc initWithContentRect:wRect styleMask:wMask backing:NSBackingStoreBuffered defer:YES];
	_window.level = NSScreenSaverWindowLevel;
	NSScrollView *_sv; NSTextField *_matchCt;
	[_window.contentView addSubview:_matchCt = [NSTextField.alloc initWithFrame:mRect]];
	[_matchCt bind:NSValueBinding toObject:self withKeyPath:@"matched" options:nil];
	_matchCt.autoresizingMask = NSViewMinYMargin;
	[_matchCt setEditable:NO];
	[_window.contentView addSubview:_searchField = [NSSearchField.alloc initWithFrame:fRect]];
	_searchField.target = self; _searchField.delegate = (id<NSTextFieldDelegate>)self;
	_searchField.action = @selector(search:);	
	_searchField.backgroundColor = NSColor.redColor;
	_searchField.drawsBackground = YES;
	_searchField.autoresizingMask =  NSViewWidthSizable| NSViewMinYMargin;
	[_window.contentView addSubview:_sv = [NSScrollView.alloc initWithFrame:oRect]];
	_sv.documentView = _nodeView = [NSOutlineView.alloc initWithFrame:oRect]; 
	_sv.autoresizingMask =  NSViewWidthSizable | NSViewHeightSizable;
	_sv.hasVerticalScroller = YES;

	_nodeView.usesAlternatingRowBackgroundColors = YES;
	_nodeView.gridStyleMask = NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask;
	_nodeView.gridColor = NSColor.lightGrayColor;
	NSTableColumn *key	= [NSTableColumn.alloc initWithIdentifier:  @"key"];
	NSTableColumn *value = [NSTableColumn.alloc initWithIdentifier:@"value"];
	value.width = key.width = 100;
	[_nodeView addTableColumn:  key];
	[_nodeView addTableColumn:value];
	_nodeView.outlineTableColumn = key;
	_nodeView.dataSource = self;
	_nodeView.delegate = self;
	
	[_window makeFirstResponder:_nodeView];
	return _window; 
}
-  (NSDictionary*) expansions 						{	
	NSData* data = [NSData dataWithContentsOfFile:_plistPath];	NSString *errorDesc = nil;	NSPropertyListFormat format;
	return (NSDictionary*)[NSPropertyListSerialization propertyListFromData:data    mutabilityOption:NSPropertyListMutableContainersAndLeaves
																									format:&format errorDescription:&errorDesc];
}
-     (PlistNode*) root 								{ _root = PlistNode.new; _root.key = @"Expansions"; __block PlistNode *cat, *def;  NSString*w = [_searchField stringValue]; w = [w isEqualToString:@""] ? nil : w;
																	self.matched = 0;  
	[self.expansions enumerateKeysAndObjectsUsingBlock:^(id key,id obj,BOOL*stop){ cat = PlistNode.new; cat.key = key;
		[obj enumerateKeysAndObjectsUsingBlock:^(NSString* macro,NSString *expand,BOOL*stop){ 
			if (w!= nil && (macro!=nil || expand!=nil))	if ([macro rangeOfString:w].location == NSNotFound && [expand rangeOfString:w].location == NSNotFound) return;
			[cat.children addObject:def = PlistNode.new]; def.key = macro; def.value = expand;	self.matched = _matched +1;
		}];
		if (cat.children.count) { if (w) cat.expanded = @YES; [_root.children addObject:cat]; }
	}];
	return _root;
}
-  	      (void) addItem:(id)x							{	PlistNode *item; 	[item.children addObject: item = [_nodeView itemAtRow:_nodeView.selectedRow] ?: self.root];
																							[_nodeView reloadItem:item reloadChildren:YES];
}												
-      (NSString*) generatedHeader 						{

	__block NSString *define, *definition; __block NSUInteger pad, longest; __block NSMutableArray *keys;
	__block NSMutableString *definer = @"#import <QuartzCore/QuartzCore.h>\n".mutableCopy;
	[self.root.children enumerateObjectsUsingBlock:^(PlistNode* category,NSUInteger idx,BOOL *stop) {
		[definer appendFormat:@"\n#pragma mark - %@\n\n", category.key];
		[keys = [[category.children valueForKeyPath:@"key"]mutableCopy] sortUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2) {
			return 	s1.length < s2.length ? (NSComparisonResult) NSOrderedDescending :
						s1.length > s2.length ? (NSComparisonResult) NSOrderedAscending  : (NSComparisonResult)NSOrderedSame;
		}];
		longest = [keys[0] length];
		[category.children enumerateObjectsUsingBlock:^(PlistNode *defineNode, NSUInteger idx, BOOL *stop) {
			if (!defineNode.key || [defineNode.key isEqualToString:@"Inactive"]) return; else definition = defineNode.key;
			pad 		= MAX(8, (NSInteger)(longest - definition.length + 8));
			NSLog(@"def: %@  pad: %lu",definition, pad);
			define	= [@"#define" stringByPaddingToLength:pad withString:@" " startingAtIndex:0];
			[definer appendString:[define stringByAppendingFormat:@"%@ %@\n", definition, defineNode.value ?: @""]];
		}];
	}];		
	return definer;
}
- (NSArray*) control: (NSControl*)c 
				textView:(NSTextView*)tv 
		   completions:   (NSArray*)w 
 forPartialWordRange:    (NSRange)r 
 indexOfSelectedItem: (NSInteger*)i 					{
	

		NSLog(@"annoying method called");
	//	Use this method to override NSFieldEditor's default matches (which is a much bigger	list of keywords).  
	NSString *partial 		= [_searchField.stringValue substringWithRange:r];
   NSArray *keywords 		= [self.allKeywords arrayByAddingObjectsFromArray:self.allReplacements];
   __block NSMutableArray *matches = NSMutableArray.new;
    // find any match in our keyword array against what was typed -
   [keywords enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[obj rangeOfString:partial options:NSAnchoredSearch|NSCaseInsensitiveSearch range:NSMakeRange(0,[obj length] )].location != NSNotFound ? [matches addObject:obj] : nil;
	}];
	[matches sortUsingSelector:@selector(compare:)];
   return matches;
}
- (void) search:(id) sender {
	static NSString *lastSearch = nil; 
	if (![lastSearch isEqualToString:[sender stringValue]]) { [self root];  [_nodeView reloadData]; [_nodeView expandItem:nil expandChildren:YES]; lastSearch = [sender stringValue]; }
}
@end

int main(int argc, const char * argv[])	{
	@autoreleasepool {
	
		__block DefinitionController *v 	= DefinitionController.new;
		NSProcessInfo *pInfo					= NSProcessInfo.processInfo;
		NSDictionary *env 					= pInfo.environment; 
		NSString *plistPath					= env[@"PLIST_FILE"]  ?: @"/Volumes/2T/ServiceData/AtoZ.framework/AtoZMacroDefines.plist";
		NSString *generatedHeaderPath 	= env[@"INCLUDE_OUT"] ?: @"/Volumes/2T/ServiceData/AtoZ.framework/AtoZMacroDefines.h";
		
		
		
		void (^setUpApp)(void) = ^{
			[NSApplication sharedApplication];	id appMenu, menuBar, appMenuItem;
			[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
			[NSApp setMainMenu:  menuBar    =	  NSMenu.new];
			[menuBar addItem:appMenuItem 	  = NSMenuItem.new];
			[appMenuItem setSubmenu:appMenu =     NSMenu.new];
			[appMenu addItem:[NSMenuItem.alloc initWithTitle:[@"Quit "stringByAppendingString:[pInfo processName]] action:@selector(terminate:) keyEquivalent:@"q"]];
			[NSApp setDelegate:v];
		};
		void(^justProcessHeaders)(void) = ^{  v.plistPath = plistPath; v.generatedHeaderPath = generatedHeaderPath;
			NSLog(@"root: %@", v.root);
			[v.generatedHeader writeToFile:v.generatedHeaderPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		};		
		BOOL(^hasFileChanged)(void) = ^BOOL{
		
			NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:plistPath error:nil];
			NSDate *date = [attributes fileModificationDate];
			NSTimeInterval thatTime = [date timeIntervalSinceReferenceDate];
			NSTimeInterval lastModifiedBuild = [NSUserDefaults.standardUserDefaults doubleForKey:@"lastBuilt"];
			
			NSDictionary *toolInfo = [NSFileManager.defaultManager attributesOfItemAtPath:[pInfo arguments][0] error:nil];
			NSDate *buildDate = [toolInfo fileModificationDate];
			NSTimeInterval toolTime = [buildDate timeIntervalSinceReferenceDate];
			NSTimeInterval lastRunDate = [NSUserDefaults.standardUserDefaults doubleForKey:@"lastKnownBuildDate"];
			BOOL needsit = NO;
			needsit =  (toolTime != lastRunDate);
			if (needsit) {  NSLog(@"the tool:%@ has been rebuilt since last use.\n %f vs %f.\n  running it regardless",toolInfo, toolTime, lastRunDate);
				[NSUserDefaults.standardUserDefaults setDouble:thatTime forKey:@"lastKnownBuildDate"]; 
				[NSUserDefaults.standardUserDefaults synchronize];
				return YES;
			}
			
			if (thatTime == lastModifiedBuild) { NSLog(@"file:%@\n%@ is unchanged since %@", [pInfo arguments][0], plistPath, date); return NO; }
			NSLog(@"file: %@ has CHANGED!  Setting New date as double.. %f", plistPath, thatTime);
			[NSUserDefaults.standardUserDefaults setDouble:thatTime forKey:@"lastBuilt"]; 
			[NSUserDefaults.standardUserDefaults synchronize];
			return YES;
		};
		if (hasFileChanged()) justProcessHeaders();
		if ([pInfo arguments].count > 1) { setUpApp(); justProcessHeaders();	[NSApp run]; }
	}
	return 0;
}


//		 [NSString stringWithFormat:@"%@/../Include/%@",srcRoot, @"AZGenerated.h"]

//+         (NSSet*) keyPathsForValuesAffectingExpansions					{	return [NSSet setWithArray:@[@"plistPath"]]; }
//+         (NSSet*) keyPathsForValuesAffectingGeneratedHeader 			{	return [NSSet setWithArray:@[@"root"]]; }
