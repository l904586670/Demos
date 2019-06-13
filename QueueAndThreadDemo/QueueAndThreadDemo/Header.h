//
//  Header.h
//  QueueAndThreadDemo
//
//  Created by Rock on 2019/6/13.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#ifndef Header_h
#define Header_h

// https://www.jianshu.com/p/2d57c72016c6
// https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2

/*
 单核设备以时间切片的方式在多个线程切换实现并发,
 多核设备可以通过多核并行执行多个线程实现并发.
 只有执行并发任务才可能实现多核并行. GCD会根据系统的可用资源决定它打开多核并行

 GCD是在共享线程池的基础上执行的并发任务

 队列（Dispatch Queue）这里的队列指执行任务的等待队列，即用来存放任务的队列。队列是一种特殊的线性表，采用 FIFO（先进先出）的原则，即新任务总是被插入到队列的末尾，而读取任务的时候总是从队列的头部开始读取。

 同步任务和异步任务. 同步任务会阻碍当前线程. 异步任务会开辟一个新线程(或者复用没有任务的线程)执行.不会阻碍当前线程

 // 串行队列 和 并行队列
 串行队列 : 一次只执行一个任务,当前任务执行完后,再执行下一个任务.所以无论是异步任务还是同步任务在串行对列中都是按添加顺序执行
          同步和异步的区别在于同步在当前线程按顺序执行. 异步会创建一个线程按顺序执行(第一个异步创建一个线程A,后面的异步任务复用线程A)
 并行队列 :一次可以执行多个任务.但是执行多个任务的顺序也是按添加的顺序执行的(FIFO). 添加同步任务不会开辟新线程,阻碍当前线程执行,所以会添加顺序执行
          添加异步任务,gcd按fifo原则执行任务,异步任务会开辟线程执行,线程会加入到线程池中由cpu调用.(不清楚是线程的开辟耗时还是cpu无序调用线程).异步任务的执行顺序从log上看是无序的.

 并发是关于结构，而并行是关于执行

 栅栏函数
 并发队列里面添加栅栏函数 dispatch_barrier_async / dispatch_barrier_sync . 用于确保多线程数据读写安全. 栅栏函数里面的方法会在栅栏函数以前的任务完全执行完毕后调用.  栅栏函数 后面的任务会在栅栏函数里面的任务执行完毕后开始执行. dispatch_barrier_async/dispatch_barrier_sync 区别就是dispatch_barrier_async有开辟线程的能力,会在另外的线程执行任务,不会阻碍当前线程. dispatch_barrier_sync 会在添加当前线程(添加栅栏函数的线程)执行任务,会阻碍当前线程.

 */


#endif /* Header_h */
