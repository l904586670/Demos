//
//  ViewController.m
//  QueueAndThreadDemo
//
//  Created by Rock on 2019/6/13.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, strong) dispatch_queue_t serialQueue;     // 串行
@property(nonatomic, strong) dispatch_queue_t concurrentQueue;  // 并发

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
  self.concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);

//  [self mainQueueAddAsyncTask];

//  [self mainQueueAddSyncTask];

//  [self serialQueueAddAsyncTask];

//  [self serialQueueAddSyncTask];

  [self serialQueueAddTask];


//  [self concurrentQueueAddAsyncTask];

//  [self concurrentQueueAddSyncTask];

//  [self concurrentQueueAddTask];

//  [self concurrentQueueAddBarrier];
}

#pragma mark - 队列和任务

// 主线程是串行
// 主线程测试添加异步任务到主线程, 结果: 任务会追加到最后面去
- (void)mainQueueAddAsyncTask {
  NSLog(@"main start");
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"main async0");
  });
  sleep(1);
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"main async1");
  });
  sleep(1);
  NSLog(@"main end");
}

// 主线程添加同步任务到主线程 结果 : EXC_BAD_INSTRUCTION 死锁. 在执行同步的代码处crash
// 在串行队列中添加同步任务到当前线程会产生死锁
- (void)mainQueueAddSyncTask {
  NSLog(@"main start");
  dispatch_sync(dispatch_get_main_queue(), ^{
    NSLog(@"main async0");
  });

  NSLog(@"main end");
}



// 串行队列中添加异步任务 结果 : 会异步开辟出一个新线程.因为fifo的原则.在串行队列中同一时间只执行一个任务. 所以任务按顺序执行, 根据设备性能的不同,开辟线程的时长不同, task async0 start 和 custom Async end的打印顺序不同
- (void)serialQueueAddAsyncTask {
  NSLog(@"current Thread : %@", [NSThread currentThread]);
  NSLog(@"custom Async start");
  sleep(1);
  dispatch_async(self.serialQueue, ^{
    NSLog(@"task async0 start");
    NSLog(@"current Thread : %@", [NSThread currentThread]);
    sleep(3);
    NSLog(@"task async0 end");
  });

  dispatch_async(self.serialQueue, ^{
    NSLog(@"task async1 start");
    NSLog(@"current Thread : %@", [NSThread currentThread]);
    sleep(1);
    NSLog(@"task async1 end");
  });

  sleep(1);
  dispatch_async(self.serialQueue, ^{
    NSLog(@"task async2 start");
    NSLog(@"current Thread : %@", [NSThread currentThread]);
    NSLog(@"task async2 end");
  });
  NSLog(@"custom Async end");
}

// 串行队列中添加同步任务 结果: 添加同步任务. 会阻塞当前串行线程,按顺序执行.
- (void)serialQueueAddSyncTask {
  NSLog(@"custom Async start");
  dispatch_sync(self.serialQueue, ^{
    NSLog(@"task sync0 start");
    sleep(3);
    NSLog(@"task sync0 end");
  });

  dispatch_sync(self.serialQueue, ^{
    NSLog(@"task sync1 start");
    sleep(1);
    NSLog(@"task sync1 end");
  });

  dispatch_sync(self.serialQueue, ^{
    NSLog(@"task sync2 start");
    NSLog(@"task sync2 end");
  });
  NSLog(@"custom Async end");
}

// 串行队列添加混合任务 , 结果: 在串行队列中添加任务, 都是按添加顺序执行. 在串行队列任务中再次执行同步任务会产生死锁
- (void)serialQueueAddTask {
  NSLog(@"custom Async start");
  NSLog(@"current Thread : %@", [NSThread currentThread]);

  dispatch_sync(self.serialQueue, ^{
    NSLog(@"task sync0 start");
    NSLog(@"current Thread : %@", [NSThread currentThread]);
    sleep(1);
    NSLog(@"task sync0 end");
  });

  dispatch_async(self.serialQueue, ^{
    NSLog(@"task async0 start");
    sleep(2);
    NSLog(@"current Thread : %@", [NSThread currentThread]);
    NSLog(@"task async0 end");
  });

  dispatch_async(self.serialQueue, ^{
    NSLog(@"task async3 start");
    sleep(1);
    NSLog(@"current Thread : %@", [NSThread currentThread]);
    NSLog(@"task async3 end");
  });

  dispatch_sync(self.serialQueue, ^{
    NSLog(@"task sync1 start");
    sleep(1);
    NSLog(@"task sync1 end");
  });

  dispatch_async(self.serialQueue, ^{
    NSLog(@"task async2 start");
    NSLog(@"current Thread : %@", [NSThread currentThread]);
    NSLog(@"task async2 end");
  });
  NSLog(@"custom Async end");
}

