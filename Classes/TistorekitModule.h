/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */

#import "TiModule.h"
#import <StoreKit/StoreKit.h>

#import "Base64.h"

@interface TistorekitModule : TiModule <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
	KrollCallback *successCallback;
	KrollCallback *failCallback;
	KrollCallback *errorCallback;
}

@end

