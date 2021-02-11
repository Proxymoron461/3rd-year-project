module FlatBuilders where

import MakeSingletons
import ChessTypes
import Data.Singletons
import Data.Singletons.Prelude.Bool
import Data.Type.Nat hiding (SNat(..))
import Lib
import FirstClassFunctions
import qualified GHC.TypeLits as TL

-- A continuation has form (t -> m)
type Spec t = forall m. (t -> m) -> m

type Conv s t = s -> Spec t

type Term t r = t -> r

----------------------------------------------------------------------------------------------------

-- Spec Int has type (Int -> r) -> r, for some type r
-- In other words, if you create a Spec Piece, all you need next is a function that takes a piece

-- Starts as black, because the first move needs to be white
-- type Spec t = forall m. (t -> m) -> m
chess :: Spec (Proxy StartDec)
chess cont = cont (Proxy @StartDec)

data MoveArgs where
    MA :: BoardDecorator -> Position -> PieceName -> Position -> MoveArgs

pawn :: Proxy (b :: BoardDecorator) -> SPosition fromPos -> Spec (Proxy (MA b fromPos 'Pawn))
pawn (dec :: Proxy b) (from :: SPosition fromPos) cont = cont (Proxy @(MA b fromPos Pawn))

rook :: Proxy (b :: BoardDecorator) -> SPosition fromPos -> Spec (Proxy (MA b fromPos 'Rook))
rook (dec :: Proxy b) (from :: SPosition fromPos) cont = cont (Proxy @(MA b fromPos Rook))

bishop :: Proxy (b :: BoardDecorator) -> SPosition fromPos -> Spec (Proxy (MA b fromPos 'Bishop))
bishop (dec :: Proxy b) (from :: SPosition fromPos) cont = cont (Proxy @(MA b fromPos Bishop))

queen :: Proxy (b :: BoardDecorator) -> SPosition fromPos -> Spec (Proxy (MA b fromPos 'Queen))
queen (dec :: Proxy b) (from :: SPosition fromPos) cont = cont (Proxy @(MA b fromPos Queen))

knight :: Proxy (b :: BoardDecorator) -> SPosition fromPos -> Spec (Proxy (MA b fromPos 'Knight))
knight (dec :: Proxy b) (from :: SPosition fromPos) cont = cont (Proxy @(MA b fromPos Knight))

king :: Proxy (b :: BoardDecorator) -> SPosition fromPos -> Spec (Proxy (MA b fromPos 'King))
king (dec :: Proxy b) (from :: SPosition fromPos) cont = cont (Proxy @(MA b fromPos King))

to :: Proxy (MA (b :: BoardDecorator) (fromPos :: Position) (n :: PieceName)) -> SPosition toPos
      -> Spec (Proxy (Eval (IfPieceThenMove n fromPos toPos b)))
to (args :: Proxy (MA (b :: BoardDecorator) (fromPos :: Position) (n :: PieceName))) (to' :: SPosition toPos)  cont
    = cont (Proxy @(Eval (IfPieceThenMove n fromPos toPos b)))

-- Shorthands
p :: Proxy (b :: BoardDecorator) -> SPosition toPos -> Spec (Proxy (MoveTo Pawn toPos b))
p (dec :: Proxy b) (to :: SPosition toPos) cont = cont (Proxy @(MoveTo Pawn toPos b))

n :: Proxy (b :: BoardDecorator) -> SPosition toPos -> Spec (Proxy (MoveTo Knight toPos b))
n (dec :: Proxy b) (to :: SPosition toPos) cont = cont (Proxy @(MoveTo Knight toPos b))

r :: Proxy (b :: BoardDecorator) -> SPosition toPos -> Spec (Proxy (MoveTo Rook toPos b))
r (dec :: Proxy b) (to :: SPosition toPos) cont = cont (Proxy @(MoveTo Rook toPos b))

b :: Proxy (b :: BoardDecorator) -> SPosition toPos -> Spec (Proxy (MoveTo Bishop toPos b))
b (dec :: Proxy b) (to :: SPosition toPos) cont = cont (Proxy @(MoveTo Bishop toPos b))

q :: Proxy (b :: BoardDecorator) -> SPosition toPos -> Spec (Proxy (MoveTo Queen toPos b))
q (dec :: Proxy b) (to :: SPosition toPos) cont = cont (Proxy @(MoveTo Queen toPos b))

k :: Proxy (b :: BoardDecorator) -> SPosition toPos -> Spec (Proxy (MoveTo King toPos b))
k (dec :: Proxy b) (to :: SPosition toPos) cont = cont (Proxy @(MoveTo King toPos b))

-- Even though it's a Proxy TypeError, it will split out errors just fine!
end :: Term (Proxy (b :: BoardDecorator)) (Proxy (b :: BoardDecorator))
end = id

becomes :: Proxy (b :: BoardDecorator) -> SPieceName name
           -> Spec (Proxy (PromotePieceTo' name (GetLastPosition b) b))
becomes (dec :: Proxy b) (n :: SPieceName name) cont = cont (Proxy @(PromotePieceTo' name (GetLastPosition b) b))

promoteTo :: Proxy (MA (b :: BoardDecorator) (fromPos :: Position) (n :: PieceName)) -> SPieceName promoteTo -> SPosition toPos
      -> Spec (Proxy (Eval (PromotePawnMove fromPos toPos promoteTo b)))
promoteTo (args :: Proxy (MA (b :: BoardDecorator) (fromPos :: Position) (n :: PieceName))) (pro :: SPieceName promoteTo) (to' :: SPosition toPos)  cont
    = cont (Proxy @(Eval (PromotePawnMove fromPos toPos promoteTo b)))

-- data SetPieceAtDec :: Piece -> BoardDecorator -> Position -> Exp BoardDecorator
data CreateArgs where
    CA :: BoardDecorator -> Team -> PieceName -> Position -> CreateArgs

create :: Spec (Proxy JustKingsDec)
create cont = cont (Proxy @JustKingsDec)

put :: Proxy (b :: BoardDecorator) -> STeam team -> SPieceName name -> Spec (Proxy (CA b team name))
put (dec :: Proxy b) (t :: STeam team) (p :: SPieceName name) cont = cont (Proxy @(CA b team name))

at :: Proxy (CA (b :: BoardDecorator) (team :: Team) (name :: PieceName)) -> SPosition toPos
      -> Spec (Proxy (Eval (SetPieceAtDec (MkPiece team name (Info Z toPos False)) b toPos)))
at (dec :: Proxy (CA b team name)) (p :: SPosition toPos) cont
    = cont (Proxy @(Eval (SetPieceAtDec (MkPiece team name (Info Z toPos False)) b toPos)))

lastTeam :: Proxy (b :: BoardDecorator) -> STeam team -> Spec (Proxy (SetLastTeam b team))
lastTeam (dec :: Proxy b) (t :: STeam team) cont
    = cont (Proxy @(SetLastTeam b team))
lastteam = lastTeam

lastMoved :: Proxy (b :: BoardDecorator) -> SPosition pos -> Spec (Proxy (SetLastPosition pos b))
lastMoved (dec :: Proxy b) (t :: SPosition pos) cont
    = cont (Proxy @(SetLastPosition pos b))

lastmoved = lastMoved

startMoves :: Conv (Proxy (b :: BoardDecorator)) (Proxy (b :: BoardDecorator))
startMoves (dec :: Proxy b) cont = cont dec
startmoves = startMoves

-- TODO: Introduce a bunch of different EDSL endings that you need!
endGetBoard :: Term (Proxy (a :: BoardDecorator)) (Proxy (GetBoard a))
endGetBoard (Proxy :: Proxy (b :: BoardDecorator)) = Proxy @(GetBoard b)

-- TODO: Code should deal with:
    -- Checkmate (compile or don't compile?)
    -- Draw (can only move into check)
    -- Trapped pieces

data Fen (n :: Nat) where
    FF  :: Fen Nat0
    F1  :: Fen n -> Fen (S n)
    F2  :: Fen n -> Fen (S (S n))
    F3  :: Fen n -> Fen (S (S (S n)))
    F4  :: Fen n -> Fen (S (S (S (S n))))
    F5  :: Fen n -> Fen (S (S (S (S (S n)))))
    F6  :: Fen n -> Fen (S (S (S (S (S (S n))))))
    F7  :: Fen n -> Fen (S (S (S (S (S (S (S n)))))))
    F8  :: Fen Nat8
    Pw  :: Fen n -> Fen (S n)
    Nw  :: Fen n -> Fen (S n)
    Qw  :: Fen n -> Fen (S n)
    Kw  :: Fen n -> Fen (S n)
    Bw  :: Fen n -> Fen (S n)
    Rw  :: Fen n -> Fen (S n)
    Pb  :: Fen n -> Fen (S n)
    Nb  :: Fen n -> Fen (S n)
    Qb  :: Fen n -> Fen (S n)
    Kb  :: Fen n -> Fen (S n)
    Bb  :: Fen n -> Fen (S n)
    Rb  :: Fen n -> Fen (S n)

f0 :: Term (Proxy (b :: Fen n)) (Proxy (b :: Fen n))
f0 = id

f1 :: (Proxy (b :: Fen n)) -> Spec (Proxy (F1 b))
f1 (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(F1 b))

f2 :: (Proxy (b :: Fen n)) -> Spec (Proxy (F2 b))
f2 (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(F2 b))

f3 :: (Proxy (b :: Fen n)) -> Spec (Proxy (F3 b))
f3 (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(F3 b))

f4 :: (Proxy (b :: Fen n)) -> Spec (Proxy (F4 b))
f4 (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(F4 b))

f5 :: (Proxy (b :: Fen n)) -> Spec (Proxy (F5 b))
f5 (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(F5 b))

f6 :: (Proxy (b :: Fen n)) -> Spec (Proxy (F6 b))
f6 (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(F6 b))

f7 :: (Proxy (b :: Fen n)) -> Spec (Proxy (F7 b))
f7 (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(F7 b))

ff :: Spec (Proxy FF)
ff cont = cont (Proxy @FF)

f8 :: Term (Proxy (b :: Fen Nat8)) (Proxy (b :: Fen Nat8))
f8 = id

wP :: (Proxy (b :: Fen n)) -> Spec (Proxy (Pw b))
wP (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Pw b))

wQ :: (Proxy (b :: Fen n)) -> Spec (Proxy (Qw b))
wQ (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Qw b))

wN :: (Proxy (b :: Fen n)) -> Spec (Proxy (Nw b))
wN (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Nw b))

wK :: (Proxy (b :: Fen n)) -> Spec (Proxy (Kw b))
wK (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Kw b))

wB :: (Proxy (b :: Fen n)) -> Spec (Proxy (Bw b))
wB (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Bw b))

wR :: (Proxy (b :: Fen n)) -> Spec (Proxy (Rw b))
wR (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Rw b))

bP :: (Proxy (b :: Fen n)) -> Spec (Proxy (Pb b))
bP (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Pb b))

bQ :: (Proxy (b :: Fen n)) -> Spec (Proxy (Qb b))
bQ (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Qb b))

bN :: (Proxy (b :: Fen n)) -> Spec (Proxy (Nb b))
bN (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Nb b))

bK :: (Proxy (b :: Fen n)) -> Spec (Proxy (Kb b))
bK (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Kb b))

bB :: (Proxy (b :: Fen n)) -> Spec (Proxy (Bb b))
bB (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Bb b))

bR :: (Proxy (b :: Fen n)) -> Spec (Proxy (Rb b))
bR (Proxy :: Proxy (b :: Fen n)) cont = cont (Proxy @(Rb b))

-- data Fen (n :: Nat) where
--     FF  :: Fen Nat0 -> Fen Nat0
--     F1  :: (Fen (S m) -> Fen n) -> Fen n
--     F2  :: (Fen (S (S m)) -> Fen n) -> Fen n
--     F3  :: (Fen (S (S (S m))) -> Fen n) -> Fen n
--     F4  :: (Fen (S (S (S (S m)))) -> Fen n) -> Fen n
--     F5  :: (Fen (S (S (S (S (S m))))) -> Fen n) -> Fen n
--     F6  :: (Fen (S (S (S (S (S (S m)))))) -> Fen n) -> Fen n
--     F7  :: (Fen (S (S (S (S (S (S (S m))))))) -> Fen n) -> Fen n
--     F8  :: Fen Nat8 -> Fen Nat8
--     P   :: Fen n -> Fen (S n)
--     N   :: Fen n -> Fen (S n)
--     Q   :: Fen n -> Fen (S n)
--     K   :: Fen n -> Fen (S n)
--     B   :: Fen n -> Fen (S n)
--     R   :: Fen n -> Fen (S n)
--     Pb  :: Fen n -> Fen (S n)
--     Nb  :: Fen n -> Fen (S n)
--     Qb  :: Fen n -> Fen (S n)
--     Kb  :: Fen n -> Fen (S n)
--     Bb  :: Fen n -> Fen (S n)
--     Rb  :: Fen n -> Fen (S n)

-- F2 F1 F0 = Fen 3
-- F2 F1 = ((Fen n) -> Fen m) -> 
-- F2 = (Fen n) -> Fen 

