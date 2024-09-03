!
! Libpq-Fortran: Simulation with Database Sample code 
!
! Copyright 2023, Amasaki Shinobu

program main
   use, intrinsic :: iso_fortran_env
   use, intrinsic :: iso_c_binding
   use :: libpq

   implicit none

   real(real64), parameter :: tend = 0.6d0
   real(real64), parameter :: tout_interval = 0.1d0

   integer, parameter :: NX = 200     ! 分割格子の数
   real(real64), parameter :: L = 1d0 ! 計算領域長さ

   character(*), parameter  :: fmtOut   = '(e10.3, 1x, e10.3, 1x, i0)'
   character(*), parameter  :: fmtErrOut= "('  output  ', 'step=', i8, ' time=', e10.3, ' nth_out =', i3)"
   character(*), parameter  :: fmtStop  = "('  stop    ', 'step=', i8, ' time=', e10.3)"
   
   character(:), allocatable :: filename
   integer :: k

   real(real64) :: cs, dt, dx
   integer :: nstep, offset_k

   type(c_ptr) :: conn
   character(:), allocatable :: conninfo
   character(10) :: date = '2023-11-26'
   
   conninfo = 'host=localhost dbname=simulation user=shinobu'
   conn = PQconnectdb(conninfo)

   if (PQstatus(conn) /= 0) then
      print *, PQerrorMessage(conn)
      error stop 
   end if

   offset_k = 1
   do k = 1, 16
      cs = 1d0
      dt = 5d-4  + 3d-4*dble(k)
      dx = L/dble(nx)
      call main_loop(cs, dt, dx, nstep, filename, offset_k, k, 'LF_')
      call data_registration(conn, 'Lax-Friedrich', filename, offset_k, k, cs, dt, dx, nstep, date)
   end do
   
   offset_k = 17
   do k = 1, 16
   	cs = 1d0
   	dt = 5d-4  + 3d-4*dble(k)
   	dx = L/dble(nx)
   	call main_loop(cs, dt, dx, nstep, filename, offset_k, k, 'LW_')
      call data_registration(conn, 'Lax-Wendroff', filename, offset_k, k, cs, dt, dx, nstep, date)
   end do
   
