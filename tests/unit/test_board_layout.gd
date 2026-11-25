extends "res://tests/test_case.gd"


func test_track_has_52_unique_squares() -> void:
	var track := BoardLayout.track_cells()
	assert_eq(track.size(), BoardLayout.TRACK_LENGTH, "track length")
	var seen := {}
	for cell in track:
		seen[cell] = true
	assert_eq(seen.size(), BoardLayout.TRACK_LENGTH, "unique track squares")


func test_track_is_a_continuous_loop() -> void:
	var track := BoardLayout.track_cells()
	for i in track.size():
		var a: Vector2i = track[i]
		var b: Vector2i = track[(i + 1) % track.size()]
		assert_eq(chebyshev(a, b), 1, "squares %d and %d must touch:" % [i, i + 1])


func test_track_cell_matches_track_cells() -> void:
	var track := BoardLayout.track_cells()
	for i in track.size():
		assert_eq(BoardLayout.track_cell(i), track[i], "track_cell(%d)" % i)
	assert_eq(BoardLayout.track_cell(52), track[0], "track index wraps around")


func test_track_stays_out_of_bases_and_centre() -> void:
	for cell in BoardLayout.track_cells():
		assert_false(BoardLayout.is_centre_cell(cell), "%s is in the centre" % cell)
		for seat in BoardLayout.SEAT_COUNT:
			assert_false(BoardLayout.base_rect(seat).has_point(cell), "%s is inside base %d" % [cell, seat])


func test_each_start_square_is_next_to_its_own_base() -> void:
	assert_eq(BoardLayout.track_cell(BoardLayout.start_index(0)), Vector2i(1, 6), "seat 0 start square")
	for seat in BoardLayout.SEAT_COUNT:
		var start := BoardLayout.track_cell(BoardLayout.start_index(seat))
		for other in BoardLayout.SEAT_COUNT:
			var touches := BoardLayout.base_rect(other).grow(1).has_point(start)
			assert_eq(touches, other == seat, "start of seat %d next to base %d" % [seat, other])
		assert_eq(BoardLayout.seat_of_start_index(BoardLayout.start_index(seat)), seat, "seat_of_start_index")
	assert_eq(BoardLayout.seat_of_start_index(5), -1, "index 5 is not a start square")


func test_safe_squares_are_starts_and_stars() -> void:
	var safe := BoardLayout.safe_track_indices()
	assert_eq(safe.size(), 8, "eight safe squares")
	for seat in BoardLayout.SEAT_COUNT:
		assert_true(BoardLayout.is_safe_index(BoardLayout.start_index(seat)), "start of seat %d is safe" % seat)
		assert_true(BoardLayout.is_safe_index(BoardLayout.start_index(seat) + BoardLayout.STAR_OFFSET), "star of seat %d is safe" % seat)
	assert_false(BoardLayout.is_safe_index(1), "index 1 is not safe")
	assert_true(BoardLayout.is_safe_index(52), "safe check wraps around")


func test_home_columns_lead_from_entry_to_centre() -> void:
	var track := BoardLayout.track_cells()
	for seat in BoardLayout.SEAT_COUNT:
		var column := BoardLayout.home_column_cells(seat)
		assert_eq(column.size(), BoardLayout.HOME_COLUMN_LENGTH, "home column length")
		var entry := BoardLayout.track_cell(BoardLayout.home_entry_index(seat))
		assert_eq(chebyshev(entry, column[0]), 1, "seat %d entry touches its home column" % seat)
		for i in range(1, column.size()):
			assert_eq(chebyshev(column[i - 1], column[i]), 1, "home column squares touch")
		var last: Vector2i = column[column.size() - 1]
		assert_true(Rect2i(BoardLayout.CENTRE_RECT).grow(1).has_point(last), "home column ends at the centre")
		for cell in column:
			assert_false(track.has(cell), "home column square %s is not on the track" % cell)


func test_home_entry_is_the_square_before_the_start() -> void:
	for seat in BoardLayout.SEAT_COUNT:
		assert_eq(BoardLayout.home_entry_index(seat), posmod(BoardLayout.start_index(seat) - 2, BoardLayout.TRACK_LENGTH), "seat %d home entry" % seat)


func test_progress_points() -> void:
	for seat in BoardLayout.SEAT_COUNT:
		var start := BoardLayout.cell_center(BoardLayout.track_cell(BoardLayout.start_index(seat)))
		assert_eq(BoardLayout.progress_point(seat, 0), start, "progress 0 is the start square")
		var entry := BoardLayout.cell_center(BoardLayout.track_cell(BoardLayout.home_entry_index(seat)))
		assert_eq(BoardLayout.progress_point(seat, BoardLayout.LAST_TRACK_PROGRESS), entry, "progress 50 is the home entry")
		var column := BoardLayout.home_column_cells(seat)
		assert_eq(BoardLayout.progress_point(seat, 51), BoardLayout.cell_center(column[0]), "progress 51 is the first home square")
		assert_eq(BoardLayout.progress_point(seat, 55), BoardLayout.cell_center(column[4]), "progress 55 is the last home square")
		assert_eq(BoardLayout.progress_point(seat, BoardLayout.FINISH_PROGRESS), BoardLayout.finish_point(seat), "progress 56 is the finish")
		assert_eq(BoardLayout.progress_to_track_index(seat, 0), BoardLayout.start_index(seat), "track index at progress 0")
		assert_eq(BoardLayout.progress_to_track_index(seat, 51), -1, "home column is off the track")
	assert_false(BoardLayout.is_valid_progress(-1), "progress -1 is invalid")
	assert_false(BoardLayout.is_valid_progress(57), "progress 57 is invalid")


func test_board_is_rotationally_symmetric() -> void:
	for i in BoardLayout.TRACK_LENGTH:
		var rotated := BoardLayout.rotate_cell(BoardLayout.track_cell(i), 1)
		assert_eq(BoardLayout.track_cell(i + BoardLayout.SEGMENT_LENGTH), rotated, "quarter turn of square %d" % i)
	assert_eq(BoardLayout.rotate_cell(Vector2i(3, 2), 4), Vector2i(3, 2), "four quarter turns is identity")


func test_base_slots_are_inside_their_base() -> void:
	for seat in BoardLayout.SEAT_COUNT:
		var area := Rect2(BoardLayout.base_rect(seat))
		var slots := BoardLayout.base_slot_points(seat)
		assert_eq(slots.size(), BoardLayout.PAWNS_PER_PLAYER, "four base slots")
		for p in slots:
			assert_true(area.has_point(p), "slot %s inside base %d" % [p, seat])
		var centre := Rect2(BoardLayout.CENTRE_RECT)
		assert_true(centre.grow(0.01).has_point(BoardLayout.finish_point(seat)), "finish point is in the centre")
