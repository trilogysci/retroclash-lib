{-# OPTIONS_GHC -fconstraint-solver-iterations=5 #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Extra.Solver #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.KnownNat.Solver #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Normalise #-}
module RetroClash.BCD
    ( Digit, toDigit
    , BCD
    , fromBCD
    , BCDSize
    , toBCD
    , ShiftAdd, initBCD, stepBCD
    , prop_BCD
    ) where

import Clash.Prelude hiding (shift, add)
import RetroClash.Utils

type Digit = Index 10
type BCD n = Vec n Digit

toDigit :: Unsigned 4 -> Digit
toDigit = bitCoerce

fromBCD :: BCD n -> Integer
fromBCD = foldl (\x d -> x * 10 + fromIntegral d) 0

type BCDSize n = CLog 10 (2 ^ n)
type ShiftAdd n = (Vec (BCDSize n) (Unsigned 4), Unsigned n)

{-# INLINE initBCD #-}
initBCD :: (KnownNat n) => Unsigned n -> ShiftAdd n
initBCD = (,) (repeat 0)

stepBCD :: (KnownNat n) => ShiftAdd n -> ShiftAdd n
stepBCD = shift . add
  where
    shift :: (KnownNat n) => ShiftAdd n -> ShiftAdd n
    shift = bitwise (`shiftL` 1)

    add :: ShiftAdd n -> ShiftAdd n
    add (digits, buf) = (map add3 digits, buf)
      where
        add3 d = if d >= 5 then d + 3 else d

{-# INLINE toBCD #-}
toBCD :: forall n. (KnownNat n) => Unsigned n -> BCD (BCDSize n)
toBCD = map toDigit . fst . last . iterate (SNat @(n + 1)) stepBCD . initBCD

roundtrip :: (KnownNat n) => Unsigned n -> Unsigned n
roundtrip = fromIntegral . fromBCD . map bitCoerce . toBCD

prop_BCD :: (KnownNat n) => Unsigned n -> Bool
prop_BCD x = x == roundtrip x
