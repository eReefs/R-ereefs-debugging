# R-ereefs-debugging

This respository contains a docker environment definition for use in debugging problems accessing eReefs datasets from R

## Usage

### Step 1. Set up a bunch of environment variables to define your test environment

These will be referenced in docker commands later on.

```bash
export CURL_VERSION="7.88.1"
export HDF5_VERSION="1.14.0"
export NETCDF_VERSION="4.9.2"
export R_VERSION="4.3.0"
export BASE_IMAGE="r-base:${R_VERSION}"
export R_SCRIPT="opendap_ncml_test.r"
```

&nbsp;

### Step 2. Build the Docker Image

Setting explicit build arguments according to the test environment you're trying to build.

This example uses the environment variables exported in the previous step.

```bash
docker build \
  --build-arg "CURL_VERSION=${CURL_VERSION}" \
  --build-arg "HDF5_VERSION=${HDF5_VERSION}" \
  --build-arg "NETCDF_VERSION=${NETCDF_VERSION}" \
  --build-arg "R_VERSION=${R_VERSION}" \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --tag "r-ereefs-debugging:r${R_VERSION}-curl${CURL_VERSION}-hdf5${HDF5_VERSION}-netcdf${NETCDF_VERSION}" \
  .
```

The full set of supported build arguments are:

- `CURL_VERSION` => The version of `curl` (and `libcurl`) that should be used for testing. Default is `8.1.2`, [released 2023-05-30](https://github.com/curl/curl/releases)
- `HDF5_VERSION` => The version of the HDF 5 library that should be compiled for testing. Default is `1.14.0`, [released 2023-02-08](https://support.hdfgroup.org/ftp/HDF5/releases/). (Note for HDF5 v1.14+, you need netcdf 4.9.2 or later)
- `NETCDF_VERSION` => The version of the netCDF-C library that should be compiled for testing. Default is `4.9.2`, [released 2023-03-14](https://github.com/Unidata/netcdf-c/releases)
- `R_LIBRARIES` => Space-seperated list of R library packages that should be installed from CRAN. Default is `dplyr ncdf4 tidync`
- `R_VERSION` => The version of R that should be used.  Default is `4.3.0`
- `BASE_IMAGE` => The base docker image that should be used.  Default is `r-base:${R_VERSION}`

The build may take quite a while, as it will attempt to compile the CURL, HDF5 and netCDF-C libraries from source, which is slow!

&nbsp;


### Step 3. Use the docker image to run your test script

Bind-mount the R script you want to run into the `/app` working directory, and also specify the name of that script as the run command.   Save the results to a logfile for later comparison.

This example uses the environment variables exported in Step 1.

```bash
docker run \
    --volume ${PWD}/${R_SCRIPT}:/app/${R_SCRIPT} \
    r-ereefs-debugging:r${R_VERSION}-netcdf${NETCDF_VERSION}-curl${CURL_VERSION} \
    ${R_SCRIPT} \
    > "${R_SCRIPT}_r${R_VERSION}-netcdf${NETCDF_VERSION}-curl${CURL_VERSION}.log" 2>&1
```
