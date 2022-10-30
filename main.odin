package main

import "core:fmt"
import "core:math/rand"
import "core:strings"
import sdl "vendor:sdl2"

NEXT_CARD_Y_OFFSET :: 0.22 // What happens here really? Auto-cast?

CARD_POWER_COUNT :: 13
CARD_SUIT_COUNT  :: 4

CardPowers :: enum u8{
	ace,
	two, three, four, five, six, seven, eight, nine, ten,
	jack, queen, king,
}

// CardNames :: []string{
// 	"ace",
// 	"1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
// 	"jack", "queen", "king",
// }

CardSuits :: enum u8{
	spades, clubs, diamonds, hearts,
}

CardIndex :: union { int }

Card :: struct {
	power: CardPowers,
	suit: CardSuits,
	
	is_on_goal: bool,
	is_on_cell: bool,
	
	under_index, over_index: CardIndex,
	rect, last_rect: sdl.Rect,
	
	texture_index: int,
}

Cell :: struct {
	over_index: CardIndex,
	single_spot: bool,
	rect: sdl.Rect,
}

GoalSpot :: struct {
	over_index: CardIndex,
	held_power: int,
	held_suit: CardSuits,
	rect: sdl.Rect,
}

// Returns true for black
get_suit_color :: proc(suit: CardSuits) -> bool {
	return (suit == .spades || suit == .clubs)
}

// Returns true if suits are different
comp_suits :: proc(suit_1: CardSuits, suit_2: CardSuits) -> bool {
	return get_suit_color(suit_1) ~ get_suit_color(suit_2)
}

// Returns true if suits are different
comp_card_suits :: proc(card_1: ^Card, card_2: ^Card) -> bool {
	return comp_suits(card_1.suit, card_2.suit)
}

to_card_index :: proc(power: CardPowers, suit: CardSuits) -> int {
	return int(power) + (CARD_POWER_COUNT * int(suit))
}

from_card_index :: proc(value: int) -> (CardPowers, CardSuits) {
	power := value % CARD_POWER_COUNT
	suit  := value / CARD_POWER_COUNT
	return CardPowers(power), CardSuits(suit)
}

// This is just '%%' operator
// wrap_range :: proc(value: int, range: int) -> int {
// 	out := value % range
// 	if out < 0 {out = range + out}
// 	return out
// }

