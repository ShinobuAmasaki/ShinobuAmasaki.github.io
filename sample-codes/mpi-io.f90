program main
   use, intrinsic :: iso_fortran_env
   use mpi_f08
   implicit none

   integer :: i
   character(len=7), parameter :: out_file='out.bin'

   integer :: outuni
   integer(int16) :: fill(528)

   integer,parameter :: count = 8
 
   integer(int16) :: buf(count)[*]

   ! for MPI I/O
   integer :: ierr, amode, whence
   integer(MPI_OFFSET_KIND) :: offset
   type(MPI_INFO) :: info
   type(MPI_FILE) :: fh
   type(MPI_STATUS) :: stat
   integer :: resultlen
   character(len=MPI_MAX_ERROR_STRING) :: err_message
   integer :: rank

   ! Preprocessing
   fill(:) = -1
   if (this_image() == 1) then
      open (newunit=outuni, file=out_file, form='unformatted', access='stream', status='replace')
      write(outuni) fill(:)
      close(outuni)
   end if
   sync all
   ! End of preprocessing
   
   ! Create data
   if (this_image() == 1) then
      buf(:) = int(this_image(), int16)
   end if
   
   call co_broadcast(buf, source_image=1)
   do i = 1, count
      buf(i) = buf(i) * this_image()
   end do


   ! MPI I/O
   info = MPI_INFO_NULL
   amode = MPI_MODE_WRONLY + MPI_MODE_CREATE
   call mpi_file_open(mpi_comm_world, out_file, amode, info, fh, ierr)
   call print_error_message(ierr)

   offset = 16
   whence = MPI_SEEK_SET

   call mpi_file_seek_shared (fh, offset, whence, ierr)
   call print_error_message(ierr)

   call mpi_file_write_shared(fh, buf, count, MPI_INTEGER2, stat, ierr)
   !call mpi_file_write_ordered(fh, buf, count, MPI_INTEGER2, stat, ierr)
   call print_error_message(ierr)
   
   call mpi_file_close(fh, ierr)
   call print_error_message(ierr)

contains

   subroutine print_error_message (ierr)
      implicit none
      integer, intent(in) :: ierr
      character(MPI_MAX_ERROR_STRING) :: message
      integer :: resultlen

      if (ierr /= 0) then
         call mpi_error_string(ierr, message, resultlen)
         print *, trim(message)
      end if
   end subroutine print_error_message

end program main 
