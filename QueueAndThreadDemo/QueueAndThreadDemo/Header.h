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

 队列（Dispatch Queue）这里的队列指执行任务的等待队列，即用来存放任务的队列。队列是一种特殊的线性表，采用 FIFO（先进先出）的原则，即新任务总是被插入到队列的末尾，而读取任务的时候总是从队列的头部开始读取。每读取一个任务，则从队列中释放一个任务。队列的结构可参考下图



 并发是关于结构，而并行是关于执行

 */


#endif /* Header_h */
