#Terminal app to play the classic risk board game
#(currently with a partial board setup)

class GameManager
  attr_accessor :board
  def initialize(territory_hash, num_players)
    @board = Board.new territory_hash
    @board.territories.each_value {|v| v.num_troops = 4}
    @players = []
    num_players.times do |n|
      puts "Player #{n}, What is your name?"
      name = gets.chomp!
      puts "Hi #{name}. What color would you like?"
      color = gets.chomp!
      @players << Player.new(name, color)
    end
    assign_territories_to_players
  end

  def roll_dice(num_dice) #returns array of roll reverse sorted (descending)
    roll_result = []
    num_dice.times { roll_result << rand(1..6)}
    roll_result.sort!.reverse!
  end

  def attack_once(offense, defense)
    arr = get_num_dice offense, defense
    attack_roll = roll_dice arr[0]
    defense_roll = roll_dice arr[1]
    puts "#{offense} is attacking #{defense}"
    puts "Attack: #{attack_roll}"
    puts "Defend: #{defense_roll}"
    casualties = find_casualties(attack_roll, defense_roll)
    puts "#{offense} loses #{casualties[0]} troops. #{defense} loses #{casualties[1]} troops."
    puts ""
    @board.remove_troops(offense, casualties[0])
    @board.remove_troops(defense, casualties[1])
    puts "#{offense} has #{@board.territories[offense].num_troops} troops. #{defense} has #{@board.territories[defense].num_troops} troops."
  end

  def annihilate(offense, defense)
    while @board.territories[defense].num_troops >= 1 && @board.territories[offense].num_troops >= 3
      attack_once(offense, defense)
    end
  end

  def attack_successful?(offense, defense)
    if @board.territories[defense].num_troops == 0
      puts "attack successful"
      return true
    else
      puts "defense holds"
      return false
    end
  end

  def get_num_dice(offense, defense)
    @board.territories[defense].num_troops > 1 ? num_defending_dice = 2 : num_defending_dice = 1
    if @board.territories[offense].num_troops == 2
      num_attacking_dice = 1
    elsif @board.territories[offense].num_troops == 3
      num_attacking_dice = 2
    else
      num_attacking_dice = 3
    end
    return [num_attacking_dice, num_defending_dice]
  end

  def find_casualties(attack_roll, defense_roll) #returns array of [offense casualties, defense casualties]; assumes input array reverse sorted
    offense_casualties = 0
    defense_casualties = 0
    defense_roll.each_index do |i|
      if attack_roll[i] > defense_roll[i]
        defense_casualties += 1
      else
        offense_casualties += 1
      end
    end
    return [offense_casualties, defense_casualties]
  end

  def assign_territories_to_players
    arr = []
    @board.territories.each_key {|k| arr << k}
    arr.shuffle!
    arr.length.times do |i|
      @players[i%@players.length].territories << arr[i]
      @board.territories[arr[i]].occupant = @players[i%@players.length].color
    end
    puts "Player 0 territories #{@players[0].territories.each {|ter| puts ter}}"
    puts ""
    puts ""
    puts "Player 1 territories #{@players[1].territories.each {|ter| puts ter}}"
    @board.territories.each {|k,v| puts k, v.occupant }
  end

  def is_legal_attack?(offensive_territory, defending_territory)
    @board.is_adjacent?(offensive_territory, defending_territory) &&
    @board.territories[offensive_territory].num_troops > 1 &&
    @board.territories[defending_territory].num_troops > 0 &&
    !@board.same_occupant?(offensive_territory, defending_territory)
  end

  def is_legal_troop_move?(from_territory, to_territory)
    @board.is_adjacent?(from_territory, to_territory) && @board.same_occupant?(from_territory, to_territory)
  end

  def player_turn(player_index)
    place_reinforcements(player_index)
    attack_cycle(player_index)
    end_of_turn_troop_move
    #draw a card
    @board.print_board
  end

  def attack_cycle(player_index)
    puts "#{@players[player_index].name}: Would you like to attack (Enter Y or N)"
    answer = gets.chomp!
    if answer == 'y'
      arr = ask_for_attack
      execute_attack(arr[0], arr[1])
      @board.print_board
      attack_cycle(player_index)
    end
  end

  def ask_for_attack
    puts "Where would you like to attack from?"
    offense = gets.chomp!
    puts "Where would you like to attack?"
    defense = gets.chomp!
    if is_legal_attack?(offense, defense)
      return [offense, defense]
    else
      puts "That attack isn't legal. Please enter a legal attack..."
      ask_for_attack
    end
  end

  def execute_attack(offense, defense)
    annihilate(offense, defense)
    transfer_ownership(offense, defense) if attack_successful?(offense, defense)
  end

  def transfer_ownership(offense, defense)
    @board.territories[defense].occupant = @board.territories[offense].occupant
    puts "How many troops would you like to move from #{offense} to #{defense}? #{@board.territories[offense].num_troops - 1} available to move."
    num = gets.chomp!.to_i
    @board.add_troops(defense, num)
    @board.remove_troops(offense, num)
  end

  def end_of_turn_troop_move
    puts "Would you like to move troops?"
    answer = gets.chomp!
    puts "Answer is...   #{answer}"
    if answer == 'y'
      puts "Where from?"
      from_territory = gets.chomp!
      puts "Where to?"
      to_territory = gets.chomp!
      if is_legal_troop_move?(from_territory, to_territory)
        puts "#{from_territory} has #{@board.territories[from_territory].num_troops} troops."
        puts "#{to_territory} has #{@board.territories[to_territory].num_troops} troops."
        puts "How many troops would you like to move?"
        num = gets.chomp!.to_i
        @board.add_troops(to_territory, num)
        @board.remove_troops(from_territory, num)
      else
        puts "That is not a legal troop move."
      end
    end
  end

  def place_reinforcements(player_index)
    troops_to_place = 3
    while troops_to_place > 0
      territory = get_territory(player_index, troops_to_place)
      num = get_num_reinforcements(troops_to_place)
      @board.add_troops(territory, num)
      troops_to_place -= num
    end
  end

  def get_territory(player_index, troops_to_place)
    puts "#{@players[player_index].name}. You have #{troops_to_place} troops to place."
    puts "Where would you like to place them?"
    gets.chomp!
  end

  def get_num_reinforcements(troops_to_place)
    if troops_to_place > 1
      puts "How many do you want to place?"
      num = gets.chomp!.to_i
      if num <= troops_to_place
        return num
      else
        puts "Invalid input. Placing 1 troop..."
        return 1
      end
    else
      return 1
    end
  end

