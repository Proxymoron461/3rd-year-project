module Lib where

import GHC.TypeLits

someFunc :: IO ()
someFunc = putStrLn "someFunc"

-- A helpful kind synonym!
type Type = *
-- A datatype for Proxy types!
data Proxy a = Proxy

-- Defunctionalisation helpers! (thanks to https://github.com/Lysxia/first-class-families)
type Exp a = a -> Type
type family Eval (e :: Exp a) :: a

-- ID function, for wrapping data in Exp
data ID :: a -> Exp a
type instance Eval (ID x) = x

data (.) :: (b -> Exp c) -> (a -> Exp b) -> a -> Exp c
type instance Eval ((.) g f x) = Eval (g (Eval (f x)))
infixr 6 .

data Flip :: (a -> b -> Exp c) -> b -> a -> Exp c
type instance Eval (Flip f b a) = Eval (f a b)

-- Wrapping up a function, so that you can curry it at multiple layers!
-- TODO: If required, allow curry wrapping at multiple layers, for futype (???) = TypeError (Text "Function undefined!")nctions like (a -> b -> c) ??
data CurryWrap :: (a -> b) -> a -> Exp b
type instance Eval (CurryWrap f a) = f a
data CW :: (a -> b) -> a -> Exp b
type instance Eval (CW f a) = Eval (CurryWrap f a)

-- Curry-able add function!
data Add :: Nat -> Nat -> Exp Nat
type instance Eval (Add x y)    = x + y

-- Type-level functors! (Almost)
data Map :: (a -> Exp b) -> f a -> Exp (f b)
-- Maybe instance
type instance Eval (Map f Nothing)  = Nothing
type instance Eval (Map f (Just x)) = Just (Eval (f x))
-- Vector instance
type instance Eval (Map f VEnd)       = VEnd
type instance Eval (Map f (x :-> xs)) = Eval (f x) :-> Eval (Map f xs)

data (<$>) :: (a -> Exp b) -> f a -> Exp (f b)
type instance Eval (f <$> x) = Eval (Map f x)

-- Type-level applicative functors! (Almost)
-- (<*>) :: Applicative f => f (a -> b) -> f a -> f b
-- :kind! Eval (Map (Add 1) (Just 1)) = 'Just 2
-- :kind! Eval (Apply (Eval (Map (CW Add) (Just 1))) (Just 5)) = 'Just 6
data Pure :: a -> Exp (f a)
type instance Eval (Pure x) = Just x

data Apply :: f (a -> Exp b) -> f a -> Exp (f b)
type instance Eval (Apply _ Nothing)         = Nothing
type instance Eval (Apply (Just f) (Just x)) = Just (Eval (f x))

data (<*>) :: f (a -> Exp b) -> f a -> Exp (f b)
type instance Eval (f <*> x) = Eval (Apply f x)

-- Type-level monads! (Almost)
data Return :: a -> Exp (f a)
type instance Eval (Return x) = Pure x

data Bind :: (a -> Exp (f b)) -> f a -> Exp (f b)
type instance Eval (Bind f Nothing)  = Nothing
type instance Eval (Bind f (Just x)) = Eval (f x)

data (>>=) :: f a -> (a -> Exp (f b)) -> Exp (f b)
type instance Eval (x >>= f) = Eval (Bind f x)

data Join :: m (m a) -> Exp (m a)
type instance Eval (Join Nothing)  = Nothing
type instance Eval (Join (Just x)) = x

-- Some new thing - surely it already exists
data Flatten :: f (a -> Exp (f b)) -> f a -> Exp (f b)
type instance Eval (Flatten f x) = Eval (Join (Eval (Apply f x)))

-- This delays the evaluation of the type error!
-- (Thanks https://blog.poisson.chat/posts/2018-08-06-one-type-family.html#fnref4)
data TE' :: ErrorMessage -> Exp a
type instance Eval (TE' msg) = TypeError msg

-- A quick way of checking if two types are equal!
-- TODO: Test this to make sure it all works??
data IsTypeEqual :: a -> b -> Exp Bool
type instance Eval (IsTypeEqual a b) = IsTypeEqualNonFCF a b
data (:==:) :: a -> b -> Exp Bool
type instance Eval (a :==: b) = Eval (IsTypeEqual a b)

type family IsTypeEqualNonFCF (x :: a) (y :: b) :: Bool where
    IsTypeEqualNonFCF x x = 'True
    IsTypeEqualNonFCF x y = 'False

data If :: Bool -> Exp b -> Exp b -> Exp b
type instance Eval (If 'True thenDo elseDo) = Eval thenDo
type instance Eval (If 'False  thenDo elseDo) = Eval elseDo

data IsJust :: Maybe a -> Exp Bool
type instance Eval (IsJust (Just _)) = True
type instance Eval (IsJust Nothing)  = False

data FromJust :: Maybe a -> Exp a
type instance Eval (FromJust (Just x)) = x

data ToJust :: a -> Exp (Maybe a)
type instance Eval (ToJust x) = Just x

data FromMaybe :: b -> (a -> Exp b) -> Maybe a -> Exp b
type instance Eval (FromMaybe b f Nothing)  = b
type instance Eval (FromMaybe b f (Just x)) = Eval (f x)


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
data Vec (n :: Nat) (a :: Type) where
    VEnd   :: Vec 0 a
    (:->)  :: a -> Vec (n - 1) a -> Vec n a
infixr 4 :->

-- Helper type family, to avoid the (:-> VEnd) bit.
type family (:<>) (x :: a) (y :: a) :: Vec 2 a where
    x :<> y = x :-> y :-> VEnd
infixr 5 :<>

type family VecToList (v :: Vec n a) :: [a] where
    VecToList VEnd         = '[]
    VecToList (x :-> rest) = x ': (VecToList rest)

-- Membership checking for vectors
type family Elem (x :: a) (ys :: Vec n a) :: Bool where
    Elem x (y :-> rest) = Eval ((Eval (x :==: y)) :||: (ID (Elem x rest)))
    Elem x VEnd         = 'False

-- :kind! Eval (Or True (TE' (Text "eeeeh")))
-- A lazy version of Or, which only evaluates its' second param if the first fails.
data LazyOr :: Bool -> Exp Bool -> Exp Bool
type instance Eval (LazyOr True  _) = True
type instance Eval (LazyOr False x) = Eval x

data (:||:) :: Bool -> Exp Bool -> Exp Bool
type instance Eval (x :||: y) = Eval (LazyOr x y)

data LazyAnd :: Bool -> Exp Bool -> Exp Bool
type instance Eval (LazyAnd False _) = False
type instance Eval (LazyAnd True x)  = Eval x

data (:&&:) :: Bool -> Exp Bool -> Exp Bool
type instance Eval (x :&&: y) = Eval (LazyAnd x y)

data Any :: (a -> Exp Bool) -> Vec n a -> Exp Bool
type instance Eval (Any p VEnd)       = False
type instance Eval (Any p (x :-> xs)) = Eval (Eval (p x) :||: Any p xs)

data All :: (a -> Exp Bool) -> Vec n a -> Exp Bool
type instance Eval (All p VEnd)       = True
type instance Eval (All p (x :-> xs)) = Eval (Eval (p x) :&&: All p xs)


-- FIXME: FilterMap is not evaluating for VEnd. What's up with that?? Maybe n ~ m is undecidable??
data FilterMap :: (a -> Exp Bool) -> (a -> Exp b) -> Vec n a -> Exp (Vec m b)
type instance Eval (FilterMap cond f (x :-> xs)) = Eval (If (Eval (cond x)) (ID (Eval (f x) :-> Eval (FilterMap cond f xs))) ((FilterMap cond f xs)))
type instance Eval (FilterMap _    _ VEnd)       = VEnd

-- Type synonym for an 8x8 grid
type Grid8x8 = Vec 8 (Vec 8 (Maybe Piece))

-- TODO: Dimensions of board in type??
type Board = Grid8x8

data Piece where
    MkPiece :: Team -> PieceName -> PieceInfo -> Piece

data Team = Black | White

-- Make singleton types for each piece??
data PieceName = Pawn
               | Bishop
               | Knight
               | Rook
               | King
               | Queen

-- Holds the number of moves they've made, plus their current position.
-- While their position is implicit from where they are in the board, it's
-- helpful!
data PieceInfo where
    Info :: MyNat -> Position -> PieceInfo

-- TODO: Type level char??
-- Goes column-row, e.g. At "a" 4 means first column from left, 4 up from the bottom, where Black is at the top
data Position where
    At :: Symbol -> Nat -> Position

type Move = (Piece, Position)

-- TODO: Constrain so n < 3??
-- Can get the piece from the initial Position pair
data Moves where
    Moves :: Vec n Move -> Moves

type ValidColumns = "a" :-> "b" :-> "c" :-> "d" :-> "e" :-> "f" :-> "g" :<> "h"

type family ValidColumn (row :: Symbol) :: Maybe Symbol where
    ValidColumn x = Eval (If (Elem x ValidColumns) (ID (Just x)) (ID Nothing))

-- Custom Nat class, to allow pattern matching on Nat > 2
data MyNat where
    Z :: MyNat
    S :: MyNat -> MyNat

data NatToMyNat :: Nat -> Exp (MyNat)
type instance Eval (NatToMyNat n) = NatToMyNatNonFCF n
data MyNatToNat :: MyNat -> Exp (Nat)
type instance Eval (MyNatToNat Z)     = 0
type instance Eval (MyNatToNat (S n)) = 1 + (Eval (MyNatToNat n))

type family NatToMyNatNonFCF (n :: Nat) :: MyNat where
    NatToMyNatNonFCF 0 = Z
    NatToMyNatNonFCF n = S (NatToMyNatNonFCF (n - 1))

-- Type families to add an offset to columns!
-- TODO: Customise the number of columns?? As it is, it's chess-specific.
data (:+) :: MyNat -> Symbol -> Exp (Maybe Symbol)
data (:-) :: MyNat -> Symbol -> Exp (Maybe Symbol)

type instance Eval ((:+) Z         col) = ValidColumn col
type instance Eval ((:+) (S Z)     "a") = Just "b"
type instance Eval ((:+) (S Z)     "b") = Just "c"
type instance Eval ((:+) (S Z)     "c") = Just "d"
type instance Eval ((:+) (S Z)     "d") = Just "e"
type instance Eval ((:+) (S Z)     "e") = Just "f"
type instance Eval ((:+) (S Z)     "f") = Just "g"
type instance Eval ((:+) (S Z)     "g") = Just "h"
type instance Eval ((:+) (S Z)     "h") = Nothing
type instance Eval ((:+) (S (S n)) col) = Eval (Bind ((:+) (S n)) (Eval ((:+) (S Z) col)))

type instance Eval ((:-) Z         col) = ValidColumn col
type instance Eval ((:-) (S Z)     "a") = Nothing
type instance Eval ((:-) (S Z)     "b") = Just "a"
type instance Eval ((:-) (S Z)     "c") = Just "b"
type instance Eval ((:-) (S Z)     "d") = Just "c"
type instance Eval ((:-) (S Z)     "e") = Just "d"
type instance Eval ((:-) (S Z)     "f") = Just "e"
type instance Eval ((:-) (S Z)     "g") = Just "f"
type instance Eval ((:-) (S Z)     "h") = Just "g"
type instance Eval ((:-) (S (S n)) col) = Eval (Bind ((:-) (S n)) (Eval ((:-) (S Z) col)))

-- TEST TYPES
-- TODO: Remove these
type TestPosition = At "a" 1  -- i.e. bottom left
type TestPiece    = MkPiece Black Pawn (Info Z TestPosition)
type EmptyRow     = Nothing :-> Nothing :-> Nothing :-> Nothing :-> Nothing :-> Nothing :-> Nothing :<> Nothing
type TestBoard    = (Just TestPiece :-> Nothing :-> Nothing :-> Nothing :-> Nothing :-> Nothing :-> Nothing :<> Nothing)
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :<> EmptyRow
type TestBoard2   = (Just TestPiece :-> Nothing :-> Nothing :-> Nothing :-> Nothing :-> Nothing :-> Nothing :<> Nothing)
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :-> EmptyRow
                    :<> EmptyRow

type family UpdateBoard (board :: Board) (turn :: Team) (moves :: Moves) :: Board where
    UpdateBoard _ _ ('Moves VEnd) = TypeError (Text "A move must be made!")
    UpdateBoard _ _ _    = TypeError (Text "UpdateBoard is unfinished!")

type family IsUpdateValid (from :: Board) (to :: Board) (turn :: Team) :: Board where
    IsUpdateValid x x _ = TypeError (Text "A move must be made - the board cannot stay exactly the same.")
    IsUpdateValid _ _ _ = TypeError (Text "IsUpdateValid is unfinished!")

-- When using Maybes, this returns another maybe!
-- :kind! Eval (VecAt TestBoard Z) :: Maybe (Vec 8 (Maybe Piece))
-- data Bind :: (a -> Exp (f b)) -> f a -> Exp (f b)
data VecAt :: Vec n a -> MyNat -> Exp (Maybe a)
type instance Eval (VecAt VEnd _) = Nothing
type instance Eval (VecAt (x :-> xs) Z) = Just x
type instance Eval (VecAt (x :-> xs) (S n)) = Eval (VecAt xs n)

data (!!) :: Vec n a -> MyNat -> Exp (Maybe a)
type instance Eval (vec !! nat) = Eval (VecAt vec nat)

type family ElemIndex (vec :: Vec n a) (item :: a) :: Maybe Nat where
    ElemIndex VEnd item          = Nothing
    ElemIndex (item :-> xs) item = Just 0
    ElemIndex (x :-> xs)    item = Eval (Map (Add 1) (ElemIndex xs item))

-- TODO: Maybe make this tied less to ValidColumns??
type family ColToIndex (col :: Symbol) :: Maybe Nat where
    ColToIndex col = ElemIndex ValidColumns col

-- TODO: Make it cause an error when row = 0
data GetPieceAt :: Board -> Position -> Exp (Maybe Piece)
type instance Eval (GetPieceAt board (At col row)) = Eval (Join (Eval (Join (Eval ((Eval ((CW (!!)) <$> (Eval (board !! (Eval (NatToMyNat (row - 1))))))) <*> (Eval (NatToMyNat <$> (ColToIndex col))))))))

-- Rudimentary way to display type errors, for now.
x :: Proxy (UpdateBoard TestBoard White ('Moves VEnd))
x = Proxy

data IsBlack :: Piece -> Exp (Bool)
type instance Eval (IsBlack (MkPiece team _ _)) = Eval (team :==: Black)

data IsWhite :: Piece -> Exp (Bool)
type instance Eval (IsWhite (MkPiece team _ _)) = Eval (team :==: White)

-- TODO: Figure out how to handle the side effects of moves (e.g. taking a piece, castling, replacing a piece with another)
-- TODO: Maybe represent the boards that the piece can move to? A new function, MovePiece, which handles any side effects??
-- Returns an empty vector if the board is empty at that position!
data CalculateValidMoves :: Position -> Board -> Exp (Vec n Position)
type instance Eval (CalculateValidMoves pos board) = Eval (FromMaybe VEnd ((Flip PieceCanMoveTo) board) (Eval (GetPieceAt board pos)))

-- TODO: Write instances for each team x piece, e.g. White Pawn, Black Knight, ...
data PieceCanMoveTo :: Piece -> Board -> Exp (Vec n Position)
type instance Eval (PieceCanMoveTo (MkPiece Black Pawn info) board)   = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece White Pawn info) board)   = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece Black Bishop info) board) = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece White Bishop info) board) = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece Black Knight info) board) = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece White Knight info) board) = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece Black Rook info) board)   = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece White Rook info) board)   = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece Black Queen info) board)  = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece White Queen info) board)  = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece Black King info) board)   = TypeError (Text "Not written PieceCanMoveTo yet!")
type instance Eval (PieceCanMoveTo (MkPiece White King info) board)   = TypeError (Text "Not written PieceCanMoveTo yet!")

