ARG R_VERSION=4.3.0
ARG BASE_IMAGE=r-base:${R_VERSION}
FROM ${BASE_IMAGE}

# Install prerequisite OS packages
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        curl \
        libdap-dev \
        libopenmpi-dev \
        libudunits2-dev \
    && apt-get clean \
    && apt-get autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

# Download and build custom parallel hdf5 library
ARG HDF5_VERSION=1.12.2
ARG HDF5_VERSION_SHORT=1.12
RUN curl -s https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION_SHORT}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.bz2 \
    | tar -xj -C /usr/local/src/ && \
    cd /usr/local/src/hdf5-${HDF5_VERSION} && \
    ./configure --prefix=/usr/local --enable-parallel --enable-threadsafe --enable-unsupported && make install && ldconfig

# Download build custom parallel netcdf library
# CPATH is needed as mpi header files from the package manager is not in a standard location.
#  Another option might be to ask the MPI library, eg. `mpicc -showme:compile`, but this add other flags than just he include path
#  which may not be desireable
#
# Note: There is no specific way to tell configure which HDF5 library to use, we can only infulence it by making sure it's on the inc/lib paths
#       and having it in /usr/local/lib does the trick. It's likely that other hdf5 libraries have been installed as a dependency of some
#       other package by the package manager (eg. libgdal-dev) but they don't get in the way of downstream builds from source - so all good.
ARG NETCDF_VERSION=4.8.1
RUN curl -L -s https://github.com/Unidata/netcdf-c/archive/refs/tags/v${NETCDF_VERSION}.tar.gz \
    | tar -xz -C /usr/local/src/ && \
    cd /usr/local/src/netcdf-c-${NETCDF_VERSION}/ && \
    export CPATH=/usr/lib/x86_64-linux-gnu/openmpi/include && \
    ./configure --prefix=/usr/local && \
    make install && ldconfig

# Install OS packages that depend on the hdf5 or netcdf libraries
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install --no-install-recommends -y \
        nco \
    && apt-get clean \
    && apt-get autoremove --purge \
    && rm -rf /var/lib/apt/lists/*


# Install R library packages
ARG MRAN=https://cran.rstudio.com/
ENV MRAN=${MRAN}

ARG R_LIBRARIES="dplyr ncdf4 tidync"
RUN for R_LIB in $R_LIBRARIES; do R -q -e "install.packages('${R_LIB}', repos='${MRAN}')"; done

# Install the custom test script, and prepare to run it on startup
WORKDIR /app
COPY * .

ENTRYPOINT ["Rscript"]
CMD [""]
