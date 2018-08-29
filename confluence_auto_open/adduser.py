#!/usr/bin/python
#
# File Name: AddUser.py
# Purpose: Sets up a user login and gives the user a personal space
#
# Notes:
#   All rights management is also done
#   User added to confluence-users
#   No command-line or gui as of yet - just edit top parameters and run
#
#   To use this file you first need to change some things like the
#   address format, the URL to the wiki, and the space key used for
#   the user's page.
#
#   This should really just be a starting point for people to work with.
#
# File History:
# 06-03-01 russ  Created file
 
import xmlrpclib
import sys 
# ****** EDIT THESE NEXT PARAMETERS ******
userName = sys.argv[1]
fullName = userName
# ****** END OF PARAMETERS TO EDIT!! *****
 
wikiURL = "http://1.1.1.1:8090"
s = xmlrpclib.ServerProxy(wikiURL + "/rpc/xmlrpc")
 
#log in as admin...
print "Logging in..."
token = s.confluence1.login("admin", "xxxxxxxxx")
 
#add the user...
if not s.confluence1.hasUser(token, userName):
  print "Adding user '%s'..." % userName
  userDef = dict(email = "%s@6666.com" % (userName,),
                 fullname = fullName,
                 name = userName,
                 url = wikiURL + "/display/~%s" % (userName,)
                 )
  password = sys.argv[2]
  s.confluence1.addUser(token, userDef, password)
else:
  print "User '%s' already exists!" % userName
 
