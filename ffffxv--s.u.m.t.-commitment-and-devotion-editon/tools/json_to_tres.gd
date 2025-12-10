@tool
extends EditorScript

func _run():
	var folder_path = "res://Dialogue/" # Folder where your JSON files are
	var dir = DirAccess.open(folder_path)
	if not dir:
		printerr("Cannot open folder: ", folder_path)
		return

	dir.list_dir_begin(true, true) # skip hidden, recursive=false
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var json_path = folder_path + file_name
			print("Converting: ", json_path)

			var file = FileAccess.open(json_path, FileAccess.READ)
			if not file:
				printerr("Cannot read file: ", json_path)
				file_name = dir.get_next()
				continue

			var text = file.get_as_text()
			file.close()

			# Create a new TextFile resource
			var text_res = TextFile.new()
			text_res.text = text

			# Save it as .tres
			var tres_path = folder_path + file_name.replace(".json", ".tres")
			var err = ResourceSaver.save(tres_path, text_res)
			if err == OK:
				print("Saved .tres: ", tres_path)
			else:
				printerr("Failed to save .tres: ", tres_path)

		file_name = dir.get_next()
