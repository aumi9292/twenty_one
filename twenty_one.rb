require 'pry'
MAX_SCORE = 36
LOGICAL_STOP = MAX_SCORE - 4
PLAYER = :Player
DEALER = :Dealer
PARTY_KEYS = [PLAYER, DEALER]

WELCOME_INSTRUCTIONS =
  "Welcome to #{MAX_SCORE}!" \
  "\n\tThe purpose is to get closer to #{MAX_SCORE} than your opponent," \
  "the dealer." \
  "\n\tYou and the dealer will both be dealt two cards." \
  "\n\tYou will only see one of the dealer's cards." \
  "\n\tYou can then choose to \"hit\" and take another card or
  \t\"stay\" and accept your total." \
  "\n\tThe dealer then tries to reach #{MAX_SCORE}." \
  "\n\tCards 2-10 are worth their value, face cards are worth 10." \
"\n\tAces can be worth 1 or 11 and will automatically be adjusted."

DECK = {
  Hearts:
  { Two: 2, Three: 3, Four: 4, Five: 5, Six: 6, Seven: 7, Eight: 8,
    Nine: 9, Ten: 10, Jack: 10, Queen: 10, King: 10, Ace: [1, 11] },
  Diamonds:
  { Two: 2, Three: 3, Four: 4, Five: 5, Six: 6, Seven: 7, Eight: 8,
    Nine: 9, Ten: 10, Jack: 10, Queen: 10, King: 10, Ace: [1, 11] },
  Spades:
  { Two: 2, Three: 3, Four: 4, Five: 5, Six: 6, Seven: 7, Eight: 8,
    Nine: 9, Ten: 10, Jack: 10, Queen: 10, King: 10, Ace: [1, 11] },
  Clubs:
  { Two: 2, Three: 3, Four: 4, Five: 5, Six: 6, Seven: 7, Eight: 8,
    Nine: 9, Ten: 10, Jack: 10, Queen: 10, King: 10, Ace: [1, 11] }
}

def ready?
  loop do
    puts
    puts "Sound fun? (Y/N)"
    start = gets.chomp.downcase

    if start == 'y'
      clean_announce("Good luck!", true, 1.5)
      return true
    elsif start == 'n'
      exit
    end

    puts "Sorry, that's not a valid choice."
  end
end

def welcome
  clean_announce(WELCOME_INSTRUCTIONS, true)
  return if ready?
end

def clean_announce(message, clear = false, time = 3, spaces = 0)
  system('clear') if clear
  spaces.times { puts }
  puts ">>> #{message}"
  sleep(time)
end

def deal_cards(deck)
  clean_announce("Dealing cards ...", true, 2, 1)
  hands = []

  PARTY_KEYS.each do |label|
    hands << [label, { hand: [draw_card(deck), draw_card(deck)] }]
  end

  add_score_to_player_stats!(hands.to_h)
end

def add_score_to_player_stats!(hands)
  hands.each_value { |party| party[:score] = 0 }
end

def form(card)
  "\t#{card[:article]} #{card[:num]} of #{card[:suit]}"
end

def announce_hand(hands)
  hands.each do |party, stats|
    clean_announce(" #{party} hand:", false, 1, 1)

    stats[:hand].each do |card|
      determine_article(card)
      clean_announce(form(card), false, 0.75)
      break if party == DEALER
    end

    announce_value(hands, party) unless party == DEALER
  end
end

def gameplay_announce(hands)
  clean_announce("#{PLAYER} hand: ")

  hands[PLAYER][:hand].each do |card|
    determine_article(card)
    clean_announce(form(card), false, 0.75)
  end

  announce_value(hands, PLAYER)
end

def announce_value(hands, party)
  clean_announce("Total hand value: #{hands[party][:score]}", false, 2)
end

def determine_points!(hands)
  hands.each_key do |party|
    hands[party][:score] = add_cards(hands[party][:hand])
  end
end

def add_cards(cards)
  sum = 0
  aces = []

  cards.each { |card| card[:num] == :Ace ? aces << card : sum += card[:value] }

  aces.empty? ? sum : sum + determine_ace_value(sum, aces)
end

def determine_ace_value(sum, aces)
  adjusted = aces.map.with_index do |ace, num|
    adjusted_max = MAX_SCORE - (num * 11)
    ace[:value][1] + sum > adjusted_max ? ace[:value][0] : ace[:value][1]
  end

  adjusted.reduce(&:+)
end

def determine_article(card)
  card[:article] = card[:num].to_s.start_with?(/[aeiouAEIOU]/) ? "An" : "A"
