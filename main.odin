package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl2"

UNIQUE_CARD_COUNT :: 11
CARD_SIZE_X :: 60
CARD_SIZE_Y :: 60
NEXT_CARD_Y_OFFSET :: CARD_SIZE_Y * 0.4 // What happens here really? Auto-cast?

CARD_POWER_COUNT :: 14
CARD_SUIT_COUNT  :: 4

CardPowers :: enum u8{
	ace,
	one, two, three, four, five, six, seven, eight, nine, ten,
	jack, queen, king,
}

// CardNames :: []string{
// 	"ace",
// 	"1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
// 	"jack", "queen", "king",
// }

CardSuits :: enum u8{
	spades, clubs, diamonds, hearts
}

CardIndex :: union { int }

Card :: struct {
	power: CardPowers,
	suit: CardSuits,
	
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

to_card_index :: proc(power: CardPowers, suit: CardSuits) -> int {
	return int(power) + (CARD_POWER_COUNT * int(suit))
}

wrap_range :: proc(value: int, range: int) -> int {
	out := value % range
	if out < 0 {out = range + out}
	return out
}

main :: proc() {
	sdl.Init(sdl.INIT_VIDEO)
	
	// window_flags : sdl.WindowFlags
	window := sdl.CreateWindow("Title", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, 1680, 1050, sdl.WindowFlags{})
	renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_ACCELERATED)
	
	card_surface_template := sdl.LoadBMP("data\\card_face_template.bmp")
	card_texture_template := sdl.CreateTextureFromSurface(renderer, card_surface_template)
	template_size : struct {w: i32, h: i32} = ---
	sdl.QueryTexture(card_texture_template, nil, nil, &template_size.w, &template_size.h)
	// pixel_format : u32
	// sdl.QueryTexture(card_texture_template, &pixel_format, nil, nil, nil)
	// fmt.println(sdl.GetPixelFormatName(pixel_format))
	// template_renderer     := sdl.CreateSoftwareRenderer(card_surface_template)
	
	top_number_pos    := sdl.Point{195, 20}
	top_suit_pos      := sdl.Point{195, 65}
	bottom_number_pos := sdl.Point{20,  295}
	bottom_suit_pos   := sdl.Point{20,  250}
	tex_diameter      :i32= 35
	
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
		card_power_source_tex := sdl.CreateTextureFromSurface(renderer, sdl.LoadBMP(card_power_name))
		power_textures[card_power] = card_power_source_tex
	}
	
	for card_suit in CardSuits {
		for card_power in CardPowers {
			out_texture := sdl.CreateTexture(renderer, u32(sdl.PixelFormatEnum.ARGB8888), sdl.TextureAccess.TARGET, template_size.w, template_size.h)
			sdl.SetRenderTarget(renderer, out_texture)
			
			sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode.BLEND)
			sdl.SetTextureBlendMode(out_texture, sdl.BlendMode.BLEND)
			sdl.SetRenderDrawColor(renderer, 0, 0, 0, 0)
			sdl.RenderFillRect(renderer, nil)
			// sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode.BLEND)
			
			sdl.RenderCopy(renderer, card_texture_template, nil, nil)
			
			sdl.RenderCopy  (renderer, power_textures[card_power], nil, &sdl.Rect{top_number_pos.x,    top_number_pos.y,    tex_diameter, tex_diameter})
			sdl.RenderCopyEx(renderer, power_textures[card_power], nil, &sdl.Rect{bottom_number_pos.x, bottom_number_pos.y, tex_diameter, tex_diameter}, 180, nil, nil)
			
			sdl.RenderCopy  (renderer, suit_textures[card_suit], nil, &sdl.Rect{top_suit_pos.x,    top_suit_pos.y,    tex_diameter, tex_diameter})
			sdl.RenderCopyEx(renderer, suit_textures[card_suit], nil, &sdl.Rect{bottom_suit_pos.x, bottom_suit_pos.y, tex_diameter, tex_diameter}, 180, nil, nil)

			new_card_textures[to_card_index(card_power, card_suit)] = out_texture
		}
	}
	sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode.BLEND)
	sdl.SetRenderTarget(renderer, nil)
	
	
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
	
	card_creation_selection : struct {power: CardPowers, suit: CardSuits}
	
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
					new_card.power = CardPowers(card_type_number)
					new_card.texture_index = card_type_number
					new_card.rect = sdl.Rect{mouse_x, mouse_y, CARD_SIZE_X, CARD_SIZE_Y}
					draw_queue[card_count] = card_count
					cards[card_count] = new_card
					card_count += 1
				}
				
				#partial switch event.key.keysym.sym {
					case .UP: {
						card_creation_selection.power = CardPowers(wrap_range(int(card_creation_selection.power) + 1, CARD_POWER_COUNT))
					}
					case .DOWN: {
						card_creation_selection.power = CardPowers(wrap_range(int(card_creation_selection.power) - 1, CARD_POWER_COUNT))
					}
					case .RIGHT: {
						card_creation_selection.suit = CardSuits(wrap_range(int(card_creation_selection.suit) + 1, CARD_SUIT_COUNT))
					}
					case .LEFT: {
						card_creation_selection.suit = CardSuits(wrap_range(int(card_creation_selection.suit) - 1, CARD_SUIT_COUNT))
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
						if is_in_rect && goal.held_power + 1 == int(grabbed_card.power) && grabbed_card.over_index == nil {
							goal.over_index = grabbed_card_index
							goal.held_power = int(grabbed_card.power)
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
							if is_in_rect == true && int(grabbed_card.power) + 1 == int(card.power) {
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
		
		sdl.RenderCopy(renderer, new_card_textures[to_card_index(card_creation_selection.power, card_creation_selection.suit)], nil, &sdl.Rect{00*10, 50, card_surface_template.w, card_surface_template.h})
		
		
		
		sdl.RenderCopy(renderer, power_textures[card_creation_selection.power], nil, &sdl.Rect{0,  0, tex_diameter, tex_diameter})
		sdl.RenderCopy(renderer, suit_textures[card_creation_selection.suit],   nil, &sdl.Rect{35, 0, tex_diameter, tex_diameter})
		
		sdl.RenderPresent(renderer)
	}
	
	sdl.Quit()
}
