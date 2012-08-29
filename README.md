DCHTTPRequest
=============

DCHTTPRequest is a wrapper around NSHTTPRequest that simplifies its usability.

To use, simply init a DCHTTPRequest instead of a NSHTTPRequest.  Then either start it immediately, or queue it using the built in NSOperationQueue.  Use the completion block if you care about the response of the request.