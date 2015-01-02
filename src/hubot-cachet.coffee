# Description:
#   Hubot Cachet API client
#
# Configuration:
#   HUBOT_CACHET_API_URL = http://cachet.dev
#   HUBOT_CACHET_API_USERNAME = me@example.com
#   HUBOT_CACHET_API_PASSWORD = supersecretpassword
#   
# Commands:
#   hubot cachet components list - list all the components and their status
#   hubot cachet incidents list - list all the incidents and their status
#   hubot cache incident add <name>, <status>, <message> - add a new incident (commas are important!)

cachetURL = process.env.HUBOT_CACHET_API_URL

moment = require('moment')

module.exports = (robot) ->

  createCredential = ->
    cachetUser = process.env.HUBOT_CACHET_API_USERNAME
    cachetPass = process.env.HUBOT_CACHET_API_PASSWORD
    if cachetUser && cachetPass
      auth = 'Basic ' + new Buffer(cachetUser + ':' + cachetPass).toString('base64');
    else
      auth = null
    auth

  robot.respond /cachet help/i, (msg) ->
    cmds = robot.helpCommands()
    cmds = (cmd for cmd in cmds when cmd.match(/(cachet)/))
    msg.send cmds.join("\n")

  robot.respond /cachet components list/i, (msg) ->
    req = robot.http(cachetURL + '/api/components')
    req
      .get() (err, res, body) ->
        if err
          msg.send "Problem accessing the Cachet API"
          return
        if res.statusCode is 200
          results = JSON.parse(body)
          if results.data results.data.length > 0
            output = []
            for result,value of results.data
              message = "Component: " + value['name'] + " -- Status: " + value['status'] + " -- Updated at: " + moment.unix(value['updated_at']).format('HH:MM YYYY/MM/DD')
              output.push message
            msg.send output.sort().join('\n')
           else
            msg.send "No components defined"
        else
          msg.send "An error occurred listing the components (#{res.statusCode}: #{body})"

  robot.respond /cachet incidents list/i, (msg) ->
    req = robot.http(cachetURL + '/api/incidents')
    req
      .get() (err, res, body) ->
        if err
          msg.send "Problem accessing the Cachet API"
          return
        if res.statusCode is 200
          results = JSON.parse(body)
          if results.data && results.data.length > 0
            output = []
            for result, value of results.data
              message = "Incident: " + value['name'] + " -- Current Status: " + value['human_status'] + " -- Started at: " + moment.unix(value['created_at']).format('HH:MM YYYY/MM/DD') + " -- Last Updated: " + moment.unix(value['updated_at']).format('HH:MM YYYY/MM/DD')
              output.push message
            msg.send output.sort().join('\n')
          else
            msg.send "No incidents"
        else
          msg.send "An error occurred listing the incidents (#{res.statusCode}: #{body})"


  robot.respond /cachet incident add (.*), (.*), (.*)/i, (msg) ->
    title = msg.match[1]
    progress = msg.match[2].toLowerCase()
    message = msg.match[3]

    switch progress
      when "investigating" then progress_real = 1
      when "identified" then progress_real = 2
      when "watching" then progress_real = 3
      when "fixed" then progress_real = 4
      else 
        msg.send "Please provide a valid status from: Indentified, Investigating, Watching or Fixed"

    postData = {}
    postData['name'] = title
    postData['message'] = message
    postData['status'] = progress_real

    console.log postData

    if title && progress_real && message
      credential = createCredential()
      req = robot.http(cachetURL + '/api/incidents')
      req = req.headers(Authorization: credential )
      req
        .header('Content-Type', 'application/json')
        .post(JSON.stringify(postData)) (err, res, body) ->
          if res.statusCode is 200
            msg.send "Incident added!"
          else
            msg.send "Error adding incident - returned statuscode #{res.statusCode}"
    else
      msg.send "You didn't give me enough info to create the incident"


    
