#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd "$(dirname "$0")/.." && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#------------------------------------------------------------------------------
# Set up OpenStack Networking (neutron) for controller node.
# http://docs.openstack.org/liberty/install-guide-ubuntu/neutron-controller-install.html
#------------------------------------------------------------------------------

echo "Setting up database for neutron."
setup_database neutron

source "$CONFIG_DIR/admin-openstackrc.sh"

neutron_admin_user=$(service_to_user_name neutron)
neutron_admin_password=$(service_to_user_password neutron)

# Wait for keystone to come up
wait_for_keystone

echo "Creating neutron user and giving it admin role under service tenant."
openstack user create \
    --domain default  \
    --password "$neutron_admin_password" \
    "$neutron_admin_user"

openstack role add \
    --project "$SERVICE_PROJECT_NAME" \
    --user "$neutron_admin_user" \
    "$ADMIN_ROLE_NAME"

echo "Registering neutron with keystone so that other services can locate it."
openstack service create \
    --name neutron \
    --description "OpenStack Networking" \
    network

openstack endpoint create \
    --region "$REGION" \
    "$neutron_admin_user" \
    public http://controller:9696

openstack endpoint create \
    --region "$REGION" \
    "$neutron_admin_user" \
    internal http://controller:9696

openstack endpoint create \
    --region "$REGION" \
    "$neutron_admin_user" \
    public http://controller:9696
