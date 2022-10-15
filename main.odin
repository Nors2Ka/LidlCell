/* TODOs:
Rename dropoff_spot to goal_spot.
Remake goal_spot to be more of a thing that eats cards up.

*/
package main

import "core:fmt"
import sdl "vendor:sdl2"

UNIQUE_CARD_COUNT :: 11
CARD_SIZE_X :: 60
CARD_SIZE_Y :: 60
NEXT_CARD_Y_OFFSET :: CARD_SIZE_Y * 0.4 // What happens here really? Auto-cast?

CardIndex :: union { int }

Card :: struct {
	power: int,
	is_on_goal: bool,
	is_on_base_spot: bool,
	
	under_index, over_index: CardIndex,
	rect, last_rect: sdl.Rect,
	
	texture_index: int
}

BaseSpot :: struct {
	over_index: CardIndex,
	rect: sdl.Rect
}

GoalSpot :: struct {
	over_index: CardIndex,
	held_power: int,
	rect: sdl.Rect
}

main :: proc() {
	sdl.Init(sdl.INIT_VIDEO)
	
	// window_flags : sdl.WindowFlags
	window := sdl.CreateWindow("Title", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, 800, 640, sdl.WindowFlags{})
	renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_ACCELERATED)
	
	
	card_surfaces : [UNIQUE_CARD_COUNT]^sdl.Surface
	card_textures : [UNIQUE_CARD_COUNT]^sdl.Texture
	card_surfaces[0] = sdl.LoadBMP("data\\base_spot.bmp")
	card_surfaces[1] = sdl.LoadBMP("data\\card_1.bmp")
	card_surfaces[2] = sdl.LoadBMP("data\\card_2.bmp")
	card_surfaces[3] = sdl.LoadBMP("data\\card_3.bmp")
	card_surfaces[4] = sdl.LoadBMP("data\\card_4.bmp")
	card_surfaces[5] = sdl.LoadBMP("data\\card_5.bmp")
	card_surfaces[6] = sdl.LoadBMP("data\\card_6.bmp")
	card_surfaces[7] = sdl.LoadBMP("data\\card_7.bmp")
	card_surfaces[8] = sdl.LoadBMP("data\\card_8.bmp")
	card_surfaces[9] = sdl.LoadBMP("data\\card_9.bmp")
	card_surfaces[10] = sdl.LoadBMP("data\\card_10.bmp")
	for index := 0; index < UNIQUE_CARD_COUNT; index += 1 {
		card_textures[index] = sdl.CreateTextureFromSurface(renderer, card_surfaces[index])
		sdl.FreeSurface(card_surfaces[index])
	}
	dropoff_surf := sdl.LoadBMP("data\\dropoff_spot.bmp")
	dropoff_tex  := sdl.CreateTextureFromSurface(renderer, dropoff_surf)
	sdl.FreeSurface(dropoff_surf)
	// --Tech init over--
	
	
	// --Game init--
	base_spots : [128]BaseSpot
	base_spot_count := 0
	
	base_spot_count += 1
	base_spots[0].rect = sdl.Rect{20, 10, CARD_SIZE_X + 2, CARD_SIZE_Y + 2}
	
	base_spot_count += 1
	base_spots[1].rect = sdl.Rect{20 + 120, 10, CARD_SIZE_X + 2, CARD_SIZE_Y + 2}
	
	base_spot_count += 1
	base_spots[2].rect = sdl.Rect{20 + 240, 10, CARD_SIZE_X + 2, CARD_SIZE_Y + 2}
	
	
	goal_spots : [128]GoalSpot
	goal_spot_count := 0
	
	goal_spot_count += 1
	goal_spots[0].rect = sdl.Rect{20 + 240 + 240, 10, CARD_SIZE_X + 2, CARD_SIZE_Y + 2}
	
	
	cards : [256]Card 
	draw_queue : [256]int 
	card_count := 0
	
	mouse_x, mouse_y : i32 = 0, 0
	mouse_state : u32 = 0
	
	is_grabbing_card := false
	was_just_grabbing_card := false
	grabbed_card_index := 0
	grabbed_relative_x, grabbed_relative_y : i32 = 0, 0
	
	
	event : sdl.Event
	running : sdl.bool = true
	for running {
		// -- Input START --
		for sdl.PollEvent(&event) {
			if (event.type == sdl.EventType.KEYDOWN && event.key.repeat == 0) {
				base_keycode_value := int(sdl.Keycode.NUM1)
				key_keycode := int(event.key.keysym.sym)
				if (key_keycode >= base_keycode_value) && (key_keycode <= base_keycode_value + 9) {
					card_type_number := key_keycode - base_keycode_value + 1
					
					new_card : Card
					new_card.power = card_type_number
					new_card.texture_index = card_type_number
					new_card.rect = sdl.Rect{mouse_x, mouse_y, CARD_SIZE_X, CARD_SIZE_Y}
					draw_queue[card_count] = card_count
					cards[card_count] = new_card
					card_count += 1
				}
				
				// #partial switch event.key.keysym.sym {
				// 	case .NUM1: {
				// 		new_card := BLANK_CARD
				// 		new_card.texture_index = 1
				// 		new_card.rect = sdl.Rect{mouse_x, mouse_y, CARD_SIZE_X, CARD_SIZE_Y}
				// 		draw_queue[card_count] = card_count
				// 		cards[card_count] = new_card
				// 		card_count += 1
				// 	}
				// 	case .NUM2: {
				// 	}
				// 	case .ESCAPE: {
				// 		running = false 
				// 	}
				// 	case: {
				// 		sdl.Log("Else")
				// 	}
				// }
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
			if !is_grabbing_card { // Mouse1 pressed while not holding a card
				for o_index := card_count - 1; o_index >= 0; o_index -= 1 {
					card := &cards[draw_queue[o_index]]
					if sdl.PointInRect(&sdl.Point{mouse_x, mouse_y}, &card.rect) && !card.is_on_goal {
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
				when true {
					grabbed_card.rect.x = mouse_x - (CARD_SIZE_X / 2)
					grabbed_card.rect.y = mouse_y - (CARD_SIZE_Y / 5)
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
				found_is_base_spot := false
				found_is_goal := false
				
				search_for_dropoff: {
					for b_index in 0..<base_spot_count {
						base := &base_spots[b_index]
						is_in_rect := sdl.PointInRect(&mouse_point, &base.rect)
						if is_in_rect == true && base.over_index == nil {
							base.over_index = grabbed_card_index
							
							found_is_base_spot = true
							found_under_index = b_index
							found_new_position.x = base.rect.x + 1
							found_new_position.y = base.rect.y + 1
							
							valid_dropoff_found = true
							break search_for_dropoff
						}
					}
					
					for g_index in 0..<goal_spot_count {
						goal := &goal_spots[g_index]
						is_in_rect := sdl.PointInRect(&mouse_point, &goal.rect)
						if is_in_rect && goal.held_power + 1 == grabbed_card.power && grabbed_card.over_index == nil {
							goal.over_index = grabbed_card_index
							goal.held_power = grabbed_card.power
							// goal.power += 1
							
							found_is_goal = true
							found_new_position.x = goal.rect.x + 1
							found_new_position.y = goal.rect.y + 1
							
							valid_dropoff_found = true
							break search_for_dropoff
						}
					
					}
					
					for c_index in 0..<card_count {
						if c_index != grabbed_card_index {
							card := &cards[c_index]
							if card.is_on_goal || card.over_index != nil do continue
							is_in_rect := sdl.PointInRect(&mouse_point, &card.rect)
							if is_in_rect == true && grabbed_card.power + 1 == card.power {
								card.over_index = grabbed_card_index
								
								if card.is_on_goal { found_is_goal = true }
								found_under_index = c_index
								found_new_position.x = card.rect.x
								found_new_position.y = card.rect.y + NEXT_CARD_Y_OFFSET
								
								valid_dropoff_found = true
								break search_for_dropoff
							}
						}
					}
				}
				
				if valid_dropoff_found {
					if grabbed_card.is_on_base_spot {
						base_spots[grabbed_card.under_index.(int)].over_index = nil
						grabbed_card.is_on_base_spot = false
					} else if grabbed_card.under_index != nil {
						cards[grabbed_card.under_index.(int)].over_index = nil
					}
					
					grabbed_card.rect = found_new_position
					grabbed_card.under_index = found_under_index
					grabbed_card.is_on_base_spot = found_is_base_spot
					grabbed_card.is_on_goal = found_is_goal
					assert(!(found_is_base_spot && found_is_goal))
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
				over_card.rect.y = grabbed_card.rect.y + NEXT_CARD_Y_OFFSET
				prev_card := over_card
				for over_card.over_index != nil {
					over_card = &cards[prev_card.over_index.(int)]
					over_card.rect.x = prev_card.rect.x
					over_card.rect.y = prev_card.rect.y + NEXT_CARD_Y_OFFSET
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
		// sdl.SetRenderDrawColor(renderer, 255, 255, 255, sdl.ALPHA_OPAQUE);
		
		for index := 0; index < base_spot_count; index += 1 {
			sdl.RenderCopy(renderer, card_textures[0], nil, &base_spots[index].rect)
		}
		
		for index in 0..<goal_spot_count {
			sdl.RenderCopy(renderer, dropoff_tex, nil, &goal_spots[index].rect)
		}
		
		for index := 0; index < card_count; index += 1 {
			current_card := &cards[draw_queue[index]]
			sdl.RenderCopy(renderer, card_textures[current_card.texture_index], nil, &current_card.rect)
		}
		
		
		// sdl.RenderDrawLine(renderer, 20, 20, mouse_x, mouse_y);
		
		sdl.RenderPresent(renderer)
	}
	
	sdl.Quit()
}
