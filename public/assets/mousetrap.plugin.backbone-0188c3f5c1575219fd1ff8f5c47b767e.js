!function(e,t,n){"use strict";var i=t.View.prototype.delegateEvents,r=t.View.prototype.undelegateEvents,o=t.View.prototype.remove,s={};e.extend(t.View.prototype,{keyboardEvents:{},bindKeyboardEvents:function(t){if(t||(t=e.result(this,"keyboardEvents"))){for(var i in t){var r=t[i];if(e.isFunction(r)||(r=this[t[i]]),!r)throw new Error('Method "'+t[i]+'" does not exist');r=e.bind(r,this),"bindGlobal"in n&&(-1!==i.indexOf("mod")||-1!==i.indexOf("command")||-1!==i.indexOf("ctrl"))?n.bindGlobal(i,r):n.bind(i,r),s[i]=this}return this}},unbindKeyboardEvents:function(){for(var e in this.keyboardEvents)s[e]===this&&(n.unbind(e),delete s[e]);return this},delegateEvents:function(){var e=i.apply(this,arguments);return this.bindKeyboardEvents(),e},undelegateEvents:function(){var e=r.apply(this,arguments);return this.unbindKeyboardEvents&&this.unbindKeyboardEvents(),e},remove:function(){var e=o.apply(this,arguments);return this.unbindKeyboardEvents&&this.unbindKeyboardEvents(),e}})}(_,Backbone,Mousetrap);