contains

   subroutine main_loop(cs, dt, dx, nstep, filename, offset_k, k, prefix)
      implicit none
      real(real64), intent(in) :: cs, dt, dx
      integer(int32), intent(in) :: k
      character(:), allocatable, intent(inout) :: filename
      integer :: offset_k
      character(*), intent(in) :: prefix
      integer, intent(out) :: nstep

      character(4) :: code
      integer :: nstop, nth_out
      real(real64) :: tout, time
      real(real64) :: Courant
      
      integer :: i
      integer :: uni

      real(real64), allocatable :: x(:)
      real(real64), allocatable :: u(:), f(:), u_new(:), f0(:)

      write(code, '(1i4.4)') k + (offset_k - 1)


      Courant = cs*dt/dx

      write(error_unit, '(a, i0, a)') "### START ", k, "-th Simulation ###"
      write(error_unit, '(a, f10.3)') " Courant number: ", Courant

      ! Initialize
      uni = 100
      nth_out = 0
      nstep = 1
      time = 0d0
      nstop = 200
      tout = 0
      allocate(x(0:nx), source=0d0)
      allocate(u(0:nx), source=0d0)
      allocate(u_new(0:nx), source=0d0)
      allocate(f0(0:nx), source=0d0)
      allocate(f(0:nx), source=0d0)


      ! Set grid
      x(0) = 0d0
      do i = 1, nx
         x(i) = x(0) + dx*dble(i)
      end do

      ! Set initial condition
      do i = 0, nx
         if (x(i) < 0.1d0) then
            u(i) = 1d0
         else
            u(i) = 0d0
         end if
      end do

      filename = 'result/'//trim(adjustl(prefix))//code//'.dat'
      open(uni, file=filename, form='formatted', status='replace')
      call data_output(uni, x, u, tout, time, 0, nth_out)

      do
         nstep = nstep + 1
         time = time + dt

         f0(:) = cs*u(:) ! numerical flux

         ! Lax-Friedrich scheme
         if (trim(prefix) == 'LF_') then
            do i = 1, nx-1
               f(i) = 0.5d0*(f0(i+1)+f0(i)) - 0.5d0*dx/dt *(u(i+1) - u(i))
            end do          
         end if

         ! Lax-Wendroff scheme
         if (trim(prefix) == 'LW_') then
            do i = 1, nx-1
               f(i) = 0.5d0*( (1d0-Courant)*f0(i+1) + (1d0+Courant)*f0(i) )
            end do
         end if


         do i = 1, nx-1 
            u_new(i) = u(i) - Courant*(f(i) - f(i-1))
         end do

         ! Update
         u(2:nx-1) = u_new(2:nx-1)

         ! BC
         u(1) = u(2)
         u(nx) = u(nx-1)

         if (time >= tout) call data_output(uni, x, u, tout, time, nstep, nth_out)

         if (time > tend) exit

      end do

      close(uni)

      write(error_unit, fmtStop) nstep, time
      write(error_unit, '(a)') "### Normal STOP ###"

   end subroutine main_loop


   subroutine data_output (uni, x, u, tout, time, nstep, nth_out)
      implicit none
      integer, intent(in) :: uni
      real(real64), intent(inout) :: tout
      real(real64), intent(in) :: time
      integer, intent(in) :: nstep
      integer, intent(inout) :: nth_out 

      real(real64), intent(in) :: x(:), u(:)

      integer :: i

      ! write(uni, '(a, i0)') '> -Z', nth_out
      do i = 1, nx
         write(uni, fmtOut) x(i), u(i)
      end do
      write(uni, '(/)')

      tout = tout + tout_interval

      write(error_unit, fmtErrOut) nstep, time, nth_out
      nth_out = nth_out + 1
   end subroutine data_output


   subroutine data_registration(conn, simu_name, filename, offset_k, k, cs, dt, dx, nstep, date)
      use :: iso_c_binding
      use :: libpq
      implicit none
      type(c_ptr), intent(in) :: conn
      character(*), intent(in) :: simu_name
      character(*), intent(in) :: filename
      integer, intent(in) :: k, offset_k
      real(real64), intent(in) :: cs, dt, dx
      integer, intent(in) :: nstep
      character(*), intent(in) :: date

      character(:), allocatable :: query
      character(256) :: values(11)

      type(c_ptr) :: res
      real(real64) :: Courant
      character(4) :: code
      integer :: i

      Courant = cs*dt/dx

      write(code, '(1i4.4)') k + (offset_k-1)
      values(1) = code
      values(2) = trim(adjustl(date))
      values(3) = trim(simu_name)
      write(values(4),  '(f16.8)') cs
      write(values(5),  '(f16.8)') dt
      write(values(6),  '(f16.8)') dx
      write(values(7),  '(f16.8)') Courant
      write(values(8),  '(f16.8)') L 
      write(values(9),  '(i0)') nx
      write(values(10), '(i0)') nstep
      values(11) = trim(adjustl(filename)) 

      do i = 1, 9
         values(i) = trim(adjustl(values(i)))
      end do

      query = 'insert into advection &
      &        (sim_id, start_date, sim_name, cs, dt, dx, courant, l, nx, nstep, dat_file) &
      & values ($1,     $2,         $3,       $4, $5, $6, $7,     $8, $9, $10,   $11)'

      res = PQexecParams(conn, query, 11, [(0, i=1,11)], values(:))

      if (PQresultStatus(res) /= PGRES_COMMAND_OK) then
         print *, PQerrorMessage(conn)
      end if

      call PQclear(res)

   end subroutine data_registration

end program main