#pragma mark - /*********************/

// 并发队列添加异步任务. 结果: 并发队列添加异步任务, 会开辟新线程. log显示任务的执行顺序不定(可能原因为创建线程耗时. 或者添加到的线程有任务没有执行完?).任务执行结束的时长看任务的耗时
- (void)concurrentQueueAddAsyncTask {
  NSLog(@"custom concurrent start");

  dispatch_async(self.concurrentQueue, ^{
    NSLog(@"task async0 start currentThread : %@", [NSThread currentThread]);
    sleep(3);
    NSLog(@"task async0 end");
  });

  dispatch_async(self.concurrentQueue, ^{
    NSLog(@"task async1 start currentThread : %@", [NSThread currentThread]);
    sleep(1);
    NSLog(@"task async1 end");
  });

  dispatch_async(self.concurrentQueue, ^{
    NSLog(@"task async2 start currentThread : %@", [NSThread currentThread]);
    NSLog(@"task async2 end");
  });
  NSLog(@"custom concurrent end");
}


// 并发执行添加同步任务. 结果: 任务按顺序执行fifo. 同步任务没有开辟线程的能力,所以等上一个任务执行完才会执行下一个任务
- (void)concurrentQueueAddSyncTask {
  NSLog(@"custom concurrent start");

  dispatch_sync(self.concurrentQueue, ^{
    NSLog(@"task sync0 start currentThread : %@", [NSThread currentThread]);
    sleep(3);
    NSLog(@"task sync0 end");
  });

  dispatch_sync(self.concurrentQueue, ^{
    NSLog(@"task sync1 start currentThread : %@", [NSThread currentThread]);
    sleep(1);
    NSLog(@"task sync1 end");
  });

  dispatch_sync(self.concurrentQueue, ^{
    NSLog(@"task sync2 start currentThread : %@", [NSThread currentThread]);
    NSLog(@"task sync2 end");
  });
  NSLog(@"custom concurrent end");
}

// 并发队列添加混合任务, 执行任务顺序是随机的
- (void)concurrentQueueAddTask {
  dispatch_async(self.concurrentQueue, ^{
    NSLog(@"task async1 start currentThread : %@", [NSThread currentThread]);
    sleep(1);
    NSLog(@"task async1 end");
  });

  dispatch_sync(self.concurrentQueue, ^{
    NSLog(@"task sync0 start currentThread : %@", [NSThread currentThread]);
    sleep(1);
    NSLog(@"task sync0 end");
  });

  dispatch_async(self.concurrentQueue, ^{
    NSLog(@"task async2 start currentThread : %@", [NSThread currentThread]);
    sleep(2);
    NSLog(@"task async2 end");
  });
}

// 并发队列里面添加栅栏函数 dispatch_barrier_async / dispatch_barrier_sync . 用于确保多线程数据读写安全. 栅栏函数里面的方法会在栅栏函数以前的任务完全执行完毕后调用.  栅栏函数 后面的任务会在栅栏函数里面的任务执行完毕后执行. dispatch_barrier_async/dispatch_barrier_sync 区别就是dispatch_barrier_async有开辟线程的能力,会在另外的线程执行任务,不会阻碍当前线程. dispatch_barrier_sync 会在添加当前线程(添加栅栏函数的线程)执行任务,会阻碍当前线程.
- (void)concurrentQueueAddBarrier {
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    dispatch_async(self.concurrentQueue, ^{
      NSLog(@"log 0");
      sleep(1);
      NSLog(@"log 0 end");
    });

    dispatch_async(self.concurrentQueue, ^{
      NSLog(@"log 1");
      sleep(2);
      NSLog(@"log 1 end");
    });

    dispatch_async(self.concurrentQueue, ^{
      NSLog(@"log 2");
      NSLog(@"log 2 end");
      NSLog(@"current thread : %@", [NSThread currentThread]);
    });

    dispatch_barrier_sync(self.concurrentQueue, ^{
      NSLog(@"log barrier start");
      sleep(2);
      NSLog(@"current thread : %@", [NSThread currentThread]);
      NSLog(@"log barrier end");
    });

    dispatch_async(self.concurrentQueue, ^{
      NSLog(@"log 3");
      NSLog(@"log 3 end");
    });

    NSLog(@"end");
  });
}


@end
