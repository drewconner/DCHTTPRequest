//
//  DCHTTPRequest.m
//  DCHTTPRequest
//
//  Created by Drew Conner on 2/14/12.
//  Copyright (c) 2012 Drew Conner. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// 

#import "DCHTTPRequest.h"

@interface DCHTTPRequest ()

@property (nonatomic, strong, readonly) NSMutableDictionary *headerFields;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) BOOL backgroundSupported;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, copy) DCHTTPRequestCompletionBlock completionHandler;

+ (NSOperationQueue *)connectionQueue;
- (NSOperationQueue *)backgroundQueue;
- (NSURLRequest *)createRequest;
- (void)finish;

@end


@implementation DCHTTPRequest

@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize cachePolicy = _cachePolicy;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize httpMethod = _httpMethod;
@synthesize httpBody = _httpBody;
@synthesize shouldUseBackgroundThread = _shouldUseBackgroundThread;
@synthesize userInfo = _userInfo;
@synthesize response = _response;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize headerFields = _headerFields;
@synthesize connection = _connection;
@synthesize backgroundSupported = _backgroundSupported;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;
@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize completionHandler = _completionHandler;


#pragma mark - Properites

- (NSMutableDictionary *)headerFields {
	if (!_headerFields) {
		_headerFields = [[NSMutableDictionary alloc] init];
	}
	
	return _headerFields;
}

- (void)setExecuting:(BOOL)executing {
	if (executing != _executing) {
		[self willChangeValueForKey:@"isExecuting"];
		_executing = executing;
		[self didChangeValueForKey:@"isExecuting"];
	}
}

- (void)setFinished:(BOOL)finished {
	if (finished != _finished) {
		[self willChangeValueForKey:@"isFinished"];
		_finished = finished;
		[self didChangeValueForKey:@"isFinished"];
	}
}


#pragma mark - Constructor

+ (id)requestWithURL:(NSURL *)aURL {
	return [[DCHTTPRequest alloc] initWithURL:aURL];
}


#pragma mark - Initalization

- (id)initWithURL:(NSURL *)aURL {
	self = [super init];
	
	if (self) {
		self.url = aURL;
		self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
		self.timeoutInterval = 60.0f;
		
		UIDevice *device = [UIDevice currentDevice];
		if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
			self.backgroundSupported = device.multitaskingSupported;
		} else {
			self.backgroundSupported = NO;
		}
	}
	
	return self;
}


#pragma mark - Class Methods

+ (NSOperationQueue *)connectionQueue {
	static NSOperationQueue *connectionQueue = nil;
	
	if (connectionQueue == nil) {
		connectionQueue = [[NSOperationQueue alloc] init];
		[connectionQueue setMaxConcurrentOperationCount:3];
	}
	
	return connectionQueue;
}

+ (void)setMaximumConcurrentConnections:(NSInteger)maxConnections {
	[[self connectionQueue] setMaxConcurrentOperationCount:maxConnections];
}


#pragma mark - Public Methods

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
	[self.headerFields setValue:value forKey:field];
}

- (void)startImmediately {
	[self startBackgroundTask];
	
	NSURLRequest *request = [self createRequest];
	
	self.responseData = [[NSMutableData alloc] init];
	
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	if (self.shouldUseBackgroundThread) {
		[self.connection setDelegateQueue:self.backgroundQueue];
	}
	
	[self.connection start];
}

- (void)startImmediatelyWithCompletionHandler:(DCHTTPRequestCompletionBlock)aHandler {
	[self startBackgroundTask];
	
	NSURLRequest *request = [self createRequest];
	
	self.responseData = [[NSMutableData alloc] init];
	
	NSOperationQueue *queue = nil;
	
	if (self.shouldUseBackgroundThread) {
		queue = self.backgroundQueue;
	} else {
		queue = [NSOperationQueue mainQueue];
	}
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:queue
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
							   self.response = (NSHTTPURLResponse *)response;
							   [self.responseData appendData:data];
							   self.responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
							   
							   aHandler(self, error);
							   
							   [self finish];
						   }];
}

- (void)enqueue {
	[self enqueueWithCompletionHandler:nil];
}

- (void)enqueueWithCompletionHandler:(DCHTTPRequestCompletionBlock)aHandler {
	[self startBackgroundTask];
	
	self.completionHandler = aHandler;
	
	[[DCHTTPRequest connectionQueue] addOperation:self];
}

- (void)cancel {
	[super cancel];
	
	[self finish];
}


#pragma mark - Private Methods

- (NSOperationQueue *)backgroundQueue {
	static NSOperationQueue *backgroundQueue = nil;
	
	if (backgroundQueue == nil) {
		backgroundQueue = [[NSOperationQueue alloc] init];
	}
	
	return backgroundQueue;
}

- (NSURLRequest *)createRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url cachePolicy:self.cachePolicy timeoutInterval:self.timeoutInterval];
	
	if (self.httpMethod) {
		[request setHTTPMethod:self.httpMethod];
	}

	if (self.headerFields.count > 0) {
		[request setAllHTTPHeaderFields:self.headerFields];
	}
	
	if (self.httpBody) {
		[request setHTTPBody:self.httpBody];
	}
	
	return request;
}

- (void)startBackgroundTask {
	if (!self.backgroundSupported) return;
	
	UIApplication *application = [UIApplication sharedApplication];
	
	self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
		[self cancel];
		
        [application endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
}

- (void)finish {
	[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
	self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
	
	self.delegate = nil;
	self.completionHandler = nil;
	
	if (self.connection) {
		[self.connection cancel];
		self.connection = nil;
	}
	
	self.executing = NO;
	self.finished = YES;
}


#pragma mark - <NSOperation> Methods

- (void)start {
	self.executing = YES;
	
	[self main];
}

- (void)main {
	if (self.completionHandler) {
		[self startImmediatelyWithCompletionHandler:self.completionHandler];
	} else {
		[self startImmediately];
		
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (self.isFinished == NO);
	}
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isReady {
	return YES;
}

- (BOOL)isExecuting {
	return self.executing;
}

- (BOOL)isFinished {
	return self.finished;
}


#pragma mark - <NSURLConnectionDelegate> Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.response = (NSHTTPURLResponse *)response;
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(request:didReceivedResponse:)]) {
		[self.delegate request:self didReceivedResponse:self.response];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(requestFinished:)]) {
		[self.delegate requestFinished:self];
	}
	
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if (self.delegate && [self.delegate respondsToSelector:@selector(requestFailed:withError:)]) {
		[self.delegate requestFailed:self withError:error];
	}
	
	[self finish];
}


@end
