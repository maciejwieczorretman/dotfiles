import argparse
import subprocess
import os
import re

class MaintainerExtractor():

    def __init__(self, args):
        self.args = args
        self.old_cwd = os.getcwd()
        os.chdir(args.kernel)
        self.filenames = os.listdir(args.input)
        self.filenames.sort()
        self.text = self.read_all_get_maintainers_output()

    def read_get_maintainers_output(self, file):
        addresses = {"to": [], "cc": []}
        f = os.path.join(self.args.input, file)
        proc = subprocess.Popen(["./scripts/get_maintainer.pl", f], stdout=subprocess.PIPE)
        output_ml = proc.stdout.read().decode("utf-8").split('\n')
        for line in output_ml:
            ret = re.search(r'\<(.*)\>', line)
            if ret:
                addresses["to"].append(ret.group(1))
            else:
                ret_ml = re.search(r'([^\s]+)', line)
                if ret_ml:
                    addresses["cc"].append(ret_ml.group(1))
        return addresses

    def read_all_get_maintainers_output(self):
        addresses = {"to": [], "cc": []}
        for file in self.filenames:
            file_addresses = self.read_get_maintainers_output(file)
            addresses["to"] += file_addresses["to"]
            addresses["cc"] += file_addresses["cc"]

        addresses["to"] = list(set(addresses["to"]))
        addresses["cc"] = list(set(addresses["cc"]))
        if self.args.debug:
            print("FULL ADDRESS LIST : ", addresses)
        return addresses

    def send_all_patches(self):
        for file in self.filenames:
            if not file.endswith('.patch'):
                continue
            patch = os.path.join(self.args.input, file)
            to = ""
            cc = ""
            file_addresses = {}
            if "0000" in file:
                file_addresses = self.read_all_get_maintainers_output()
            else:
                file_addresses = self.read_get_maintainers_output(file)
            file_addresses["to"] = ["--to=" + str for str in file_addresses["to"]] 
            file_addresses["cc"] = ["--cc=" + str for str in file_addresses["cc"]] 
            to = ' '.join(list(set(file_addresses["to"])))
            cc = ' '.join(list(set(file_addresses["cc"])))
            command = f'git send-email {to} {cc} {self.args.git_arguments} {patch}'
            if(self.args.debug):
                print("COMMAND : ", command)
            else:
                subprocess.run(command, shell = True, executable="/bin/bash")


argParser = argparse.ArgumentParser()
argParser.add_argument("-i", "--input", help="Patch series directory", required=True)
argParser.add_argument("-k", "--kernel", help="Location of kernel source -\
                        default is the current working directory", nargs='?', const=os.getcwd())

argParser.add_argument("-d", "--debug", help="Print things rather than send email", action='store_true')
argParser.add_argument("-g", "--git-arguments", help="Git send-email arguments", action='store', nargs='?')
args = argParser.parse_args()

Maintainers = MaintainerExtractor(args)
Maintainers.send_all_patches()
os.chdir(Maintainers.old_cwd)
