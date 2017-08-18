import argparse
import yaml
import socket
import os
import shutil
import sys
from jinja2 import Template

class InputParam:

    def __init__(self, config_file, templates_dir, output_dir, kvs):

        self.config_file = config_file
        self.templates_dir = templates_dir
        self.output_dir = output_dir

        self.__check()

        kv_data = {}
        if kvs:
            for kv in kvs:
                k, v = kv.split('=')
                k = str(k).strip()
                v = str(v).strip()
                kv_data[k] = v

        self.kv_data = kv_data

    def __check(self):

        if not os.path.isfile(self.config_file):
            raise Error(self.config_file + ' is not existent')

        if not os.path.exists(self.templates_dir):
            raise Error(self.templates_dir + ' is not existent')

class AppConfigRender:
    def __init__(self, app, basic_data, input):
        self.app = app
        data = dict(basic_data)
        data['app'] = app
        self.data = data
        self.input = input

    def __render_str(self, str):
        s = Template(str)
        val = s.render(self.data)
        return val

    def __render_template_file(self, template_file):
        if not os.path.isfile(template_file):
            return
        dir = os
        file = self.output_dir_for_app + '/' + os.path.basename(template_file)
        print 'write to %s' % file
        with open(template_file, 'r') as f:
            patten = f.read()
            result = self.__render_str(patten)
            with open(file, 'w') as fw:
                fw.write(result)

    def __render_vars(self, config_data):
        vars = config_data['vars']
        '''
        for key, val in vars.items():
            val = self.__render_str(val)
            vars[key] = val
        '''
        data = self.data.copy()
        data.update(vars)
        self.data = data

    def __prepare_output_dir(self):

        dir = self.input.output_dir + '/' + self.app
        if not os.path.exists(dir):
            os.makedirs(dir)
        else:
            shutil.rmtree(dir)
            os.makedirs(dir)

        self.output_dir_for_app = dir

    def render(self, config_data):
        self.__prepare_output_dir()
        self.__render_vars(config_data)

        for template_file in config_data['nginx-templates']:
            template_file = self.input.templates_dir + '/' + template_file
            template_file = self.__render_str(template_file)
            self.__render_template_file(template_file)

class Updater:

    def prepare_basic_data(self, input):

        for root, dirs, files in os.walk(input.output_dir):
            for f in files:
                os.unlink(os.path.join(root, f))
            for d in dirs:
                shutil.rmtree(os.path.join(root, d), ignore_errors=True)

        # mix env
        data = {}
        data.update(input.kv_data)
        self.basic_data = data

    def load_yaml(self, file):
        data = None
        with open(file, 'r') as f:
            data = yaml.load(f)
        return data

    def run(self, input):

        self.prepare_basic_data(input)
        yaml = self.load_yaml(input.config_file)

        for app_key, config_data in yaml.items():
            render = AppConfigRender(app_key, self.basic_data, input)
            render.render(config_data)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('-o', metavar=('output directory'), nargs=1, required=True)
    parser.add_argument('-t', metavar=('templates file directory'), nargs=1, required=True)
    parser.add_argument('-c', metavar=('config file'), nargs=1, required=True)
    parser.add_argument('--kvs', metavar=('key=val'), nargs='*', required=False)

    args = parser.parse_args()

    output_dir = args.o[0]
    config_file = args.c[0]
    templates_dir = args.t[0]
    input = InputParam(config_file, templates_dir, output_dir, args.kvs)

    updater = Updater()
    updater.run(input)
