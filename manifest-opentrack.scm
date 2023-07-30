(use-modules (guix packages)
						 (gnu packages)
						 (gnu packages kde)
						 (gnu packages qt)
						 (guix git-download)
						 (guix build-system cmake)
						 (guix licenses))

(let* ((otversion "2023.1.02")
			 (opentrack
	
			 (package
				(name "opentrack")
				(version otversion)
				(source (origin
								 (method git-fetch)
								 (uri (git-reference
											 (url "https://github.com/opentrack/opentrack.git")
											 (commit "cdabb9f3ad3e13e3b76b983a7b3ea6c118fc114e")))
								 ;(file-name (git-file-name name version))
                 (sha256
									(base32
                   "1kx87q0yyzhl6ab8fjikyrl64r5s9vni37l7lrnj7da9184i3bvd"))))
				(build-system cmake-build-system)
				(arguments '())
				(inputs (list qtbase-5 qttools-5))
				(synopsis "Hello, GNU world: An example GNU package")
				(description "Guess what GNU Hello prints!")
				(home-page "https://www.gnu.org/software/hello/")
				(license gpl3+))))
	

	(packages->manifest
	 (list opentrack)))
						
