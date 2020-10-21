{-# OPTIONS_GHC -fdefer-type-errors #-}

import Test.Hspec
import Test.HUnit.Lang (Assertion, assertFailure)
import Test.ShouldNotTypecheck (shouldNotTypecheck)
import Control.DeepSeq (force, NFData)
import Control.Exception (evaluate, try, TypeError(..))
import Data.Type.Equality ((:~:)(..))
import Data.Proxy(Proxy(..))
import qualified GHC.TypeLits as TL (Nat)
import Data.Type.Nat hiding (SNat(..))

import Lib
import Vec
import FirstClassFunctions
import ChessTypes

import Movement
import TestTypes
import KingTests

----------------------------------------------------------------------------------------------
-- TEST FUNCTIONS

pawnTest1 :: '[ At D Nat3, At D Nat2] :~: Eval (PawnReachableBelow TestBoard2 (At D Nat4) Nat2)
pawnTest1 = Refl

whitePawnToQueenTest :: Just (MkPiece White Queen (Info (S Z) (At D Nat8) True)) :~: Eval ((Eval (Move (At D Nat7) (At D Nat8) (Eval (SetPieceAt (MkPiece White Pawn TestInfo) EmptyBoard (At D Nat7))))) >>= (Flip GetPieceAt) (At D Nat8))
whitePawnToQueenTest = Refl

blackPawnToQueenTest :: Just (MkPiece Black Queen (Info (S Z) (At D Nat1) True)) :~: Eval ((Eval (Move (At D Nat2) (At D Nat1) (Eval (SetPieceAt (MkPiece Black Pawn TestInfo) EmptyBoard (At D Nat2))))) >>= (Flip GetPieceAt) (At D Nat1))
blackPawnToQueenTest = Refl

getReachableLeftTest1 :: '[ At C Nat2, At B Nat2, At A Nat2] :~: Eval (AllReachableLeft Black TestBoard2 (At D Nat2))
getReachableLeftTest1 = Refl

getReachableLeftTest2 :: '[ At C Nat2, At B Nat2] :~: Eval (AllReachableLeft White TestBoard2 (At D Nat2))
getReachableLeftTest2 = Refl

getReachableLeftTest3 :: '[ At B Nat1, At A Nat1] :~: Eval (AllReachableLeft White TestBoard (At C Nat1))
getReachableLeftTest3 = Refl

getReachableLeftTest4 :: '[ At B Nat1 ] :~: Eval (AllReachableLeft Black TestBoard (At C Nat1))
getReachableLeftTest4 = Refl

getReachableLeftTest5 :: ('[] :: [Position]) :~: Eval (AllReachableLeft Black TestBoard (At A Nat1))
getReachableLeftTest5 = Refl

pawnReachableAboveTest1 :: ('[] :: [Position]) :~: Eval (PawnReachableAbove TestBoard2 (At B Nat7) Nat2)
pawnReachableAboveTest1 = Refl

pawnReachableAboveTest2 :: ('[ At D Nat5, At D Nat6] ) :~: Eval (PawnReachableAbove TestBoard2 (At D Nat4) Nat2)
pawnReachableAboveTest2 = Refl

pawnReachableBelowTest1 :: ('[] :: [Position]) :~: Eval (PawnReachableBelow TestBoard2 (At A Nat3) Nat2)
pawnReachableBelowTest1 = Refl

getPieceAtTest1 :: Just TestPiece :~: Eval (GetPieceAt TestBoard (At A Nat1))
getPieceAtTest1 = Refl

-- :k VecAtR Z :: Vec n a -> Exp (Maybe a)
getPieceAtTest2 :: Just TestPiece :~: Eval (Join (Eval (Bind ((Flip (!!) (Nat0))) (Eval (TestBoard !! Nat0)))))
getPieceAtTest2 = Refl

-- :kind! VecAt (Z :<> (S Z)) :: Nat -> Exp (Maybe Nat)
getPieceAtTest3 :: Just Z :~: Eval (Join (Eval ((Eval ((CW (!!)) <$> Just (Z :<> (S Z)))) <*> Just Z)))
getPieceAtTest3 = Refl

canMoveToTest1 :: True :~: Eval (CanMoveTo (At A Nat7) (At A Nat6) (Eval (SetPieceAt (MkPiece Black Pawn (Info (S Z) TestPosition False)) EmptyBoard (At A Nat7))))
canMoveToTest1 = Refl

canMoveToTest2 :: True :~: Eval (CanMoveTo (At A Nat7) (At A Nat5) (Eval (SetPieceAt (MkPiece Black Pawn (Info Z TestPosition False)) EmptyBoard (At A Nat7))))
canMoveToTest2 = Refl

canMoveToTest3 :: False :~: Eval (CanMoveTo (At A Nat7) (At A Nat5) (Eval (SetPieceAt (MkPiece Black Pawn (Info (S Z) TestPosition False)) EmptyBoard (At A Nat7))))
canMoveToTest3 = Refl

canMoveToTest4 :: False :~: Eval (CanMoveTo (At A Nat7) (At A Nat5) (Eval (SetPieceAt (MkPiece White Pawn TestInfo) (Eval (SetPieceAt (MkPiece Black Pawn TestInfo) EmptyBoard (At A Nat7))) (At A Nat6))))
canMoveToTest4 = Refl

type CanReachBoard = Eval (SetPiecesAt '[ '(MkPiece White Rook TestInfo, At D Nat5), '(MkPiece Black King TestInfo, At D Nat4)] EmptyBoard )
canMoveToTest5 :: False :~: Eval (CanMoveTo (At D Nat5) (At D Nat4) CanReachBoard)
canMoveToTest5 = Refl

canReachTest1 :: True :~: Eval (Eval (Eval (CanMoveTo (At D Nat5) (At D Nat4) CanReachBoard) :==: False) :&&: (Eval (CanReach (At D Nat5) (At D Nat4) CanReachBoard) :==: True))
canReachTest1 = Refl

pieceMoveListWhitePawnTest :: '[ At A Nat3, At A Nat4 ] :~: Eval (PieceMoveList TestWhitePawn TestBoard2)
pieceMoveListWhitePawnTest = Refl

pawnTakePositionsBlackTest :: '[ At A Nat7, At C Nat7] :~: Eval (PawnTakePositions TestBlackPawn TestBoard2)
pawnTakePositionsBlackTest = Refl

pawnTakePositionsWhiteTest :: ('[] :: [Position]) :~: Eval (PawnTakePositions TestWhitePawn TestBoard2)
pawnTakePositionsWhiteTest = Refl

listEqualityTest1 :: 'True :~: Eval (('[] :: [Nat]) :=:=: ('[] :: [Nat]))
listEqualityTest1 = Refl

listEqualityTest2 :: 'True :~: Eval (TestList :=:=: Eval (Reverse TestList))
listEqualityTest2 = Refl

listEqualityTest3 :: 'False :~: Eval (TestList :=:=: (90 ': TestList))
listEqualityTest3 = Refl

knightPositionsTest1 :: 'True :~: Eval (('[At E Nat6, At E Nat2, At C Nat6, At C Nat2, At B Nat5, At B Nat3, At F Nat5, At F Nat3]) :=:=: Eval (GetAllKnightPositions (At D Nat4)))
knightPositionsTest1 = Refl

knightPositionsTest2 :: 'True :~: Eval (('[At B Nat3, At C Nat2 ]) :=:=: Eval (GetAllKnightPositions (At A Nat1)))
knightPositionsTest2 = Refl

allReachableGivenListTest1 :: ('[] :: [Position]) :~: Eval (AllReachableGivenList White TestBoard2 '[ At A Nat2, At A Nat7, At B Nat3 ])
allReachableGivenListTest1 = Refl

allReachableGivenListTest2 :: '[ At A Nat1, At A Nat2, At A Nat7, At B Nat3 ] :~: Eval (AllReachableGivenList Black TestBoard2 '[ At A Nat1, At A Nat2, At A Nat7, At B Nat3 ])
allReachableGivenListTest2 = Refl

