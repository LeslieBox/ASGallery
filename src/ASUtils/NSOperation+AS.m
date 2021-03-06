//
//  NSOperation+ext.m
//
//  Created by Andrey Syvrachev on 22.10.12. andreyalright@gmail.com
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSOperation+AS.h"
#import <objc/runtime.h>



@implementation NSOperationCompletion

+(NSOperationCompletion*)completionWithBlock:(NSOperationCompletionBlock)block onThread:(NSThread*)thread
{
    NSOperationCompletion* cb = [[NSOperationCompletion alloc] init];
    cb.block = block;
    cb.thread = thread;
    return cb;
}

+(NSOperationCompletion*)completionWithTarget:(id)target selector:(SEL)selector onThread:(NSThread*)thread
{
    NSOperationCompletion* cb = [[NSOperationCompletion alloc] init];
    cb.target = target;
    cb.selector = selector;
    cb.thread = thread;
    return cb;
}


@end

static char completionBlocksArrayKey;

@implementation NSOperation (ext)

-(void)callCompletionBlock:(NSOperationCompletion*)cb
{
    if (cb)
        cb.block(self);
}

-(void)addCompletion:(NSOperationCompletion*)block
{
    NSMutableArray* completionBlocks = objc_getAssociatedObject(self,&completionBlocksArrayKey);
    if (completionBlocks == nil)
    {
        completionBlocks = [NSMutableArray array];
        objc_setAssociatedObject(self, &completionBlocksArrayKey, completionBlocks, OBJC_ASSOCIATION_RETAIN);
    }
    [completionBlocks addObject:block];
    
    if (!self.completionBlock)
    {
        // set real completion block to self
        __weak NSOperation* SELF = self;
        
        self.completionBlock = ^{
            
            @synchronized(SELF){
                for (NSOperationCompletion* cb in completionBlocks) {
                    
                    if (cb.target)
                        [cb.target performSelector:cb.selector onThread:cb.thread withObject:SELF waitUntilDone:NO];
                    
                    if (cb.block)
                        [SELF performSelector:@selector(callCompletionBlock:) onThread:cb.thread withObject:cb waitUntilDone:NO];
                }
            }
            
        };
    }
}

@end
