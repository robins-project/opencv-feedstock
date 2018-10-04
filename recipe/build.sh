#!/usr/bin/env bash

set +x
SHORT_OS_STR=$(uname -s)

QT="5"
if [ "${SHORT_OS_STR:0:5}" == "Linux" ]; then
    OPENMP="-DWITH_OPENMP=1"
    # Looks like there's a bug in Opencv 3.2.0 for building with FFMPEG
    # with GCC opencv/issues/8097
    export CXXFLAGS="$CXXFLAGS -D__STDC_CONSTANT_MACROS"
fi
if [ "${SHORT_OS_STR}" == "Darwin" ]; then
    OPENMP=""
    QT="0"
fi

CUDA="0"
if [ "$cuda_impl" == "cuda" ]; then
    CUDA="1"
    # build with c++11
    export CXXFLAGS=$(echo $CXXFLAGS | sed "s/-std=c++17/-std=c++11/")
fi
export CFLAGS="$CFLAGS -idirafter /usr/include"
export CXXFLAGS="$CXXFLAGS -idirafter /usr/include"
export LDFLAGS="$LDFLAGS -fuse-ld=gold"

mkdir -p build
cd build

if [ $PY3K -eq 1 ]; then
    PY_MAJOR=3
    PY_UNSET_MAJOR=2
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}m${SHLIB_EXT}"
    INC_PYTHON="$PREFIX/include/python${PY_VER}m"
else
    PY_MAJOR=2
    PY_UNSET_MAJOR=3
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}${SHLIB_EXT}"
    INC_PYTHON="$PREFIX/include/python${PY_VER}"
fi


PYTHON_SET_FLAG="-DBUILD_opencv_python${PY_MAJOR}=1"
PYTHON_SET_EXE="-DPYTHON${PY_MAJOR}_EXECUTABLE=${PYTHON}"
PYTHON_SET_INC="-DPYTHON${PY_MAJOR}_INCLUDE_DIR=${INC_PYTHON} "
PYTHON_SET_NUMPY="-DPYTHON${PY_MAJOR}_NUMPY_INCLUDE_DIRS=${SP_DIR}/numpy/core/include"
PYTHON_SET_LIB="-DPYTHON${PY_MAJOR}_LIBRARY=${LIB_PYTHON}"
PYTHON_SET_SP="-DPYTHON${PY_MAJOR}_PACKAGES_PATH=${SP_DIR}"

PYTHON_UNSET_FLAG="-DBUILD_opencv_python${PY_UNSET_MAJOR}=0"
PYTHON_UNSET_EXE="-DPYTHON${PY_UNSET_MAJOR}_EXECUTABLE="
PYTHON_UNSET_INC="-DPYTHON${PY_UNSET_MAJOR}_INCLUDE_DIR="
PYTHON_UNSET_NUMPY="-DPYTHON${PY_UNSET_MAJOR}_NUMPY_INCLUDE_DIRS="
PYTHON_UNSET_LIB="-DPYTHON${PY_UNSET_MAJOR}_LIBRARY="
PYTHON_UNSET_SP="-DPYTHON${PY_UNSET_MAJOR}_PACKAGES_PATH="

# FFMPEG building requires pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

# cmake -G "$CMAKE_GENERATOR"                                             \
cmake -G "Ninja"                                                          \
    -DCMAKE_BUILD_TYPE="Release"                                          \
    -DCMAKE_PREFIX_PATH=${PREFIX}                                         \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}                                      \
    -DCMAKE_INSTALL_LIBDIR="lib"                                          \
    -DCMAKE_LIBRARY_PATH=${PREFIX}/lib                                    \
    $OPENMP                                                               \
    -DWITH_EIGEN=1                                                        \
    -DBUILD_TESTS=0                                                       \
    -DBUILD_DOCS=0                                                        \
    -DBUILD_PERF_TESTS=0                                                  \
    -DBUILD_ZLIB=0                                                        \
    -DHDF5_ROOT=${PREFIX}                                                 \
    -DBUILD_TIFF=0                                                        \
    -DBUILD_PNG=0                                                         \
    -DBUILD_OPENEXR=1                                                     \
    -DBUILD_JASPER=0                                                      \
    -DBUILD_JPEG=0                                                        \
    -DBUILD_JAVA=0                                                        \
    -DBUILD_PROTOBUF=1                                                    \
    -DWITH_CUDA=$CUDA                                                     \
    -DWITH_OPENGL=1                                                       \
    -DWITH_OPENNI=0                                                       \
    -DWITH_FFMPEG=1                                                       \
    -DWITH_GSTREAMER=0                                                    \
    -DWITH_MATLAB=0                                                       \
    -DWITH_VTK=0                                                          \
    -DWITH_GTK=0                                                          \
    -DWITH_QT=$QT                                                         \
    -DWITH_GPHOTO2=0                                                      \
    -DWITH_TBB=1                                                          \
    -DINSTALL_C_EXAMPLES=0                                                \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"               \
    -DCMAKE_SKIP_RPATH:bool=ON                                            \
    -DPYTHON_PACKAGES_PATH=${SP_DIR}                                      \
    -DPYTHON_EXECUTABLE=${PYTHON}                                         \
    -DPYTHON_INCLUDE_DIR=${INC_PYTHON}                                    \
    -DPYTHON_LIBRARY=${LIB_PYTHON}                                        \
    $PYTHON_SET_FLAG                                                      \
    $PYTHON_SET_EXE                                                       \
    $PYTHON_SET_INC                                                       \
    $PYTHON_SET_NUMPY                                                     \
    $PYTHON_SET_LIB                                                       \
    $PYTHON_SET_SP                                                        \
    $PYTHON_UNSET_FLAG                                                    \
    $PYTHON_UNSET_EXE                                                     \
    $PYTHON_UNSET_INC                                                     \
    $PYTHON_UNSET_NUMPY                                                   \
    $PYTHON_UNSET_LIB                                                     \
    $PYTHON_UNSET_SP                                                      \
    -DOPENGL_egl_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so              \
    -DOPENGL_glu_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLU.so              \
    -DOPENGL_glx_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLX.so              \
    -DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so        \
    -DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so                \
    -D OpenGL_GL_PREFERENCE=GLVND                                         \
    ..

ninja install