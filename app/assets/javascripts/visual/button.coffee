###
   Copyright (c) 2012-2015, Fairmondo eG.  This file is
   licensed under the GNU Affero General Public License version 3 or later.
   See the COPYRIGHT file for details.
###

icheck = ->
	$("input[type=checkbox]").iCheck()
	$("input[type=radio]").iCheck()

$(document).ready icheck
$(document).ajaxStop icheck
