//
//  CombineTests.swift
//  CombineTests
//
//  Created by EXZACKLY on 11/21/19.
//  Copyright © 2019 EXZACKLY. All rights reserved.
//

import Combine
import XCTest

class CombineTests: XCTestCase {
    
    //MARK: - Publishers
    
    func testJustPublisher() {
        let justValue = 7
        let expectedValue = justValue
        
        let justPublisher = Just(justValue) // Test line
        
        let justSubscriber = justPublisher
            .sink { XCTAssertEqual($0, expectedValue) }
        
        justSubscriber.cancel()
    }
    
    func testFuturePublisher() {
        let successExpectation = XCTestExpectation(description: "success expectation")
        let failureExpectation = XCTestExpectation(description: "failure expectation")
        
        let successFuturePublisher = Future<Void, CombineError>() { promise in promise(.success(())) } // Test line
        let failureFuturePublisher = Future<Void, CombineError>() { promise in promise(.failure(CombineError())) } // Test line
        
        let successFutureSubscriber = successFuturePublisher
            .assertNoFailure()
            .sink { _ in successExpectation.fulfill() }
        
        let failureFutureSubscriber = failureFuturePublisher
            .sink(receiveCompletion: { _ in failureExpectation.fulfill() },
                  receiveValue: { _ in XCTFail("Should not receive value") })
        
        wait(for: [successExpectation, failureExpectation], timeout: Constants.expectationTimeout)
        successFutureSubscriber.cancel()
        failureFutureSubscriber.cancel()
    }
    
    func testPublishedPublisher() {
        let replacementValue = 21
        let expectedSequenceValues = [PublishedWrapper.initialValue, replacementValue]
        
        let publishedWrapper = PublishedWrapper()
        let publishedPublisher = publishedWrapper.$publishedValue
        
        let publishedValueSubscriber = publishedPublisher
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        publishedWrapper.publishedValue = replacementValue // Test line
        
        publishedValueSubscriber.cancel()
    }
    
    func testEmptyPublisher() {
        let passthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let passthroughSubjectSubscriber = passthroughSubjectPublisher
            .flatMap { _ in Empty<Void, Never>() } // Test line
            .sink { _ in XCTFail("Should not receive value") }
        
        passthroughSubjectPublisher.send()
        
        passthroughSubjectSubscriber.cancel()
    }
    
    func testFailPublisher() {
        let correctErrorValue = 7
        let wrongErrorValue = 21
        let expectedValue = correctErrorValue
        
        let failPublisher = Fail<Int, Error>(error: CombineError()) // Test line
        
        let failSubscriber = failPublisher
            .catch { $0 is CombineError ? Just(correctErrorValue) : Just(wrongErrorValue) }
            .sink { XCTAssertEqual($0, expectedValue) }
        
        failSubscriber.cancel()
    }
    
    func testSequencePublisher() {
        let sequenceValues = [7,21,721]
        let expectedSequenceValues = sequenceValues
        
        let sequencePublisher = sequenceValues.publisher // Test line
        
        let sequenceSubscriber = sequencePublisher
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        sequenceSubscriber.cancel()
    }
    
    func testDeferredPublisher() {
        var isCreatingTooEarly = true
        
        let deferredPublisher = Deferred<PassthroughSubject<Int, Never>> {
            if isCreatingTooEarly {
                XCTFail("Should not create before setting isCreatingTooEarly to false")
            }
            return PassthroughSubject<Int, Never>()
        }
        
        isCreatingTooEarly = false // Test line
        
        let deferredSubscriber = deferredPublisher
            .sink { _ in }
        
        deferredSubscriber.cancel()
    }
    
    func testObservableObjectPublisher() {
        let expectation = XCTestExpectation()
        
        let replacementValue = 21
        
        let publishedWrapper = PublishedWrapper()
        
        let objectWillChangeSubscriber = publishedWrapper.objectWillChange
            .sink { _ in expectation.fulfill() }
        
        publishedWrapper.publishedValue = replacementValue // Test line
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        objectWillChangeSubscriber.cancel()
    }
    
    func testNotificationCenterPublisher() {
        let expectation = XCTestExpectation()
        
        let notificationName = Notification.Name(rawValue: "TestName")
        let notification = Notification(name: notificationName)
        
        let notificationCenterPublisher = NotificationCenter.default.publisher(for: notificationName)
        
        let notificationCenterSubscriber = notificationCenterPublisher
            .sink { _ in expectation.fulfill() }
        
        NotificationCenter.default.post(notification) // Test line
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        notificationCenterSubscriber.cancel()
    }
    
