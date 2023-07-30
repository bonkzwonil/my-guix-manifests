(use-modules (guix packages)
						 (gnu packages)
						 (guix git-download)
						 (gnu packages image)
						 (gnu packages compression)
						 (gnu packages graphics)
						 (gnu packages gtk)
						 (gnu packages python)
						 (gnu packages video)
						 (gnu packages maths)
						 (gnu packages gcc)
						 (gnu packages photo)
						 (gnu packages gnome)
						 (gnu packages python-xyz)
						 (gnu packages protobuf)
						 (gnu packages image-processing)
						 (gnu packages pkg-config)
						 (gnu packages xorg)

						 (guix build-system cmake)
						 ((guix licenses) :prefix license:))


(define-public opencv-2
  (package
    (name "opencv")
    (version "2.4.13.6")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                     (url "https://github.com/opencv/opencv")
                     (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "00vn1c1fxqalxyx5my9wlg0d541jx8b14ajpi26xz5j8ja48l9ds"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  ;; Remove external libraries. We have all available in Guix:
                  (delete-file-recursively "3rdparty")

                  ;; Milky icon set is non-free:
                  (delete-file-recursively "modules/highgui/src/files_Qt/Milky")

                  #t))))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags
       (list "-DWITH_IPP=OFF"
             "-DWITH_ITT=OFF"
             "-DWITH_CAROTENE=OFF" ; only visible on arm/aarch64
             "-DENABLE_PRECOMPILED_HEADERS=OFF"

             ;; CPU-Features:
             ;; See cmake/OpenCVCompilerOptimizations.cmake
             ;; (CPU_ALL_OPTIMIZATIONS) for a list of all optimizations
             ;; BASELINE is the minimum optimization all CPUs must support
             ;;
             ;; DISPATCH is the list of optional dispatches.
             "-DCPU_BASELINE=SSE2"

           
             "-DBUILD_PERF_TESTS=OFF"
             "-DBUILD_TESTS=ON"

             ;;Define test data:
             (string-append "-DOPENCV_TEST_DATA_PATH=" (getcwd)
                            "/opencv-extra/testdata")

             ;; Is ON by default and would try to rebuild 3rd-party protobuf,
             ;; which we had removed, which would lead to an error:
             "-DBUILD_PROTOBUF=OFF"

             ;; Rebuild protobuf files, because we have a slightly different
             ;; version than the included one. If we would not update, we
             ;; would get a compile error later:
             "-DPROTOBUF_UPDATE_FILES=ON"

             ;; xfeatures2d disabled, because it downloads extra binaries from
             ;; https://github.com/opencv/opencv_3rdparty
             ;; defined in xfeatures2d/cmake/download_{vgg|bootdesc}.cmake
             ;; Cmp this bug entry:
             ;; https://github.com/opencv/opencv_contrib/issues/1131
             "-DBUILD_opencv_xfeatures2d=OFF")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'disable-broken-tests
           (lambda _
             ;; These tests fails with:
             ;; vtkXOpenGLRenderWindow (0x723990): Could not find a decent config
             ;; I think we have no OpenGL support with the Xvfb.
             (substitute* '("modules/viz/test/test_tutorial3.cpp"
                            "modules/viz/test/test_main.cpp"
                            "modules/viz/test/tests_simple.cpp"
                            "modules/viz/test/test_viz3d.cpp")
               (("(TEST\\(Viz, )([a-z].*\\).*)" all pre post)
                (string-append pre "DISABLED_" post)))

             ;; This one fails with "unknown file: Failure"

             #t))

         (add-after 'unpack 'unpack-submodule-sources
           (lambda* (#:key inputs #:allow-other-keys)
             (mkdir "../opencv-extra")
             (copy-recursively (assoc-ref inputs "opencv-extra")
                               "../opencv-extra")
						 #t))

         (add-after 'set-paths 'add-ilmbase-include-path
           (lambda* (#:key inputs #:allow-other-keys)
           ;; OpenEXR propagates ilmbase, but its include files do not appear
           ;; in the CPATH, so we need to add "$ilmbase/include/OpenEXR/" to
           ;; the CPATH to satisfy the dependency on "ImathVec.h".
           (setenv "CPATH"
                   (string-append (assoc-ref inputs "ilmbase")
                                  "/include/OpenEXR"
                                  ":" (or (getenv "CPATH") "")))
           #t))
       (add-before 'check 'start-xserver
         (lambda* (#:key inputs #:allow-other-keys)
           (let ((xorg-server (assoc-ref inputs "xorg-server"))
                 (disp ":1"))
             (setenv "HOME" (getcwd))
             (setenv "DISPLAY" disp)
             ;; There must be a running X server and make check doesn't start one.
             ;; Therefore we must do it.
             (zero? (system (format #f "~a/bin/Xvfb ~a &" xorg-server disp)))))))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("xorg-server" ,xorg-server-for-tests) ; For running the tests
       ("opencv-extra"
        ,(origin
           (method git-fetch)
           (uri (git-reference
                  (url "https://github.com/opencv/opencv_extra")
                  (commit version)))
           (file-name (git-file-name "opencv_extra" version))
           (sha256
            (base32 "0zmbs83rkz1fp90azs4aziwnyvfhmlxhgm4hxxjydpvl279lm4yh"))))))
    (inputs `(("libjpeg" ,libjpeg-turbo)
              ("libpng" ,libpng)
              ("jasper" ,jasper)
              ;; ffmpeg 4.0 causes core dumps in tests.
              ("ffmpeg" ,ffmpeg-3.4)
              ("libtiff" ,libtiff)
              ("hdf5" ,hdf5)
              ("libgphoto2" ,libgphoto2)
              ("libwebp" ,libwebp)
              ("zlib" ,zlib)
              ("gtkglext" ,gtkglext)
              ("openexr" ,openexr)
              ("ilmbase" ,ilmbase)
              ("gtk+" ,gtk+-2)
              ("python-numpy" ,python-numpy)
              ("protobuf" ,protobuf)
              ("vtk" ,vtk)
              ("python" ,python)))
    ;; These three CVEs are not a problem of OpenCV, see:
    ;; https://github.com/opencv/opencv/issues/10998
    (properties '((lint-hidden-cve . ("CVE-2018-7712"
                                      "CVE-2018-7713"
                                      "CVE-2018-7714"))))
    (synopsis "Computer vision library")
    (description "OpenCV is a library aimed at
real-time computer vision, including several hundred computer
vision algorithms.  It can be used to do things like:

@itemize
@item image and video input and output
@item image and video processing
@item displaying
@item feature recognition
@item segmentation
@item facial recognition
@item stereo vision
@item structure from motion
@item augmented reality
@item machine learning
@end itemize\n")
    (home-page "https://opencv.org/")
    (license license:bsd-3)))

(packages->manifest
 (list opencv-2))
						
