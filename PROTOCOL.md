In this scenario we have three browsers (A, B, and C) and the server.

# Creating the call

1. A would like to call B.
2. A creates a call with the server via createCall and gets back the unique call ID.

# Adding the first user

1. A requests to add B to the call.
2. B receives the request and can either accept or decline it. B accepts it.
3. B is added into the call room on the server and will receive all future messages within it.
4. A is notified via the room that B has accepted the call.
5. Begin exchange sequence between A and B.

# Adding the second user

1. A requests to add C to the call.
2. C receives the request and can either accept or decline it. C accepts it.
3. C is added into the call room on the server and will receive all future messages within it.
4. A and B are notified via the room that C has accepted the call.
5. Begin exchange sequence between A and C.
6. Begin exchange sequence between B and C.

# Exchange sequence

1. User 1 creates new PeerConnection for User 2.
2. User 2 creates new PeerConnection for User 1.
3. User 1 sends SDP offer to User 2.
4. User 2 sends SDP answer to User 1.
5. User 1 and User 2 send eachother ICE candidates at will