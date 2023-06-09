ARG R_VERSION=4.3.0
ARG BASE_IMAGE=r-base:${R_VERSION}
FROM ${BASE_IMAGE}

# Install prerequisite OS packages
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        wget \
    && apt-get clean \
    && apt-get autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

#------------------------------------------------------------------------------
# Optionally install netCDF-C and supporting libs from source.
# (this lets us control exactly which versions regardless of OS package.
# Make sure R know about those versions at runtime.
#------------------------------------------------------------------------------
ARG NETCDF_VERSION=""
WORKDIR /app

# libcurl and curl:
# Instructions: https://curl.se/docs/install.html
# Versions: https://github.com/curl/curl/releases
# prerequisites: libssl
ARG CURL_VERSION=""
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${CURL_VERSION}" ]]; then \
      apt-get update \
      && apt-get install --no-install-recommends -y libssl-dev \
      && apt-get purge curl libcurl4-openssl-dev -y \
      && apt-get autoremove -y; \
    elif [ -n "${NETCDF_VERSION}" ]; then \
      apt-get update \
      && apt-get install --no-install-recommends -y libcurl4-openssl-dev curl; \
    else \
      apt-get update \
      && apt-get install --no-install-recommends -y curl; \
    fi
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${CURL_VERSION}" ]]; then \
      wget -O - "https://github.com/curl/curl/releases/download/curl-$(echo "${CURL_VERSION}" | tr '.' '_')/curl-${CURL_VERSION}.tar.gz"  | tar -xz -C /usr/local/src/ \
      && cd /usr/local/src/curl-${CURL_VERSION}/ \
      && ./configure --prefix=/usr/local --with-openssl \
      && make \
      && make install \
      && ldconfig; \
    fi
RUN echo "CURL_VERSION='$(curl --version | head -n 1)'" >> .NcLibs
RUN echo "CURLOPT_VERBOSE=1" >> .Renviron

# libdap
# Instructions: https://github.com/OPENDAP/libdap/blob/master/INSTALL
# Versions: https://www.opendap.org/software/libdap
# Prerequisites: libxml2, libz. See https://www.opendap.org/allsoftware/third-party
ARG DAP_VERSION=""
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${DAP_VERSION}" ]]; then \
      apt-get update \
      && apt-get install --no-install-recommends -y libxml2-dev zlib1g-dev \
      && apt-get purge curl libdap-dev -y \
      && apt-get autoremove -y; \
    else \
      apt-get update \
      && apt-get install --no-install-recommends -y libdap-dev \
      && echo "DAP_VERSION='$(apt-cache policy libdap-dev | grep '*')'" >> .NcLibs; \
    fi
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${DAP_VERSION}" ]]; then \
      wget -O - "https://www.opendap.org/pub/source/libdap-${DAP_VERSION}.tar.gz"  | tar -xz -C /usr/local/src/ \
      && cd /usr/local/src/curl-${DAP_VERSION}/ \
      && ./configure --prefix=/usr/local \
      && make \
      && make install \
      && ldconfig \
      && echo "DAP_VERSION='${DAP_VERSION}'" >> .NcLibs; \
    fi

# HDF5   (Installing this from source is *slow*!)
# Instructions: https://github.com/HDFGroup/hdf5/blob/develop/release_docs/INSTALL
# Versions: https://support.hdfgroup.org/ftp/HDF5/releases/
# Prerequisites: zlib, MPI, MPI-IO
ARG HDF5_VERSION=""
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${HDF5_VERSION}" ]]; then \
      apt-get update \
      && apt-get install --no-install-recommends -y libopenmpi-dev zlib1g-dev \
      && apt-get purge curl libhdf5-dev -y \
      && apt-get autoremove -y; \
    elif [ -n "${NETCDF_VERSION}"]; then  \
      apt-get update \
      && apt-get install --no-install-recommends -y libhdf5-dev \
      && echo "HDF5_VERSION='$(apt-cache policy libhdf5-dev | grep '*')'" >> .NcLibs; \
    fi
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${HDF5_VERSION}" ]]; then \
      wget -O - https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(echo "${HDF5_VERSION}" | sed -r 's/([[:digit:]]+\.[[:digit:]]+).*/\1/')/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.bz2 | tar -xj -C /usr/local/src/ \
      && cd /usr/local/src/hdf5-${HDF5_VERSION} \
      && ./configure --prefix=/usr/local --enable-parallel --enable-threadsafe --enable-unsupported \
      && make install \
      && ldconfig \
      && echo "HDF5_VERSION='${HDF5_VERSION}'" >> .NcLibs; \
    fi

