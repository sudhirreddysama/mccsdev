Date.prototype.toFormattedString = function(include_time){
  var hour, str;
  str = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][this.getDay()] + ",<br />" + Date.months[this.getMonth()] + " " + this.getDate() + ", " + this.getFullYear();  
  if (include_time) { 
  	hour = this.getHours(); 
  	str += " " + this.getAMPMHour() + ":" + this.getPaddedMinutes() + " " + this.getAMPM();
  }
  return str;
}
Date.parseFormattedString = function(string) { 
	return new Date(string);
}