-- -- TODO: Check the piece's reported position is the actual position, eh
-- type family PieceMoves (p :: Piece) (board :: Board) :: Maybe (Vec n Position) where
--     PieceMoves (MkPiece team Pawn info) board = PawnMoves (MkPiece team Pawn info) board
--     PieceMoves _ _ = TypeError (Text "Unfinished!")

-- -- TODO: Include diagonal takes!
-- -- TODO: Take the board into account!
-- -- TODO: Return Nothing if no valid moves
-- type family PawnMoves (p :: Piece) (board :: Board) :: Maybe (Vec n Position) where
--     PawnMoves (MkPiece Black Pawn (Info 0 (At col row))) board = Just (At col (row - 1) :<> At col (row - 2))
--     PawnMoves (MkPiece Black Pawn (Info n (At col row))) board = Just (At col (row - 1) :-> VEnd)
--     PawnMoves (MkPiece White Pawn (Info 0 (At col row))) board = Just (At col (row + 1) :<> At col (row + 2))
--     PawnMoves (MkPiece White Pawn (Info n (At col row))) board = Just (At col (row + 1) :-> VEnd)

-- pawnMovesTest1 :: Proxy (Just (At "a" 3 :<> At "a" 2))
-- pawnMovesTest1 = Proxy @(PawnMoves (MkPiece Black Pawn (Info 0 (At "a" 4))) TestBoard)

