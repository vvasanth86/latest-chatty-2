//
//  ThreadViewController.m
//  LatestChatty2
//
//  Created by Alex Wayne on 3/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ThreadViewController.h"
#include "LatestChatty2AppDelegate.h"

@implementation ThreadViewController

@synthesize rootPost;
@synthesize selectedIndexPath;

- (id)initWithThreadId:(NSUInteger)aThreadId {
  [super initWithNibName:@"ThreadViewController" bundle:nil];
  
  threadId = aThreadId;
  grippyBarPosition = 1;
  self.title = @"Thread";
  
  return self;
}

- (id)initWithStateDictionary:(NSDictionary *)dictionary {
  [self initWithThreadId:[[dictionary objectForKey:@"threadId"] intValue]];
  
  self.rootPost = [dictionary objectForKey:@"rootPost"];
  storyId = [[dictionary objectForKey:@"storyId"] intValue];
  threadId = [[dictionary objectForKey:@"threadId"] intValue];
  selectedIndexPath = [dictionary objectForKey:@"selectedIndexPath"];
  lastReplyId = [[dictionary objectForKey:@"lastReplyId"] intValue];
  
  return self;
}

- (NSDictionary *)stateDictionary {
  return [NSDictionary dictionaryWithObjectsAndKeys:@"Thread", @"type",
                                                    rootPost,  @"rootPost",
                                                    [NSNumber numberWithInt:storyId],  @"storyId",
                                                    [NSNumber numberWithInt:threadId], @"threadId",
                                                    selectedIndexPath, @"selectedIndexPath",
                                                    [NSNumber numberWithInt:lastReplyId], @"lastReplyId",
                                                    nil];
}


- (IBAction)refresh:(id)sender {
  [super refresh:sender];
  loader = [[Post findThreadWithId:threadId delegate:self] retain];
  
  highlightMyPost = NO;
  if ([sender isKindOfClass:[ComposeViewController class]]) highlightMyPost = YES;
}

- (void)didFinishLoadingModel:(id)model otherData:(id)otherData {  
  self.rootPost = (Post *)model;
  [loader release];
  loader = nil;
  [super didFinishLoadingAllModels:nil otherData:otherData];
  
  // Set story data
  NSDictionary *dataDictionary = (NSDictionary *)otherData;
  storyId = [[dataDictionary objectForKey:@"storyId"] intValue];
  self.title   = [dataDictionary objectForKey:@"storyName"];
  
  // Find the target post in the thread.
  Post *firstPost = nil;
  
  if (highlightMyPost) {
    highlightMyPost = NO;
    for (Post *post in [rootPost repliesArray]) {
      if ([post.author isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"username"]] && post.modelId > firstPost.modelId)
        firstPost = post;
    }
  } else if (rootPost.modelId == threadId) {
    firstPost = rootPost;
  } else {
    for (Post *reply in [rootPost repliesArray]) {
      if (reply.modelId == threadId) firstPost = reply;
    }
  }
  
  // Check for invalid data
  if (rootPost.date == nil) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                    message:@"Thread loading failed.  Could not parse the response properly."
                                                   delegate:nil
                                          cancelButtonTitle:@"Sad face"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    [self.navigationController popViewControllerAnimated:YES];
    return;
  }
  
  
  // Select and display the targeted post
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[rootPost repliesArray] indexOfObject:firstPost] inSection:0];  
  if (indexPath == nil || indexPath.row >= [[rootPost repliesArray] count])
    indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ([rootPost.category isEqualToString:@"ontopic"] || [defaults boolForKey:[NSString stringWithFormat:@"postCategory.%@", rootPost.category]]) {
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    
  } else {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check your Filters"
                                                    message:@"You current filters do not allow to view this thead.  Check the filters in your settings and try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (rootPost) {
    [self.tableView reloadData];
    NSIndexPath *indexPath = selectedIndexPath;
    if (indexPath == nil) indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
  } else {
    [self refresh:self];
  }
  
  UIBarButtonItem *replyButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                                               target:self
                                                                               action:@selector(tappedReplyButton)];
  self.navigationItem.rightBarButtonItem = replyButton;
  [replyButton release];
  
  // Fill in emtpy web view
  StringTemplate *htmlTemplate = [[StringTemplate alloc] initWithTemplateName:@"Post.html"];
  NSString *stylesheet = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Stylesheet.css" ofType:nil] usedEncoding:nil error:nil];
  [htmlTemplate setString:stylesheet forKey:@"stylesheet"];
  [postView loadHTMLString:htmlTemplate.result baseURL:nil];
  [htmlTemplate release];
  
  if (selectedIndexPath) [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
  
  [self resetLayout];
}

- (void)viewWillAppear:(BOOL)animated {
  // prevent superclass behaviour of cell deselection
}

- (IBAction)tappedReplyButton {
  Post *post = [[rootPost repliesArray] objectAtIndex:selectedIndexPath.row];
  
  ComposeViewController *viewController = [[ComposeViewController alloc] initWithStoryId:storyId post:post];
  [self.navigationController pushViewController:viewController animated:YES];
  [viewController release];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
  return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [ReplyCell cellHeight];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
  return [[rootPost repliesArray] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
  static NSString *CellIdentifier = @"ReplyCell";
  
  ReplyCell *cell = (ReplyCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[ReplyCell alloc] init] autorelease];
  }
  
  cell.post = [[rootPost repliesArray] objectAtIndex:indexPath.row];

  return cell;
}


- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
  UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DropShadow.png"]];
  background.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 16);
  background.alpha = 0.75;
  return [background autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 16.0;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.selectedIndexPath = indexPath;
  Post *post = [[rootPost repliesArray] objectAtIndex:indexPath.row];
    
  // Create HTML for the post
  StringTemplate *htmlTemplate = [[StringTemplate alloc] initWithTemplateName:@"Post.html"];

  NSString *stylesheet = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Stylesheet.css" ofType:nil] usedEncoding:nil error:nil];
  [htmlTemplate setString:stylesheet forKey:@"stylesheet"];
  [htmlTemplate setString:[Post formatDate:post.date] forKey:@"date"];
  [htmlTemplate setString:post.author forKey:@"author"];
  [htmlTemplate setString:[NSString stringWithFormat:@"%i", post.modelId] forKey:@"postId"];
  
  NSString *body = [self postBodyWithYoutubeWidgets:post.body];
  
  [htmlTemplate setString:body forKey:@"body"];
  [postView loadHTMLString:htmlTemplate.result baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://shacknews.com/laryn.x?id=%i", rootPost.modelId]]];
  
  [htmlTemplate release];
}

- (NSString *)postBodyWithYoutubeWidgets:(NSString *)body {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"embedYoutube"]) return body;
  
  // Insert youtube widgets
  if ([body isMatchedByRegex:@"<a href=\"(http://(www\\.)?youtube\\.com/watch\\?v=.*?)\">.*?</a>"]) {
    @try {
      body = [body stringByReplacingOccurrencesOfRegex:@"<a href=\"(http://(www\\.)?youtube\\.com/watch\\?v=.*?)\">.*?</a>"
                   withString:@"<div class=\"youtube-widget\">\
                                  <object width=\"140\" height=\"105\">\
                                    <param name=\"movie\" value=\"$1\"></param>\
                                    <param name=\"wmode\" value=\"transparent\"></param>\
                                    <embed id=\"yt\" src=\"$1\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"140\" height=\"105\"></embed>\
                                  </object>\
                                  <a href=\"$1\">$1</a>\
                                </div>"];
    } @catch (NSException *exception) {
      NSLog(@"Error inserting youtube widgets.");
    }
  }
  
  return body;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  if (scrollView == tableView) {
    [tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  }
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if (navigationType == UIWebViewNavigationTypeLinkClicked) {
    LatestChatty2AppDelegate *appDelegate = (LatestChatty2AppDelegate *)[[UIApplication sharedApplication] delegate];
    id viewController = [appDelegate viewControllerForURL:[request URL]];
    if (viewController == nil) viewController = [[[BrowserViewController alloc] initWithRequest:request] autorelease];
    [self.navigationController pushViewController:viewController animated:YES];
      
    return NO;
  }
  
  return YES;
}


#pragma mark Grippy Bar Methods

- (void)resetLayout {
  CGFloat usableHeight = self.view.frame.size.height - 24.0;
  CGFloat dividerLocation;
  
  switch (grippyBarPosition) {
    case 0:
      dividerLocation = 0.25;
      break;
      
    case 1:
      dividerLocation = 0.5;
      break;
      
    case 2:
      dividerLocation = 0.8;
      break;
  }
  
  [UIView beginAnimations:@"ResizePostView" context:nil];
  postView.frame = CGRectMake(postView.frame.origin.x,
                              postView.frame.origin.y,
                              postView.frame.size.width,
                              floor(usableHeight * dividerLocation));
  
  grippyBar.frame = CGRectMake(grippyBar.frame.origin.x,
                               floor(usableHeight * dividerLocation) - 12,
                               grippyBar.frame.size.width,
                               grippyBar.frame.size.height);
  
  tableView.frame = CGRectMake(tableView.frame.origin.x,
                               floor(usableHeight * dividerLocation) + 24,
                               tableView.frame.size.width,
                               floor(usableHeight * (1.0 - dividerLocation)));
  [UIView commitAnimations];
}

- (void)grippyBarDidSwipeUp {
  grippyBarPosition--;
  if (grippyBarPosition < 0) grippyBarPosition = 0;
  [self resetLayout];
}

- (void)grippyBarDidSwipeDown {
  grippyBarPosition++;
  if (grippyBarPosition > 2) grippyBarPosition = 2;
  [self resetLayout];
}


- (void)grippyBarDidTapRightButton; {
  NSIndexPath *oldIndexPath = selectedIndexPath;
  
  NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:oldIndexPath.row + 1 inSection:0];
  if (oldIndexPath.row == [[rootPost repliesArray] count] - 1) newIndexPath = oldIndexPath;
  
  [tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
  [self tableView:tableView didSelectRowAtIndexPath:newIndexPath];
}

- (void)grippyBarDidTapLeftButton {
  NSIndexPath *oldIndexPath = selectedIndexPath;
  
  NSIndexPath *newIndexPath;
  if (oldIndexPath.row == 0)
    newIndexPath = oldIndexPath;
  else
    newIndexPath = [NSIndexPath indexPathForRow:oldIndexPath.row - 1 inSection:0];
  
  [tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
  [self tableView:tableView didSelectRowAtIndexPath:newIndexPath];  
}

- (void)grippyBarDidTapRefreshButton {
  [self refresh:nil];
}

- (void)grippyBarDidTapTagButton {
  UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Tag this Post"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"LOL", @"INF", @"Mark", nil];
  [sheet showInView:self.view];
  [sheet release];
}

#pragma mark Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSUInteger postId = [[[rootPost repliesArray] objectAtIndex:selectedIndexPath.row] modelId];
  
  if (buttonIndex == 0) [Tag tagPostId:postId tag:TagTypeLOL];
  if (buttonIndex == 1) [Tag tagPostId:postId tag:TagTypeINF];
  if (buttonIndex == 2) [Tag tagPostId:postId tag:TagTypeMark];
}


#pragma mark Cleanup

- (void)dealloc {
  [rootPost release];
  [selectedIndexPath release];
  [super dealloc];
}


@end

