import os
from setuptools import setup, find_packages

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(
    name = "Riemann reporter",
    version = "0.0.1",
    author = "Antal Nemes",
    author_email = "antal.nemes@balabit.com",
    description = ("Sends periodic reports to riemann"),
    keywords = "riemann",
    url = "https://github.com/furiel/riemann-reporter",
    packages=find_packages(),
    package_data={
        'riemann-reporter': ['*.hy'],
    },
    long_description=read('README.org'),
    install_requires=[
        'bernhard', 'hy'
    ],
)
