### HOPE
##### the ultra quick progressive web-app framework

#### INSTALLATION
```
git clone https://github.com/xorgnak/hope && cd hope && chmod +x start && ./start
```

#### CONFIGURATION
Each domain has it's own configuration.  It can be accessed with the hope shell.
```
@host = DB['mydomain.com']
```
Each host is configured with it's own user, group, badge, and item container.  
It also has helpful methods to simplify actions.

#### USAGE
The hope framework is designed for direct person-to-person interactions.  

##### INTERNAL
1. First user to sign in is designated the owner of the host.
	- they may pre-create groups, badges, and items.
	- the may configure host content.
2. The owner creates an invite QR for a new user to a group.
	1. menu
	2. badge
	3. invite :arrow_right: group
3. The new user scans the new user invite QR.
4. The new user logs into the invite.
	1. create username and password.
5. The new user can now interact with their group.
6. The owner or another administrator can promote a user by scanning their badge QR or using the give tool.

##### EXTERNAL
1. A visitor scans a user's badge QR.
	1. the user earns a work token.
	2. the visitor gets a contactor form for the user or their group.
	3. the visitor may vote for the user or group in contests.
	4. the visitor may install the web-app for later usage.
2. The user gets updated when the visitor interacts with the contactor form.
3. The owner or another administrator can view productivity of group or system users.
