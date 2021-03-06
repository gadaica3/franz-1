//
//  OffsetCommitFetchAPI.swift
//  Franz
//
//  Created by Kellan Cummings on 1/19/16.
//  Copyright © 2016 Kellan Cummings. All rights reserved.
//

import Foundation

typealias OffsetMetadata = String

class OffsetCommitRequest: KafkaRequest {
	
    convenience init(
        consumerGroupId: String,
        generationId: Int32,
        consumerId: String,
        topics: [TopicName: [PartitionId: (Offset, OffsetMetadata?)]],
        retentionTime: Int64 = 0
    ) {
        self.init(
            value: OffsetCommitRequestMessage(
                consumerGroupId: consumerGroupId,
                generationId: generationId,
                consumerId: consumerId,
                topics: topics,
                retentionTime: retentionTime
            )
        )
    }
    
    init(value: OffsetCommitRequestMessage) {
		super.init(apiKey: ApiKey.offsetCommitRequest, value: value, apiVersion: .v2)
    }
}

class OffsetCommitRequestMessage: KafkaType {

    let consumerGroupId: String
    let consumerGroupGenerationId: Int32
    let consumerId: String
    let retentionTime: Int64
    let topics: KafkaArray<OffsetCommitTopic>
 
    init(consumerGroupId: String, generationId: Int32, consumerId: String, topics: [TopicName: [PartitionId: (Offset, OffsetMetadata?)]], retentionTime: Int64 = 0) {
		self.consumerGroupId = consumerGroupId
		self.consumerGroupGenerationId = generationId
		self.consumerId = consumerId
		self.retentionTime = retentionTime
		self.topics = KafkaArray<OffsetCommitTopic>(topics.map { arg in
			let (key, value) = arg
			return OffsetCommitTopic(topic: key, partitions: value)
		})
    }
    
    required init(data: inout Data) {
        consumerGroupId = String(data: &data)
        consumerGroupGenerationId = Int32(data: &data)
        consumerId = String(data: &data)
        retentionTime = Int64(data: &data)
        topics = KafkaArray(data: &data)
    }

    var dataLength: Int {
		let values: [KafkaType] = [consumerGroupId, consumerGroupGenerationId, consumerId, retentionTime, topics]
		return values.map { $0.dataLength }.reduce(0, +)
	}
    
    var data: Data {
        var data = Data(capacity: dataLength)
        data += consumerGroupId.data
        data += consumerGroupGenerationId.data
        data += consumerId.data
        data += retentionTime.data
        data += topics.data
        return data
    }
}


class OffsetCommitTopic: KafkaType {
	let topicName: TopicName
    let partitions: KafkaArray<OffsetCommitPartitionOffset>

    init(topic: TopicName, partitions: [PartitionId: (Offset, OffsetMetadata?)]) {
        self.topicName = topic
		self.partitions = KafkaArray(partitions.map { arg in
			let (key, value) = arg
			return OffsetCommitPartitionOffset(partition: key, offset: value.0, metadata: value.1)
		})
    }
    
	required init(data: inout Data) {
        topicName = String(data: &data)
        partitions = KafkaArray(data: &data)
    }

    var dataLength: Int {
        return topicName.dataLength + partitions.dataLength
	}
    
    var data: Data {
        var data = Data(capacity: self.dataLength)
        data += topicName.data
        data += partitions.data
        return data
	}
}

class OffsetCommitPartitionOffset: KafkaType {
    let partition: PartitionId
    let offset: Offset
    let metadata: String?

    init(partition: PartitionId, offset: Offset, metadata: String? = nil) {
        self.partition = partition
		self.offset = offset
        self.metadata = metadata
    }

    required init(data: inout Data) {
        partition = PartitionId(data: &data)
        offset = Offset(data: &data)
        metadata = String(data: &data)
    }

    var dataLength: Int {
        return partition.dataLength + offset.dataLength + metadata.dataLength
	}
	
    var data: Data {
        var data = Data(capacity: self.dataLength)
        data += partition.data
        data += offset.data
		data += metadata.data
        return data
	}
}


class OffsetCommitResponse: KafkaResponse {
    
    let topics: KafkaArray<OffsetCommitTopicResponse>
    
    required init(data: inout Data) {
        topics = KafkaArray(data: &data)
    }
    
    var dataLength: Int {
        return topics.dataLength
	}
	
    var data: Data {
        return topics.data
	}
}

class OffsetCommitTopicResponse: KafkaType {
    
    let topicName: String
    let partitions: KafkaArray<OffsetCommitPartitionResponse>
    
    required init(data: inout Data) {
        topicName = String(data: &data)
        partitions = KafkaArray(data: &data)
    }
    
    var dataLength: Int {
        return topicName.dataLength + partitions.dataLength
	}
		
	var data: Data {
        return topicName.data + partitions.data
	}
}

class OffsetCommitPartitionResponse: KafkaType {
    
    let partition: Int32
    private var errorCode: Int16
    
    var error: KafkaErrorCode? {
        return KafkaErrorCode(rawValue: errorCode)
    }
    
    required init(data: inout Data) {
        partition = Int32(data: &data)
        errorCode = Int16(data: &data)
    }
    
    var dataLength: Int {
        return partition.dataLength + errorCode.dataLength
	}
    
    var data: Data {
		return partition.data + errorCode.data
	}
	
}



