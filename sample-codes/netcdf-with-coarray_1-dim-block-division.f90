program main
   use, intrinsic :: iso_fortran_env
   use :: mpi_f08
   use :: netcdf
   implicit none

   integer :: thisis, petot, ierr
   logical :: isImage1


   real(real64) :: global_min_x, global_max_x, global_min_y, global_max_y
   integer :: i, j

   ! For netCDF
   real(real64), allocatable :: x(:), y(:)
   real(real64), dimension(:,:), allocatable :: local_data
   real(real64), codimension[*] :: step_x, step_y

   integer, parameter :: nx = 1024
   integer, parameter :: ny = nx
   integer, parameter :: nz = 1

   integer(int32) :: ncid
   integer(int32) :: dim_id_x, dim_id_y
   integer(int32) :: var_id_x, var_id_y, var_id_elevation
   character(len=6), parameter :: out_nc_file = 'out.nc'
   integer(int32) :: start_nc(2), count_nc(2)

   real(real64), parameter :: init_value_dp = 1d0
   character(3), parameter :: fmt='(a)'

   ! Division
   integer :: ndiv
   integer, allocatable :: local_nx(:)
   integer, allocatable :: local_ny(:)
   integer :: n_begin_x, n_end_x

   ! MPI
   type(mpi_comm) :: comm
   type(mpi_info) :: info

   block ! Initialize
      comm = MPI_COMM_WORLD
      info = MPI_INFO_NULL

      thisis = this_image()
      petot = num_images()
      isImage1 = (thisis == 1)

      global_min_x = 0d0
      global_max_x = 1d0
      global_min_y = 0d0
      global_max_y = 1d0
   end block


   block
      integer :: modulus
      ndiv = petot
      allocate(local_nx(1:ndiv))
      allocate(local_ny(1:ndiv))
      
      do concurrent (i = 1:ndiv)
         local_nx(i) = int(nx/ndiv, int32)
      end do 
      
      modulus = mod(nx, ndiv)
      if(modulus /= 0) then     
         local_nx(1:modulus) = local_nx(1:modulus) + 1
      end if
      
      local_ny(:) = ny
      
      n_begin_x = sum(local_nx(1:(thisis-1))) + 1
      n_end_x = n_begin_x + local_nx(thisis) -1

   end block

   block  ! Define nc
      call check( nf90_create_par(trim(out_nc_file), NF90_HDF5, comm%mpi_val, info%mpi_val, ncid) )
      call check( nf90_def_dim(ncid, 'x', nx, dim_id_x) )
      call check( nf90_def_dim(ncid, 'y', ny, dim_id_y) )
      call check( nf90_def_var(ncid, 'x', NF90_DOUBLE, dim_id_x, var_id_x))
      call check( nf90_def_var(ncid, 'y', NF90_DOUBLE, dim_id_y, var_id_y))
      call check( nf90_def_var(ncid, 'elevation', NF90_DOUBLE, [dim_id_x, dim_id_y], var_id_elevation, deflate_level=1 ))

      call check( nf90_put_att(ncid, var_id_x, 'units', 'meter') )
      call check( nf90_put_att(ncid, var_id_y, 'units', 'meter') )
      call check( nf90_put_att(ncid, var_id_elevation, 'units', 'meter') )

      call check( nf90_enddef(ncid) )
   end block
   if (isImage1) write(*, fmt) 'nc definition completed.'
   
   ! Define x-y dimension
   block 
      step_x = (global_max_x - global_min_x)/dble(nx)
      step_y = (global_max_y - global_min_y)/dble(ny)

      allocate (x(nx), source=init_value_dp)
      allocate (y(ny), source=init_value_dp)

      x(:) = [(global_min_x + (sum(local_nx(1:thisis-1))+dble(i-1))*step_x, i=1, nx)]
      y(:) = [(global_min_y + dble(j-1)*step_y, j=1, ny)]
   end block
   if (isImage1) write(*, fmt) 'x-y dimensions are defined.'

   ! Write x-axis and y-axis into nc
   block
      call check( nf90_put_var(ncid, var_id_x, x, start=[n_begin_x], count=[local_nx(thisis)]))

      if (thisis == 1) then
         call check( nf90_put_var(ncid, var_id_y, y, start=[1], count=[ny] ))
      end if
   end block
   if (isImage1) write(*, fmt) 'X-axis and Y-axis have been written.'

   ! Write main data
   block
      allocate(local_data(1:local_nx(thisis), ny))

      local_data(:,:) = thisis
      start_nc = [n_begin_x, 1]
      count_nc = [local_nx(thisis), local_ny(thisis)]
      call check( nf90_put_var(ncid, var_id_elevation, local_data, start=start_nc, count=count_nc))
   end block

   call check(nf90_close(ncid))
   if (isImage1) write(*, fmt) out_nc_file//' is finalized.'

contains

   subroutine check(status)
      implicit none
      integer, intent(in) :: status
      integer :: ierr
      
      if(status .ne. NF90_noerr) then
         print '(a,i3,a)', 'Image: ', this_image(), ': '//trim(nf90_strerror(status))
         error stop
      end if
   end subroutine check
   

end program main
    