-- pawnMovesTest2 :: Proxy (Just (At "a" 3 :-> VEnd))
-- pawnMovesTest2 = Proxy @(PawnMoves (MkPiece Black Pawn (Info 7 (At "a" 4))) TestBoard)

-- pawnMovesTest3 :: Proxy (Just (At "a" 5 :<> At "a" 6))
-- pawnMovesTest3 = Proxy @(PawnMoves (MkPiece White Pawn (Info 0 (At "a" 4))) TestBoard)

-- pawnMovesTest4 :: Proxy (Just (At "a" 5 :-> VEnd))
-- pawnMovesTest4 = Proxy @(PawnMoves (MkPiece White Pawn (Info 7 (At "a" 4))) TestBoard)

getPieceAtTest1 :: Proxy (Just TestPiece)
getPieceAtTest1 = Proxy @(Eval (GetPieceAt TestBoard (At "a" 1)))

-- :k VecAtR Z :: Vec n a -> Exp (Maybe a)
getPieceAtTest2 :: Proxy (Just TestPiece)
getPieceAtTest2 = Proxy @(Eval (Join (Eval (Bind ((Flip (!!)) (Eval (NatToMyNat 0))) (Eval (TestBoard !! (Eval (NatToMyNat 0))))))))

-- TODO: Fix this!! Use bind!
-- :kind! VecAt (Z :<> (S Z)) :: MyNat -> Exp (Maybe MyNat)
getPieceAtTest3 :: Proxy (Just Z)
getPieceAtTest3 = Proxy @(Eval (Join (Eval ((Eval ((CW (!!)) <$> Just (Z :<> (S Z)))) <*> Just Z))))

