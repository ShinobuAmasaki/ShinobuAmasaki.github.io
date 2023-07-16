---
title: Test Fortran code
date: 2023-07-16
description: test
---

# Hello world code with coarray in modern Fortran

Following code is written in modern Fortran with Coarray extension.

```fortran
program main
   use, intrinsic :: iso_fortran_env, only: int32
   implicit none

   integer(int32), codimension[*] :: array
   integer(int32) :: thisis, petot

   thisis = this_image()
   petot = num_images()

   print '(a,i0,a,i0)', 'Hello coarray world, this processor element is ', thisis, '/', petot
   sync all

end program main
```

Above code is executed and outs following:

```bash
% export FPM_FC=caf
% export FPM_FFLAGS="-I/usr/lib64 -I/usr/include -fcoarray=lib"

% fpm install --prefix .
% cafrun -n 64 bin/hellocoarray
Hello coarray world, this is 17/64
Hello coarray world, this is 18/64
Hello coarray world, this is 19/64
Hello coarray world, this is 20/64
Hello coarray world, this is 21/64
Hello coarray world, this is 22/64
Hello coarray world, this is 23/64
Hello coarray world, this is 24/64
Hello coarray world, this is 25/64
Hello coarray world, this is 26/64
Hello coarray world, this is 27/64
Hello coarray world, this is 28/64
Hello coarray world, this is 29/64
Hello coarray world, this is 30/64
Hello coarray world, this is 31/64
Hello coarray world, this is 32/64
Hello coarray world, this is 33/64
Hello coarray world, this is 34/64
Hello coarray world, this is 35/64
Hello coarray world, this is 36/64
Hello coarray world, this is 37/64
Hello coarray world, this is 38/64
Hello coarray world, this is 39/64
Hello coarray world, this is 40/64
Hello coarray world, this is 41/64
Hello coarray world, this is 42/64
Hello coarray world, this is 43/64
Hello coarray world, this is 44/64
Hello coarray world, this is 45/64
Hello coarray world, this is 46/64
Hello coarray world, this is 47/64
Hello coarray world, this is 48/64
Hello coarray world, this is 49/64
Hello coarray world, this is 50/64
Hello coarray world, this is 51/64
Hello coarray world, this is 52/64
Hello coarray world, this is 53/64
Hello coarray world, this is 54/64
Hello coarray world, this is 55/64
Hello coarray world, this is 56/64
Hello coarray world, this is 57/64
Hello coarray world, this is 58/64
Hello coarray world, this is 59/64
Hello coarray world, this is 60/64
Hello coarray world, this is 61/64
Hello coarray world, this is 62/64
Hello coarray world, this is 63/64
Hello coarray world, this is 64/64
Hello coarray world, this is 4/64
Hello coarray world, this is 5/64
Hello coarray world, this is 6/64
Hello coarray world, this is 7/64
Hello coarray world, this is 8/64
Hello coarray world, this is 9/64
Hello coarray world, this is 10/64
Hello coarray world, this is 11/64
Hello coarray world, this is 12/64
Hello coarray world, this is 13/64
Hello coarray world, this is 14/64
Hello coarray world, this is 15/64
Hello coarray world, this is 16/64
Hello coarray world, this is 1/64
Hello coarray world, this is 2/64
Hello coarray world, this is 3/64
```

The compiler command `caf` is implemented by OpenCoarrays.  `cafrun` is the execution command.

Above `FFLAGS`(`FPM_FFLAGS`) is set for Gentoo Linux:

 - `/usr/lib64` includes the `mpi_f08.mod` file of gfortran.
 - `/usr/include` tend to include other `*.mod` files.