end

def draw_card(deck)
  card = build_card(deck)
  remove_card_from_deck!(deck, card)
  card
end

def build_card(deck)
  suit, num, value = choose_card(deck)
  { suit: suit, num: num, value: value }
end

def choose_card(deck)
  suit = deck.keys.sample
  num = deck[suit].keys.sample
  [suit, num, deck[suit][num]]
end

def remove_card_from_deck!(deck, card)
  deck[card[:suit]].delete(card[:num])
end

def announce_new_card(card)
  determine_article(card)
  clean_announce("New card:\n" + form(card), false, 1, 1)
end

def move
  loop do
    clean_announce("Hit or stay? (h for hit, s for stay)", false, 0, 1)
    move = gets.chomp.downcase
    return move if move == 's' || move == 'h'
    clean_announce("Sorry, that's not a valid choice.")
  end
end

def hit_stay(deck, hands)
  if move == 'h'
    hit(deck, hands)
  else
    clean_announce("You stay: #{hands[PLAYER][:score]}", true, 0.75, 1)
  end
end

def hit(deck, hands)
  binding.pry
  clean_announce("New card is being dealt ...", true, 1, 1)
  new_card = draw_card(deck)
  announce_new_card(new_card)
  add_card_to_hand!(new_card, hands[PLAYER])
  recalculate_score!(hands, PLAYER, new_card)
  gameplay_announce(hands)
  bust_sequence(PLAYER) if bust?(hands[PLAYER][:score])
  hit_stay(deck, hands) unless bust_or_win?(hands[PLAYER][:score])
end

def bust_sequence(party)
  clean_announce("#{party} busts!".upcase, false, 1, 1)
end

def win_sequence(party)
  announce_winner(party)
end

def bust?(points)
  points > MAX_SCORE
end

def win?(points)
  points == MAX_SCORE
end

def bust_or_win?(points)
  bust?(points) || win?(points)
end

def add_card_to_hand!(new_card, hand)
  hand[:hand] << new_card
end

def recalculate_score!(hands, party, new_card)
  aces = hands[party][:hand].select { |card| card[:num] == :Ace }

  if aces.length > 0
    determine_points!(hands)
  else
    hands[party][:score] += new_card[:value]
  end
end

def dealer_turn(deck, hands)
  return if bust_or_win?(hands[PLAYER][:score])

  until hands[DEALER][:score] >= LOGICAL_STOP || bust?(hands[DEALER][:score])
    dealer_hit_announcement
    new_card = dealer_chooses_card(deck, hands[DEALER])
    recalculate_score!(hands, DEALER, new_card)

    bust_sequence(DEALER) if bust?(hands[DEALER][:score])
  end
end

def dealer_hit_announcement
  clean_announce("Dealer hits ...", false, 0.75, 1)
end

def dealer_final_reveal(dealer)
  clean_announce("The dealer reveals #{dealer[:hand].size} cards:", false, 1, 1)

  dealer[:hand].each do |card|
    determine_article(card)
    clean_announce(form(card), false, 0.75)
  end

  clean_announce("Dealer's total hand value: #{dealer[:score]}", false, 2, 1)
end

def dealer_chooses_card(deck, dealer_cards)
  new_card = draw_card(deck)
  add_card_to_hand!(new_card, dealer_cards)
  new_card
end

def compare_hands(hands)
  player_score = hands[PLAYER][:score]
  dealer_score = hands[DEALER][:score]

  return PLAYER if bust?(dealer_score)
  return DEALER if bust?(player_score)

  return PLAYER if player_score > dealer_score
  return DEALER if dealer_score > player_score

  "No one" if player_score == dealer_score
end

def announce_winner(winner)
  puts
  puts '*' * 35
  puts "Winner: #{winner}".center(30)
  puts '*' * 35
  puts
end

def play_again?
  loop do
    clean_announce("Would you like to play again? (Y/N)", false, 0)
    again = gets.chomp.downcase
    return false if again == 'n'
    return true if again == 'y'
    clean_announce("Sorry, that's not a valid option.", false, 0)
  end
end

loop do
  deck = DECK
  welcome
  hands = deal_cards(deck)
  determine_points!(hands)
  announce_hand(hands)
  if win?(hands[PLAYER][:score])
    4.times { win_sequence(PLAYER) }
  else
    hit_stay(deck, hands)
    dealer_turn(deck, hands)
    dealer_final_reveal(hands[DEALER])
  end
  win_sequence(compare_hands(hands))
  break unless play_again?
end
