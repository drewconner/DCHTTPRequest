//
//  DCHTTPRequest.h
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

#import <Foundation/Foundation.h>


@class DCHTTPRequest;


typedef void (^DCHTTPRequestCompletionBlock)(DCHTTPRequest *, NSError *);


@protocol DCHTTPRequestDelegate <NSObject>

@optional
- (void)request:(DCHTTPRequest *)aRequest didReceivedResponse:(NSHTTPURLResponse *)aResponse;
- (void)requestFinished:(DCHTTPRequest *)aRequest;
- (void)requestFailed:(DCHTTPRequest *)aRequest withError:(NSError *)anError;

@end


@interface DCHTTPRequest : NSOperation <NSURLConnectionDelegate>

// DCHTTPRequest Specific Properties and Methods
@property (nonatomic, weak) id<DCHTTPRequestDelegate> delegate;
@property (nonatomic, assign) BOOL shouldUseBackgroundThread;
@property (nonatomic, strong) id userInfo;

+ (id)requestWithURL:(NSURL *)aURL;
- (id)initWithURL:(NSURL *)aURL;

+ (void)setMaximumConcurrentConnections:(NSInteger)maxConnections;


// HTTP Request Properties and Methods
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSData *httpBody;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;


// Request Lifecycle Methods

- (void)startImmediately;
- (void)startImmediatelyWithCompletionHandler:(DCHTTPRequestCompletionBlock)aHandler;

- (void)enqueue;
- (void)enqueueWithCompletionHandler:(DCHTTPRequestCompletionBlock)aHandler;

- (void)cancel;


// Response Properties
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSString *responseString;


@end
