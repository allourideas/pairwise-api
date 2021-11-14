Pairwise 2.0 [![Build Status](https://secure.travis-ci.org/allourideas/pairwise-api.png?branch=master)](http://travis-ci.org/allourideas/pairwise-api)
-------------------

Pairwise web service 2.0.  This provides the API utilized by [photocracy.org](http://www.photocracy.org/) and [allourideas.org](http://www.allourideas.org/)

Installing
-------------------
CFLAGS="-Wno-error=implicit-function-declaration"  before rbenv install
<https://github.com/allourideas/pairwise-api/wiki/Installing>

We've installed your MySQL database without a root password. To secure it run:
mysql_secure_installation

MySQL is configured to only allow connections from localhost by default

To connect run:
mysql -uroot

To have launchd start mysql now and restart at login:
brew services start mysql
Or, if you don't want/need a background service you can just run:
mysql.server start

API Documentation
-------------------
<https://github.com/allourideas/pairwise-api/wiki/API-Documentation>

Getting Started Using the API
-------------------

<https://github.com/allourideas/pairwise-api/wiki/Using-The-API>

Email List
-------------------

If you would like to join the allourideas email list, send a message to allourideas+subscribe@googlegroups.com.
The email list is a place to ask and discuss technical questions about the project.

If you would like to send a question to the allourideas email list, send your message to allourideas@googlegroups.com.
Note that you can only post if you are already a member of the group.

If you would like to review and search previous content from the email list, visit https://groups.google.com/forum/#!forum/allourideas.

Ownership
-------------------

Copyright (c) 2010, Matthew J. Salganik and the Trustees of Princeton University. Licensed under the 3-clause BSD License, which is also known as the "Modified BSD License".  Full text of the license is below.  This license is GPL compatible (http://www.gnu.org/licenses/license-list.html#ModifiedBSD).

Code for this project has been contributed by (in chronological order): Peter Lubell-Doughtie, Adam Sanders, Pius Uzamere, Dhruv Kapadia, Calvin Lee, Chap Ambrose, Dmitri Garbuzov, Brian Tubergen, and Luke Baker.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the <organization> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL (COPYRIGHT HOLDER) BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
