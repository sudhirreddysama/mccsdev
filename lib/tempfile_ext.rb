class TempfileExt < Tempfile
	
	def make_tmpname(basename, n)
		ext = File::extname(basename)
		sprintf('%s%d-%d%s', File::basename(basename, ext), $$.to_i, n.to_i, ext)
	end
	
end