getAdjacentTest1 :: 'True :~: Eval ('[At A Nat2, At B Nat1, At B Nat2] :=:=: Eval (GetAdjacent (At A Nat1)))
getAdjacentTest1 = Refl

getAdjacentTest2 :: 'True :~: Eval ('[At E Nat4, At E Nat5, At E Nat6, At G Nat4, At G Nat5, At G Nat6,At F Nat4, At F Nat6] :=:=: Eval (GetAdjacent (At F Nat5)))
getAdjacentTest2 = Refl

getAdjacentTest3 :: 'False :~: Eval (In (At D Nat4) (Eval (GetAdjacent (At D Nat4))))
getAdjacentTest3 = Refl

oppositeTeamTest1 :: White :~: Eval (OppositeTeam Black)
oppositeTeamTest1 = Refl

oppositeTeamTest2 :: Black :~: Eval (OppositeTeam White)
oppositeTeamTest2 = Refl

setPieceAtTest1 :: At B Nat6 :~: Eval (PiecePosition (Eval (FromJust (Eval (GetPieceAt (Eval (SetPieceAt (MkPiece Black Pawn (Info Z (At D Nat2) False)) EmptyBoard (At B Nat6))) (At B Nat6))))))
setPieceAtTest1 = Refl

-- :kind! Flip (SetPieceAt piece) :: Position -> Board -> Exp Board
-- data Foldr :: (a -> b -> Exp b) -> b -> [a] -> Exp b
setPieceAtTest2 :: Nat3 :~: Eval (NoOfPieces (Eval (Foldr (Uncurry2 SetPieceAtSwapped) EmptyBoard (Eval (Zip TestPieceList '[At B Nat1, At B Nat2, At B Nat3])))))
setPieceAtTest2 = Refl

setPieceAtTest3 :: Nat1 :~: Eval (NoOfPieces (Eval (Foldr (Uncurry2 SetPieceAtSwapped) EmptyBoard (Eval (Zip TestPieceList (Eval (Replicate Nat3 (At B Nat1))))))))
setPieceAtTest3 = Refl

setPiecesAtTest1 :: Nat3 :~: Eval (NoOfPieces (Eval (SetPiecesAt (Eval (Zip TestPieceList '[At B Nat1, At B Nat2, At B Nat3])) EmptyBoard)))
setPiecesAtTest1 = Refl

setPiecesAtTest2 :: (Eval (Foldr (Uncurry2 SetPieceAtSwapped) EmptyBoard (Eval (Zip TestPieceList '[At B Nat1, At B Nat2, At B Nat3]))))
                    :~: (Eval (SetPiecesAt (Eval (Zip TestPieceList '[At B Nat1, At B Nat2, At B Nat3])) EmptyBoard))
setPiecesAtTest2 = Refl

-- -- TODO: Make en passant tests
-- enPassantTest1 :: True :~: False
-- enPassantTest1 = Refl

----------------------------------------------------------------------------------------------
-- ACTUAL TESTS

shouldTypecheck :: NFData a => a -> Assertion
shouldTypecheck a = do
    result <- try (evaluate (force a))  -- Using Haskell’s do-notation
    case result of
        Right _ -> return ()  -- Test passes
        Left (TypeError msg) -> assertFailure ("Term didn’t compile.")

shouldTypeCheck :: NFData a => a -> Assertion
shouldTypeCheck = shouldTypecheck

-- TODO: Multiple test suites over multiple files??
main :: IO ()
main = hspec $ do
  describe "List Equality Tests" $ do
    it "Nat1: Two empty lists should be equal" $ do
      shouldTypecheck listEqualityTest1
    it "Nat2: Two non-empty lists with the same elements should be equal" $
      shouldTypecheck listEqualityTest2
    it "Nat3: Two non-empty lists with different elements should not be equal" $ 
      shouldTypecheck listEqualityTest3
  describe "SetPieceAt Tests" $ do
    it "Nat1: A piece set to a position should then have that position recorded in the piece's info record" $ 
      shouldTypecheck setPieceAtTest1
    it "Nat2: Setting n pieces down should mean that there are n pieces on the board" $ 
      shouldTypecheck setPieceAtTest2
  describe "SetPiecesAt (plural) Tests" $ do
    it "Nat1: Setting n pieces down should mean that there are n pieces on the board" $ 
      shouldTypecheck setPiecesAtTest1
    it "Nat2: The result of SetPiecesAt should be identical to repeated applications of SetPieceAt" $ 
      shouldTypecheck setPiecesAtTest2
  describe "OppositeTeam Tests" $ do
    it "Nat1: OppositeTeam White = Black" $
      shouldTypecheck oppositeTeamTest1
    it "Nat2: OppositeTeam White = Black" $
      shouldTypecheck oppositeTeamTest2
  describe "GetReachableLeft Tests" $ do
    it "Nat1" $
      shouldTypecheck getReachableLeftTest1
    it "Nat2" $
      shouldTypecheck getReachableLeftTest2
    it "Nat3" $
      shouldTypecheck getReachableLeftTest3
    it "Nat4" $
      shouldTypecheck getReachableLeftTest4
    it "Nat5" $
      shouldTypecheck getReachableLeftTest5
  describe "PawnReachableAbove Tests" $ do
    it "Nat1" $
      shouldTypecheck pawnReachableAboveTest1
    it "Nat2" $
      shouldTypecheck pawnReachableAboveTest2
  describe "PawnReachableBelow Tests" $ do
    it "Nat1" $
      shouldTypecheck pawnReachableBelowTest1
  describe "GetPieceAt Tests" $ do
    it "Nat1" $
      shouldTypecheck getPieceAtTest1
    it "Nat2" $
      shouldTypecheck getPieceAtTest2
    it "Nat3" $
      shouldTypecheck getPieceAtTest3
  describe "CanMoveTo and CanReach Tests" $ do
    describe "CanMoveTo Tests" $ do
      it "Nat1: A black pawn should be able to move to the space directly below it (if it is empty)." $
        shouldTypecheck canMoveToTest1
      it "Nat2: A black pawn that has not moved should be able to move Nat2 spaces below itself (if both are empty)." $
        shouldTypecheck canMoveToTest2
      it "Nat3: A black pawn that has already moved should not be able to move Nat2 spaces below itself." $
        shouldTypecheck canMoveToTest3
      it "Nat4: A black pawn that has not moved should not be able to move Nat2 spaces below itself if the space below it is empty." $
        shouldTypecheck canMoveToTest4
      it "Nat5: A piece should not be able to move to the King's current position, even if it is reachable." $
        shouldTypecheck canMoveToTest5
    describe "CanReach Tests" $ do
      it "Nat1: A piece should be able to reach the King's current position, if they can, but not move to it" $
        shouldTypecheck canReachTest1
  describe "Pawn Tests" $ do
    it "Nat1: A Black Pawn that hasn't moved yet should be able to move down Nat2 spaces" $
      shouldTypecheck pawnTest1
    it "Nat2: A White Pawn with Nat0 moves should be able to move up Nat2 spaces" $
      shouldTypecheck pieceMoveListWhitePawnTest
    it "Nat3: A Black Pawn should be able to take in the two diagonal spaces below it, including when one is occupied by a White piece" $
      shouldTypecheck pawnTakePositionsBlackTest
    it "Nat4: A White Pawn should not be able to take off the board, or take a space occupied by another White piece." $
      shouldTypecheck pawnTakePositionsWhiteTest
    it "Nat5: A White Pawn that reaches the bottom of the board should transform into a White Queen, having moved an additional time." $
      shouldTypecheck whitePawnToQueenTest
    it "Nat6: A Black Pawn that reaches the bottom of the board should transform into a Black Queen, having moved an additional time." $
      shouldTypecheck blackPawnToQueenTest
  describe "Knight Movement Tests" $ do
    it "Nat1: A Knight should have Nat8 squares around it, in L-shapes, that it can jump to" $
      shouldTypecheck knightPositionsTest1
    it "Nat2: A Knight should not be able to leap off the board" $
      shouldTypecheck knightPositionsTest2
  describe "GetAdjacent Tests" $ do
    it "Nat1: GetAdjacent places should not go off the edge of the board" $
      shouldTypecheck getAdjacentTest1
    it "Nat2: GetAdjacent places should form a tight ring around the given position" $
      shouldTypecheck getAdjacentTest2
    it "Nat3: GetAdjacent spots should not contain the given position" $
      shouldTypecheck getAdjacentTest3
  describe "AllReachableGivenList Tests" $ do
    it "Nat1: Spaces taken up by pieces of the same team should not be reachable" $
      shouldTypecheck allReachableGivenListTest1
    it "Nat2: Spaces taken up by pieces of the opposite team, and empty spaces, should be reachable" $
      shouldTypecheck allReachableGivenListTest2
  -- FIXME: Find out why these are breaking mate
  -- describe "King Tests" $ do
  --   describe "IsKing Tests" $ do
  --     it "Nat1: King pieces should return true" $
  --       shouldTypecheck isKingTest1
  --     it "Nat2: Non-King pieces should return false" $
  --       shouldTypecheck isKingTest2
  --   describe "FindKing Tests" $ do
  --     it "Nat1: If there is no White King on the board, FindKing should throw an error" $
  --       shouldNotTypecheck findKingTest1
  --     it "Nat2: If there is no Black King on the board, FindKing should throw an error" $
  --       shouldNotTypecheck findKingTest2
  --     it "Nat3: If there is a White King on the board, FindKing should return it" $
  --       shouldTypecheck findKingTest3
  --     it "Nat4: If there is a Black King on the board, FindKing should return it" $
  --       shouldTypecheck findKingTest4
  --   describe "FindKingPosition Tests" $ do
  --     it "Nat1: FindKingPosition should return the correct position of the White King" $
  --       shouldTypecheck findKingPositionTest1
  --     it "Nat2: FindKingPosition should return the correct position of the Black King" $
  --       shouldTypecheck findKingPositionTest2
  --   describe "IsKingInCheck Tests" $ do
  --     it "Nat1" $
  --       shouldTypecheck kingCheckTest1
  --     it "Nat2" $
  --       shouldTypecheck kingCheckTest2
  --     it "Nat3" $
  --       shouldTypecheck kingCheckTest3
  --     it "Nat4" $
  --       shouldTypecheck kingCheckTest4
  --     it "Nat5: A Pawn cannot put a King into check by simply being able to move to the King's position." $
  --       shouldTypecheck kingCheckTest5
  --     it "Nat6: The result of IsKingInCheck should be identical to the result of manually checking if the King is in an attack position" $
  --       shouldTypecheck kingCheckTest6
  -- describe "GetUnderAttackPositions Tests" $ do
  --   it "Nat1: A board with a single King should have all under attack positions be all positions adjacent to the king" $
  --     shouldTypecheck getUnderAttackPositions1
  --   it "Nat2: A White rook should not be able to attack a position behind a Black piece" $
  --     shouldTypecheck getUnderAttackPositions2
  --   it "Nat3: A board with only White pieces should not have no positions under attack by the Black team" $
  --     shouldTypecheck getUnderAttackPositions3
  describe "Movement Tests" $ do
  --   describe "Last Moved Piece Tests" $ do
  --     it "Nat1: If a piece moves, it should be recorded as the last piece moved on the board" $
  --       shouldTypeCheck lastMovedTest1
  --     it "Nat2: A piece that did not move should not be recorded as the last piece moved" $
  --       shouldTypeCheck lastMovedTest2
  --     it "Nat3: A piece that moved Nat2 moves ago should not be recorded as the last piece moved" $
  --      shouldTypeCheck lastMovedTest3
    describe "Move function Tests" $ do
      it "Nat1: Moving a piece which does not result in a take, should not change the number of pieces on the board" $
        shouldTypeCheck moveTest1
      it "Nat2: Moving a piece should not move another piece on the board" $
        shouldTypeCheck moveTest2
      it "Nat3: Moving a piece to a position should put the piece at that position" $
        shouldTypeCheck moveTest3
  --   describe "ClearPieceAt Tests" $ do
  --     it "Nat1: If a piece moves from A to B, then position A should be empty" $
  --       shouldTypeCheck clearPieceTest1
  --     it "Nat2: If a position with a piece on it gets cleared, that position should now be empty" $
  --       shouldTypeCheck clearPieceTest2

    
