package com.apparence.camerawesome.utils

import java.util.concurrent.TimeUnit
import java.util.concurrent.locks.AbstractQueuedSynchronizer

/**
 * A synchronization aid that allows one or more threads to wait until
 * a set of operations being performed in other threads completes.
 *
 *
 * A `CountDownLatch` is initialized with a given *count*.
 * The [await][.await] methods block until the current count reaches
 * zero due to invocations of the [.countDown] method, after which
 * all waiting threads are released and any subsequent invocations of
 * [await][.await] return immediately.  This is a one-shot phenomenon
 * -- the count cannot be reset.  If you need a version that resets the
 * count, consider using a [CyclicBarrier].
 *
 *
 * A `CountDownLatch` is a versatile synchronization tool
 * and can be used for a number of purposes.  A
 * `CountDownLatch` initialized with a count of one serves as a
 * simple on/off latch, or gate: all threads invoking [await][.await]
 * wait at the gate until it is opened by a thread invoking [ ][.countDown].  A `CountDownLatch` initialized to *N*
 * can be used to make one thread wait until *N* threads have
 * completed some action, or some action has been completed N times.
 *
 *
 * A useful property of a `CountDownLatch` is that it
 * doesn't require that threads calling `countDown` wait for
 * the count to reach zero before proceeding, it simply prevents any
 * thread from proceeding past an [await][.await] until all
 * threads could pass.
 *
 *
 * **Sample usage:** Here is a pair of classes in which a group
 * of worker threads use two countdown latches:
 *
 *  * The first is a start signal that prevents any worker from proceeding
 * until the driver is ready for them to proceed;
 *  * The second is a completion signal that allows the driver to wait
 * until all workers have completed.
 *
 *
 * <pre>
 * class Driver { // ...
 * void main() throws InterruptedException {
 * CountDownLatch startSignal = new CountDownLatch(1);
 * CountDownLatch doneSignal = new CountDownLatch(N);
 *
 * for (int i = 0; i < N; ++i) // create and start threads
 * new Thread(new Worker(startSignal, doneSignal)).start();
 *
 * doSomethingElse();            // don't let run yet
 * startSignal.countDown();      // let all threads proceed
 * doSomethingElse();
 * doneSignal.await();           // wait for all to finish
 * }
 * }
 *
 * class Worker implements Runnable {
 * private final CountDownLatch startSignal;
 * private final CountDownLatch doneSignal;
 * Worker(CountDownLatch startSignal, CountDownLatch doneSignal) {
 * this.startSignal = startSignal;
 * this.doneSignal = doneSignal;
 * }
 * public void run() {
 * try {
 * startSignal.await();
 * doWork();
 * doneSignal.countDown();
 * } catch (InterruptedException ex) {} // return;
 * }
 *
 * void doWork() { ... }
 * }
 *
</pre> *
 *
 *
 * Another typical usage would be to divide a problem into N parts,
 * describe each part with a Runnable that executes that portion and
 * counts down on the latch, and queue all the Runnables to an
 * Executor.  When all sub-parts are complete, the coordinating thread
 * will be able to pass through await. (When threads must repeatedly
 * count down in this way, instead use a [CyclicBarrier].)
 *
 * <pre>
 * class Driver2 { // ...
 * void main() throws InterruptedException {
 * CountDownLatch doneSignal = new CountDownLatch(N);
 * Executor e = ...
 *
 * for (int i = 0; i < N; ++i) // create and start threads
 * e.execute(new WorkerRunnable(doneSignal, i));
 *
 * doneSignal.await();           // wait for all to finish
 * }
 * }
 *
 * class WorkerRunnable implements Runnable {
 * private final CountDownLatch doneSignal;
 * private final int i;
 * WorkerRunnable(CountDownLatch doneSignal, int i) {
 * this.doneSignal = doneSignal;
 * this.i = i;
 * }
 * public void run() {
 * try {
 * doWork(i);
 * doneSignal.countDown();
 * } catch (InterruptedException ex) {} // return;
 * }
 *
 * void doWork() { ... }
 * }
 *
</pre> *
 *
 *
 * Memory consistency effects: Actions in a thread prior to calling
 * `countDown()`
 * [*happen-before*](package-summary.html#MemoryVisibility)
 * actions following a successful return from a corresponding
 * `await()` in another thread.
 *
 * @since 1.5
 * @author Doug Lea
 */
class ResettableCountDownLatch(count: Int) {
    /**
     * Synchronization control For CountDownLatch.
     * Uses AQS state to represent count.
     */
    private class Sync internal constructor(val startCount: Int) : AbstractQueuedSynchronizer() {
        init {
            state = startCount
        }