main :: proc() {
	sdl.Init(sdl.INIT_VIDEO)
	
	// window_flags : sdl.WindowFlags
	window := sdl.CreateWindow("Title", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, 1280, 1280, sdl.WindowFlags{})
	renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_ACCELERATED)
	
	card_surface_template := sdl.LoadBMP("data\\card_face_template.bmp")
	card_texture_template := sdl.CreateTextureFromSurface(renderer, card_surface_template)
	sdl.SetTextureBlendMode(card_texture_template, sdl.BlendMode.NONE)
	
	card_size : struct {w: i32, h: i32} = ---
	sdl.QueryTexture(card_texture_template, nil, nil, &card_size.w, &card_size.h)
	
	symbol_size       :i32= 35
	top_number_pos    := sdl.Point{85, 0}
	top_suit_pos      := sdl.Point{85, 30}
	bottom_number_pos := sdl.Point{card_size.w - top_number_pos.x - symbol_size, card_size.h - top_number_pos.y - symbol_size}
	bottom_suit_pos   := sdl.Point{card_size.w - top_suit_pos.x - symbol_size, card_size.h - top_suit_pos.y - symbol_size}
	
	base_file_path := "data\\"
	new_card_textures : [56]^sdl.Texture
	suit_textures  := make(map[CardSuits]^sdl.Texture)
	power_textures := make(map[CardPowers]^sdl.Texture)
	// Freeing surface and texture memory saves nothing, as far as I'm concerned, better to leave this clean.
	for card_suit in CardSuits {
		card_suit_name := strings.clone_to_cstring(fmt.tprintf("%ssuit_%s.bmp", base_file_path, card_suit), context.temp_allocator)
		card_suit_source_tex := sdl.CreateTextureFromSurface(renderer, sdl.LoadBMP(card_suit_name))
		suit_textures[card_suit] = card_suit_source_tex
	}
	for card_power in CardPowers {
		card_power_name := strings.clone_to_cstring(fmt.tprintf("%spower_%s.bmp", base_file_path, card_power), context.temp_allocator)
		card_power_surf := sdl.LoadBMP(card_power_name)
		pixels := ([^]u32)(card_power_surf.pixels)[:(card_power_surf.w * card_power_surf.h)]
		for pixel in &pixels {
			pixel = pixel | 0b1111_1111_1111_1111_1111_1111
			// fmt.printf("%v ", pixels[idx] >> 24)
		}
		card_power_source_tex := sdl.CreateTextureFromSurface(renderer, card_power_surf)
		sdl.SetTextureColorMod(card_power_source_tex, 0, 0, 0)
		power_textures[card_power] = card_power_source_tex
	}
	
	for card_suit in CardSuits {
		for card_power in CardPowers {
			out_texture := sdl.CreateTexture(renderer, u32(sdl.PixelFormatEnum.ARGB8888), sdl.TextureAccess.TARGET, card_size.w, card_size.h)
			sdl.SetRenderTarget(renderer, out_texture)
			sdl.SetTextureBlendMode(out_texture, sdl.BlendMode.BLEND)
			
			sdl.RenderCopy(renderer, card_texture_template, nil, nil)
			
			if card_suit == .hearts || card_suit == .diamonds {
				sdl.SetTextureColorMod(power_textures[card_power], 220, 0, 0)
			}
			sdl.RenderCopy  (renderer, power_textures[card_power], nil, &sdl.Rect{top_number_pos.x,    top_number_pos.y,    symbol_size, symbol_size})
			sdl.RenderCopyEx(renderer, power_textures[card_power], nil, &sdl.Rect{bottom_number_pos.x, bottom_number_pos.y, symbol_size, symbol_size}, 180, nil, nil)
			sdl.SetTextureColorMod(power_textures[card_power], 0, 0, 0)
			
			sdl.RenderCopy  (renderer, suit_textures[card_suit], nil, &sdl.Rect{top_suit_pos.x,    top_suit_pos.y,    symbol_size, symbol_size})
			sdl.RenderCopyEx(renderer, suit_textures[card_suit], nil, &sdl.Rect{bottom_suit_pos.x, bottom_suit_pos.y, symbol_size, symbol_size}, 180, nil, nil)

			new_card_textures[to_card_index(card_power, card_suit)] = out_texture
		}
	}
	sdl.SetRenderTarget(renderer, nil)
	
	cell_texture := sdl.CreateTextureFromSurface(renderer, sdl.LoadBMP("data\\new_base_spot.bmp"))
	goal_spot_texture := sdl.CreateTextureFromSurface(renderer, sdl.LoadBMP("data\\new_goal_spot.bmp"))
	// --Tech init over--
	
	
	// --Game init--
	cells : [128]Cell
	cell_count := 11
	
	cells[0].rect = sdl.Rect{20, 250, card_size.w, card_size.h}
	cells[1].rect = sdl.Rect{cells[0].rect.x + 40 + card_size.w, cells[0].rect.y, card_size.w, card_size.h}
	cells[2].rect = sdl.Rect{cells[1].rect.x + 40 + card_size.w, cells[0].rect.y, card_size.w, card_size.h}
	cells[3].rect = sdl.Rect{cells[2].rect.x + 40 + card_size.w, cells[0].rect.y, card_size.w, card_size.h}
	cells[4].rect = sdl.Rect{cells[3].rect.x + 40 + card_size.w, cells[0].rect.y, card_size.w, card_size.h}
	cells[5].rect = sdl.Rect{cells[4].rect.x + 40 + card_size.w, cells[0].rect.y, card_size.w, card_size.h}
	
	cells[6].rect  = sdl.Rect{20, 40, card_size.w, card_size.h}
	cells[7].rect  = sdl.Rect{cells[6].rect.x + 10 + card_size.w, cells[6].rect.y, card_size.w, card_size.h}
	cells[8].rect  = sdl.Rect{cells[7].rect.x + 10 + card_size.w, cells[6].rect.y, card_size.w, card_size.h}
	cells[9].rect  = sdl.Rect{cells[8].rect.x + 10 + card_size.w, cells[6].rect.y, card_size.w, card_size.h}
	cells[10].rect = sdl.Rect{cells[9].rect.x + 10 + card_size.w, cells[6].rect.y, card_size.w, card_size.h}
	
	cells[6].single_spot = true
	cells[7].single_spot = true
	cells[8].single_spot = true
	cells[9].single_spot = true
	cells[10].single_spot = true
	
	goal_spots : [128]GoalSpot
	goal_spot_count := 4
	
	goal_spots[0].rect = sdl.Rect{700, 40, card_size.w, card_size.h}
	goal_spots[1].rect = sdl.Rect{goal_spots[0].rect.x + 10 + card_size.w, 40, card_size.w, card_size.h}
	goal_spots[2].rect = sdl.Rect{goal_spots[1].rect.x + 10 + card_size.w, 40, card_size.w, card_size.h}
	goal_spots[3].rect = sdl.Rect{goal_spots[2].rect.x + 10 + card_size.w, 40, card_size.w, card_size.h}
	
	
	cards : [256]Card
	draw_queue : [256]int
	card_count := 0
	
	stacked_card_offset := i32(f32(card_size.h) * NEXT_CARD_Y_OFFSET)
	
	mouse_x, mouse_y : i32 = 0, 0
	mouse_state : u32 = 0
	
	is_grabbing_card := false
	was_just_grabbing_card := false
	grabbed_card_index := 0
	grabbed_relative_x, grabbed_relative_y : i32 = 0, 0
	
	card_creation_selection : struct {power: CardPowers, suit: CardSuits}
	
	// -- Board init --
	
	// card_count = 52
	order_shuffle : [CARD_POWER_COUNT * CARD_SUIT_COUNT]int
	for _, index in order_shuffle { order_shuffle[index] = index }
	rand.shuffle(order_shuffle[:])
	rand.shuffle(order_shuffle[:])
	rand.shuffle(order_shuffle[:])
	rand.shuffle(order_shuffle[:])
	rand.shuffle(order_shuffle[:])
	for shuffle, index in order_shuffle {
		new_card : Card
		new_card.power, new_card.suit = from_card_index(shuffle)
		new_card.texture_index = shuffle
		
		// Really need to yoink this out to a function
		target_cell := index % 6
		cell := &cells[target_cell]
		if (cell.over_index == nil) {
			new_card.rect.x = cell.rect.x
			new_card.rect.y = cell.rect.y
			
			new_card.under_index = target_cell
			new_card.is_on_cell = true
			cell.over_index = card_count
		} else {
			next_index := cell.over_index
			for {
				next_card := &cards[next_index.(int)]
				new_card.under_index = next_index.(int)
				if next_index = next_card.over_index; next_index != nil {continue}
				next_card.over_index = card_count
				new_card.rect.x = next_card.rect.x
				new_card.rect.y = next_card.rect.y + stacked_card_offset
				break;
			}
		}
		new_card.rect.w = card_size.w
		new_card.rect.h = card_size.h
		// new_card.rect = sdl.Rect{1600 - i32(index * 40), 100, card_size.w, card_size.h}
		draw_queue[card_count] = card_count
		cards[card_count] = new_card
		card_count += 1
	}
	
	
	event : sdl.Event
	running : sdl.bool = true
	for running {
		// -- Input START --
		for sdl.PollEvent(&event) {
			if (event.type == sdl.EventType.KEYDOWN && event.key.repeat == 0) {
				base_keycode_value := int(sdl.Keycode.NUM1)
				key_keycode := int(event.key.keysym.sym)
				
				#partial switch event.key.keysym.sym {
					case .SPACE: {
						new_card : Card
						new_card.power = card_creation_selection.power
						new_card.suit  = card_creation_selection.suit
						new_card.texture_index = to_card_index(card_creation_selection.power, card_creation_selection.suit)
						new_card.rect = sdl.Rect{mouse_x, mouse_y, card_size.w, card_size.h}
						draw_queue[card_count] = card_count
						cards[card_count] = new_card
						card_count += 1
					}
					
					case .UP: {
						card_creation_selection.power = CardPowers((int(card_creation_selection.power) + 1) %% CARD_POWER_COUNT)
					}
					case .DOWN: {
						card_creation_selection.power = CardPowers((int(card_creation_selection.power) - 1) %% CARD_POWER_COUNT)
					}
					case .RIGHT: {
						card_creation_selection.suit = CardSuits((int(card_creation_selection.suit) + 1) %% CARD_SUIT_COUNT)
					}
					case .LEFT: {
						card_creation_selection.suit = CardSuits((int(card_creation_selection.suit) - 1) %% CARD_SUIT_COUNT)
					}
					case .R: {
						card_count = 0
						for b_idx in 0..<cell_count {
							cells[b_idx].over_index = nil
						}
						for g_idx in 0..<goal_spot_count {
							goal_spots[g_idx].over_index = nil
						}
					}
					case .ESCAPE: {
						running = false 
					}
					case: {
						sdl.Log("Else")
					}
				}
			}
			if (event.type == .QUIT) {
				running = false
			}
		}
		sdl.PumpEvents()
		mouse_state = sdl.GetMouseState(&mouse_x, &mouse_y)
		// -- Input END --
		
		// -- Game logic START --
		if mouse_state != 0 {
			if !is_grabbing_card { // Mouse1 pressed while NOT holding a card
				card_selection_loop: for o_index := card_count - 1; o_index >= 0; o_index -= 1 {
					card := &cards[draw_queue[o_index]]
					if sdl.PointInRect(&sdl.Point{mouse_x, mouse_y}, &card.rect) && !card.is_on_goal {
						// Checks if the stack of cards is legal
						{
							previous_card := card
							for {
								next_card_index, next_card_exists := previous_card.over_index.(int)
								if next_card_exists {
									next_card := &cards[next_card_index]
									if (next_card.power == CardPowers(int(previous_card.power) - 1)) && comp_card_suits(previous_card, next_card) {
										previous_card = next_card
									} else {
										break card_selection_loop
									}
								} else {break}
							}
						}
						
						grabbed_card_index = draw_queue[o_index]
						cards[grabbed_card_index].last_rect = cards[grabbed_card_index].rect
						is_grabbing_card = true
						was_just_grabbing_card = true // Maybe move this out?
						
						grabbed_relative_x = mouse_x - card.rect.x
						grabbed_relative_y = mouse_y - card.rect.y
						
						// Puts the grabbed card at the top of the draw_queue array,
						// as well as all the cards stacked on top of it.
						shuffle_card_order := o_index
						for {
							shuffled_cards_index := draw_queue[shuffle_card_order]
							for reshufle_index in shuffle_card_order..<card_count - 1 {
								draw_queue[reshufle_index] = draw_queue[reshufle_index + 1]
							}
							draw_queue[card_count - 1] = shuffled_cards_index
							
							over_card, over_card_exists := cards[shuffled_cards_index].over_index.(int)
							if over_card_exists {
								for search_index, order_index in draw_queue {
									if over_card == search_index {
										shuffle_card_order = order_index
										break
									}
								}
							} else { break }
						}
						break
					}
				}
			}
			
			if is_grabbing_card {
				grabbed_card := &cards[grabbed_card_index]
				// Relative to when first grabbed or fixed position?
				when false {
					grabbed_card.rect.x = mouse_x - (card_size.w / 2)
					grabbed_card.rect.y = mouse_y - (card_size.h / 5)
				}
				else {
					grabbed_card.rect.x = mouse_x - grabbed_relative_x
					grabbed_card.rect.y = mouse_y - grabbed_relative_y
				}
			}
		} else if mouse_state == 0 {
			if is_grabbing_card { // Mouse1 released while holding a card
				is_grabbing_card = false
				grabbed_card := &cards[grabbed_card_index]
				mouse_point := sdl.Point{mouse_x, mouse_y}
				
				valid_dropoff_found := false
				found_under_index: int
				found_new_position := grabbed_card.rect
				found_is_cell := false
				found_is_goal := false
				
				search_for_dropoff: {
					// Cell
					for b_index in 0..<cell_count {
						cell := &cells[b_index]
						if cell.single_spot && grabbed_card.over_index != nil {continue}
						is_in_rect := sdl.PointInRect(&mouse_point, &cell.rect)
						if is_in_rect == true && cell.over_index == nil {
							cell.over_index = grabbed_card_index
							
							found_is_cell = true
							found_under_index = b_index
							found_new_position.x = cell.rect.x
							found_new_position.y = cell.rect.y
							
							valid_dropoff_found = true
							break search_for_dropoff
						}
					}
					
					// Goal
					for g_index in 0..<goal_spot_count {
						goal := &goal_spots[g_index]
						is_in_rect := sdl.PointInRect(&mouse_point, &goal.rect)
						if is_in_rect && grabbed_card.over_index == nil && ((goal.over_index == nil && grabbed_card.power == .ace) || (goal.over_index != nil && goal.held_power + 1 == int(grabbed_card.power))) {
							if goal.over_index == nil { 
								goal.held_suit = grabbed_card.suit
							}
							else if goal.held_suit != grabbed_card.suit {continue}
							
							goal.over_index = grabbed_card_index
							goal.held_power = int(grabbed_card.power)
							
							found_is_goal = true
							found_new_position.x = goal.rect.x
							found_new_position.y = goal.rect.y
							
							valid_dropoff_found = true
							break search_for_dropoff
						}
					
					}
					
					// Cards
					for c_index in 0..<card_count {
						if c_index != grabbed_card_index {
							card := &cards[c_index]
							if card.is_on_goal || card.over_index != nil || !comp_card_suits(card, grabbed_card) {continue}
							if card.is_on_cell && cells[card.under_index.(int)].single_spot {continue}
							
							is_in_rect := sdl.PointInRect(&mouse_point, &card.rect)
							if is_in_rect == true && int(grabbed_card.power) + 1 == int(card.power) {
								card.over_index = grabbed_card_index
								
								if card.is_on_goal { found_is_goal = true }
								found_under_index = c_index
								found_new_position.x = card.rect.x
								found_new_position.y = card.rect.y + stacked_card_offset
								
								valid_dropoff_found = true
								break search_for_dropoff
							}
						}
					}
				}
				
				if valid_dropoff_found {
					if grabbed_card.is_on_cell {
						cells[grabbed_card.under_index.(int)].over_index = nil
						grabbed_card.is_on_cell = false
					} else if grabbed_card.under_index != nil {
						cards[grabbed_card.under_index.(int)].over_index = nil
					}
					
					grabbed_card.rect = found_new_position
					grabbed_card.under_index = found_under_index
					grabbed_card.is_on_cell = found_is_cell
					grabbed_card.is_on_goal = found_is_goal
					assert(!(found_is_cell && found_is_goal))
				} else {
					grabbed_card.rect = grabbed_card.last_rect
				}
			}
		}
		if was_just_grabbing_card {
			grabbed_card := &cards[grabbed_card_index]
			if grabbed_card.over_index != nil {
				over_card := &cards[grabbed_card.over_index.(int)]
				over_card.rect.x = grabbed_card.rect.x
				over_card.rect.y = grabbed_card.rect.y + stacked_card_offset
				prev_card := over_card
				for over_card.over_index != nil {
					over_card = &cards[prev_card.over_index.(int)]
					over_card.rect.x = prev_card.rect.x
					over_card.rect.y = prev_card.rect.y + stacked_card_offset
					prev_card = over_card
				}
			}
		}
		if !is_grabbing_card && was_just_grabbing_card {
			was_just_grabbing_card = false
		}
		// -- Game logic END --
		
		// -- Render --
		sdl.SetRenderDrawColor(renderer, 30, 120, 0, sdl.ALPHA_OPAQUE)
		sdl.RenderClear(renderer)
		
		// Selection
		if get_suit_color(card_creation_selection.suit) {sdl.SetTextureColorMod(power_textures[card_creation_selection.power], 0, 0, 0)}
		else {sdl.SetTextureColorMod(power_textures[card_creation_selection.power], 220, 0, 0)}
		sdl.RenderCopy(renderer, power_textures[card_creation_selection.power], nil, &sdl.Rect{0,  0, symbol_size, symbol_size})
		sdl.RenderCopy(renderer, suit_textures[card_creation_selection.suit],   nil, &sdl.Rect{35, 0, symbol_size, symbol_size})
		
		// Cell Spots
		for index := 0; index < cell_count; index += 1 {
			sdl.RenderCopy(renderer, cell_texture, nil, &cells[index].rect)
		}
		
		// Goals
		for index in 0..<goal_spot_count {
			sdl.RenderCopy(renderer, goal_spot_texture, nil, &goal_spots[index].rect)
		}
		
		// Cards
		for index := 0; index < card_count; index += 1 {
			current_card := &cards[draw_queue[index]]
			sdl.RenderCopy(renderer, new_card_textures[current_card.texture_index], nil, &current_card.rect)
		}
		
		sdl.RenderPresent(renderer)
		// -- Render END --
	}
	
	sdl.Quit()
}
