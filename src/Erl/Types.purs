module Erl.Types
  ( NonNegInt
  , PosInt
  , MonotonicTime(..)
  , NativeTime(..)
  , StrictlyMonotonicInt(..)
  , TimeOffset(..)
  , Second(..)
  , Microsecond(..)
  , Nanosecond(..)
  , Timeout(..)
  , IntOrInfinity(..)
  , Ref
  , class ToErl
  , toErl
  , addMilliseconds
  , delMilliseconds
  , FfiMilliseconds -- Don't export the constructor
  , toFfiMilliseconds
  , fromFfiMilliseconds
  ) where

import Prelude

import Data.Int (round, toNumber)
import Data.Newtype (class Newtype)
import Data.Time.Duration as Duration
import Erl.Atom (atom)
import Erl.Data.Binary (Binary)
import Erl.Data.Tuple (Tuple2, Tuple3, Tuple4, Tuple5, Tuple6, Tuple7, Tuple8, tuple2, tuple3, tuple4, tuple5, tuple6, tuple7, tuple8, uncurry2, uncurry3, uncurry4, uncurry5, uncurry6, uncurry7, uncurry8)
import Foreign (Foreign, unsafeToForeign)

type NonNegInt
  = Int

type PosInt
  = Int

foreign import data Ref :: Type

newtype MonotonicTime
  = MonotonicTime Int

newtype NativeTime
  = NativeTime Int

newtype TimeOffset
  = TimeOffset Int

newtype StrictlyMonotonicInt
  = StrictlyMonotonicInt Int

newtype Second
  = Second Int

-- Use Data.Time.Duration.Milliseconds instead
-- newtype Millisecond = Millisecond Int
newtype Microsecond
  = Microsecond Int

newtype Nanosecond
  = Nanosecond Int

newtype FfiMilliseconds
  = FfiMilliseconds Int

toFfiMilliseconds :: Duration.Milliseconds -> FfiMilliseconds
toFfiMilliseconds (Duration.Milliseconds ms) = FfiMilliseconds $ round ms

fromFfiMilliseconds :: FfiMilliseconds -> Duration.Milliseconds
fromFfiMilliseconds (FfiMilliseconds ms) = Duration.Milliseconds $ toNumber ms

addMilliseconds :: Duration.Milliseconds -> Duration.Milliseconds -> Duration.Milliseconds
addMilliseconds (Duration.Milliseconds l) (Duration.Milliseconds r) = Duration.Milliseconds (l + r)

delMilliseconds :: Duration.Milliseconds -> Duration.Milliseconds -> Duration.Milliseconds
delMilliseconds (Duration.Milliseconds l) (Duration.Milliseconds r) = Duration.Milliseconds (l - r)

derive instance newtype_Second :: Newtype Second _

derive instance newtype_Microsecond :: Newtype Microsecond _

derive instance newtype_Nanosecond :: Newtype Nanosecond _

instance showSecond :: Show Second where
  show (Second v) = "Second " <> show v

instance showMicrosecond :: Show Microsecond where
  show (Microsecond v) = "Microsecond " <> show v

instance showNanosecond :: Show Nanosecond where
  show (Nanosecond v) = "Nanosecond " <> show v

instance semigroup_Second :: Semigroup Second where
  append (Second lhs) (Second rhs) = Second (lhs + rhs)

instance semigroup_Microsecond :: Semigroup Microsecond where
  append (Microsecond lhs) (Microsecond rhs) = Microsecond (lhs + rhs)

instance semigroup_Nanosecond :: Semigroup Nanosecond where
  append (Nanosecond lhs) (Nanosecond rhs) = Nanosecond (lhs + rhs)

instance semiring_Second :: Semiring Second where
  add (Second lhs) (Second rhs) = Second (lhs + rhs)
  zero = Second 0
  mul (Second lhs) (Second rhs) = Second (lhs * rhs)
  one = Second 1

instance semiring_Microsecond :: Semiring Microsecond where
  add (Microsecond lhs) (Microsecond rhs) = Microsecond (lhs + rhs)
  zero = Microsecond 0
  mul (Microsecond lhs) (Microsecond rhs) = Microsecond (lhs * rhs)
  one = Microsecond 1

instance semiring_Nanosecond :: Semiring Nanosecond where
  add (Nanosecond lhs) (Nanosecond rhs) = Nanosecond (lhs + rhs)
  zero = Nanosecond 0
  mul (Nanosecond lhs) (Nanosecond rhs) = Nanosecond (lhs * rhs)
  one = Nanosecond 1

instance ring_Second :: Ring Second where
  sub (Second lhs) (Second rhs) = Second (lhs - rhs)

instance ring_Microsecond :: Ring Microsecond where
  sub (Microsecond lhs) (Microsecond rhs) = Microsecond (lhs - rhs)

instance ring_Nanosecond :: Ring Nanosecond where
  sub (Nanosecond lhs) (Nanosecond rhs) = Nanosecond (lhs - rhs)

instance eq_Second :: Eq Second where
  eq (Second lhs) (Second rhs) = eq lhs rhs

instance eq_Microsecond :: Eq Microsecond where
  eq (Microsecond lhs) (Microsecond rhs) = eq lhs rhs

instance eq_Nanosecond :: Eq Nanosecond where
  eq (Nanosecond lhs) (Nanosecond rhs) = eq lhs rhs

instance ord_Second :: Ord Second where
  compare (Second lhs) (Second rhs) = compare lhs rhs

instance ord_Microsecond :: Ord Microsecond where
  compare (Microsecond lhs) (Microsecond rhs) = compare lhs rhs

instance ord_Nanosecond :: Ord Nanosecond where
  compare (Nanosecond lhs) (Nanosecond rhs) = compare lhs rhs