filterMapTest1 :: Proxy (VEnd)
filterMapTest1 = Proxy @(Eval (FilterMap IsJust FromJust (Nothing :<> Nothing)))

filterMapTest2 :: Proxy ("a" :-> "c" :-> "abcd" :-> VEnd)
filterMapTest2 = Proxy @(Eval (FilterMap IsJust FromJust (Just "a" :-> Nothing :-> Just "c" :-> Just "abcd" :-> Nothing :-> Nothing :<> Nothing)))

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

-- type family Update (board :: Board) (pieces :: Vec n Piece) (positions :: Vec n Position) :: Board where
--     Update board pieces positions = TypeError (Text "Unfinished!")

-- -- TODO: Make this work
-- -- Associated type family for pieces that can move; takes their current position, the board,
-- -- and then a series of valid next positions!
-- -- TODO: Use type equality (~) to check that the piece is at that position
-- class Moveable p where
--     type NextPositions p :: Position -> Board -> Exp (Vec n Position)

-- -- Defunctionalised evaluation of moveable pieces
-- type Exp a = a -> Type

-- type family Eval (e :: Exp a) :: a

-- data MovePawn :: Position -> Board -> Exp (Vec n Position)

-- -- TODO: Complete the below by checking the piece at the location!
-- -- FIXME: Pawns move in different directions depending on their color - fix this
-- -- FIXME: Pawns move 1 or 2 spaces depending on whether it's their first move or not
-- type instance Eval (MovePawn (At row col) b) = (At row (col + 1)) :-> ((At row (col + 2)) :-> VEnd)

-- instance Moveable Pawn where
--     type NextPositions Pawn = MovePawn

-- type family MovePawn (pos :: Position) (b :: Board) :: Vec n Position where
--     MovePawn x y = TestPosition :-> VEnd
