import argparse
import os
import re
"""
The script assumes that the changelog follows these rules:
	1. Every changelog starts with "Changelog vN:"
	2. After every changelog block there is a newline
	3. There is no line in the patch that starts with the string
		"Changelog vN:"

    N - the number
"""

# Preferences :
changelog_string = "^Changelog v[0-9]*:"
# changelog_string = "^Changes since .*V[0-9]*:"

subject_string = "^Signed-off-by: Maciej Wieczor-Retman <m.wieczorretman@pm.me>$"
first_subject_string = "^Signed-off-by: Maciej Wieczor-Retman <maciej.wieczor-retman@intel.com>$"

class PatchChangelog():
	def __init__(self, filename):
		self.filename = filename
		self.lines = self.readLines()
		self.first_line = self.findFirstChangelog()
		self.last_line = self.findLastChangelog()
		self.dashes_line = self.findDashesChangelog()
		self.signed_off = self.findSignedOffLine()
		self.second_signed_off = self.findSecondSignedOffLine()
		self.tag_section = self.dashes_line - self.last_line

	def readLines(self):
		with open(self.filename, 'r') as f: # open in readonly mode
			return f.readlines()

	def findSignedOffLine(self):
		line_counter = 0
		found_line = 0
		for line in self.lines:
			line_match = re.match(subject_string, line)
			if line_match:
				return line_counter
			line_counter += 1
		return -1

	def findSecondSignedOffLine(self):
		line_counter = 0
		found_line = 0
		for line in self.lines:
			# Match start of a changelog block
			if found_line == 1 and re.match(subject_string, line):
				return line_counter
			line_match = re.match(first_subject_string, line)
			if line_match:
				found_line = 1
			line_counter += 1
		return -1

	def findFirstChangelog(self):
		line_counter = 0
		for line in self.lines:
			# Match start of a changelog block
			line_match = re.match(changelog_string, line)
			if line_match:
				return line_counter
			line_counter += 1
		return -1

	def findLastChangelog(self):
		line_counter = 0
		last_line = -1
		looking_for_last = 0
		for line in self.lines:
			# Match start of a changelog block
			line_match = re.match("^Changelog v[0-9]*:", line)
			# Find end of last changelog block
			if (looking_for_last and line == '\n'):
				last_line = line_counter
				looking_for_last = 0

			# Found block - start looking for the newline
			if (line_match):
				looking_for_last = 1
			line_counter += 1
		return last_line

	def findDashesChangelog(self):
		line_counter = 0
		for line in self.lines:
			if (line == "---\n"):
				return line_counter
			line_counter += 1
		return -1


class Changelog_Modify():

	def __init__(self, input, output):
		# empty list of patches
		self.input = input + "changelog"
		if not output:
			self.output = input + "changelog"
		else:
			self.output = output

		path_exists = os.path.exists(self.output)
		if not path_exists:
			os.makedirs(self.output)
		self.patches = self.readPatches()

	def readPatches(self):
		patches = []
		cover_letter = None
		for filename in os.listdir(self.input):
			# parse filenames to exclude the cover letter since
			# we want the changelog there to stay
			f = os.path.join(self.input, filename)
			# print(filename)
			if (filename[0] != '0' and filename[0] != 'v'):
				continue
			patch_number_index = 0
			if (filename[0] == 'v'):
				patch_number_index = 1
			else:
				patch_number_index = 0
			if (int(filename.split('-')[patch_number_index]) == 0):
				# print(filename)
				with open(f, 'r') as cl_i: # open in readonly mode
					cover_letter = cl_i.readlines()
				with open(os.path.join(self.output, filename), 'w+') as cl_o: # open in readonly mode
					cl_o.write("".join(cover_letter))
				continue
			patches.append(PatchChangelog(f))
			# print(patches[-1].first_line, patches[-1].last_line, patches[-1].dashes_line)
		return patches

	def moveChangelogs(self):
		for patch in self.patches:
			if (patch.first_line < 0):
				continue
			changelog_slice = patch.lines[patch.first_line:patch.last_line]
			patch.lines[patch.first_line - 1 : patch.first_line + patch.tag_section] = patch.lines[patch.last_line:patch.dashes_line + 1]
			patch.lines[patch.first_line + patch.tag_section : patch.dashes_line] = changelog_slice
			patch.lines[patch.dashes_line] = '\n'

	def savePatches(self):
		# print(self.output)
		for patch in self.patches:
			with open(self.output + '/' + patch.filename.split('/')[-1], 'w+') as f: # open in readonly mode
				# print(self.output + '/' + patch.filename.split('/')[-1])
				f.write("".join(patch.lines))

class EmailFixup():
	def __init__(self, input, output):
		self.input = input
		if not output:
			self.output = input + "changelog"
		else:
			self.output = output

		path_exists = os.path.exists(self.output)
		if not path_exists:
			os.makedirs(self.output)
		self.patches = self.readPatches()

	def readPatches(self):
		patches = []
		cover_letter = None
		for filename in os.listdir(self.input):
			# parse filenames to exclude the cover letter since
			# we want the changelog there to stay
			f = os.path.join(self.input, filename)
			# print(filename)
			if (filename[0] != '0' and filename[0] != 'v'):
				continue
			patch_number_index = 0
			if (filename[0] == 'v'):
				patch_number_index = 1
			else:
				patch_number_index = 0
			if (int(filename.split('-')[patch_number_index]) == 0):
				with open(f, 'r') as cl_i: # open in readonly mode
					cover_letter = cl_i.readlines()
				with open(os.path.join(self.output, filename), 'w+') as cl_o: # open in readonly mode
					cl_o.write("".join(cover_letter))
				continue
			patches.append(PatchChangelog(f))
			# print(patches[-1].first_line, patches[-1].last_line, patches[-1].dashes_line)
		return patches

	def writeEmail(self):
		for patch in self.patches:
			if (patch.signed_off > 0):
				patch.lines[patch.signed_off] = "Signed-off-by: Maciej Wieczor-Retman <maciej.wieczor-retman@intel.com>\n"
			if (patch.second_signed_off > 0):
				patch.lines[patch.second_signed_off] = ""

	def savePatches(self):
		# print(self.output)
		for patch in self.patches:
			with open(self.output + '/' + patch.filename.split('/')[-1], 'w+') as f: # open in readonly mode
				# print(self.output + '/' + patch.filename.split('/')[-1])
				f.write("".join(patch.lines))

argParser = argparse.ArgumentParser()
argParser.add_argument("-i", "--input", help="Patch series directory")
argParser.add_argument("-o", "--output", help="Modified output directory")

args = argParser.parse_args()

emailParser = EmailFixup(args.input, args.output)
emailParser.writeEmail()
emailParser.savePatches()

changelogParser = Changelog_Modify(args.input, args.output)
changelogParser.moveChangelogs()
changelogParser.savePatches()
