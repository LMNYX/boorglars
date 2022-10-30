import System.IO
import UnityEngine

static class Settings:

	SettingsPath = Path.Combine(Application.persistentDataPath, "Settings.ini")

	public MouseSensitivity:
		get:
			Section = "Controls"
			Key = "MouseSensitivity"
			DefaultValue = 3.0f

			iniParser = INIParser(SettingsPath)

			if not iniParser.IsSectionExists(Section) or not iniParser.IsKeyExists(Section, Key):
				iniParser.WriteValue(Section, Key, DefaultValue)

			keyValue = iniParser.ReadValue(Section, Key, DefaultValue)

			iniParser.Close()

			return keyValue
		set:
			iniParser = INIParser(SettingsPath)
			iniParser.WriteValue("Controls", "MouseSensitivity", value)
			iniParser.Close()