instance toErl_Second :: ToErl Second where
  toErl (Second val) = unsafeToForeign val

instance toErl_MillisecondSecond :: ToErl Duration.Milliseconds where
  toErl val = unsafeToForeign $ toFfiMilliseconds val

instance toErl_Microsecond :: ToErl Microsecond where
  toErl (Microsecond val) = unsafeToForeign val

instance toErl_Nanosecond :: ToErl Nanosecond where
  toErl (Nanosecond val) = unsafeToForeign val

data Timeout
  = Timeout Duration.Milliseconds
  | InfiniteTimeout

data IntOrInfinity
  = Finite Int
  | Infinity

instance eqIntOrInfinite :: Eq IntOrInfinity where
  eq Infinity Infinity = true
  eq (Finite lhs) (Finite rhs) = lhs == rhs
  eq _ _ = false

class ToErl :: Type -> Constraint
class ToErl option where
  toErl :: option -> Foreign

instance toErl_Foreign :: ToErl Foreign where
  toErl = identity

instance toErl_Int :: ToErl Int where
  toErl = unsafeToForeign

instance toErl_Infinity :: ToErl IntOrInfinity where
  toErl (Finite n) = unsafeToForeign n
  toErl (Infinity) = unsafeToForeign $ atom "infinity"

instance toErl_Timeout :: ToErl Timeout where
  toErl (Timeout (Duration.Milliseconds ms)) = unsafeToForeign $ round ms
  toErl (InfiniteTimeout) = unsafeToForeign $ atom "infinity"

instance toErl_String :: ToErl String where
  toErl = unsafeToForeign

instance toErl_Boolean :: ToErl Boolean where
  toErl = unsafeToForeign

instance toErl_Binary :: ToErl Binary where
  toErl = unsafeToForeign

instance ToErl (Tuple2 Int Int) where
  toErl = unsafeToForeign
else
instance (ToErl a1, ToErl a2) => ToErl (Tuple2 a1 a2) where
  toErl val = unsafeToForeign $ uncurry2 (\a1 a2 -> tuple2 (toErl a1) (toErl a2)) val

instance ToErl (Tuple3 Int Int Int) where
  toErl = unsafeToForeign
else
instance (ToErl a1, ToErl a2, ToErl a3) => ToErl (Tuple3 a1 a2 a3) where
  toErl val = unsafeToForeign $ uncurry3 (\a1 a2 a3 -> tuple3 (toErl a1) (toErl a2) (toErl a3)) val

instance ToErl (Tuple4 Int Int Int Int) where
  toErl = unsafeToForeign
else
instance (ToErl a1, ToErl a2, ToErl a3, ToErl a4) => ToErl (Tuple4 a1 a2 a3 a4) where
  toErl val = unsafeToForeign $ uncurry4 (\a1 a2 a3 a4 -> tuple4 (toErl a1) (toErl a2) (toErl a3) (toErl a4)) val

instance ToErl (Tuple5 Int Int Int Int Int) where
  toErl = unsafeToForeign
else
instance (ToErl a1, ToErl a2, ToErl a3, ToErl a4, ToErl a5) => ToErl (Tuple5 a1 a2 a3 a4 a5) where
  toErl val = unsafeToForeign $ uncurry5 (\a1 a2 a3 a4 a5 -> tuple5 (toErl a1) (toErl a2) (toErl a3) (toErl a4) (toErl a5)) val

instance ToErl (Tuple6 Int Int Int Int Int Int) where
  toErl = unsafeToForeign
else
instance (ToErl a1, ToErl a2, ToErl a3, ToErl a4, ToErl a5, ToErl a6) => ToErl (Tuple6 a1 a2 a3 a4 a5 a6) where
  toErl val = unsafeToForeign $ uncurry6 (\a1 a2 a3 a4 a5 a6 -> tuple6 (toErl a1) (toErl a2) (toErl a3) (toErl a4) (toErl a5) (toErl a6)) val

instance ToErl (Tuple7 Int Int Int Int Int Int Int) where
  toErl = unsafeToForeign
else
instance (ToErl a1, ToErl a2, ToErl a3, ToErl a4, ToErl a5, ToErl a6, ToErl a7) => ToErl (Tuple7 a1 a2 a3 a4 a5 a6 a7) where
  toErl val = unsafeToForeign $ uncurry7 (\a1 a2 a3 a4 a5 a6 a7 -> tuple7 (toErl a1) (toErl a2) (toErl a3) (toErl a4) (toErl a5) (toErl a6) (toErl a7)) val

instance ToErl (Tuple8 Int Int Int Int Int Int Int Int) where
  toErl = unsafeToForeign
else
instance (ToErl a1, ToErl a2, ToErl a3, ToErl a4, ToErl a5, ToErl a6, ToErl a7, ToErl a8) => ToErl (Tuple8 a1 a2 a3 a4 a5 a6 a7 a8) where
  toErl val = unsafeToForeign $ uncurry8 (\a1 a2 a3 a4 a5 a6 a7 a8 -> tuple8 (toErl a1) (toErl a2) (toErl a3) (toErl a4) (toErl a5) (toErl a6) (toErl a7) (toErl a8)) val

-- instance toErl_Record ::
--   ( RL.RowToList r rl
--   , ToErlRecord rl
--   ) =>
--   ToErl (Record r) where
--   toErl = unsafeCoerce 1
-- class ToErlRecord :: RL.RowList Type -> Constraint
-- class ToErlRecord row where
--   toErlRecord
-- instance toErlRecord_nil :: ToErlRecord RL.Nil
-- instance toErlRecord_cons ::
--   ( ToErl a
--   , ToErlRecord tail
--   ) =>
--   ToErlRecord (RL.Cons sym a tail)
