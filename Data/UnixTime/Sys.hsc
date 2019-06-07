{-# LANGUAGE ForeignFunctionInterface #-}

module Data.UnixTime.Sys (getUnixTime) where

import Data.UnixTime.Types
import Foreign.C.Error
import Foreign.C.Types
import Foreign.Marshal.Alloc
import Foreign.Ptr
import Foreign.Storable
#if defined(_WIN32)
import Data.Word
#endif

-- from System.Time

#include <time.h>
#include <sys/time.h>

type CTimeVal = ()
type CTimeZone = ()

foreign import ccall unsafe "gettimeofday"
    c_gettimeofday :: Ptr CTimeVal -> Ptr CTimeZone -> IO CInt

-- |
-- Get current 'UnixTime' from OS.

getUnixTime :: IO UnixTime
getUnixTime = allocaBytes (#const sizeof(struct timeval)) $ \ p_timeval -> do
    throwErrnoIfMinus1_ "getClockTime" $ c_gettimeofday p_timeval nullPtr
    peek (castPtr p_timeval)
