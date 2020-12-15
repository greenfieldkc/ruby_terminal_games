

class GameManager
  attr_reader :move_count
  def initialize
    puts "Welcome to Kyle's Connect 4! Player 1 is Red. Player 2 is black."
    puts "Remember we are working on a 0-index, so when entering your move, the first row is row 0."
    puts "Let's get started..."
    @move_count = 0
    @current_move
    @board = Board.new
    @winner
    @num_players
    get_players
  end

  def get_players
    puts "How many humans are playing? (press 1 or 2)"
    @num_players = gets.chomp!.to_i
  end

  def get_move
    @move_count += 1
    if @move_count % 2 == 1
      color = "red"
      puts "Player 1, it's your turn."
      get_human_move(color)
    elsif @move_count % 2 == 0 && @num_players == 2
      color = "black"
      puts "Player 2, it's your turn."
      get_human_move(color)
    else
      color = "black"
      puts "Computer's turn..."
      col = stop_winning_move
      row = @board.find_next_row(col)
      @current_move = [col, row, color]
      puts "Computer's move is #{@current_move}"
    end
  end

  def get_human_move(color)
    puts "Choose column:"
    col = gets.chomp!.to_i
    row = @board.find_next_row(col)
    @current_move = [col, row, color]
    puts "Awesome! Your move is #{@current_move}"
  end

  def execute_move
    if @board.is_move_valid?(@current_move[0])
      @board.place_piece(@current_move[0], @current_move[2])
      @board.print_board
    else
      puts "Invalid move"
      @move_count -= 1
    end
  end

  def player_turn
    get_move
    execute_move
    update_winner(@current_move[2]) if @board.is_winner?(@current_move)
  end

  def run_game
    while @move_count < (@board.height * @board.width)
      break if @winner
      player_turn
    end
  end

  def update_winner(color)
    @winner = color
    puts "Congratulations! The winner is: #{@winner}" if @winner != nil
  end


  def place_randomly
    column = rand(@board.width - 1)
    if @board.find_next_row(column)
      return column
    else
      place_randomly
    end
  end

  def stop_winning_move
    @board.width.times do |col|
      row = @board.find_next_row(col)
      return col if @board.is_winner?([col,row,"red"])
    end
    place_randomly
  end

end #end of GameManager class

class Board
  attr_accessor :cells
  attr_reader :height
  attr_reader :width
  def initialize(width=7, height=6)
      @width = width
      @height = height
      @cells = Hash.new
      create_board
  end

  def create_board
    #puts "inside create_board"
    @width.times do |col|
      @height.times do |row|
        cell_id = "#{col}.#{row}"
        @cells[cell_id] = Cell.new(col, row)
      end
    end
  end


  def print_board
    puts " "
    (@height - 1).downto(0) do |row|
      @width.times do |col|
        @cells["#{col}.#{row}"].print_cell
        #puts "printing cell #{col}.#{row}"
      end
      puts " "
    end
    puts " "
  end

  def check_occupancy(col, row)
    @cells["#{col}.#{row}"].occupant ? @cells["#{col}.#{row}"].occupant : false
  end

  def place_piece(col, color)
    row = find_next_row(col)
    @cells["#{col}.#{row}"].update_occupant(color)
  end

  def is_move_valid?(col)
    if find_next_row(col) <= @height && col <= @width
      return true
    else
      puts "Invalid move"
      return false
    end
  end

  def find_next_row(column)
    row_count = 0
    puts "top of findnextrow row_count = #{row_count}..."
    until check_occupancy(column, row_count) == false
      row_count += 1
      check_occupancy(column, row_count)
      puts "in findnextrow check_occupancy. row count is #{row_count}"
    end
    return row_count
  end

  def is_winner?(last_move) #last_move is array of [col,row,color]
    if is_vertical_winner?(last_move)
      return true
    elsif is_horizontal_winner?(last_move)
      return true
    elsif is_diagonal_winner?(last_move)
      return true #diagonal code not implemented yet
    else
      return false
    end
  end

  def is_vertical_winner?(last_move) #currently returns winner when column fills even if not a real winner
    consecutives = 0
    @height.times do |r|
      if @cells["#{last_move[0]}.#{r}"].occupant == last_move[2]
        consecutives += 1
        puts "vertical consecutives is #{consecutives}"
        break if consecutives == 4
      else
        consecutives = 0
        break if @cells["#{last_move[0]}.#{r}"].occupant == nil
      end
    end
    return consecutives == 4
  end

  def is_horizontal_winner?(last_move)
    width_array = []
    consecutives = 1
    @width.times do |c|
      width_array << @cells["#{c}.#{last_move[1]}"].occupant
    end
    width_array.each_index do |i|
      break if i + 1 > width_array.length
      if width_array[i] != nil
        if width_array[i] == width_array[i+1]
          consecutives += 1
          return true if consecutives == 4
        else
          consecutives = 1
        end
      end
    end
    puts "horizontal consecutives = #{consecutives}"
    return false
  end

  def is_diagonal_winner?(last_move)
    c = last_move[0]
    r = last_move[1]
    consecutives = 1
    while r < @height - 1 && c < @width - 1
      r += 1
      c += 1
      if @cells["#{c}.#{r}"].occupant == nil
        break
      elsif @cells["#{c}.#{r}"].occupant == last_move[2]
        consecutives += 1
        r += 1
        c += 1
      else
        break
      end
    end
    c = last_move[0] - 1
    r = last_move[1] - 1
    while r >= 0 && c >= 0
      if @cells["#{c}.#{r}"].occupant == nil
        break
      elsif @cells["#{c}.#{r}"].occupant == last_move[2]
        consecutives += 1
        r -= 1
        c -= 1
      else
        break
      end
    end
    puts "diagonal consecutives = #{consecutives}"
    consecutives >= 4 ? true : false
  end

end #end of Board class


class Cell
  attr_accessor :occupant
  attr_reader :column
  attr_reader :row
  def initialize(column, row, occupant=nil)
    @column = column
    @row = row
    @occupant = nil
    #puts "Cell created: column: #{column} row: #{row} occupant: #{occupant}"
  end

  def print_cell
    if self.occupant == "red"
      print " Red "
    elsif self.occupant == "black"
      print " Bla "
    else
      print  " ___ "
    end
  end

  def update_occupant(color)
    @occupant = color
  end

end #end of Cell class


game = GameManager.new
game.run_game
