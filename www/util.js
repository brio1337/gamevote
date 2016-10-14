module.exports.filenameToModulename = function(filename) {
  // strip the extension
  return filename.replace(/\.js$/, '');
}
