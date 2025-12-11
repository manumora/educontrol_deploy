##############################################################################
# -*- coding: utf-8 -*-
# Project:     EduControl Agent Puppet Task
# Language:    Puppet
# Date:        4-Dec-2025
# Authors:     Manuel Mora Gordillo
# Repository:  https://github.com/manumora/educontrol_deploy
# Copyright:   Manuel Mora Gordillo    <manuel.mora.gordillo @nospam@ gmail.com>
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this. If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################
#
# Uso:
#   include educontrol_agent
#

class educontrol_agent () {

  # Versión del agente
  $version = '1.0.10'

  # Asegurar que el directorio existe
  file { '/etc/educontrol':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Descargar el paquete .deb en el cliente
  file { "/tmp/educontrol-agent_${version}_all.deb":
    ensure => file,
    source => "puppet:///modules/educontrol_agent/educontrol-agent_${version}_all.deb",
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    require => File['/etc/educontrol'],
  }

  # Instalar el paquete .deb
  exec { 'install-educontrol-agent':
    command => "/usr/bin/dpkg -i /tmp/educontrol-agent_${version}_all.deb && /usr/bin/apt-get install -f -y",
    unless  => "/usr/bin/dpkg -s educontrol-agent 2>/dev/null | /bin/grep -q '^Version: ${version}$'",
    require => File["/tmp/educontrol-agent_${version}_all.deb"],
    notify  => Service['educontrol-agent'],
  }

  # Descargar el archivo de configuración en el cliente
  file { '/etc/educontrol/agent_config.json':
    ensure  => file,
    source  => 'puppet:///modules/educontrol_agent/agent_config.json',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [
      File['/etc/educontrol'],
      Exec['install-educontrol-agent'],
    ],
    notify  => Service['educontrol-agent'],
  }

  # Asegurar que el servicio esté habilitado y corriendo
  service { 'educontrol-agent':
    ensure    => running,
    enable    => true,
    require   => [
      Exec['install-educontrol-agent'],
      File['/etc/educontrol/agent_config.json'],
    ],
  }
}