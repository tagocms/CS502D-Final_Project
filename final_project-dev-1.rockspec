package = "Final_Project"
version = "dev-1"

source = {
   url = "git+https://github.com/tagocms/CS502D-Final_Project.git"
}
description = {
   homepage = "https://github.com/tagocms/CS502D-Final_Project",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "hump >= 0.4",
   "knife",
   
}
build = {
   type = "command",
   build_command = "love .",
   modules = { }
}
