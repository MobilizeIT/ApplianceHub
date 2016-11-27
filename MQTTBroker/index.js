var mosca = require('mosca');
var mysql = require('mysql');
var myKeyPath = 'certs/selfsigned/server-key.pem';
var myCertPath = 'certs/selfsigned/server-cert.pem';
var JSONstr = '';
var q = '';

var connection = mysql.createConnection({
		host : 'localhost',
		user : 'root',
		password : '',
		database : 'appliancehub'
});
	
connection.connect(function (err) {
	if (err) {
		console.error('error connecting: ' + err.stack);
		return;
	}
	console.log('Connected to MySql as id ' + connection.threadId);
});

var authenticate = function (client, username, password, callback) {
	if (typeof(username) != "undefined") {
		if (username.charAt(6) == '#') {
			if (username.substring(0, 6) == "signup") {
				client.user = username.substring(7, username.length);
				client.user2 = username.substring(7, username.length);
				callback(null, true);
			} else {
				callback(null, false);
			}
		} else if (username.charAt(3) == '#') {
			var type = username.substring(0, 3);
			var sn = username.substring(4, username.length);
			q = 'SELECT ad.owner FROM appliancemaster am, appliancedetail ad WHERE ad.applianceserial = ' + mysql.escape(sn) + ' AND ad.applianceid = am.applianceid AND am.applianceid = ' + mysql.escape(type) + ' AND ad.password = ' + mysql.escape(password.toString()) + ';';
			connection.query(q, function (err, rows) {
				if (err) {
					callback(null, false);
				} else if (rows.length !== 0 && rows[0].owner !== null && rows[0].owner !== '') {
					client.user = rows[0].owner;
					client.user2 = sn;
					callback(null, true);
				} else
					callback(null, false);
			});
		} else {
			q = 'SELECT username FROM user WHERE username = ' + mysql.escape(username.toString()) + ' AND password = ' + mysql.escape(password.toString());
			connection.query(q, function (err, rows) {
				if (err) {
					callback(null, false);
				} else if (rows.length !== 0) {
					client.user = username;
					client.user2 = username;
					JSONstr = '{"msg":"loginStatus","status":"SUCCESS"}';
					encodeReply(JSONstr, "/general/" + username);
					callback(null, true);
				} else {
					JSONstr = '{"msg":"loginStatus","status":"FAIL"}';
					encodeReply(JSONstr, "/general/" + username);
					callback(null, false);
				}
			});
		}
	} else {
		callback(null, false);
	}
};
var authorizePublish = function (client, topic, payload, callback) {
	callback(null, client.user == topic.split('/')[2] || client.user2 == topic.split('/')[2] || "lwt" == topic.split('/')[1]);
};
var authorizeSubscribe = function (client, topic, callback) {
	callback(null, client.user == topic.split('/')[2] || client.user2 == topic.split('/')[2] || "lwt" == topic.split('/')[1]);
};
var ascoltatore = {
	type : 'mqtt',
	mqtt : require('mqtt'),
	host : '127.0.0.1',
	port : 1880
};
var moscaSettings = {
	backend : ascoltatore,
	secure : {
		port : 1883,
		keyPath : myKeyPath,
		certPath : myCertPath
	}
};
var server = new mosca.Server(moscaSettings);
server.on('ready', function () {
	console.log('Appliance Hub server is up and running');
	server.authenticate = authenticate;
	server.authorizeSubscribe = authorizeSubscribe;
	server.authorizePublish = authorizePublish;
});
server.on('clientConnected', function (client) {
	console.log('Client connected', client.id);
});
function encodeReply(JSONstring, tpc) {
	var rply = {
		topic : tpc,
		payload : JSONstring,
		qos : 1,
		retain : false
	};
	server.publish(rply);
	console.log("Server published " + JSONstring + " to " + tpc);
}
server.on('published', function (packet, client) {
	var packetOverhead = packet.topic.substring(0, 4);
	if (packetOverhead != "$SYS") {
		if (typeof client != "undefined") {
			console.log("Server received " + packet.payload.toString() + " at " + packet.topic + " from " + client.id);
		}
		try {
			var JSONmsg = JSON.parse(packet.payload);
		} catch (e) {
			return console.error(e);
		}
		if (JSONmsg.msg == "signup") {
			q = 'INSERT INTO user VALUES ("' + JSONmsg.username + '","' + JSONmsg.password + '","' + JSONmsg.fullname + '","' + JSONmsg.email + '","' + JSONmsg.phone + '");';
			connection.query(q, function (err, rows) {
				if (err) {
					JSONstr = '{"msg":"signupStatus","status":"FAIL"}';
					encodeReply(JSONstr, packet.topic);
					return console.error(err);
				} else {
					if (rows.affectedRows == 1) {
						JSONstr = '{"msg":"signupStatus","status":"SUCCESS"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.affectedRows != 1) {
						JSONstr = '{"msg":"signupStatus","status":"FAIL"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "getOwner") {
			q = 'SELECT owner FROM appliancedetail WHERE applianceserial = "' + JSONmsg.applianceserial + '";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.length > 0) {
						JSONstr = '{"msg":"owner","owner":"' + rows[0].owner + '"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.length === 0) {
						JSONstr = '{"msg":"owner","owner":"NOTFOUND"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
			q = 'UPDATE appliancedetail SET status = "ACTIVE" WHERE applianceserial = "' + JSONmsg.applianceserial + '";';
			connection.query(q, function (err, rows) {
				if (err)
					throw err;
			});
		} else if (JSONmsg.msg == "getMyAppliance") {
			q = 'SELECT applianceid, applianceserial,nickname,status FROM appliancedetail WHERE owner="' + JSONmsg.owner + '" ORDER BY nickname ASC;';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.length > 0) {
						JSONstr = '{"msg":"myAppliance","dat":[';
						for (n = 0; n < rows.length; n++) {
							if (n == rows.length - 1) {
								JSONstr += '{"applianceserial":"' + rows[n].applianceserial + '","applianceid":"' + rows[n].applianceid + '","nickname":"' + rows[n].nickname + '","status":"' + rows[n].status + '"}]}';
							} else {
								JSONstr += '{"applianceserial":"' + rows[n].applianceserial + '","applianceid":"' + rows[n].applianceid + '","nickname":"' + rows[n].nickname + '","status":"' + rows[n].status + '"},';
							}
						}
						encodeReply(JSONstr, packet.topic);
					} else if (rows.length === 0) {
						JSONstr = '{"msg":"myAppliance","dat":"NOTFOUND"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "registerMyAppliance") {
			q = 'UPDATE appliancedetail SET owner = "' + JSONmsg.owner + '" WHERE applianceserial = "' + JSONmsg.applianceserial + '" AND owner = "";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.changedRows == 1) {
						JSONstr = '{"msg":"registrationStatus","status":"SUCCESS"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.changedRows != 1) {
						JSONstr = '{"msg":"registrationStatus","status":"FAIL"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "unregisterMyAppliance") {
			q = 'UPDATE appliancedetail SET owner = "" WHERE applianceserial = "' + JSONmsg.applianceserial + '" AND owner = "' + JSONmsg.owner + '" AND  (SELECT 1 FROM user WHERE username = "' + JSONmsg.owner + '" and password = "' + JSONmsg.password + '");';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.changedRows == 1) {
						JSONstr = '{"msg":"unregisterStatus","status":"SUCCESS"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.changedRows != 1) {
						JSONstr = '{"msg":"unregisterStatus","status":"FAIL"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "getProfile") {
			q = 'SELECT username,name,email,phonenumber FROM user WHERE username = "' + JSONmsg.username + '" AND password = "' + JSONmsg.password + '";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				if (rows.length > 0) {
					JSONstr = '{"msg":"myProfile","username":"' + rows[0].username + '","fullname":"' + rows[0].name + '","email":"' + rows[0].email + '","phone":"' + rows[0].phonenumber + '"}';
					encodeReply(JSONstr, packet.topic);
				} else if (rows.length === 0) {
					JSONstr = '{"msg":"myProfile","username":"NOTFOUND"}';
					encodeReply(JSONstr, packet.topic);
				}
			});
		} else if (JSONmsg.msg == "updateProfile") {
			q = 'UPDATE user SET name = "' + JSONmsg.fullname + '",email = "' + JSONmsg.email + '", phonenumber = "' + JSONmsg.phone + '" WHERE username = "' + JSONmsg.username + '" AND password = "' + JSONmsg.password + '";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.changedRows == 1) {
						JSONstr = '{"msg":"updateProfileStatus","status":"SUCCESS"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.changedRows != 1) {
						JSONstr = '{"msg":"updateProfileStatus","status":"FAIL"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "updatePassword") {
			q = 'UPDATE user SET password = "' + JSONmsg.newpassword + '" WHERE username = "' + JSONmsg.username + '" AND password = "' + JSONmsg.oldpassword + '";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.changedRows == 1) {
						JSONstr = '{"msg":"updatePasswordStatus","status":"SUCCESS"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.changedRows != 1) {
						JSONstr = '{"msg":"updatePasswordStatus","status":"FAIL"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "renameAppliance") {
			q = 'UPDATE appliancedetail SET nickname = "' + JSONmsg.nickname + '" WHERE applianceserial = "' + JSONmsg.applianceserial + '" AND owner = "' + JSONmsg.owner + '";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.changedRows == 1) {
						JSONstr = '{"msg":"renameStatus","status":"SUCCESS"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.changedRows != 1) {
						JSONstr = '{"msg":"renameStatus","status":"FAIL"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "getStatus") {
			q = 'SELECT status FROM appliancedetail WHERE applianceserial = "' + JSONmsg.applianceserial + '" AND owner = "' + JSONmsg.owner + '";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.length > 0) {
						JSONstr = '{"msg":"applianceStatus","status":"' + rows[0].status + '"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.length === 0) {
						JSONstr = '{"msg":"applianceStatus","status":"NOTFOUND"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "getLog") {
			q = 'SELECT UNIX_TIMESTAMP(r.rtimestamp) AS rtimestamp,r.rprt FROM command c, report r WHERE c.applianceserial = "' + JSONmsg.applianceserial + '" AND c.owner = "' + JSONmsg.owner + '" AND r.commandid = c.commandid ORDER BY c.ctimestamp DESC;';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.length > 0) {
						JSONstr = '{"msg":"reportLog","dat":[';
						for (n = 0; n < rows.length; n++) {
							if (n == rows.length - 1) {
								JSONstr += '{"rtimestamp":' + rows[n].rtimestamp + ',"rprt":"' + rows[n].rprt + '"}]}';
							} else {
								JSONstr += '{"rtimestamp":' + rows[n].rtimestamp + ',"rprt":"' + rows[n].rprt + '"},';
							}
						}
						encodeReply(JSONstr, packet.topic);
					} else if (rows.length === 0) {
						JSONstr = '{"msg":"reportLog","dat":"NOTFOUND"}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else if (JSONmsg.msg == "offline") {
			q = 'UPDATE appliancedetail SET status = "INACTIVE" WHERE applianceserial = "' + JSONmsg.applianceserial + '";';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
			});
		} else if (JSONmsg.msg == "boardStatus" && typeof client != "undefined") {
			q = 'INSERT INTO report (rtimestamp,applianceserial,rprt,commandid) VALUES ("' + JSONmsg.rtimestamp + '","' + JSONmsg.applianceserial + '","' + mysql.escape(JSON.stringify(JSONmsg)) + '",'+JSONmsg.cmdid+');';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				if(JSONmsg.cmdid!=0){
					q = 'UPDATE command SET ctimestamp = "' + JSONmsg.rtimestamp + '" WHERE commandid = ' + JSONmsg.cmdid + ';';
					connection.query(q, function (err, rows) {
					if (err)
						return console.error(err);
					});
				}
			});
		} else if (JSONmsg.msg == "getBoardStatus") {
			q = 'SELECT UNIX_TIMESTAMP(r.rtimestamp) AS rtimestamp,r.rprt FROM report r, appliancedetail ad WHERE r.applianceserial = "' + JSONmsg.applianceserial + '" AND ad.applianceserial = r. applianceserial AND ad.owner = "'+ JSONmsg.owner +'" ORDER BY rtimestamp DESC;';
			connection.query(q, function (err, rows) {
				if (err)
					return console.error(err);
				else {
					if (rows.length > 0) {
						JSONstr = rows[0].rprt.replace(/'/g, '');
						encodeReply(JSONstr, packet.topic);
					} else if (rows.length === 0) {
						JSONstr = '{"msg":"boardStatus","rtimestamp":"yyyy-mm-dd hh:mm:ss","applianceserial":"' + JSONmsg.applianceserial + '","upint":1,"cmdid":0,"dinputs":[0,0,0,0,0,0,0],"doutputs":[0,0,0,0,0,0],"ainputs":[0,0,0,0]}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});

		} else if(JSONmsg.msg == "setBoardUpdateInterval" || JSONmsg.msg == "setPinOutput"){
				q = 'INSERT INTO command (applianceserial,cmd,owner) VALUES ("' + JSONmsg.applianceserial + '","' + mysql.escape(JSON.stringify(JSONmsg)) + '","' + JSONmsg.owner + '");';
				connection.query(q, function (err, rows) {
					if (err)
					return console.error(err);
				else {
					if (rows.affectedRows == 1) {
						JSONstr = '{"msg":"cmdid","applianceserial":"' + JSONmsg.applianceserial + '","cmdid":"' + rows.insertId + '"}';
						encodeReply(JSONstr, packet.topic);
					} else if (rows.affectedRows != 1) {
						JSONstr = '{"msg":"cmdid","applianceserial":"' + JSONmsg.applianceserial + '","cmdid":-1}';
						encodeReply(JSONstr, packet.topic);
					}
				}
			});
		} else {
			if (typeof client != "undefined") {
				console.log("Received undefined message : " + packet.payload.toString() + " on " + packet.topic);
			}
		}
	}
});
