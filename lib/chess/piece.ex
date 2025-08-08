defprotocol Chess.Piece do
  def moves(piece, board)
  def repr(piece)
  def position(piece)
  def move(piece, to)
end
