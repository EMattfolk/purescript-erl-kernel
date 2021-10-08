module Erl.Kernel.Erlang
  ( makeRef
  , utcNowMs
  , utcNowUs
  , vmNowMs
  , vmNowUs
  , sleep
  , termToString
  , eqFfi
  , listToBinary
  , monitor
  , monotonicTime
  , monotonicStartTime
  , monotonicTimeDelta
  , strictlyMonotonicInt
  , currentTimeOffset
  , monotonicTimeToInstant
  , nativeTimeToMilliseconds
  ) where

import Prelude
import Data.DateTime.Instant (Instant, instant)
import Data.Int (toNumber)
import Data.Maybe (Maybe)
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Erl.Atom (Atom)
import Erl.Data.Binary (Binary)
import Erl.Data.List (List)
import Erl.Process.Raw (Pid)
import Erl.Types (FfiMilliseconds, Microsecond, MonotonicTime(..), NativeTime(..), Octet, Ref, StrictlyMonotonicInt(..), TimeOffset(..), toFfiMilliseconds)
import Foreign (Foreign)

foreign import makeRef :: Effect Ref

foreign import utcNowMs :: Effect FfiMilliseconds

foreign import utcNowUs :: Effect Microsecond

foreign import vmNowMs :: Effect Microsecond

foreign import vmNowUs :: Effect Microsecond

foreign import listToBinary :: List Octet -> Binary

sleep :: Milliseconds -> Effect Unit
sleep ms = sleep_ (toFfiMilliseconds ms)

foreign import sleep_ :: FfiMilliseconds -> Effect Unit

foreign import termToString :: Foreign -> String

foreign import eqFfi :: forall a. a -> a -> Boolean

foreign import monitor :: Atom -> Pid -> Effect Unit

monotonicTime :: Effect MonotonicTime
monotonicTime = monotonicTime_ MonotonicTime

foreign import monotonicTime_ :: (Int -> MonotonicTime) -> Effect MonotonicTime

monotonicStartTime :: MonotonicTime
monotonicStartTime = monotonicStartTime_ MonotonicTime

foreign import monotonicStartTime_ :: (Int -> MonotonicTime) -> MonotonicTime

monotonicTimeDelta :: MonotonicTime -> MonotonicTime -> NativeTime
monotonicTimeDelta (MonotonicTime start) (MonotonicTime end) =
  NativeTime $ end - start

nativeTimeToMilliseconds :: NativeTime -> Milliseconds
nativeTimeToMilliseconds (NativeTime t) =
  nativeTimeToMilliseconds_ (Milliseconds <<< toNumber) t

foreign import nativeTimeToMilliseconds_ :: (Int -> Milliseconds) -> Int -> Milliseconds

currentTimeOffset :: Effect TimeOffset
currentTimeOffset = currentTimeOffset_ TimeOffset

foreign import currentTimeOffset_ :: (Int -> TimeOffset) -> Effect TimeOffset

strictlyMonotonicInt :: Effect StrictlyMonotonicInt
strictlyMonotonicInt = strictlyMonotonicInt_ StrictlyMonotonicInt

foreign import strictlyMonotonicInt_ :: (Int -> StrictlyMonotonicInt) -> Effect StrictlyMonotonicInt

monotonicTimeToInstant :: MonotonicTime -> TimeOffset -> Maybe Instant
monotonicTimeToInstant (MonotonicTime t) (TimeOffset o) =
  instant $ nativeTimeToMilliseconds $ NativeTime $ t + o