    func testTimerPublisher() {
        let expectation = XCTestExpectation()
        
        var counter = 0
        let counterTarget = 10
        
        let timerPublisher = Timer.publish(every: 0.001, on: .main, in: .common) // Test line
        
        let timerSubscriber = timerPublisher
            .autoconnect()
            .map { _ in counter += 1 }
            .filter { _ in counter > counterTarget }
            .sink { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        timerSubscriber.cancel()
    }
    
    func testKVOPublisher() {
        let expectation = XCTestExpectation()
        
        let replacementValue = 7
        let expectedValue = replacementValue
        
        let valueWrapper = KVOValueWrapper()
        
        let KVOPublisher = valueWrapper.publisher(for: \.value)
        
        let KVOSubscriber = KVOPublisher
            .filter { $0 == expectedValue }
            .sink { _ in expectation.fulfill() }
        
        valueWrapper.value = replacementValue // Test line
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        KVOSubscriber.cancel()
    }
    
    func testBufferPublisher() {
        let bufferSize = 4
        let sequence = [1,2,3,4,5,6,7]
        let expectedSequenceValues = Array(sequence.dropFirst(sequence.count - bufferSize))
        
        let sequencePublisher = sequence.publisher
        
        let bufferSubscriber = Publishers.Buffer(upstream: sequencePublisher,
                                                 size: bufferSize,
                                                 prefetch: .byRequest,
                                                 whenFull: .dropOldest) // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        bufferSubscriber.cancel()
    }
    
    func testResultPublisher() {
        let successValue = 7
        let expectedValue = successValue
        let error = CombineError()
        let expectedError = error
        
        let successResultPublisher = Result { return successValue }.publisher // Test line
        let failureResultPublisher = Result { throw error }.publisher // Test line
        let successResultSubscriber = successResultPublisher
            .assertNoFailure()
            .sink { XCTAssertEqual($0, expectedValue) }
        
        let failureResultSubscriber = failureResultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should not receive finished")
                case .failure(let error):
                    XCTAssertEqual(error as? CombineError, expectedError)
                }
            },
                  receiveValue: { _ in XCTFail("Should not receive value") })
        
        successResultSubscriber.cancel()
        failureResultSubscriber.cancel()
    }
    
    //MARK: - Operators
    
    func testScan() {
        let initialValue = 7
        let expectedSequenceValues = [14,35,756]
        
        let sequencePublisher = [7,21,721].publisher
        
        let sequenceSubscriber = sequencePublisher
            .scan(initialValue) { $0 + $1 } // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        sequenceSubscriber.cancel()
    }
    
    func testMap() {
        let sequenceValues = [7,21,721]
        let adjustmentValue = 4
        let expectedSequenceValues = [11,25,725]
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .map { $0 + adjustmentValue } // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        sequenceSubscriber.cancel()
    }
    
    func testFlatMap() {
        typealias IntPassthroughSubjectType = PassthroughSubject<Int, Never>
        
        let sendValue = 7
        let expectedValue = sendValue
        
        let passthroughSubjectPublisher = IntPassthroughSubjectType()
        let passthroughSubjectPublisherPublisher = PassthroughSubject<IntPassthroughSubjectType, Never>()
        
        let passthroughSubjectPublisherSubscriber = passthroughSubjectPublisherPublisher
            .flatMap { $0 } // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        passthroughSubjectPublisherPublisher.send(passthroughSubjectPublisher)
        passthroughSubjectPublisher.send(sendValue)
        
        passthroughSubjectPublisherSubscriber.cancel()
    }
    
    func testSetFailureType() {
        let expectation = XCTestExpectation()
        
        let neverErrorPassthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        let errorPassthroughSubjectPublisher = PassthroughSubject<Void, Error>()
        
        let zipPassthroughSubjectSubscriber = Publishers.Zip(
            neverErrorPassthroughSubjectPublisher
                .setFailureType(to: Error.self), // Test line
            errorPassthroughSubjectPublisher
        )
            .replaceError(with: ((), ()))
            .sink { _ in expectation.fulfill() }
        
        neverErrorPassthroughSubjectPublisher.send()
        errorPassthroughSubjectPublisher.send()
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        zipPassthroughSubjectSubscriber.cancel()
    }
    
    // MARK: - Filtering Elements
    
    func testCompactMap() {
        let sequenceValues = [nil,7,nil,21,721,nil]
        let expectedValue = 749
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .compactMap { $0 } // Test line
            .reduce(0, +)
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testFilter() {
        let sequenceValues = [7,21,7,721]
        let expectedValue = 7
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .filter { $0 == expectedValue } // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testRemoveDuplicates() {
        let sequenceValues = [7,7,21,21,721]
        let expectedSequenceValues = [7,21,721]
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .removeDuplicates() // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        sequenceSubscriber.cancel()
    }
    
    func testReplaceError() {
        let expectation = XCTestExpectation()
        
        let replacementValue = 7
        
        let failPublisher = Fail<Int, CombineError>(error: CombineError())
        
        let failSubscriber = failPublisher
            .replaceError(with: replacementValue) // Test line
            .assertNoFailure()
            .sink { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        failSubscriber.cancel()
    }
    
    func testReplaceEmpty() {
        let expectation = XCTestExpectation()
        
        let emptyPublisher = Empty<Void, Never>()
        
        let emptySubscriber = emptyPublisher
            .replaceEmpty(with: ()) // Test line
            .sink { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        emptySubscriber.cancel()
    }
    
    func testReplaceNil() {
        let replacementValue = 721
        let expectedValue = replacementValue
        
        let sequencePublisher: Publishers.Sequence<[Int?], Never> = [nil].publisher
        
        let sequenceSubscriber = sequencePublisher
            .replaceNil(with: replacementValue) // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    // MARK: - Reducing Elements
    
    func testCollect() {
        let sequenceValues = [7,21,721]
        let expectedSequenceValues = sequenceValues
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .collect() // Test line
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        sequenceSubscriber.cancel()
    }
    
    func testCollectByCount() {
        let collectCount = 3
        let sequence = [1,2,3,4,5]
        let expectedSequenceValues = Array(sequence.prefix(collectCount))
        
        let passThroughSequencePublisher = PassThroughSequence(sequence: sequence)
        
        let collectByCountSubscriber = Publishers.CollectByCount(upstream: passThroughSequencePublisher,
                                                                 count: collectCount) // Test line
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        passThroughSequencePublisher.sendNext()
        passThroughSequencePublisher.sendNext()
        passThroughSequencePublisher.sendNext()
        passThroughSequencePublisher.sendNext()
        passThroughSequencePublisher.sendNext()
        
        collectByCountSubscriber.cancel()
    }
    
    func testCollectByTime() {
        let expectation = XCTestExpectation()
        
        let sequence = [1,2,3,4,5]
        let expectedSequenceValues = Array(sequence.prefix(2))
        
        let passThroughSequencePublisher = PassThroughSequence(sequence: sequence)
        
        let collectByTimeSubscriber = Publishers.CollectByTime(upstream: passThroughSequencePublisher,
                                                               strategy: .byTime(RunLoop.main, 0.001),
                                                               options: nil) // Test line
            .map { XCTAssertEqual($0, expectedSequenceValues) }
            .sink { _ in expectation.fulfill() }
        
        passThroughSequencePublisher.sendNext()
        passThroughSequencePublisher.sendNext()
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        collectByTimeSubscriber.cancel()
    }
    
    func testIgnoreOutput() {
        let expectation = XCTestExpectation()
        
        let passthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let passthroughSubjectSubscriber = Publishers.IgnoreOutput(upstream: passthroughSubjectPublisher) // Test line
            .sink(receiveCompletion: { _ in expectation.fulfill() },
                  receiveValue: { _ in XCTFail("Should not receive value") })
        
        passthroughSubjectPublisher.send()
        passthroughSubjectPublisher.send(completion: .finished)
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        passthroughSubjectSubscriber.cancel()
    }
    
    func testReduce() {
        let sequenceValues = [7,21,721]
        let expectedValue = 749
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .reduce(0, +) // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    // MARK: - Mathematic Operations
    
    func testMax() {
        let sequenceValues = [721,21,7]
        let expectedValue = 721
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .max() // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testMin() {
        let sequenceValues = [721,21,7]
        let expectedValue = 7
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .min() // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testComparison() {
        let sequence = [7,21,721,7]
        let expectedValue = sequence.max()
        
        let sequencePublisher = sequence.publisher
        
        let sequenceSubscriber = Publishers.Comparison(upstream: sequencePublisher, areInIncreasingOrder: >) // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testCount() {
        let sendCount = 7
        let expectedValue = sendCount
        
        let passthroughPublisher = PassthroughSubject<Void, Never>()
        
        let passthroughSubscriber = passthroughPublisher
            .count() // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        (0..<sendCount).forEach { _ in passthroughPublisher.send() }
        passthroughPublisher.send(completion: .finished)
        
        passthroughSubscriber.cancel()
    }
    
    // MARK: - Applying matching criteria to elements
    
    func testAllSatisfy() {
        let sequence = [7,21,721]
        
        let sequencePublisher = sequence.publisher
        
        let sequenceSubscriber = sequencePublisher
            .allSatisfy { $0 % 2 == 1 } // Test line
            .sink { XCTAssertTrue($0) }
        
        sequenceSubscriber.cancel()
    }
    
    func testContains() {
        let sequenceValues = [7,21,721]
        let expectedValue = sequenceValues[1]
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .contains(expectedValue) // Test line
            .sink { XCTAssertTrue($0) }
        
        sequenceSubscriber.cancel()
    }
    
    func testContainsWhere() {
        let sequenceValues = [7,21,721]
        let pivotValue = 22
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .contains { $0 > pivotValue } // Test line
            .sink { XCTAssertTrue($0) }
        
        sequenceSubscriber.cancel()
    }
    
    // MARK: - Applying sequence operations to elements
    
    func testFirst() {
        let sequenceValues = [7,21,721]
        let expectedValue = sequenceValues.first
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .first() // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testFirstWhere() {
        let sequenceValues = [7,21,721]
        let whereValue = 10
        let expectedValue = sequenceValues[1]
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .first { $0 > whereValue } // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testLast() {
        let sequenceValues = [7,21,721]
        let expectedValue = sequenceValues.last
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .last() // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testLastWhere() {
        let sequenceValues = [7,21,721]
        let whereValue = 700
        let expectedValue = sequenceValues[1]
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .last { $0 < whereValue } // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    func testDropWhile() {
        let sequenceValues = [7,21,27,7,721]
        let expectedSequenceValues = [27,7,721]
        
        let sequencePublisher = sequenceValues.publisher
        
        let sequenceSubscriber = sequencePublisher
            .drop { $0 <= 21 } // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        sequenceSubscriber.cancel()
    }
    
    func testDropUntilOutput() {
        var receiveCount = 0
        let expectedReceiveCount = 1
        
        let firstPassthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        let secondPassthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let prefixUntilOutputSubscriber = firstPassthroughSubjectPublisher
            .drop(untilOutputFrom: secondPassthroughSubjectPublisher) // Test line
            .sink { _ in receiveCount += 1 }
        
        firstPassthroughSubjectPublisher.send()
        firstPassthroughSubjectPublisher.send()
        secondPassthroughSubjectPublisher.send()
        firstPassthroughSubjectPublisher.send()
        
        XCTAssertEqual(receiveCount, expectedReceiveCount)
        
        prefixUntilOutputSubscriber.cancel()
    }
    
    func testDropFirst() {
        var receiveCount = 0
        let dropCount = 1
        let expectedReceiveCount = 2
        
        let passthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let passthroughSubjectSubscriber = passthroughSubjectPublisher
            .dropFirst(dropCount) // Test line
            .sink { _ in receiveCount += 1 }
        
        passthroughSubjectPublisher.send()
        passthroughSubjectPublisher.send()
        passthroughSubjectPublisher.send()
        
        XCTAssertEqual(receiveCount, expectedReceiveCount)
        
        passthroughSubjectSubscriber.cancel()
    }
    
    func testConcatenate() {
        let firstSequenceValues = [7,21,721]
        let secondSequenceValues = [721,21,7]
        let expectedSequenceValues = firstSequenceValues + secondSequenceValues
        
        let firstSequencePublisher = firstSequenceValues.publisher
        let secondSequencePublisher = secondSequenceValues.publisher
        
        let concatenateSubscriber = Publishers.Concatenate(prefix: firstSequencePublisher,
                                                           suffix: secondSequencePublisher) // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        concatenateSubscriber.cancel()
    }
    
    func testPrefixUntilOutput() {
        var receiveCount = 0
        let expectedReceiveCount = 2
        
        let firstPassthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        let secondPassthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let prefixUntilOutputSubscriber = firstPassthroughSubjectPublisher
            .prefix(untilOutputFrom: secondPassthroughSubjectPublisher) // Test line
            .sink { _ in receiveCount += 1 }
        
        firstPassthroughSubjectPublisher.send()
        firstPassthroughSubjectPublisher.send()
        secondPassthroughSubjectPublisher.send()
        firstPassthroughSubjectPublisher.send()
        
        XCTAssertEqual(receiveCount, expectedReceiveCount)
        
        prefixUntilOutputSubscriber.cancel()
    }
    
    func testPrefixMaxCount() {
        var receiveCount = 0
        let expectedReceiveCount = 2
        
        let passthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let passthroughSubjectSubscriber = passthroughSubjectPublisher
            .prefix(expectedReceiveCount) // Test line
            .sink { _ in receiveCount += 1 }
        
        passthroughSubjectPublisher.send()
        passthroughSubjectPublisher.send()
        passthroughSubjectPublisher.send()
        
        XCTAssertEqual(receiveCount, expectedReceiveCount)
        
        passthroughSubjectSubscriber.cancel()
    }
    
    func testPrefixWhile() {
        var receiveCount = 0
        let validValue = 7
        let invalidValue = 21
        let expectedReceiveCount = 2
        
        let passthroughSubjectPublisher = PassthroughSubject<Int, Never>()
        
        let passthroughSubjectSubscriber = passthroughSubjectPublisher
            .prefix { $0 != invalidValue } // Test line
            .sink { _ in receiveCount += 1 }
        
        passthroughSubjectPublisher.send(validValue)
        passthroughSubjectPublisher.send(validValue)
        passthroughSubjectPublisher.send(invalidValue)
        passthroughSubjectPublisher.send(validValue)
        
        XCTAssertEqual(receiveCount, expectedReceiveCount)
        
        passthroughSubjectSubscriber.cancel()
    }
    
    func testOutput() {
        let sequence = [7,21,721]
        let index = 1
        let expectedValue = sequence[index]
        
        let sequencePublisher = sequence.publisher
        
        let sequenceSubscriber = sequencePublisher
            .output(at: index) // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        sequenceSubscriber.cancel()
    }
    
    // MARK: - Combining elements from multiple publishers
    
    func testCombineLatest() {
        let firstSequence = [1,2,3]
        let secondSequence = [3,2,1]
        let expectedSequenceValues = [(1,3),(2,3),(3,3),(3,2),(3,1)]
        
        let firstPassThroughSequencePublisher = PassThroughSequence(sequence: firstSequence)
        let secondPassThroughSequencePublisher = PassThroughSequence(sequence: secondSequence)
        
        let combineLatestSubscriber = Publishers.CombineLatest(
            firstPassThroughSequencePublisher.passthroughSubject,
            secondPassThroughSequencePublisher.passthroughSubject
        ) // Test line
            .collect()
            .sink { zip($0, expectedSequenceValues).forEach { XCTAssertTrue($0.0 == $1.0 && $0.1 == $1.1) } }
        
        firstPassThroughSequencePublisher.sendNext()   // (1,_)
        secondPassThroughSequencePublisher.sendNext()  // (1,3)
        firstPassThroughSequencePublisher.sendNext()   // (2,3)
        firstPassThroughSequencePublisher.sendNext()   // (3,3)
        secondPassThroughSequencePublisher.sendNext()  // (3,2)
        secondPassThroughSequencePublisher.sendNext()  // (3,1)
        firstPassThroughSequencePublisher.sendFinish()
        secondPassThroughSequencePublisher.sendFinish()
        
        combineLatestSubscriber.cancel()
    }
    
    func testMerge() {
        let firstSequence = [1,2,3]
        let secondSequence = [3,2,1]
        let expectedSequenceValues = [1,3,2,3,2,1]
        
        let firstPassThroughSequencePublisher = PassThroughSequence(sequence: firstSequence)
        let secondPassThroughSequencePublisher = PassThroughSequence(sequence: secondSequence)
        
        let mergeSubscriber = Publishers.Merge(
            firstPassThroughSequencePublisher.passthroughSubject,
            secondPassThroughSequencePublisher.passthroughSubject
        ) // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        firstPassThroughSequencePublisher.sendNext()  // 1
        secondPassThroughSequencePublisher.sendNext() // 3
        firstPassThroughSequencePublisher.sendNext()  // 2
        firstPassThroughSequencePublisher.sendNext()  // 3
        secondPassThroughSequencePublisher.sendNext() // 2
        secondPassThroughSequencePublisher.sendNext() // 1
        firstPassThroughSequencePublisher.sendFinish()
        secondPassThroughSequencePublisher.sendFinish()
        
        mergeSubscriber.cancel()
    }
    
    func testZip() {
        let firstSequence = [1,2,3]
        let secondSequence = [3,2,1]
        let expectedSequenceValues = [(1,3),(2,2),(3,1)]
        
        let firstPassThroughSequencePublisher = PassThroughSequence(sequence: firstSequence)
        let secondPassThroughSequencePublisher = PassThroughSequence(sequence: secondSequence)
        
        let zipSubscriber = Publishers.Zip(
            firstPassThroughSequencePublisher.passthroughSubject,
            secondPassThroughSequencePublisher.passthroughSubject
        ) // Test line
            .collect()
            .sink { zip($0, expectedSequenceValues).forEach { XCTAssertTrue($0.0 == $1.0 && $0.1 == $1.1) } }
        
        firstPassThroughSequencePublisher.sendNext()  // (1,_)
        secondPassThroughSequencePublisher.sendNext() // (1,3)
        firstPassThroughSequencePublisher.sendNext()  // (2,_)
        firstPassThroughSequencePublisher.sendNext()  // (2,_),(3,_)
        secondPassThroughSequencePublisher.sendNext() // (2,2),(3,_)
        secondPassThroughSequencePublisher.sendNext() // (3,1)
        firstPassThroughSequencePublisher.sendFinish()
        secondPassThroughSequencePublisher.sendFinish()
        
        zipSubscriber.cancel()
    }
    
    // MARK: - Handling errors
    
    func testCatch() {
        let value = 7
        let expectedValue = value
        
        let failPublisher = Fail<Int, CombineError>(error: CombineError())
        
        let failSubscriber = failPublisher
            .catch { _ in Just(value) } // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        failSubscriber.cancel()
    }
    
    func testAssertNoFailure() {
        let value = 7
        let expectedValue = value
        
        let failPublisher = Fail<Int, CombineError>(error: CombineError())
        
        let failSubscriber = failPublisher
            .replaceError(with: value)
            .assertNoFailure() // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        failSubscriber.cancel()
    }
    
    func testRetry() {
        var receiveCount = 0
        let retryCount = 2
        let expectedReceiveCount = retryCount + 1
        
        let failPublisher = Fail<Int, CombineError>(error: CombineError())
        
        let failSubscriber = failPublisher
            .handleEvents(receiveCompletion: { _ in receiveCount += 1 })
            .retry(retryCount) // Test line
            .ignoreOutput()
            .assertNoFailure()
            .sink { _ in }
        
        XCTAssertEqual(receiveCount, expectedReceiveCount)
        
        failSubscriber.cancel()
    }
    
    func testMapError() {
        let expectation = XCTestExpectation()
        
        let failPublisher = Fail<Void, CombineError>(error: CombineError())
        
        let failSubscriber = failPublisher
            .mapError { _ in CombineError.expected } // Test line
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should not receive finished")
                case .failure(let error) where error == .expected:
                    expectation.fulfill()
                case .failure:
                    XCTFail("Should not receive other error")
                }
            },
                  receiveValue: {
                    XCTFail("Should not receive value")
            })
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        failSubscriber.cancel()
    }
    
    // MARK: - Adapting publisher types
    
    func testSwitchToLatest() {
        let firstSequence = [1,2,3]
        let secondSequence = [3,2,1]
        let expectedSequenceValues = [1,2,1]
        
        let firstPassThroughSequencePublisher = PassThroughSequence(sequence: firstSequence)
        let secondPassThroughSequencePublisher = PassThroughSequence(sequence: secondSequence)
        let passthroughSubjectPublisherPublisher = PassthroughSubject<PassThroughSequence<Int>, Never>()
        
        let passthroughSubjectPublisherSubscriber = passthroughSubjectPublisherPublisher
            .switchToLatest() // Test line
            .collect()
            .sink { XCTAssertEqual($0, expectedSequenceValues) }
        
        passthroughSubjectPublisherPublisher.send(firstPassThroughSequencePublisher)
        firstPassThroughSequencePublisher.sendNext()   // [1]
        secondPassThroughSequencePublisher.sendNext()  // _
        passthroughSubjectPublisherPublisher.send(secondPassThroughSequencePublisher)
        firstPassThroughSequencePublisher.sendNext()   // _
        secondPassThroughSequencePublisher.sendNext()  // [1,2]
        firstPassThroughSequencePublisher.sendNext()   // _
        secondPassThroughSequencePublisher.sendNext()  // [1,2,1]
        firstPassThroughSequencePublisher.sendFinish()
        secondPassThroughSequencePublisher.sendFinish()
        passthroughSubjectPublisherPublisher.send(completion: .finished)
        
        passthroughSubjectPublisherSubscriber.cancel()
    }
    
    // MARK: - Controlling timing
    
    func testDebounce() {
        let expectation = XCTestExpectation()
        
        let debounceDuration: RunLoop.SchedulerTimeType.Stride = 0.001
        
        let sequence = [7,21,721]
        let expectedValue = sequence.last
        
        let passthroughSequencePublisher = PassThroughSequence(sequence: sequence)
        
        let passthroughSequenceSubscriber = passthroughSequencePublisher
            .debounce(for: debounceDuration, scheduler: RunLoop.main) // Test line
            .map { XCTAssertEqual($0, expectedValue) }
            .sink { _ in expectation.fulfill() }
        
        passthroughSequencePublisher.sendNext()
        passthroughSequencePublisher.sendNext()
        passthroughSequencePublisher.sendNext()
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        passthroughSequenceSubscriber.cancel()
    }
    
    func testDelay() {
        let expectation = XCTestExpectation()
        
        let value = 7
        let measureLowerBound: RunLoop.SchedulerTimeType.Stride = 0.001
        let measureUpperBound: RunLoop.SchedulerTimeType.Stride = 1
        
        let justPublisher = Just(value)
        
        let justSubscriber = justPublisher
            .delay(for: measureLowerBound, scheduler: RunLoop.main) // Test line
            .measureInterval(using: RunLoop.main)
            .map { XCTAssertTrue($0 > measureLowerBound && $0 < measureUpperBound) }
            .sink { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        justSubscriber.cancel()
    }
    
    func testMeasureInterval() {
        let value = 7
        let measureLowerBound: RunLoop.SchedulerTimeType.Stride = 0
        let measureUpperBound: RunLoop.SchedulerTimeType.Stride = 1
        
        let justPublisher = Just(value)
        
        let justSubscriber = justPublisher
            .measureInterval(using: RunLoop.main) // Test line
            .sink { XCTAssertTrue($0 > measureLowerBound && $0 < measureUpperBound) }
        
        justSubscriber.cancel()
    }
    
    func testThrottle() {
        let expectation = XCTestExpectation()
        
        let throttleDuration: RunLoop.SchedulerTimeType.Stride = 0.001
        
        let sequence = [7,21,721]
        let expectedValue = sequence.last
        
        let passthroughSequencePublisher = PassThroughSequence(sequence: sequence)
        
        let passthroughSequenceSubscriber = passthroughSequencePublisher
            .throttle(for: throttleDuration, scheduler: RunLoop.main, latest: true) // Test line
            .map { XCTAssertEqual($0, expectedValue) }
            .sink { _ in expectation.fulfill() }
        
        passthroughSequencePublisher.sendNext()
        passthroughSequencePublisher.sendNext()
        passthroughSequencePublisher.sendNext()
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        passthroughSequenceSubscriber.cancel()
    }
    
    func testTimeout() {
        let expectation = XCTestExpectation()
        
        let timeoutDuration: DispatchQueue.SchedulerTimeType.Stride = 0.001
        let asyncAfterDuration = 3
        
        let passthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let passthroughSubjectSubscriber = passthroughSubjectPublisher
            .timeout(timeoutDuration, scheduler: DispatchQueue.main) // Test line
            .handleEvents(receiveCompletion: { _ in expectation.fulfill() })
            .sink { _ in XCTFail("Should not receive value") }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(asyncAfterDuration)) {
            passthroughSubjectPublisher.send()
        }
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        passthroughSubjectSubscriber.cancel()
    }
    
    // MARK: - Encoding and decoding
    
    func testEncoding() throws {
        let jsonEncoder = JSONEncoder()
        let value = 7
        let expectedValue = try jsonEncoder.encode(value)
        
        let justPublisher = Just(value)
        
        let justSubscriber = justPublisher
            .encode(encoder: jsonEncoder) // Test line
            .assertNoFailure()
            .sink { XCTAssertEqual($0, expectedValue) }
        
        justSubscriber.cancel()
    }
    
    func testDecoding() throws {
        let jsonEncoder = JSONEncoder()
        let jsonDecoder = JSONDecoder()
        let value = 7
        let valueType = type(of: value)
        let encodedValue = try jsonEncoder.encode(value)
        let expectedValue = try jsonDecoder.decode(valueType, from: encodedValue)
        
        let justPublisher = Just(encodedValue)
        
        let justSubscriber = justPublisher
            .decode(type: valueType, decoder: jsonDecoder) // Test line
            .assertNoFailure()
            .sink { XCTAssertEqual($0, expectedValue) }
        
        justSubscriber.cancel()
    }
    
    // MARK: - Working with multiple subscribers
    
    func testMulticast() {
        let sequence = [7,21,721]
        let expectedValue = 749
        
        let passthroughSequencePublisher = PassThroughSequence(sequence: sequence)
        
        let multicastPublisher = passthroughSequencePublisher
            .reduce(0, +)
            .multicast { PassthroughSubject() } // Test line
            .autoconnect()
        
        let firstPassthroughSequenceSubscriber = multicastPublisher
            .sink { XCTAssertEqual($0, expectedValue) }
        
        passthroughSequencePublisher.sendNext()
        
        let secondPassthroughSequenceSubscriber = multicastPublisher
            .sink { XCTAssertEqual($0, expectedValue) }
        
        passthroughSequencePublisher.sendNext()
        passthroughSequencePublisher.sendNext()
        passthroughSequencePublisher.sendFinish()
        
        firstPassthroughSequenceSubscriber.cancel()
        secondPassthroughSequenceSubscriber.cancel()
    }
    
    // MARK: - Debugging
    
    func testBreakpoint() {
        let value = 7
        let shouldBreakpoint = false // Set to true
        
        let justPublisher = Just(value)
        
        let justSubscriber = justPublisher
            .breakpoint(receiveSubscription: { _ in shouldBreakpoint },
                        receiveOutput: { _ in shouldBreakpoint },
                        receiveCompletion: { _ in shouldBreakpoint }) // Test line
            .sink { _ in }
        
        justSubscriber.cancel()
    }
    
    func testBreakpointOnError() {
        let failPublisher = Fail<Void, CombineError>(error: CombineError())
        
        let failSubscriber = failPublisher
            .replaceError(with: ()) // Switch with following line
            .breakpointOnError() // Test line
            .sink { _ in }
        
        failSubscriber.cancel()
    }
    
    func testHandleEvents() {
        let subscriptionExpectation = XCTestExpectation(description: "subscription expectation")
        let outputExpectation = XCTestExpectation(description: "output expectation")
        let completionExpectation = XCTestExpectation(description: "completion expectation")
        let cancelExpectation = XCTestExpectation(description: "cancel expectation")
        let requestExpectation = XCTestExpectation(description: "request expectation")
        
        let passthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        
        let firstPassthroughSubjectSubscriber = passthroughSubjectPublisher
            .handleEvents(receiveCancel: { cancelExpectation.fulfill() }) // Test line
            .sink { _ in }
        
        let secondPassthroughSubjectSubscriber = passthroughSubjectPublisher
            .handleEvents(receiveSubscription: { _ in subscriptionExpectation.fulfill() },
                          receiveOutput: { _ in outputExpectation.fulfill() },
                          receiveCompletion: { _ in completionExpectation.fulfill() },
                          receiveCancel: { cancelExpectation.fulfill() },
                          receiveRequest: { _ in requestExpectation.fulfill() }) // Test line
            .sink { _ in }
        
        firstPassthroughSubjectSubscriber.cancel()
        
        passthroughSubjectPublisher.send()
        passthroughSubjectPublisher.send(completion: .finished)
        
        wait(for: [subscriptionExpectation,
                   outputExpectation,
                   completionExpectation,
                   cancelExpectation,
                   requestExpectation], timeout: Constants.expectationTimeout)
        secondPassthroughSubjectSubscriber.cancel()
    }
    
    func testPrint() {
        let justValue = 7
        let expectedValue = justValue
        
        let justPublisher = Just(justValue)
        
        let justSubscriber = justPublisher
            .print() // Test line
            .sink { XCTAssertEqual($0, expectedValue) }
        
        justSubscriber.cancel()
    }
    
    // MARK: - Scheduler and thread handling operators
    
    func testReceive() {
        let expectation = XCTestExpectation()
        
        let justValue = 7
        
        let justPublisher = Just(justValue)
        
        let justSubscriber = justPublisher
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main) // Test line
            .handleEvents(receiveOutput: { _ in dispatchPrecondition(condition: .onQueue(DispatchQueue.main)) })
            .sink { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        justSubscriber.cancel()
    }
    
    func testSubscribe() {
        let sequence = [7,21,721]
        let expectedValue = 749
        
        let passthroughSubjectPublisher = PassthroughSubject<Int, Never>()
        
        let passthroughSubjectSubscriber = passthroughSubjectPublisher
            .reduce(0, +)
            .sink { XCTAssertEqual($0, expectedValue) }
        
        let sequenceSubscriber = Publishers.Sequence(sequence: sequence)
            .subscribe(passthroughSubjectPublisher) // Test line
        
        passthroughSubjectSubscriber.cancel()
        sequenceSubscriber.cancel()
    }
    
    // MARK: - Type erasure operators
    
    func testEraseToAnyPublisher() {
        let filterAllValues: (AnyPublisher<Void, Never>) -> AnyPublisher<Void,Never> = { publisher in
            return publisher
                .filter { _ in false }
                .eraseToAnyPublisher() // Test line
        }
        
        let passthroughSubjectPublisher = PassthroughSubject<Void, Never>()
        let erasedPassthroughSubjectPublisher = passthroughSubjectPublisher.eraseToAnyPublisher() // Test line
        let filteredPublisher = filterAllValues(erasedPassthroughSubjectPublisher)
        
        let filteredSubscriber = filteredPublisher
            .sink { XCTFail("Should not receive value") }
        
        passthroughSubjectPublisher.send()
        
        filteredSubscriber.cancel()
    }
    
    // MARK: - Subjects
    
    func testCurrentValueSubject() {
        let expectation = XCTestExpectation()
        
        let initialValue = 7
        let replacementValue = 21
        let expectedValue = replacementValue
        
        let currentValueSubjectPublisher = CurrentValueSubject<Int, Never>(initialValue)
        
        currentValueSubjectPublisher.send(replacementValue) // Test line
        
        let currentValueSubjectSubscriber = currentValueSubjectPublisher
            .map { XCTAssertEqual($0, expectedValue) }
            .sink { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        currentValueSubjectSubscriber.cancel()
    }
    
    func testPassthroughSubject() {
        let expectation = XCTestExpectation()
        
        let passthroughValue = 7
        let expectedValue = passthroughValue
        
        let passthroughPublisher = PassthroughSubject<Int, Never>() // Test line
        
        let passthroughSubscriber = passthroughPublisher
            .map { XCTAssertEqual($0, expectedValue) }
            .sink { _ in expectation.fulfill() }
        
        passthroughPublisher.send(passthroughValue)
        
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        passthroughSubscriber.cancel()
    }
    
    // MARK: - Subscribers
    
    func testAssign() {
        let justValue = 7
        let expectedValue = justValue
        
        let valueWrapper = KVOValueWrapper()
        let justPublisher = Just(justValue)
        
        let justSubscriber = justPublisher
            .assign(to: \.value, on: valueWrapper) // Test line
        
        XCTAssertEqual(valueWrapper.value, expectedValue)
        justSubscriber.cancel()
    }
    
    func testSink() {
        let justValue = 7
        let expectedValue = justValue
        
        let justPublisher = Just(justValue)
        
        let justSubscriber = justPublisher
            .sink { XCTAssertEqual($0, expectedValue) } // Test line
        
        justSubscriber.cancel()
    }
    
    func testAnyCancellable() {
        var receiveCount = 0
        let expectedReceiveCount = 1
        
        let passthroughPublisher = PassthroughSubject<Void, Never>()
        
        let passthroughSubscriber = passthroughPublisher
            .sink { _ in receiveCount += 1 }
        
        passthroughPublisher.send()
        passthroughSubscriber.cancel() // Test line
        passthroughPublisher.send()
        
        XCTAssertEqual(receiveCount, expectedReceiveCount)
    }
    
    // MARK: -
    // MARK: - Constants
    
    private struct Constants {
        static let expectationTimeout = 1.0
    }
    
    // MARK: - Combine Object Types
    
    enum CombineError: Error {
        case `default`
        case expected
        case unexpected
        
        init() {
            self = CombineError.default
        }
    }
    
    class PublishedWrapper: ObservableObject {
        static let initialValue = 7
        @Published var publishedValue = PublishedWrapper.initialValue
    }
    
    class KVOValueWrapper: NSObject {
        @objc dynamic var value = 0
    }
    
    class PassThroughSequence<T>: Publisher {
        let sequence: [T]
        var currentIndex = 0
        let passthroughSubject = PassthroughSubject<T, Never>()
        
        init(sequence: [T]) {
            self.sequence = sequence
        }
        
        func sendNext() {
            let nextValue = sequence[currentIndex]
            passthroughSubject.send(nextValue)
            currentIndex += 1
        }
        
        func sendFinish() {
            passthroughSubject.send(completion: .finished)
        }
        
        // MARK: - Publisher
        typealias Output = T
        typealias Failure = Never
        
        func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == Failure {
            passthroughSubject.receive(subscriber: subscriber)
        }
    }
    
}
