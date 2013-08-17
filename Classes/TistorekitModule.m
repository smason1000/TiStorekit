/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TistorekitModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "Base64.h"

// Private
@interface TistorekitModule()
-(void)prepCallbacks:(id)args;
-(NSString *)localizedPrice:(SKProduct *)product;
@end

@implementation TistorekitModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"3ff6d2f2-0193-4ab8-9470-624b6882df2d";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"tistorekit";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added 
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

-(void)prepCallbacks:(id)args
{
	ENSURE_UI_THREAD_1_ARG(args);
	ENSURE_SINGLE_ARG(args, NSDictionary);
	
	// Store the callbacks for later.
	id success	= [args objectForKey:@"success"];
	id fail		= [args objectForKey:@"fail"];
	id error	= [args objectForKey:@"error"];
	
	// Make sure the instance callbacks are nil.
	RELEASE_TO_NIL(successCallback);
	RELEASE_TO_NIL(failCallback);
	RELEASE_TO_NIL(errorCallback);
	
	// Put the callbacks from the passed JS object into instance vars.
	if (success != nil)
	{
		ENSURE_TYPE(success, KrollCallback); // Verifies type.
		successCallback = [success retain];
	}
	if (fail != nil)
	{
		ENSURE_TYPE(fail, KrollCallback); // Verifies type.
		failCallback = [fail retain];
	}
	if (error != nil)
	{
		ENSURE_TYPE(error, KrollCallback); // Verifies type.
		errorCallback = [error retain];
	}
}

#pragma Public APIs

-(bool)canMakePayments:(id)args
{
	[self prepCallbacks:args];
	ENSURE_SINGLE_ARG(args, NSDictionary);
	
	if (![SKPaymentQueue canMakePayments])
    {
		NSLog(@"Cannot purchase products.");fflush(stderr);
        return false;
	}
    else
    {
		NSLog(@"Can purchase products.");fflush(stderr);
        return true;
    }
}

-(void)requestProducts:(id)args
{
	[self prepCallbacks:args];
	ENSURE_SINGLE_ARG(args, NSDictionary);
	
	if (![SKPaymentQueue canMakePayments])
    {
		NSLog(@"Cannot purchase products?");
        fflush(stderr);
	}
	
	NSSet *productIds = nil;
	id ids = [args objectForKey:@"identifiers"];
	if ([ids isKindOfClass:[NSString class]])
	{ // Single ID.
		productIds = [NSSet setWithObject:ids];
	}
	else if ([ids isKindOfClass:[NSArray class]])
	{
		productIds = [NSSet setWithArray:ids];
	}
	else
	{
		[self throwException:TiExceptionInvalidType subreason:[NSString stringWithFormat:@"tistorekit.requestProducts.identifiers must be passed: Array or String, was: %@", [ids class]] location:CODELOCATION];
	}
	
	SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
	request.delegate = self;
	[request start];
}

-(void)purchase:(id)args
{
	[self prepCallbacks:args];
	ENSURE_SINGLE_ARG(args, NSDictionary);
	
	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:[args objectForKey:@"identifier"]];
	
	id quantity = [args objectForKey:@"quantity"];
	if ([quantity isKindOfClass:[NSNumber class]])
    {
		payment.quantity = [quantity integerValue];
	}
    else
    {
		payment.quantity = 1;
    }
	
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(void)restoreCompletedTransactions:(id)args
{
	NSLog(@"restore all products!");fflush(stderr);
	
	[self prepCallbacks:args];
	
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark Private Parts

-(NSString *)localizedPrice:(SKProduct *)product
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    [numberFormatter release];
	
    return formattedString;
}

#pragma mark Delegates

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	NSMutableArray *purchased = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *failed = [[[NSMutableArray alloc] init] autorelease];
	
	for (SKPaymentTransaction *transaction in transactions)
    {
		NSMutableDictionary *response = [[[NSMutableDictionary alloc] init] autorelease];
		
		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased:
				[response setObject:@"PaymentTransactionStatePurchased" forKey:@"state"];
				[response setObject:transaction.transactionIdentifier forKey:@"transactionIdentifier"];
				[response setObject:[Base64 encode:transaction.transactionReceipt] forKey:@"receipt"];
				[response setObject:transaction.payment.productIdentifier forKey:@"identifier"];
				
				if ([purchased indexOfObjectIdenticalTo:response] == NSNotFound)
				{
					[purchased addObject:response];
				}
				
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction]; // Duplicated, but only do if state is correct/matched.
				break;
			case SKPaymentTransactionStateFailed:
				[response setObject:@"PaymentTransactionStateFailed" forKey:@"state"];
				[response setObject:transaction.error.localizedDescription forKey:@"message"];
				[response setObject:[NSNumber numberWithInteger:transaction.error.code] forKey:@"code"];
				
				if ([failed indexOfObjectIdenticalTo:response] == NSNotFound)
				{
					[failed addObject:response];
				}
				
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction]; // Duplicated, but only do if state is correct/matched.
				break;
			case SKPaymentTransactionStateRestored:
				[response setObject:@"PaymentTransactionStateRestored" forKey:@"state"];
				[response setObject:transaction.originalTransaction.transactionIdentifier forKey:@"transactionIdentifier"];
				[response setObject:[Base64 encode:transaction.transactionReceipt] forKey:@"receipt"];
				[response setObject:transaction.originalTransaction.payment.productIdentifier forKey:@"identifier"];
				
				if ([purchased indexOfObjectIdenticalTo:response] == NSNotFound)
				{
					[purchased addObject:response];
				}
				
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction]; // Duplicated, but only do if state is correct/matched.
				break;
				
			default:
				break;
		}
	}
	
	if (successCallback && [purchased count] > 0)
	{
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:purchased, @"purchased", nil];
		[self _fireEventToListener:@"success" withObject:event listener:successCallback thisObject:nil];
	}
	
	if (failCallback && [failed count] > 0)
	{
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:failed, @"failed", nil];
		[self _fireEventToListener:@"fail" withObject:event listener:failCallback thisObject:nil];
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
}

- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	if (successCallback)
	{
		NSMutableArray* products = [NSMutableArray array];
		for (SKProduct* product in response.products) {
			[products addObject:[NSDictionary dictionaryWithObjectsAndKeys:product.productIdentifier, @"identifier", product.localizedTitle, @"title", product.localizedDescription, @"description", [self localizedPrice:product], @"price", nil]];
		}
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:products, @"products", nil];
		[self _fireEventToListener:@"success" withObject:event listener:successCallback thisObject:nil];
	}
	
	if (failCallback && [response.invalidProductIdentifiers count] >= 1)
	{
		NSMutableArray* failed = [NSMutableArray array];
		for (NSString *invalidProductId in response.invalidProductIdentifiers) {
			[failed addObject:invalidProductId];
		}
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:failed, @"failed", nil];
		[self _fireEventToListener:@"fail" withObject:event listener:failCallback thisObject:nil];
	}
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Failed to connect with error: %@", [error localizedDescription]);fflush(stderr);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	NSLog(@"Payments restored...");
    fflush(stderr);
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	if (failCallback)
	{
		NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:error.code, @"code", error.localizedDescription, @"message", nil];
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:e, @"error", nil];
		[self _fireEventToListener:@"fail" withObject:event listener:failCallback thisObject:nil];
	}
}

@end
