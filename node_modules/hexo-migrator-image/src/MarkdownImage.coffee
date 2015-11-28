# downloader = require('./downloader')

module.exports = class Image
  constructor: (@alt, @url, @opt) ->
    @localPath = ""
    @skipped = false
  download: (downloader, callback) ->
    downloader.download @, (err, succ) =>
      @localPath = succ
      callback?(err, succ)
