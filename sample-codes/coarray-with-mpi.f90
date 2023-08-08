program main
   use, intrinsic :: iso_fortran_env
   use mpi_f08
   implicit none
   
   integer(int32) :: rank, petot, ierr
   integer(int32) :: array[*]
   
   call mpi_comm_size(mpi_comm_world, petot, ierr)
   call mpi_comm_rank(mpi_comm_world, rank, ierr)
   
   print '(a,i2,a,i2,a,i2,a,i2)', &
      'this rank is ', rank, ' of ', petot, &
      ' | this image is ', this_image(), ' of ', num_images()
   
end program main