# netCDF-C
# Instructions: https://github.com/Unidata/netcdf-c/blob/main/INSTALL.md
# Versions: https://github.com/Unidata/netcdf-c/releases
# Prerequisites: zlib, hdf5, curl
#
# NOTE1: CPATH is needed as mpi header files from the package manager are not in a standard location.
# NOTE2: There is no specific way to tell configure which HDF5 library to use,
#        we can only influence it by making sure it's on the inc/lib paths if we built from source
#        and having it in /usr/local/lib does the trick.
RUN if [ -n "${NETCDF_VERSION}" ]; then \
      apt-get update \
      && apt-get install --no-install-recommends -y libopenmpi-dev \
      && apt-get purge libnetcdf-dev -y \
      && apt-get autoremove -y; \
    else \
      apt-get update \
      && apt-get install --no-install-recommends -y libnetcdf-dev \
      && echo "NETCDF_VERSION='$(apt-cache policy libnetcdf-dev | grep '*')'" >> .NcLibs; \
    fi
RUN if [ -n "${NETCDF_VERSION}" ]; then \
      wget -O - https://github.com/Unidata/netcdf-c/archive/refs/tags/v${NETCDF_VERSION}.tar.gz | tar -xz -C /usr/local/src/ \
      && cd /usr/local/src/netcdf-c-${NETCDF_VERSION}/ \
      && export CPATH=/usr/lib/x86_64-linux-gnu/openmpi/include \
      && ./configure --prefix=/usr/local \
      && make install \
      && ldconfig \
      && echo "NETCDF_VERSION='${NETCDF_VERSION}'" >> .NcLibs; \
    fi

# NCO
# Must be installed from source if netcdf is, or else the package dependency on
# libnetcdf will override our netcdf version
#
# Instructions: https://nco.sourceforge.net/#bld
# Versions: https://github.com/Unidata/netcdf-c/releases
# Prerequisites: ANTLR, GSL, netCDF, OPeNDAP, UDUnits
ARG NCO_VERSION="5.1.6"
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${NCO_VERSION}" ]]; then \
      apt-get update \
      && apt-get install --no-install-recommends -y antlr libantlr-dev gsl-bin libgsl-dev udunits-bin libudunits2-0 libudunits2-dev \
      && apt-get purge nco -y \
      && apt-get autoremove -y; \
    else \
      apt-get update \
      && apt-get install --no-install-recommends -y nco; \
    fi
RUN if [[ -n "${NETCDF_VERSION}" ]] && [[ -n "${NCO_VERSION}" ]]; then \
     wget -O - https://github.com/nco/nco/archive/${NCO_VERSION}.tar.gz | tar -xz -C /usr/local/src/ \
      && cd /usr/local/src/nco-${NCO_VERSION}/ \
      && ./configure --prefix=/usr/local \
      && make install \
      && ldconfig; \
    fi
RUN echo "NCKS_VERSION='$(ncks --revision 2>&1 | head -n 3 | tr '\n' '|')'" >> .NcLibs

# Clean up OS packages
RUN apt-get clean \
    && apt-get autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

# Install R library packages
ARG MRAN=https://cran.rstudio.com/
ENV MRAN=${MRAN}

ARG R_LIBRARIES="dplyr ncdf4 tidync"
RUN for R_LIB in $R_LIBRARIES; do R -q -e "install.packages('${R_LIB}', repos='${MRAN}')"; done

# Install any custom test scripts, and prepare to run something on startup
COPY *.r .
ENTRYPOINT ["Rscript"]
CMD ["opendap_ncml_test.r"]
