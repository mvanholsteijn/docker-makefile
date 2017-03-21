#!/usr/bin/env python
import os, sys, re
import fnmatch
import subprocess
import argparse

class GitReleaseTagger:

	PATCH = 2
	MINOR = 1
	MAJOR = 0

	def __init__(self):
		self.path = None
		self.release = None
		self.tag = None
		self.errors = []
		self.dry_run = False

	def path_has_release(self, path):
		return os.path.exists(os.path.join(path, '.release'))

	def read_release(self):
		result = {}
		with open(self.path, 'r') as f:
			for line in f:
				line = line.rstrip()
				if len(line) > 0 and line[0] != '#':
					value = line.split("=", 2)
					result[value[0]] = value[1]
		if not ('release' in result and 'tag' in result):
			raise ValueError('%s does not contain release and tag values' % path)
		self.release = result['release']
		self.tag = result['tag']
		self.pre_tag_command = result['pre_tag_command'] if 'pre_tag_command' in result else None

		self.base_tag = self.tag.replace(self.release, '') 
		if self.base_tag[-1:] == '-':
			self.base_tag = self.base_tag[0:-1]

	def write_release(self):
		with open(self.path, 'w') as f:
			f.write('release=%s\n' % self.release)
			f.write('tag=%s\n' % self.tag)
			if self.pre_tag_command:
				f.write('pre_tag_command=%s\n' % self.pre_tag_command)

	def exec_git(self, cmd):
		process = subprocess.Popen(cmd, cwd=self.directory, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out = process.communicate()
		if process.returncode != 0:
		    self.report_error('ERROR: %s in %s, returned %d, output %s' % (cmd, os.path.dirname(self.path), process.returncode, out[1]))
		    sys.exit(1)
		return out[0]

	def get_git_branch(self):
		self.branch = 'master'
		response = self.exec_git( ["git", "branch"])
		branches = response.split('\n')
		for branch in branches:
			if len(branch) > 0 and branch[0] == '*':
				self.branch = branch[2:]
				break
		return self.branch

	def get_git_short_revision(self):
		self.git_commit = self.exec_git(["git", "rev-parse", "--short", "HEAD"]).rstrip()

	def get_change_list(self):
		self.change_list = self.exec_git(["git", "status", "-s", "."]).split('\n')
		if len(self.change_list) > 0 and self.change_list[-1] == '':
			del self.change_list[-1]

	def get_changed_since_tag(self):
		self.get_all_tags()
		if self.has_tag():
			self.changes_since_tag = self.exec_git(["git", "diff", "--shortstat", "-r", self.tag, '.']).rstrip()
		else:
			self.changes_since_tag = "tag is missing"

	def has_changed_since(self):
		return self.changes_since_tag != ''

	def get_all_tags(self):
		self.tags = self.exec_git(["git", "tag"]).split('\n')
		if len(self.tags) > 0 and self.tags[-1] == '':
			del self.tags[-1]

	def has_tag(self):
		return len(filter(lambda tag: tag == self.tag, self.tags)) > 0

	def next_release(self, level):
		release = map(lambda n: int(n), self.release.split('.'))
		if len(release) != 3:
			raise ValueError('release should consists of major.minor.patch release numbers')
		if level == GitReleaseTagger.PATCH:
			release[GitReleaseTagger.PATCH] += 1
		elif level == GitReleaseTagger.MINOR:
			release[GitReleaseTagger.MINOR] += 1
			release[GitReleaseTagger.PATCH] = 0
		elif level == GitReleaseTagger.MAJOR:
			release[GitReleaseTagger.MAJOR] += 1
			release[GitReleaseTagger.MINOR] = 0
			release[GitReleaseTagger.PATCH] = 0
		else:
			raise ValueError('I can only bump PATCH, MINOR or MAJOR levels')

		self.release = '%d.%d.%d' % (release[0], release[1], release[2])
		if self.base_tag != '':
			self.tag = '%s-%s' % ( self.base_tag, self.release)
		else:
			self.tag = self.release

	def get_current_release(self):
		self.read_release()
		self.get_git_branch()
		self.get_all_tags()
		self.get_git_short_revision()
		self.get_change_list()
		self.get_changed_since_tag()
		self.current_release = self.release
		if self.changes_since_tag != '':
			self.current_release = '%s-%s' % (self.release, self.git_commit)
		if len(self.change_list) > 0:
			self.current_release = '%s-%s-dirty' % (self.release, self.git_commit)
		if self.current_release != self.release and self.branch != 'master':
			self.current_release = '%s@%s' % (self.current_release, self.branch)

	def tag(self):
		self.get_all_tags()
		if not self.has_tag():
			self.get_change_list()
			if len(self.change_list) == 0:
				self.write_release()
				self.exec_git([ "git", "tag", self.release ])
			else:
				self.report_error('ERROR: %s still has outstanding changes.' % os.path.dirname(self.path))
		else:
			self.report_error('ERROR: tag %s already exists.' % self.tag)

	def exec_pre_tag_command(self):
		if self.pre_tag_command:
			cmd = self.pre_tag_command % { 'release': self.release, 'tag': self.tag, 'base_tag': self.base_tag }
			process = subprocess.Popen(cmd, shell=True, cwd=os.path.dirname(self.path), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
			out = process.communicate()
			if process.returncode != 0:
			    self.report_error('ERROR: %s in %s, returned %d, output %s' % (self.pre_tag_command, os.path.dirname(self.path), process.returncode, out[1]))
			    sys.exit(1)
			return out[0]

	def report_info(self, info):
		sys.stderr.write('%s\n' % info)

	def report_error(self, error):
		self.errors.append(error)
		sys.stderr.write('%s\n' % error)

	def tag_next_release(self, level):
		self.get_change_list()
		if len(self.change_list) == 0:
			if self.has_changed_since():
				self.next_release(level)
				if not self.has_tag():
					if not self.dry_run:
						self.write_release()
						self.exec_pre_tag_command()
						self.exec_git(['git', 'add', '.'])
						self.exec_git(['git', 'commit', '-m', 'bumped %s to release %s' % (self.base_tag, self.release)])
						self.exec_git([ 'git', 'tag', self.tag ])
					self.report_info('INFO: %s tagged with release %s.' % (self.directory, self.release))
				else:
					self.report_error('ERROR: tag %s already exists.' % self.tag)
			else:
					self.report_info('INFO: %s has no changes since %s.' % (self.directory, self.release))
		else:
			self.report_error('ERROR: %s still has outstanding changes.' % self.directory)
		
	def set_directory(self, directory):
		self.directory = directory
		self.path = os.path.join(self.directory, '.release')
		self.get_current_release()

	def set_path(self, path):
		self.path = path
		self.directory = os.path.dirname(path)
		self.get_current_release()

	def find_all_release_subdirectories(self, directory):
		result = []
		for root, dir, files in os.walk(directory):
			for item in fnmatch.filter(files, ".release"):
				result.append(os.path.join(root))
		return result

	def initialize(self, directory, release):
		if not re.match("[0-9]+\.[0-9]+\.[0-9]+", release):
			raise ValueError('ERROR: to initialize, release %s should match release major.minor.patch' % options.initialize)

		if os.path.isdir(directory):
			directory = os.path.abspath(directory)
			self.path = os.path.join(directory, '.release')
			if not os.path.exists(self.path):
				self.release = release
				self.tag = '%s-%s' % (os.path.basename(directory), self.release)
				self.pre_tag_command = None
				self.write_release()
			else:
				self.report_info('INFO: %s is ready initialized.' % directory)
		else:
			self.report_error('ERROR: %s is not a directory.' % directory)

	def main(self):
		paths = [os.path.join('.', '.release')]

		parser = argparse.ArgumentParser(description='tag versions of sub directories')
		parser.add_argument("directories", nargs='*', metavar='DIRECTORY',
				    help="the directories to process")
		parser.add_argument("--recursive", "-r", action="store_true", dest="recursive",
				    help="do it for all subdirectories with a .release file")
		parser.add_argument("--dry-run", action="store_true", dest="dry_run",
				    help="show what would happen")

		group = parser.add_mutually_exclusive_group()
		group.add_argument("--tag", "-T", action="store_true", dest="tag_release",
				    help="tag the release")
		group.add_argument("--initialize", "-I", dest="initialize", metavar='RELEASE', help="initialize the directory")
		group.add_argument("--next", "-N", action="store_true", dest="show_next",
				    help="show the next release")

		group = parser.add_mutually_exclusive_group()
		group.add_argument("--patch-release", "-p", action="store_true", dest="patch_release",
				    help="bump and tag patch release level")
		group.add_argument("--minor-release", "-m", action="store_true", dest="minor_release",
				    help="bump and tag minor release level")
		group.add_argument("--major-release", "-M", action="store_true", dest="major_release",
				    help="bump and tag major release level")

		options = parser.parse_args()

		self.dry_run = options.dry_run

		if len(options.directories) == 0:
			options.directories = ['.']

		if options.minor_release:
			level = GitReleaseTagger.MINOR
		elif options.major_release:
			level = GitReleaseTagger.MAJOR
		else:
			level = GitReleaseTagger.PATCH

		if options.recursive:
			paths = []
			for d in options.directories:
				paths.extend(self.find_all_release_subdirectories(d))
		else:
			paths = options.directories

		if options.tag_release:
			for path in paths:
				self.set_path(os.path.join(path, '.release'))
				self.tag_next_release(level)

			sys.exit(len(self.errors) == 0)

		elif options.initialize:
			if not re.match("[0-9]+\.[0-9]+\.[0-9]+", options.initialize):
				parser.error('release %s does not match major.minor.patch' % options.initialize)

			if options.recursive:
				parser.error('--initialize connect be used with --recursive')

			for path in options.directories:
				self.initialize(path, options.initialize)
			sys.exit(len(self.errors) == 0)

		elif options.show_next:
			for path in paths:
				self.set_path(os.path.join(path, '.release'))
				self.next_release(level)
				if not options.recursive:
					print '%s' % (self.release)
				else:
					print '%s	%s' % (self.directory, self.release)
		else:
			for path in paths:
				self.set_path(os.path.join(path, '.release'))
				if not options.recursive:
					print '%s' % (self.current_release)
				else:
					print '%s	%s' % (self.directory, self.current_release)

if __name__ == '__main__':
	GitReleaseTagger().main()
