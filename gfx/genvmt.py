#genvmt.py
#
# generates a VMT file for a standard videogame sprite
#

#----------------------------------------------------------------------------------------
import sys, getopt

#----------------------------------------------------------------------------------------
usage = 'genvmt.py -g <game> -t <texture> -o <outfile> [-x]'

#----------------------------------------------------------------------------------------
def main(argv):
	game = ''
	texture = ''
	outputfile = ''
	transparent = False
	
	try:
		opts, args = getopt.getopt(argv,"hxg:t:o:",["help","translucent","game=","texture=","output="])
	except getopt.GetoptError:
		print "error!"
		print usage
		sys.exit(2)
	for opt, arg in opts:
		if opt in ("-h","--help"):
			print usage
			sys.exit()
		elif opt in ("-x", "--translucent"):
			transparent = True
		elif opt in ("-g", "--game"):
			game = arg
		elif opt in ("-t", "--texture"):
			texture = arg
		elif opt in ("-o", "--output"):
			outputfile = arg
		
	# quit if an argument is missing
	if game == '' or texture == '' or outputfile == '':
		print 'bad arguments'
		sys.exit(2)
		
	# poop out stuff
	print 'writing ' + outputfile + '...'
	output = open(outputfile,"w")
	output.write( '// this file generated by genvmt.py\n\n' )
	
	
	
	output.write( 'UnlitGeneric\n' )
	output.write( '{\n' )
	output.write( '    $basetexture "videogames/'+game+'/'+texture+'"\n' )
	if not transparent:
		output.write( '    $alphatest 1\n' )
	else:
		output.write( '    $translucent 1\n' )

	output.write( '    Proxies \n' )
	output.write( '    {\n' )
	output.write( '        ToggleTexture\n' )
	output.write( '        {\n' )
	output.write( '            toggleTextureVar "$basetexture"  \n' )
	output.write( '            toggleTextureFrameNumVar "$frame" \n' ) 
	output.write( '            toggleTextureShouldWrap 0 \n' )
	output.write( '        }\n' )

	output.write( '    }\n' )
	output.write( '}\n' )
	output.close()
	
	print 'done.'

#----------------------------------------------------------------------------------------
if __name__ == "__main__":
	main(sys.argv[1:])
	
	