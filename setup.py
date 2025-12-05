# coding=utf-8

from setuptools import setup

plugin_identifier = "clothopus"
plugin_package = "octoprint_clothopus"
plugin_name = "OctoPrint-Clothopus"
plugin_version = "0.1.0"
plugin_description = "A filament NFC management system for OctoPrint."
plugin_author = "Jariem"
plugin_author_email = "you@example.com"
plugin_url = "https://github.com/you/OctoPrint-Clothopus"
plugin_license = "MPL-2.0"
plugin_requires = []

setup(
    name=plugin_name,
    version=plugin_version,
    description=plugin_description,
    author=plugin_author,
    author_email=plugin_author_email,
    url=plugin_url,
    license=plugin_license,
    packages=[plugin_package],
    include_package_data=True,
    zip_safe=False,
    install_requires=plugin_requires,
    entry_points={
        "octoprint.plugin": [
            f"{plugin_identifier} = {plugin_package}"
        ]
    },
)
