module Data.UnixTime.Types where

import Control.Applicative ((<$>), (<*>))
import Data.ByteString
import Data.ByteString.Char8 ()
import Data.Int
import Foreign.C.Types
import Foreign.Storable
#if __GLASGOW_HASKELL__ >= 704
import Data.Binary
#endif

#include <sys/time.h>

#let alignment t = "%lu", (unsigned long)offsetof(struct {char x__; t (y__); }, y__)

-- |
-- Data structure for Unix time.
--
-- Please note that this uses GHC-derived 'Eq' and 'Ord' instances.
-- Notably
--
-- >>> UnixTime 1 0 > UnixTime 0 999999999
-- True
--
-- You should instead use 'UnixDiffTime' along with its helpers such
-- as 'Data.UnixTime.microSecondsToUnixDiffTime' which will ensure
-- that such unusual values are never created.
data UnixTime = UnixTime {
    -- | Seconds from 1st Jan 1970
    utSeconds :: {-# UNPACK #-} !CTime
    -- | Micro seconds (i.e. 10^(-6))
  , utMicroSeconds :: {-# UNPACK #-} !Int32
  } deriving (Eq,Ord,Show)

instance Storable UnixTime where
    sizeOf _    = (#size struct timeval)
    alignment _ = (#alignment struct timeval)
    peek ptr    = UnixTime
            <$> (#peek struct timeval, tv_sec)  ptr
            <*> (#peek struct timeval, tv_usec) ptr
    poke ptr ut = do
            (#poke struct timeval, tv_sec)  ptr (utSeconds ut)
            (#poke struct timeval, tv_usec) ptr (utMicroSeconds ut)

#if __GLASGOW_HASKELL__ >= 704
instance Binary UnixTime where
        put (UnixTime (CTime sec) msec) = do
            put sec
            put msec
        get = UnixTime <$> (CTime `fmap` get) <*> get
#endif

-- |
-- Format of the strptime()/strftime() style.
type Format = ByteString

-- |
-- Data structure for UnixTime diff.
--
-- >>> (3 :: UnixDiffTime) + 2
-- UnixDiffTime {udtSeconds = 5, udtMicroSeconds = 0}
-- >>> (2 :: UnixDiffTime) - 5
-- UnixDiffTime {udtSeconds = -3, udtMicroSeconds = 0}
-- >>> (3 :: UnixDiffTime) * 2
-- UnixDiffTime {udtSeconds = 6, udtMicroSeconds = 0}
--
-- It is up to the user to ensure that @'udtMicroSeconds' < 1000000@.
-- Helpers such as 'Data.UnixTime.microSecondsToUnixDiffTime' can help
-- you to create valid values. For example, it's a mistake to use
-- 'Data.Text.addUnixDiffTime' with a value @UnixDiffTime 0 9999999@
-- as it will produce an incorrect value back. You should instead use
-- functions such as 'Data.UnixTime.microSecondsToUnixDiffTime' to
-- create values that are in-range. This avoids any gotchas when then
-- doing comparisons.
data UnixDiffTime = UnixDiffTime {
    -- | Seconds from 1st Jan 1970
    udtSeconds :: {-# UNPACK #-} !CTime
    -- | Micro seconds (i.e. 10^(-6))
  , udtMicroSeconds :: {-# UNPACK #-} !Int32
  } deriving (Eq,Ord,Show)
