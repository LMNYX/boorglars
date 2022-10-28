// Project Boon's INIParser ported to Boo

import System
import System.Collections.Generic
import System.Globalization
import System.IO
import System.Text
import UnityEngine

class INIParser: 

	def constructor():
		pass

	def constructor(path as string):
		self.Open(path)

	// In case there is errors, this will changed to some value other than 0
	public ErrorCode = 0

	// Lock for thread-safe access to file and local cache
	private m_Lock = object

	// File name
	private m_FileName = ""
	public FileName:
		get:
			return m_FileName
		set:
			m_FileName = value

	// String represent Ini
	private m_iniString = ""
	public INIString:
		get:
			return m_iniString
		set:
			m_iniString = value

	// Automatic flushing flag
	private m_AutoFlush = false

	// Local cache
	private m_Sections = Dictionary[of string, Dictionary[of string, string]]()
	private m_Modified = Dictionary[of string, Dictionary[of string, string]]()

	// Local cache modified flag
	private m_CacheModified = false

	// Open ini file by path
	public def Open(path as string):
		m_FileName = path

		if File.Exists(m_FileName):
			m_iniString = File.ReadAllText(m_FileName)
		else:
			//If file does not exist, create one
			temp = File.Create(m_FileName)
			temp.Close()
			m_iniString = ""

		Initialize(m_iniString, false)

	// Open ini file by TextAsset: All changes is saved to local storage
	public def Open(name as TextAsset):
		if name == null:
			// In case null asset, treat as opened an empty file
			ErrorCode = 1
			m_iniString = ""
			m_FileName = null
			Initialize(m_iniString, false)
		else:
			m_FileName = Application.persistentDataPath + name.name

			// Find the TextAsset in the local storage first
			if File.Exists(m_FileName):
				m_iniString = File.ReadAllText(m_FileName)
			else:
				m_iniString = name.text

			Initialize(m_iniString, false)

	// Open ini file from string
	public def OpenFromString(str as string):
		m_FileName = null
		Initialize(str, false)

	// Get the string content of ini file
	override def ToString() as string:
		return m_iniString

	private def Initialize(iniString as string, AutoFlush as bool):
		m_iniString = iniString
		m_AutoFlush = AutoFlush
		Refresh()

	// Close, save all changes to ini file
	public def Close():
		__lockObj = m_Lock
		try:
			System.Threading.Monitor.Enter(__lockObj)
			PerformFlush()

			//Clean up memory
			m_FileName = null
			m_iniString = null
		ensure:
			System.Threading.Monitor.Exit(__lockObj)

	// Parse section name
	private def ParseSectionName(Line as string) as string:
		if not Line.StartsWith("["):
			return null
		if not Line.EndsWith("]"):
			return null
		if Line.Length < 3:
			return null

		return Line.Substring(1, Line.Length - 2)

	// Parse key+value pair
	private def ParseKeyValuePair(Line as string, ref Key as string, ref Value as string) as bool:
		// Check for key+value pair
		i = 0
		if (i = Line.IndexOf('=')) <= 0:
			return false

		j = Line.Length - i - 1
		Key = Line.Substring(0, i).Trim()

		if Key.Length <= 0:
			return false

		Value = ""

		if j > 0:
			Value = Line.Substring(i + 1, j).Trim()

		return true

	// If a line is neither SectionName nor key+value pair, it's a comment
	private def IsComment(Line as string) as bool:
		tmpKey as string = null
		tmpValue as string = null

		if ParseSectionName(Line) != null:
			return false
		if ParseKeyValuePair(Line, tmpKey, tmpValue):
			return false

		return true

	// Read file contents into local cache
	private def Refresh():
		__lockObj = m_Lock
		try:
			System.Threading.Monitor.Enter(__lockObj)
			sr as StringReader = null
			try:
				// Clear local cache
				m_Sections.Clear()
				m_Modified.Clear()

				// String Reader
				sr = StringReader(m_iniString)

				// Read up the file content
				CurrentSection as Dictionary[of string, string]
				s as string
				SectionName as string
				Key as string = null
				Value as string = null
				while (s = sr.ReadLine()) != null:
					s = s.Trim()

					// Check for section names
					SectionName = ParseSectionName(s)
					if SectionName != null:
						// Only first occurrence of a section is loaded
						if m_Sections.ContainsKey(SectionName):
							CurrentSection = null
						else:
							CurrentSection = Dictionary[of string, string]()
							m_Sections.Add(SectionName, CurrentSection)
					elif CurrentSection != null:
						// Check for key+value pair
						if ParseKeyValuePair(s, Key, Value):
							// Only first occurrence of a key is loaded
							if not CurrentSection.ContainsKey(Key):
								CurrentSection.Add(Key, Value)
			ensure:
				// Cleanup: close file
				if sr != null:
					sr.Close()
				sr = null
		ensure:
			System.Threading.Monitor.Exit(__lockObj)

	private def PerformFlush():
		// If local cache was not modified, exit
		if not m_CacheModified:
			return

		m_CacheModified = false

		// Copy content of original iniString to temporary string, replace modified values
		sw = StringWriter()

		try:
			CurrentSection as Dictionary[of string, string] = null
			CurrentSection2 as Dictionary[of string, string] = null
			sr as StringReader = null
			try:
				// Open the original file
				sr = StringReader(m_iniString)

				// Read the file original content, replace changes with local cache values
				s as string
				SectionName as string
				Key as string = null
				Value as string = null
				Unmodified = false
				Reading = true

				Deleted = false
				Key2 as string = null
				Value2 as string = null

				sb_temp as StringBuilder

				while Reading:
					s = sr.ReadLine()
					Reading = (s != null)

					// Check for end of iniString
					if Reading:
						Unmodified = true
						s = s.Trim()
						SectionName = ParseSectionName(s)
					else:
						Unmodified = false
						SectionName = null

					// Check for section names
					if (SectionName != null) or not Reading:
						if CurrentSection != null:
							// Write all remaining modified values before leaving a section
							if CurrentSection.Count > 0:
								// Optional: All blank lines before new values and sections are removed
								sb_temp = sw.GetStringBuilder()
								while sb_temp[sb_temp.Length - 1] == '\n' or sb_temp[sb_temp.Length - 1] == '\r':
									sb_temp.Length -= 1

								sw.WriteLine()
								for fkey in CurrentSection.Keys:
									if CurrentSection.TryGetValue(fkey, Value):
										sw.Write(fkey)
										sw.Write('=')
										sw.WriteLine(Value)

								sw.WriteLine()
								CurrentSection.Clear()

						if Reading:
							// Check if current section is in local modified cache
							if not m_Modified.TryGetValue(SectionName, CurrentSection):
								CurrentSection = null
					elif CurrentSection != null:
						// Check for key+value pair
						if ParseKeyValuePair(s, Key, Value):
							if CurrentSection.TryGetValue(Key, Value):
								// Write modified value to temporary file
								Unmodified = false
								CurrentSection.Remove(Key)

								sw.Write(Key)
								sw.Write('=')
								sw.WriteLine(Value)

					// Check if the section/key in current line has been deleted
					if Unmodified:
						if SectionName != null:
							if not m_Sections.ContainsKey(SectionName):
								Deleted = true
								CurrentSection2 = null
							else:
								Deleted = false
								m_Sections.TryGetValue(SectionName, CurrentSection2)
						elif CurrentSection2 != null:
							if ParseKeyValuePair(s, Key2, Value2):
								if not CurrentSection2.ContainsKey(Key2):
									Deleted = true
								else:
									Deleted = false

					// Write unmodified lines from the original iniString
					if Unmodified:
						if IsComment(s):
							sw.WriteLine(s)
						elif not Deleted:
							sw.WriteLine(s)

				// Close string reader
				sr.Close()
				sr = null
			ensure:
				// Cleanup: close string reader                  
				if sr != null:
					sr.Close()
				sr = null

			// Cycle on all remaining modified values
			for SectionPair in m_Modified:
				CurrentSection = SectionPair.Value
				if CurrentSection.Count > 0:
					sw.WriteLine()

					// Write the section name
					sw.Write('[')
					sw.Write(SectionPair.Key)
					sw.WriteLine(']')

					// Cycle on all key+value pairs in the section
					for ValuePair in CurrentSection:
						// Write the key+value pair
						sw.Write(ValuePair.Key)
						sw.Write('=')
						sw.WriteLine(ValuePair.Value)
					CurrentSection.Clear()
			m_Modified.Clear()

			// Get result to iniString
			m_iniString = sw.ToString()
			sw.Close()
			sw = null

			// Write iniString to file
			if m_FileName != null:
				File.WriteAllText(m_FileName, m_iniString)
		ensure:
			// Cleanup: close string writer
			if sw != null:
				sw.Close()

	// Check if the section exists
	public def IsSectionExists(SectionName as string) as bool:
		return m_Sections.ContainsKey(SectionName)

	// Check if the key exists
	public def IsKeyExists(SectionName as string, Key as string) as bool:
		// Check if the section exists
		if m_Sections.ContainsKey(SectionName):
			Section as Dictionary[of string, string]
			m_Sections.TryGetValue(SectionName, Section)

			// If the key exists
			return Section.ContainsKey(Key)
		else:
			return false

	// Delete a section in local cache
	public def SectionDelete(SectionName as string):
		// Delete section if exists
		if IsSectionExists(SectionName):
			__lockObj = m_Lock
			try:
				System.Threading.Monitor.Enter(__lockObj)
				m_CacheModified = true
				m_Sections.Remove(SectionName)

				//Also delete in modified cache if exist
				m_Modified.Remove(SectionName)

				// Automatic flushing: immediately write any modification to the file
				if (m_AutoFlush):
					PerformFlush()
			ensure:
				System.Threading.Monitor.Exit(__lockObj)

	// Delete a key in local cache
	public def KeyDelete(SectionName as string, Key as string):
		//Delete key if exists
		if IsKeyExists(SectionName, Key):
			__lockObj = m_Lock
			try:
				System.Threading.Monitor.Enter(__lockObj)
				m_CacheModified = true
				Section as Dictionary[of string, string]
				m_Sections.TryGetValue(SectionName, Section)
				Section.Remove(Key)

				//Also delete in modified cache if exist
				if m_Modified.TryGetValue(SectionName, Section):
					Section.Remove(SectionName)

				// Automatic flushing: immediately write any modification to the file
				if (m_AutoFlush):
					PerformFlush();
			ensure:
				System.Threading.Monitor.Exit(__lockObj)

	// Read a value from local cache
	public def ReadValue(SectionName as string, Key as string, DefaultValue as string) as string:
		__lockObj = m_Lock
		try:
			System.Threading.Monitor.Enter(__lockObj)
			Section as Dictionary[of string, string]

			// Check if the section exists
			if not m_Sections.TryGetValue(SectionName, Section):
				return DefaultValue

			Value as string

			// Check if the key exists
			if not Section.TryGetValue(Key, Value):
				return DefaultValue

			// Return the found value
			return Value
		ensure:
			System.Threading.Monitor.Exit(__lockObj)

	// Insert or modify a value in local cache
	public def WriteValue(SectionName as string, Key as string, Value as string):
		__lockObj = m_Lock
		try:
			System.Threading.Monitor.Enter(__lockObj)
			// Flag local cache modification
			m_CacheModified = true

			Section as Dictionary[of string, string]

			// Check if the section exists
			if not m_Sections.TryGetValue(SectionName, Section):
				// If it doesn't, add it
				Section = Dictionary[of string, string]()
				m_Sections.Add(SectionName, Section)

			// Modify the value
			if Section.ContainsKey(Key):
				Section.Remove(Key)

			Section.Add(Key, Value)

			// Add the modified value to local modified values cache
			if not m_Modified.TryGetValue(SectionName, Section):
				Section = Dictionary[of string, string]()
				m_Modified.Add(SectionName, Section)

			if Section.ContainsKey(Key):
				Section.Remove(Key)

			Section.Add(Key, Value)

			// Automatic flushing: immediately write any modification to the file
			if m_AutoFlush:
				PerformFlush()
		ensure:
			System.Threading.Monitor.Exit(__lockObj)

	// Encode byte array
	private def EncodeByteArray(Value as (byte)) as string:
		if Value == null:
			return null

		sb = StringBuilder()
		for b in Value:
			hex = Convert.ToString(b, 16)
			l = hex.Length
			if l > 2:
				sb.Append(hex.Substring(l - 2, 2))
			else:
				if l < 2:
					sb.Append("0")
				sb.Append(hex)
		return sb.ToString()

	// Decode byte array
	private def DecodeByteArray(Value as string) as (byte):
		if Value == null:
			return null

		l = Value.Length
		if l < 2:
			return array(byte, 0)

		l /= 2
		Result = array(byte, l);
		for i in range(0, l):
			Result[i] = Convert.ToByte(Value.Substring(i * 2, 2), 16)
		return Result

	// Getters for various types
	public def ReadValue(SectionName as string, Key as string, DefaultValue as bool) as bool:
		StringValue = ReadValue(SectionName, Key, DefaultValue.ToString(CultureInfo.InvariantCulture))
		Value as int
		if int.TryParse(StringValue, Value):
			return Value != 0
		return DefaultValue

	public def ReadValue(SectionName as string, Key as string, DefaultValue as int) as int:
		StringValue = ReadValue(SectionName, Key, DefaultValue.ToString(CultureInfo.InvariantCulture))
		Value as int
		if int.TryParse(StringValue, NumberStyles.Any, CultureInfo.InvariantCulture, Value):
			return Value
		return DefaultValue

	public def ReadValue(SectionName as string, Key as string, DefaultValue as long) as long:
		StringValue = ReadValue(SectionName, Key, DefaultValue.ToString(CultureInfo.InvariantCulture))
		Value as long
		if long.TryParse(StringValue, NumberStyles.Any, CultureInfo.InvariantCulture, Value):
			return Value
		return DefaultValue

	public def ReadValue(SectionName as string, Key as string, DefaultValue as single) as single:
		StringValue = ReadValue(SectionName, Key, DefaultValue.ToString(CultureInfo.InvariantCulture))
		Value as single
		if single.TryParse(StringValue, NumberStyles.Any, CultureInfo.InvariantCulture, Value):
			return Value
		return DefaultValue

	public def ReadValue(SectionName as string, Key as string, DefaultValue as double) as double:
		StringValue = ReadValue(SectionName, Key, DefaultValue.ToString(CultureInfo.InvariantCulture))
		Value as double
		if double.TryParse(StringValue, NumberStyles.Any, CultureInfo.InvariantCulture, Value):
			return Value
		return DefaultValue

	public def ReadValue(SectionName as string, Key as string, DefaultValue as (byte)) as (byte):
		StringValue = ReadValue(SectionName, Key, EncodeByteArray(DefaultValue))
		try:
			return DecodeByteArray(StringValue)
		except e as FormatException:
			return DefaultValue

	public def ReadValue(SectionName as string, Key as string, DefaultValue as DateTime) as DateTime:
		StringValue = ReadValue(SectionName, Key, DefaultValue.ToString(CultureInfo.InvariantCulture))
		Value as DateTime
		if DateTime.TryParse(StringValue, CultureInfo.InvariantCulture, DateTimeStyles.AllowWhiteSpaces | DateTimeStyles.NoCurrentDateDefault | DateTimeStyles.AssumeLocal, Value):
			return Value
		return DefaultValue

	// Setters for various types
	public def WriteValue(SectionName as string, Key as string, Value as bool):
		WriteValue(SectionName, Key, Value.ToString(CultureInfo.InvariantCulture))

	public def WriteValue(SectionName as string, Key as string, Value as int):
		WriteValue(SectionName, Key, Value.ToString(CultureInfo.InvariantCulture))

	public def WriteValue(SectionName as string, Key as string, Value as long):
		WriteValue(SectionName, Key, Value.ToString(CultureInfo.InvariantCulture))

	public def WriteValue(SectionName as string, Key as string, Value as single):
		WriteValue(SectionName, Key, Value.ToString(CultureInfo.InvariantCulture))

	public def WriteValue(SectionName as string, Key as string, Value as double):
		WriteValue(SectionName, Key, Value.ToString(CultureInfo.InvariantCulture))

	public def WriteValue(SectionName as string, Key as string, Value as (byte)):
		WriteValue(SectionName, Key, EncodeByteArray(Value))

	public def WriteValue(SectionName as string, Key as string, Value as DateTime):
		WriteValue(SectionName, Key, Value.ToString(CultureInfo.InvariantCulture))