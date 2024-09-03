program main
   use, intrinsic :: iso_fortran_env
   implicit none

   integer :: length, outuni
   integer(int16) :: dat, fill(128)
   integer :: thisis, petot, ierr, offset
   
   character(8), parameter :: out_file='out.bin'
   
   dat = int(this_image(), int16)
   fill(:) = -1
   
   !
   if (this_image() == 1) then
      open(newunit=outuni, file=out_file, form='unformatted', &
         access='stream', status='replace')
      write(outuni) fill(:)
      close(outuni)
   end if
   sync all
   
   inquire (iolength=length) dat
   offset = 1 + (this_image() - 1)*2
   
   open(newunit=outuni, file=out_file, access='direct', recl=length, status='old')
   write(outuni, rec=offset) dat
   close(outuni)
   sync all
   
end program main
