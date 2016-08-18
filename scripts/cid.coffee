# Description
#   A Hubot script to manage CID with brain.
#
# Configuration:
#   HUBOT_FILE_CID_PATH
#
# Commands:
#   <hubot> cid add <env> <cid> - Add CID without username(default: unused).
#   <hubot> cid add <env> <cid> <username> - Add CID with username.
#   <hubot> cid remove <env> <cid> - Remove CID.
#   <hubot> cid list <env> - Show CID list.
#   <hubot> cid list <env> <username> - Show CID list only specific user.
#   Argument is as follows.
#   <env> is 'beta' or 'beta2'.
#   <cid> is '123456789000' or '123456789000-123456789010'.
#
# Author:
#  watagashi78

Fs = require 'fs'

config =
  path: process.env.HUBOT_FILE_CID_PATH

module.exports = (robot) ->
  unless config.path?
    robot.logger.error 'process.env.HUBOT_FILE_CID_PATH is not defined'
    return

  load = ->
    if Fs.existsSync config.path
      data = JSON.parse Fs.readFileSync config.path, encoding: 'utf-8'
      robot.brain.mergeData data
    robot.brain.setAutoSave true

  save = (data) ->
    Fs.writeFileSync config.path, JSON.stringify data

  robot.brain.on 'save', save
  load()

  robot.respond /cid help$/, (msg) ->
    msg.send "Please call me as follows!"
    msg.send "<hubot> cid add <env> <cid>: Add CID without username(default: unused)."
    msg.send "<hubot> cid add <env> <cid> <username>: Add CID with username."
    msg.send "<hubot> cid remove <env> <cid>: Remove CID."
    msg.send "<hubot> cid list <env>: Show CID list."
    msg.send "<hubot> cid list <env> <username>: Show CID list only specific user."
    msg.send "Argument is as follows."
    msg.send "<env> is 'beta' or 'beta2'."
    msg.send "<cid> is '123456789000' or '123456789000-123456789010'."

  robot.respond /cid add (\S+)\ (\S+)$/, (msg) ->
    env = msg.match[1]
    cid = msg.match[2]
    user = "unused"

    if cid.match(/^\d{12}$/)
      addCid(msg.message.room, env, cid, user)
    else if cid.match(/^\d{12}-\d{12}$/)
      match = /^(\d{12})-(\d{12})$/.exec(cid)
      firstCid = match[1]
      lastCid = match[2]
      for i in [firstCid..lastCid]
        addCid(msg.message.room, env, i, user)
    else
      msg.send "Invalid CID: #{cid}"
      return

  robot.respond /cid add (\S+)\ (\S+)\ (\S+)$/, (msg) ->
    env = msg.match[1]
    cid = msg.match[2]
    user = msg.match[3]

    if cid.match(/^\d{12}$/)
      addCid(msg.message.room, env, cid, user)
    else if cid.match(/^\d{12}-\d{12}$/)
      match = /^(\d{12})-(\d{12})$/.exec(cid)
      firstCid = match[1]
      lastCid = match[2]
      for i in [firstCid..lastCid]
        addCid(msg.message.room, env, i, user)
    else
      msg.send "Invalid CID: #{cid}"
      return

  robot.respond /cid remove (\S+)\ (\S+)$/, (msg) ->
    env = msg.match[1]
    cid = msg.match[2]

    if cid.match(/^\d{12}$/)
      removeCid(msg.message.room, env, cid)
    else if cid.match(/^\d{12}-\d{12}$/)
      match = /^(\d{12})-(\d{12})$/.exec(cid)
      firstCid = match[1]
      lastCid = match[2]
      for i in [firstCid..lastCid]
        removeCid(msg.message.room, env, i)
    else
      msg.send "Invalid CID: #{cid}"
      return

  robot.respond /cid list (\S+)$/, (msg) ->
    env = msg.match[1]
    key = getKey(msg.message.room, env)
    return unless key?
    cids = robot.brain.get(key) ? []
    for index, value of cids
      msg.send "#{value.cid}: #{value.user}"

  robot.respond /cid list (\S+)\ (\S+)$/, (msg) ->
    env = msg.match[1]
    user = msg.match[2]
    key = getKey(msg.message.room, env)
    return unless key?
    cids = robot.brain.get(key) ? []
    for index, value of cids
      if value.user is user
        msg.send "#{value.cid}"

  getKey = (room, env)->
    switch env
      when "beta"  then "beta-cids"
      when "beta2" then "beta2-cids"
      else
        robot.send {room: room}, "Invalid env: #{env}"
        return

  addCid = (room, env, cid, user)->
    key = getKey(room, env)
    return unless key?
    cids = robot.brain.get(key) ? []
    input = { cid: cid.toString(), user: user }

    exist = false
    for index, value of cids
      if value.cid is input.cid
        exist = true
        if value.user isnt input.user
          robot.send {room: room}, "Update #{cid}@#{env}: #{value.user} -> #{input.user}"
          value.user = input.user
        else
          robot.send {room: room}, "Not changed #{cid}@#{env}: #{user}"
    if exist is false
      cids.push input
      robot.brain.set(key, cids)
      robot.send {room: room}, "Add #{cid}@#{env}: #{user}"

  removeCid = (room, env, cid)->
    key = getKey(room, env)
    return unless key?
    cids = robot.brain.get(key) ? []

    exist = false
    for index, value of cids
      if value.cid is cid.toString()
        exist = true
        cids.splice(index, 1)
        robot.send {room: room}, "Removed: #{cid}@#{env}"
    if exist is false
      robot.send {room: room}, "Not exist: #{cid}@#{env}"

