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
  $version = '1.0.50'

  # Asegurar que el directorio existe
  file { '/etc/educontrol':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Descargar el paquete .deb en el cliente
  file { "/var/cache/educontrol-agent_${version}_all.deb":
    ensure => file,
    source => "puppet:///modules/educontrol_agent/educontrol-agent_${version}_all.deb",
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    require => File['/etc/educontrol'],
  }

  # Instalar el paquete .deb
  exec { 'install-educontrol-agent':
    command  => "/usr/bin/dpkg -i /var/cache/educontrol-agent_${version}_all.deb || /usr/bin/apt-get install -f -y",
    unless   => "/usr/bin/dpkg-query -W -f='\${Status} \${Version}\n' educontrol-agent 2>/dev/null | /bin/grep -q '^install ok installed ${version}$'",
    provider => shell,
    require  => File["/var/cache/educontrol-agent_${version}_all.deb"],
  }

  # Descargar el archivo de configuración en el cliente
  file { '/etc/educontrol/agent_config.json':
    ensure  => file,
    source  => 'puppet:///modules/educontrol_agent/agent_config.json',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
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

  exec { 'insertar_educontrol_agent':
    command => '/usr/bin/echo "educontrol-agent" >> /etc/pkgsync/mayhave',
    onlyif  => '/usr/bin/test -f /etc/pkgsync/mayhave',
    unless  => '/usr/bin/grep -Fxq "educontrol-agent" /etc/pkgsync/mayhave',
  }

  # Paquetes que solo tienen sentido con escritorio, para no llevar librerías gráficas a los
  # servidores: x11vnc (escritorio remoto) y los avisos en pantalla (p. ej. trabajo de impresión
  # denegado).
  $desktop_check = '/usr/bin/test -d /usr/share/xsessions -o -d /usr/share/wayland-sessions'

  $desktop_packages = ['x11vnc', 'zenity', 'libnotify-bin']
  $desktop_list = join($desktop_packages, ' ')

  exec { 'install-educontrol-desktop-tools':
    command  => "/usr/bin/apt-get install -y ${desktop_list}",
    onlyif   => $desktop_check,
    unless   => "/usr/bin/dpkg-query -W -f='\${Status}\n' ${desktop_list} 2>/dev/null | /bin/grep -c '^install ok installed$' | /bin/grep -qx ${length($desktop_packages)}",
    provider => shell,
    require  => Exec['install-educontrol-agent'],
  }

  # pkgsync no debe desinstalarlos.
  $desktop_packages.each |String $pkg| {
    exec { "insertar_${pkg}":
      command  => "/usr/bin/echo '${pkg}' >> /etc/pkgsync/mayhave",
      onlyif   => "/usr/bin/test -f /etc/pkgsync/mayhave && ${desktop_check}",
      unless   => "/usr/bin/grep -Fxq '${pkg}' /etc/pkgsync/mayhave",
      provider => shell,
    }
  }
}