        val count: Int
            get() = state

        public override fun tryAcquireShared(acquires: Int): Int {
            return if (state == 0) 1 else -1
        }

        public override fun tryReleaseShared(releases: Int): Boolean {
            // Decrement count; signal when transition to zero
            while (true) {
                val c = state
                if (c == 0) return false
                val nextc = c - 1
                if (compareAndSetState(c, nextc)) return nextc == 0
            }
        }

        fun reset() {
            state = startCount
        }

        companion object {
            private const val serialVersionUID = 4982264981922014374L
        }
    }

    private val sync: Sync

    /**
     * Constructs a `CountDownLatch` initialized with the given count.
     *
     * @param count the number of times [.countDown] must be invoked
     * before threads can pass through [.await]
     * @throws IllegalArgumentException if `count` is negative
     */
    init {
        require(count >= 0) { "count < 0" }
        sync = Sync(count)
    }

    /**
     * Causes the current thread to wait until the latch has counted down to
     * zero, unless the thread is [interrupted][Thread.interrupt].
     *
     *
     * If the current count is zero then this method returns immediately.
     *
     *
     * If the current count is greater than zero then the current
     * thread becomes disabled for thread scheduling purposes and lies
     * dormant until one of two things happen:
     *
     *  * The count reaches zero due to invocations of the
     * [.countDown] method; or
     *  * Some other thread [interrupts][Thread.interrupt]
     * the current thread.
     *
     *
     *
     * If the current thread:
     *
     *  * has its interrupted status set on entry to this method; or
     *  * is [interrupted][Thread.interrupt] while waiting,
     *
     * then [InterruptedException] is thrown and the current thread's
     * interrupted status is cleared.
     *
     * @throws InterruptedException if the current thread is interrupted
     * while waiting
     */
    @Throws(InterruptedException::class)
    fun await() {
        sync.acquireSharedInterruptibly(1)
    }

    fun reset() {
        sync.reset()
    }

    /**
     * Causes the current thread to wait until the latch has counted down to
     * zero, unless the thread is [interrupted][Thread.interrupt],
     * or the specified waiting time elapses.
     *
     *
     * If the current count is zero then this method returns immediately
     * with the value `true`.
     *
     *
     * If the current count is greater than zero then the current
     * thread becomes disabled for thread scheduling purposes and lies
     * dormant until one of three things happen:
     *
     *  * The count reaches zero due to invocations of the
     * [.countDown] method; or
     *  * Some other thread [interrupts][Thread.interrupt]
     * the current thread; or
     *  * The specified waiting time elapses.
     *
     *
     *
     * If the count reaches zero then the method returns with the
     * value `true`.
     *
     *
     * If the current thread:
     *
     *  * has its interrupted status set on entry to this method; or
     *  * is [interrupted][Thread.interrupt] while waiting,
     *
     * then [InterruptedException] is thrown and the current thread's
     * interrupted status is cleared.
     *
     *
     * If the specified waiting time elapses then the value `false`
     * is returned.  If the time is less than or equal to zero, the method
     * will not wait at all.
     *
     * @param timeout the maximum time to wait
     * @param unit the time unit of the `timeout` argument
     * @return `true` if the count reached zero and `false`
     * if the waiting time elapsed before the count reached zero
     * @throws InterruptedException if the current thread is interrupted
     * while waiting
     */
    @Throws(InterruptedException::class)
    fun await(timeout: Long, unit: TimeUnit): Boolean {
        return sync.tryAcquireSharedNanos(1, unit.toNanos(timeout))
    }

    /**
     * Decrements the count of the latch, releasing all waiting threads if
     * the count reaches zero.
     *
     *
     * If the current count is greater than zero then it is decremented.
     * If the new count is zero then all waiting threads are re-enabled for
     * thread scheduling purposes.
     *
     *
     * If the current count equals zero then nothing happens.
     */
    fun countDown() {
        sync.releaseShared(1)
    }

    /**
     * Returns the current count.
     *
     *
     * This method is typically used for debugging and testing purposes.
     *
     * @return the current count
     */
    val count: Int
        get() = sync.count

    /**
     * Returns a string identifying this latch, as well as its state.
     * The state, in brackets, includes the String `"Count ="`
     * followed by the current count.
     *
     * @return a string identifying this latch, as well as its state
     */
    override fun toString(): String {
        return super.toString() + "[Count = " + sync.count + "]"
    }
}