package main

import "core:fmt"
import sdl "vendor:sdl2"

UNIQUE_CARD_COUNT :: 11
CARD_SIZE_X :: 60
CARD_SIZE_Y :: 60
NEXT_CARD_Y_OFFSET :: CARD_SIZE_Y * 0.6 // What happens here really? Auto-cast?
EMPTY_SPOT :: -1

Card :: struct {
	texture_index: int,
	is_on_base_spot: bool,
	under_index, over_index: int,
	rect, last_rect: sdl.Rect
}

BaseSpot :: struct {
	over_index: int,
	rect: sdl.Rect
}

BLANK_RECT :: sdl.Rect{-1, -1, -1, -1}
BLANK_CARD :: Card{-1, false, EMPTY_SPOT, EMPTY_SPOT, BLANK_RECT, BLANK_RECT}
BLANK_BASE_SPOT :: BaseSpot{EMPTY_SPOT, BLANK_RECT}

main :: proc() {
	sdl.Init(sdl.INIT_VIDEO)
	
	// window_flags : sdl.WindowFlags
	window := sdl.CreateWindow("Title", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, 800, 640, sdl.WindowFlags{})
	renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_ACCELERATED)
	
	
	card_surfaces : [UNIQUE_CARD_COUNT]^sdl.Surface
	card_textures : [UNIQUE_CARD_COUNT]^sdl.Texture
	card_surfaces[0] = sdl.LoadBMP("data\\card_back.bmp")
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
	// --Tech init over--
	
	
	// --Game init--
	base_spots : [128]BaseSpot
	base_spot_count := 0
	
	base_spot_count += 1
	base_spots[0] = BLANK_BASE_SPOT
	base_spots[0].rect = sdl.Rect{10, 10, CARD_SIZE_X + 2, CARD_SIZE_Y + 2}
	
	base_spot_count += 1
	base_spots[1] = BLANK_BASE_SPOT
	base_spots[1].rect = sdl.Rect{400, 10, CARD_SIZE_X + 2, CARD_SIZE_Y + 2}
	
	
	cards : [256]Card 
	draw_queue : [256]int 
	// cards[0] = {}; // temp
	card_count := 0
	
	mouse_x, mouse_y : i32 = 0, 0
	mouse_state : u32 = 0
	
	is_grabbing_card := false
	was_just_grabbing_card := false
	grabbed_card_index := EMPTY_SPOT
	grabbed_relative_x, grabbed_relative_y : i32 = 0, 0
	
	
	event : sdl.Event
	running : sdl.bool = true
	for running {
		// -- Input START --
		for sdl.PollEvent(&event) {
			if (event.type == sdl.EventType.KEYDOWN && event.key.repeat == 0) {
				#partial switch event.key.keysym.sym {
					case .NUM1: {
						new_card := BLANK_CARD
						new_card.texture_index = 1
						new_card.rect = sdl.Rect{mouse_x, mouse_y, CARD_SIZE_X, CARD_SIZE_Y}
						draw_queue[card_count] = card_count
						cards[card_count] = new_card
						card_count += 1
					}
					case .NUM2: {
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
			if !is_grabbing_card {
				for o_index := card_count - 1; o_index >= 0; o_index -= 1 {
					card := &cards[draw_queue[o_index]]
					if sdl.PointInRect(&sdl.Point{mouse_x, mouse_y}, &card.rect) {
						grabbed_card_index = draw_queue[o_index]
						cards[grabbed_card_index].last_rect = cards[grabbed_card_index].rect
						is_grabbing_card = true
						was_just_grabbing_card = true // Maybe move this out?
						
						grabbed_relative_x = mouse_x - card.rect.x
						grabbed_relative_y = mouse_y - card.rect.y
						
						// Puts the grabbed card at the top of the draw_queue array
						// TODO: account for card stacks
						shuffle_card_order := o_index
						for {
							shuffled_cards_index := draw_queue[shuffle_card_order]
							for reshufle_index in shuffle_card_order..<card_count - 1 {
								draw_queue[reshufle_index] = draw_queue[reshufle_index + 1]
							}
							draw_queue[card_count - 1] = shuffled_cards_index
							
							over_card := cards[shuffled_cards_index].over_index
							if over_card != EMPTY_SPOT {
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
			if is_grabbing_card {
				is_grabbing_card = false
				valid_dropoff_found := false
				grabbed_card := &cards[grabbed_card_index]
				mouse_point := sdl.Point{mouse_x, mouse_y}
				
				for b_index := 0; b_index < base_spot_count; b_index += 1 {
					base := &base_spots[b_index]
					is_in_rect := sdl.PointInRect(&mouse_point, &base.rect)
					if is_in_rect == true {
						// Not breaking so that it's easily visible when something goes wrong.
						if valid_dropoff_found { sdl.Log("BAD: Intersecting base spots!") }
						
						if base.over_index == EMPTY_SPOT {
							// Announce to the previous place that we're gone
							if grabbed_card.is_on_base_spot {
								base_spots[grabbed_card.under_index].over_index = EMPTY_SPOT
								grabbed_card.is_on_base_spot = false
							} else if grabbed_card.under_index != EMPTY_SPOT {
								cards[grabbed_card.under_index].over_index = EMPTY_SPOT
							}
							
							if grabbed_card.is_on_base_spot && grabbed_card.under_index != b_index {
								other_base := &base_spots[grabbed_card.under_index]
								other_base.over_index = EMPTY_SPOT
							}
							
							base.over_index = grabbed_card_index
							
							grabbed_card.is_on_base_spot = true
							grabbed_card.under_index = b_index
							grabbed_card.rect.x = base.rect.x + 1
							grabbed_card.rect.y = base.rect.y + 1
							valid_dropoff_found = true
						}
					}
				}
				
				for c_index := 0; c_index < card_count; c_index += 1 {
					if c_index != grabbed_card_index {
						card := &cards[c_index]
						is_in_rect := sdl.PointInRect(&mouse_point, &card.rect)
						if is_in_rect == true && card.over_index == EMPTY_SPOT {
							// Announce to the previous place that we're gone (again!)
							if grabbed_card.is_on_base_spot {
								base_spots[grabbed_card.under_index].over_index = EMPTY_SPOT
								grabbed_card.is_on_base_spot = false
							} else if grabbed_card.under_index != EMPTY_SPOT {
								cards[grabbed_card.under_index].over_index = EMPTY_SPOT
							}
							
							card.over_index = grabbed_card_index
							
							grabbed_card.under_index = c_index
							grabbed_card.rect.x = card.rect.x
							grabbed_card.rect.y = card.rect.y + NEXT_CARD_Y_OFFSET
							
							valid_dropoff_found = true
							break
						}
					}
				}
				
				if (!valid_dropoff_found) {
					grabbed_card.rect = grabbed_card.last_rect
				}
			}
		}
		if was_just_grabbing_card {
			grabbed_card := &cards[grabbed_card_index]
			if grabbed_card.over_index != EMPTY_SPOT {
				over_card := &cards[grabbed_card.over_index]
				over_card.rect.x = grabbed_card.rect.x
				over_card.rect.y = grabbed_card.rect.y + NEXT_CARD_Y_OFFSET
				prev_card := over_card
				for over_card.over_index != EMPTY_SPOT {
					over_card = &cards[prev_card.over_index]
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
		for index := 0; index < card_count; index += 1 {
			current_card := &cards[draw_queue[index]]
			sdl.RenderCopy(renderer, card_textures[current_card.texture_index], nil, &current_card.rect)
		}
		
		
		// sdl.RenderDrawLine(renderer, 20, 20, mouse_x, mouse_y);
		
		sdl.RenderPresent(renderer)
	}
	
	sdl.Quit()
}