end #end of GameManager class

class Board
  attr_accessor :territories
  def initialize(territory_hash) #accepts hash of key = territory name val = array of neighbors
    @territories = Hash.new #k = string name, val = Territory object
    create_territories(territory_hash)
    @territories.each do |name, obj|
      obj.assign_neighbors(territory_hash[name])
    end
    validate_borders
    #print_board
  end

  def create_territories(territory_hash)
    territory_hash.each_key {|k| @territories[k] = Territory.new(k) }
  end

  def validate_borders
    @territories.each do |k,v|
      v.neighbors.each do |n|
        puts "Border Discrepancy: #{n}, #{k}" unless is_adjacent?(n, k)
      end
    end
  end

  def is_adjacent?(territory1, territory2)
    @territories[territory1].neighbors.include? territory2
  end

  def print_board
    puts "_________________________"
    @territories.each do |k,v|
      puts "#{k}: #{v.num_troops} troops,  #{v.occupant}. Borders: #{v.neighbors}"
      puts ""
    end
    puts "_________________________"
  end

  def add_troops(territory, num)
    @territories[territory].num_troops += num
  end

  def remove_troops(territory, num)
    @territories[territory].num_troops -= num
  end

  def same_occupant?(territory1, territory2)
    @territories[territory1].occupant == @territories[territory2].occupant
  end




end #end of Board class

class Territory
attr_accessor :neighbors, :num_troops, :name, :occupant
  def initialize(name)
    @name = name
    @occupant = nil
    @num_troops = 0
    @neighbors = [] #array of adjacent territories
  end

  def assign_neighbors(neighbors_array)
    @neighbors = neighbors_array
  end


end #end of Territory class


class Player
  attr_accessor :territories, :color, :name
  def initialize(name, color)
    @name = name
    @color = color
    @cards = []
    @territories = []
  end


end #end of Player class

territory_list = {
  'Eastern US' => ['Western US', 'Eastern Canada','Mexico'],
  'Western US' => ['Eastern US', 'Western Canada', 'Mexico'],
  'Eastern Canada' => ['Eastern US', 'Western Canada', 'Greenland'],
  'Western Canada' => ['Alaska','Western US', 'Eastern Canada'],
  'Alaska' => ['Western Canada'],
  'Greenland' => ['Eastern Canada'],
  'Mexico' => ['Eastern US', 'Western US']
}

game = GameManager.new(territory_list, 2)

#game.board.add_troops 'Mexico', 10
#game.annihilate 'Mexico', 'Eastern US'
#game.annihilate 'Alaska', 'Western Canada'
#game.board.territories.each {|k,v| puts k, v.num_troops}

game.player_turn(0)
game.player_turn(1)
game.player_turn(0)
game.player_turn(1)
