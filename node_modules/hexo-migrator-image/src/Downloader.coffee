fs = require 'fs'
Url = require 'url'
Path = require 'path'
crypto = require 'crypto'
colors = require 'colors'
file = require 'hexo-fs'

# Add future protocol extensions here
protocols =
  'http:': require 'http'
  'https:': require 'https'

isLocalUrl = (url) ->
  return fs.existsSync(url)

isRemoteUrl = (url) ->
  return /\w+:\/\//.exec(url)?

defaultFileName = (path) ->
  u = Url.parse(path)
  shasum = crypto.createHash('sha1').update(u.href)
  ext = Path.extname(u.path)
  digest = shasum.digest('hex')

  return digest + ext


module.exports = class Downloader
  constructor: (@imageFolder) ->

  download: (img, callback) ->
    # TODO: download
    url = img.url
    fileName = defaultFileName url
    to = @imageFolder + fileName
    console.log "FILE ".blue + "GET".yellow + " %s", url
    # Skip downloaded
    if fs.existsSync(to)
      console.log("SKIP".green + " %s", fileName)
      callback?(null, fileName)
      return

    isLocal = isLocalUrl(url)
    isRemote = isRemoteUrl(url)

    if isLocal
      @copyLocalImage url, fileName, (err, succ) ->
        img.localPath = succ
        callback?(err, succ)
    else if isRemote
      @downloadRemoteImage url, fileName, (err, succ) ->
        img.localPath = succ
        callback?(err, succ)
    else
      console.log "SKIP".grey + " %s", url
      img.localPath = url
      img.skipped = true
      callback?(null, url)


  downloadRemoteImage: (from, fileName, callback) ->
    to = Path.resolve @imageFolder, fileName
    protocol_name = Url.parse(from).protocol
    protocol = protocols[protocol_name]
    console.log protocol_name
    if not protocol?
      err = new Error("Unsupported protocol '#{protocol_name}'")
      return callback?(err, fileName)

    request = protocol.get(from, ((response) ->
      if (response.statusCode == 200)
        msg = "#{protocol_name} ".blue + "%d ".green + "%s"
        console.log msg, response.statusCode, from

        ws = fs.createWriteStream(to)
          .on("error", (err) -> callback?(err, fileName))
          .on("close", ((err) ->
            console.log("SAVE".green + " %s", to)
            callback?(null, fileName)))

        response.pipe(ws)
      else
        msg = "HTTP ".blue + "%d ".red.blue + "%s"
        console.log msg, response.statusCode, from
        callback?(new Error("HTTP " + response.statusCode), fileName)

        ))
        .on("error", (err) ->
          console.log(err.message)
          callback(err, fileName)
        )


  copyLocalImage: (from, fileName, callback) ->
    to = Path.resolve @imageFolder, fileName
    console.log "COPY ".blue + "FROM ".yellow + "%s", from
    ws = fs.createWriteStream(to)
        .on("error", ((err) ->
          console.log "COPY ".blue + "ErrW ".green + "%s", to
          callback?(err, fileName)))
        .on("close", ((err) ->
          console.log "COPY ".blue + "DONE ".green + "%s", to
          callback?(null, fileName)))
    rs = fs.createReadStream(from)
        .on("error", ((err) ->
          console.log "COPY ".blue + "ErrR ".green + "%s", from
          callback?(err, fileName)))
        .pipe(ws)
