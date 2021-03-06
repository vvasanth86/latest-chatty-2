//
//  StoryViewController.m
//  LatestChatty2
//
//  Created by Alex Wayne on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "StoryViewController.h"


@implementation StoryViewController

@synthesize story;

- (id)initWithStoryId:(NSUInteger)aStoryId {
  [self initWithNibName:@"StoryViewController" bundle:nil];
  storyId = aStoryId;
  self.title = @"Loading...";
  return self;
}

- (id)initWithStory:(Story *)aStory {
  [self initWithNibName:@"StoryViewController" bundle:nil];
  self.story = aStory;
  self.title = self.story.title;
  return self;
}

- (id)initWithStateDictionary:(NSDictionary *)dictionary {
  return [self initWithStory:[dictionary objectForKey:@"story"]];
}

- (NSDictionary *)stateDictionary {
  return [NSDictionary dictionaryWithObjectsAndKeys:@"Story", @"type",
                                                    story,    @"story", nil];
}

- (void)didFinishLoadingModel:(id)model otherData:(id)otherData {
  self.story = model;
  [story release];
  storyLoader = nil;
  [self displayStory];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  UIBarButtonItem *chattyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ChatIcon.24.png"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(loadChatty)];
	self.navigationItem.rightBarButtonItem = chattyButton;
  [chattyButton release];
  
  // Load story
  storyLoader = [[Story findById:storyId delegate:self] retain];
  
  // Load blank page while we wait
  NSString *baseUrlString = [NSString stringWithFormat:@"http://shacknews.com/onearticle.x/%i", story.modelId];
  StringTemplate *htmlTemplate = [[StringTemplate alloc] initWithTemplateName:@"Story.html"];
  NSString *stylesheet = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Stylesheet.css" ofType:nil] usedEncoding:nil error:nil];
  [htmlTemplate setString:stylesheet forKey:@"stylesheet"];
  [htmlTemplate setString:@"" forKey:@"date"];
  [htmlTemplate setString:@"" forKey:@"storyId"];
  [htmlTemplate setString:@"" forKey:@"content"];
  [htmlTemplate setString:@"" forKey:@"storyTitle"];
  
  [content loadHTMLString:htmlTemplate.result baseURL:[NSURL URLWithString:baseUrlString]];
  [htmlTemplate release];    
}

- (void)displayStory {
  self.title = story.title;
  
  // Load up web view content
  NSString *baseUrlString = [NSString stringWithFormat:@"http://shacknews.com/onearticle.x/%i", story.modelId];
  
  StringTemplate *htmlTemplate = [[StringTemplate alloc] initWithTemplateName:@"Story.html"];
  
  NSString *stylesheet = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Stylesheet.css" ofType:nil] usedEncoding:nil error:nil];
  [htmlTemplate setString:stylesheet forKey:@"stylesheet"];
  [htmlTemplate setString:[Story formatDate:story.date] forKey:@"date"];
  [htmlTemplate setString:[NSString stringWithFormat:@"%i", story.modelId] forKey:@"storyId"];
  [htmlTemplate setString:story.body forKey:@"content"];
  [htmlTemplate setString:story.title forKey:@"storyTitle"];
  
  [content loadHTMLString:htmlTemplate.result baseURL:[NSURL URLWithString:baseUrlString]];
  [htmlTemplate release];  
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"landscape"]) return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)loadChatty {
  ChattyViewController *viewController = [[ChattyViewController alloc] initWithStoryId:story.modelId];
  [self.navigationController pushViewController:viewController animated:YES];
  [viewController release];
}



- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if (navigationType == UIWebViewNavigationTypeLinkClicked) {
    BrowserViewController *viewController = [[BrowserViewController alloc] initWithRequest:request];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
    return NO;
  }
  
  return YES;
}

- (void)dealloc {
  [storyLoader release];
  [story release];
  [super dealloc];
}


@end
