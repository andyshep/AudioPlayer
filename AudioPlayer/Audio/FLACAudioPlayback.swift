//
//  FLACAudioPlayback.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/29/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import CLibFLAC

struct FLACAudioCallback {
    let write: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__Frame>>, Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus = {
        
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, frame: Optional<UnsafePointer<FLAC__Frame>>, buffer: Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus in
        
        return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE
    }
    
    let metadata: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__StreamMetadata>>, Optional<UnsafeMutableRawPointer>) -> Void = {
        
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, metadata: Optional<UnsafePointer<FLAC__StreamMetadata>>, client_data: Optional<UnsafeMutableRawPointer>) in
        //
    }
    
    let error: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, FLAC__StreamDecoderErrorStatus, Optional<UnsafeMutableRawPointer>) -> Void = {
        
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, status: FLAC__StreamDecoderErrorStatus, client_data: Optional<UnsafeMutableRawPointer>) in
        
        print("flacErrorCallback called")
        print(status)
    }
    
    let read: @convention(c) (UnsafePointer<FLAC__StreamDecoder>?, UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<Int>?, UnsafeMutableRawPointer?) -> FLAC__StreamDecoderReadStatus = { _, _, _, _ in
        return FLAC__STREAM_DECODER_READ_STATUS_END_OF_STREAM
    }
    
    let length: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutablePointer<UInt64>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderLengthStatus = { _,_,_ in
        return FLAC__StreamDecoderLengthStatus(rawValue: 0)
    }
    
    let eof: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutableRawPointer>) -> Int32 = { _,_ in
        return 0
    }
}
